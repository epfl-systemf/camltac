"""Embed the OCaml API documentation of MLtac2 (``ltac2.mli``) in the Sphinx site.

At ``builder-inited`` the extension

1. resolves the ``[%%if rocq >= (a, b)]`` conditionals of the installed
   ``ltac2.mli`` for a given Rocq version and compiles the result to a ``.cmti``;
2. runs ``odoc`` on it, producing one HTML fragment per module;
3. writes one reStructuredText page per module into ``<srcdir>/reference/ltac2-apis/``
   (a ``.. raw:: html`` block, with odoc's cross-links rewritten to point to the
   sibling pages) so that the API is rendered by Shibuya like the rest of the docs.

The generated pages are build artifacts (git-ignored). Configuration values:

* ``mltac2_api_mli``: path of ``ltac2.mli`` (default: the one installed by the
  ``rocq-mltac2`` opam package, found through ``ocamlfind``);
* ``mltac2_api_version``: version of MLtac2 shown on the page, available in
  reStructuredText as ``|mltac2-version|`` (default: the version of the installed
  ``rocq-mltac2`` opam package, found through ``ocamlfind``);
* ``mltac2_api_rocq_version``: ``"major.minor"`` used to resolve the
  conditionals (default: the version of the ``rocq`` found in ``PATH``);
* ``mltac2_api_outdir``: output directory, relative to the source directory;
* ``mltac2_api_rocq_doc``: base URL of the Rocq OCaml API documentation, to which
  references to Rocq's modules (``Proofview.tactic``, ``Names.Id.t``, …) are linked
  (default: the ``rocq-runtime`` documentation of the Rocq version in use).

The role ``:ltac2-type:`name``` links to the Ltac2 type ``name`` on that page,
``:ltac2-val:`Ltac2.Module.name``` to a value of another Ltac2 module, and
``:rocq-api:`Module.Path.name``` (resp. ``:rocq-type:``) to the value (resp. type)
``name`` in Rocq's OCaml API documentation (``mltac2_api_rocq_doc``). All are styled like the cross-references
of the API itself.

Requires ``odoc`` and ``ocamlfind`` in ``PATH``.
"""
import html as html_lib
import json
import posixpath
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

from docutils import nodes
from sphinx.util import logging

logger = logging.getLogger(__name__)

_STATIC = Path(__file__).parent / "static"
_PACKAGES = "rocq-runtime.vernac,rocq-runtime.plugins.ltac"
_ROOT = "Ltac2"  # name of the top-level module in the generated documentation


def _run(cmd, **kw):
    return subprocess.run(cmd, check=True, capture_output=True, text=True, **kw)


def _default_mli():
    return Path(_run(["ocamlfind", "query", "rocq-mltac2"]).stdout.strip()) / "ltac2.mli"


def _default_version():
    return _run(["ocamlfind", "query", "-format", "%v", "rocq-mltac2"]).stdout.strip()


def _default_rocq_version():
    out = _run(["rocq", "--version"]).stdout
    m = re.search(r"version (\d+)\.(\d+)", out)
    return f"{m[1]}.{m[2]}"


def _default_rocq_doc(version):
    return f"https://rocq-prover.org/doc/V{version}.0/api/rocq-runtime/"


def _preprocess(src, version):
    """Resolve the ``[%%if rocq >= (a, b)]`` / ``[%%else]`` / ``[%%endif]`` lines."""
    major, minor = map(int, version.split("."))
    out, stack = [], []
    for line in src.splitlines():
        if m := re.match(r"\s*\[%%if rocq >= \((\d+), (\d+)\)\]", line):
            stack.append((major, minor) >= (int(m[1]), int(m[2])))
        elif re.match(r"\s*\[%%else\]", line):
            stack[-1] = not stack[-1]
        elif re.match(r"\s*\[%%endif\]", line):
            stack.pop()
        elif all(stack):
            out.append(line)
    return "\n".join(out) + "\n"


def _compile_rocq(work):
    """Compile the installed ``.cmti`` of ``rocq-runtime`` into ``work/rocq``, so
    that odoc can resolve (and link) references to Rocq's modules."""
    out = work / "rocq"
    out.mkdir()
    root = Path(_run(["ocamlfind", "query", "rocq-runtime"]).stdout.strip())
    for cmti in root.rglob("*.cmti"):
        if "__" in cmti.name or "plugins" in cmti.parts:  # hidden (wrapped) modules
            continue
        subprocess.run(["odoc", "compile", "--package", "rocq-runtime", "-o", str(out / f"{cmti.stem}.odoc"), str(cmti)],
                       capture_output=True)  # modules that fail to compile are simply left unlinked
    return out


def _odoc(mli, rocq_version, rocq_doc, work):
    """Build odoc's JSON output for ``mli`` into ``work/json``.

    References to Rocq's modules are linked to ``rocq_doc``, the base URL of the
    ``rocq-runtime`` package documentation."""
    src = work / "src"
    src.mkdir()
    rocq = _compile_rocq(work)
    (src / "ltac2.mli").write_text(_preprocess(mli.read_text(), rocq_version))
    _run(["ocamlfind", "ocamlc", "-package", _PACKAGES, "-bin-annot", "-c", "ltac2.mli"], cwd=src)
    # odoc treats modules whose name contains "__" as hidden, hence we compile
    # ltac2.mli ourselves instead of using the installed Mltac2__Ltac2.cmti.
    _run(["odoc", "compile", "--package", "mltac2", "-I", str(rocq), "-o", str(work / "ltac2.odoc"), str(src / "ltac2.cmti")])
    _run(["odoc", "link", "-I", str(rocq), "-I", str(work), str(work / "ltac2.odoc")])
    _run(["odoc", "html-generate", "--as-json", "-R", f"rocq-runtime:{rocq_doc}",
          "-o", str(work / "json"), str(work / "ltac2.odocl")])
    return work / "json" / "mltac2"


_HREF = re.compile(r'href="([^"#]*)(#[^"]*)?"')
_HEADING = re.compile(r'<h(\d) id="([^"]*)">(.*?)</h\1>', re.S)
_UNDERLINES = "-~^\"'+"


def _module_of(path):
    """Module name of an odoc page directory: ``Ltac2/Constr`` -> ``Ltac2.Constr``."""
    return path.replace("/", ".")


def _fix_links(html, page_dir, dirname, is_root):
    """Rewrite odoc's relative ``…/index.html#frag`` links to our flat pages.

    The root module is included in ``<dirname>.rst``, next to the directory
    holding the other modules."""
    def sub(m):
        target, frag = m[1], m[2] or ""
        if not target or re.match(r"[a-z]+:", target):
            return m[0]
        resolved = posixpath.normpath(posixpath.join(page_dir, target))
        resolved = re.sub(r"(^|/)index\.html$", "", resolved).removeprefix("mltac2/")
        module = _module_of(resolved)
        if "." not in module:
            href = f"{dirname}.html" if is_root else f"../{dirname}.html"
        else:
            href = f"{module}.html" if not is_root else f"{dirname}/{module}.html"
        return f'href="{href}{frag}"'
    return _HREF.sub(sub, html)


_SEE = re.compile(
    r'(<li class="see"><span class="at-tag">see</span>) <a href="([^"]*)" class="value">[^<]*</a>\s*<p>(.*?)</p>',
    re.S)


def _simplify_see(html):
    """``@see <url> text`` shows ``text`` as the link, instead of the (long) URL."""
    return _SEE.sub(r'\1 <a href="\2">\3</a>', html)


_DEFAULT = re.compile(
    r'(<li class="parameter">.*?<span class="value">[^<]*</span>) <p>\(default = (.*?)\)(?= |</p>)\s*(.*?)</p>',
    re.S)


def _move_defaults(html):
    """Show ``@param x (default = v) …`` as a "default" badge next to ``x``."""
    def sub(m):
        rest = f" <p>{m[3]}</p>" if m[3] else ""
        return f'{m[1]} <span class="param-default">default: {m[2]}</span>{rest}'
    return _DEFAULT.sub(sub, html)


def _raw(html):
    """A ``.. raw:: html`` block, or nothing if ``html`` is blank."""
    if not html.strip():
        return []
    body = ['<div class="odoc">', *html.splitlines(), "</div>"]  # scope of mltac2-api.css
    return [".. raw:: html", ""] + ["   " + l if l else "" for l in body] + [""]


def _page(module, children, data, page_dir, dirname):
    """The page's headings become real sections (so that Shibuya lists them in
    its table of contents); everything between them stays raw HTML.

    The root module is not a page of its own: its ``.inc`` file is included by
    the hand-written ``<dirname>.rst``, which provides the title."""
    is_root = "." not in module
    html = _move_defaults(_simplify_see(_fix_links(data["preamble"] + data["content"], page_dir, dirname, is_root)))
    if is_root:
        lines, prefix = [], dirname + "/"
    else:
        title = f"``{module.rpartition('.')[2]}``"  # the sidebar is hierarchical
        lines, prefix = [f".. _mltac2-api-{module}:", "", title, "=" * len(title), "",
                         ".. rst-class:: module-path", "", f"``{module}``", ""], ""
    if children:
        lines += [".. toctree::", "   :hidden:", ""] + [f"   {prefix}{c}" for c in children] + [""]
    stack, pos = [], 0  # stack: odoc heading levels of the open sections
    for m in _HEADING.finditer(html):
        lines += _raw(html[pos:m.start()])
        pos = m.end()
        level = int(m[1])
        text = html_lib.unescape(re.sub(r"<[^>]*>", "", m[3])).strip()
        while stack and stack[-1] >= level:
            stack.pop()
        stack.append(level)
        lines += [text, _UNDERLINES[len(stack) - 1] * len(text), ""]
    lines += _raw(html[pos:])
    return "\n".join(lines)


def _ltac2_type_role(name, rawtext, text, lineno, inliner, options={}, content=[]):
    """``:ltac2-type:`constr```: link to the type in the Ltac2 API page."""
    env = inliner.document.settings.env
    literal = nodes.literal(rawtext, text)
    if env.app.builder.format != "html":
        return [literal], []
    # The page including the root module has the name of the output directory.
    uri = env.app.builder.get_relative_uri(env.docname, env.config.mltac2_api_outdir) + f"#type-{text}"
    return [nodes.reference(rawtext, "", literal, refuri=uri, classes=["api-link"])], []


def _ltac2_val_role(name, rawtext, text, lineno, inliner, options={}, content=[]):
    """``:ltac2-val:`Ltac2.Env.path```: link to a value in the page of its Ltac2 module."""
    env = inliner.document.settings.env
    literal = nodes.literal(rawtext, text)
    if env.app.builder.format != "html":
        return [literal], []
    *path, value = text.split(".")
    page = f"{env.config.mltac2_api_outdir}/{'.'.join(path)}"
    uri = env.app.builder.get_relative_uri(env.docname, page) + f"#val-{value}"
    return [nodes.reference(rawtext, "", literal, refuri=uri, classes=["api-link"])], []


def _rocq_api_link(kind, rawtext, text, inliner):
    config = inliner.document.settings.env.config
    literal = nodes.literal(rawtext, text)
    if not config.mltac2_api_rocq_doc:  # not resolved: the API generation failed
        return [literal], []
    *path, name = text.split(".")
    uri = f"{config.mltac2_api_rocq_doc}{'/'.join(path)}/index.html#{kind}-{name}"
    return [nodes.reference(rawtext, "", literal, refuri=uri, classes=["api-link"])], []


def _rocq_api_role(name, rawtext, text, lineno, inliner, options={}, content=[]):
    """``:rocq-api:`Evarutil.new_evar```: link to a value of Rocq's OCaml API."""
    return _rocq_api_link("val", rawtext, text, inliner)


def _rocq_type_role(name, rawtext, text, lineno, inliner, options={}, content=[]):
    """``:rocq-type:`Environ.env```: link to a type of Rocq's OCaml API."""
    return _rocq_api_link("type", rawtext, text, inliner)


def _define_version(app, version):
    """Make ``|mltac2-version|`` available in every reStructuredText source."""
    app.config.rst_epilog = (app.config.rst_epilog or "") + f"\n.. |mltac2-version| replace:: {version}\n"


def _generate(app):
    srcdir = Path(app.srcdir)
    outdir = srcdir / app.config.mltac2_api_outdir
    try:
        mli = Path(app.config.mltac2_api_mli) if app.config.mltac2_api_mli else _default_mli()
        version = app.config.mltac2_api_rocq_version or _default_rocq_version()
        rocq_doc = app.config.mltac2_api_rocq_doc or _default_rocq_doc(version)
        mltac2_version = app.config.mltac2_api_version or _default_version()
        rocq_doc = rocq_doc.rstrip("/") + "/"
        app.config.mltac2_api_rocq_doc = rocq_doc  # for the ``rocq-api`` role
        with tempfile.TemporaryDirectory() as tmp:
            pages = _odoc(mli, version, rocq_doc, Path(tmp))
            modules = {}
            for f in sorted(pages.rglob("index.html.json")):
                page_dir = "mltac2/" + f.parent.relative_to(pages).as_posix()
                modules[_module_of(page_dir.removeprefix("mltac2/"))] = (page_dir, json.loads(f.read_text()))
        _define_version(app, mltac2_version)
    except (OSError, subprocess.CalledProcessError) as e:
        _define_version(app, "(unknown)")
        detail = e.stderr if isinstance(e, subprocess.CalledProcessError) else e
        logger.warning("could not generate the MLtac2 API documentation: %s", detail)
        return

    outdir.mkdir(parents=True, exist_ok=True)
    expected = set()
    for module, (page_dir, data) in modules.items():
        # Direct children only, so that the sidebar mirrors the module hierarchy.
        children = [m for m in modules if m.rpartition(".")[0] == module]
        path = outdir / (f"{module}.inc" if "." not in module else f"{module}.rst")
        text = _page(module, children, data, page_dir, outdir.name)
        expected.add(path)
        if not path.exists() or path.read_text() != text:  # keep mtimes to avoid rebuilds
            path.write_text(text)
    for stale in [*outdir.glob("*.rst"), *outdir.glob("*.inc")]:
        if stale not in expected:
            stale.unlink()
    logger.info("generated %d MLtac2 API pages (Rocq %s)", len(modules), version)


def _add_static(app, config):
    config.html_static_path.append(str(_STATIC))


def setup(app):
    app.add_config_value("mltac2_api_mli", None, "env")
    app.add_config_value("mltac2_api_version", None, "env")
    app.add_config_value("mltac2_api_rocq_version", None, "env")
    app.add_config_value("mltac2_api_rocq_doc", None, "env")
    app.add_config_value("mltac2_api_outdir", "reference/ltac2-apis", "env")
    app.add_role("ltac2-type", _ltac2_type_role)
    app.add_role("ltac2-val", _ltac2_val_role)
    app.add_role("rocq-api", _rocq_api_role)
    app.add_role("rocq-type", _rocq_type_role)
    app.connect("config-inited", _add_static)
    app.connect("builder-inited", _generate)
    app.add_css_file("mltac2-api.css")
    return {"version": "0.1", "parallel_read_safe": True, "parallel_write_safe": True}
