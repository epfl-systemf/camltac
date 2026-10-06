"""As-you-type suggestions in the search bar.

At ``build-finished`` the extension collects

* the pages and their sections (from the toctrees),
* the documented commands and attributes (``.. cmd::`` / ``.. attr::``),
* the types, values and exceptions of the generated Ltac2 API pages (see
  ``mltac2_api``),

and writes them (``[kind, label, url, page]``) to ``_static/suggestions-data.js``. ``search-suggest.js`` shows
the best matches in a dropdown under the search box while typing; Enter on a
highlighted suggestion opens it, Enter otherwise runs the regular search.
"""
import json
import re
from pathlib import Path

from docutils import nodes

_STATIC = Path(__file__).parent / "static"
_SPEC = re.compile(r'id="(type|val|exception)-([^".]+)"')
_KINDS = {"type": "type", "val": "val", "exception": "exception"}


def _add_static(app, config):
    config.html_static_path.append(str(_STATIC))


def _pages(env, builder, skip):
    for docname, toc in env.tocs.items():
        if docname.startswith(skip):
            title = env.titles.get(docname)
            if title is not None:
                # A module page is titled with its short name: like values and types,
                # it is listed under its qualified name (the script splits it).
                if docname == skip:
                    yield "page", title.astext(), builder.get_target_uri(docname), ""
                else:
                    yield "module", docname.rpartition("/")[2], builder.get_target_uri(docname), ""
            continue
        for ref in toc.findall(nodes.reference):
            anchor = ref.get("anchorname", "")
            page = env.titles[docname].astext() if anchor else ""
            yield ("section" if anchor else "page"), ref.astext(), builder.get_target_uri(docname) + anchor, page


def _objects(env, builder):
    kinds = {"cmd-ref": "cmd", "attr-ref": "attribute"}
    for (objtype, name), (docname, node_id) in env.get_domain("std").objects.items():
        if objtype in kinds:
            yield kinds[objtype], name, f"{builder.get_target_uri(docname)}#{node_id}", ""


def _ltac2(app, outdir):
    for f in sorted(outdir.glob("*.rst")) + sorted(outdir.glob("*.inc")):
        module = f.stem
        docname = f"{outdir.relative_to(app.srcdir).as_posix()}/{module}"
        if "." not in module:  # the root module lives in the hand-written ``<dirname>.rst``
            docname = outdir.relative_to(app.srcdir).as_posix()
        uri = app.builder.get_target_uri(docname)
        seen = set()
        for kind, name in _SPEC.findall(f.read_text()):
            if (kind, name) not in seen:
                seen.add((kind, name))
                yield _KINDS[kind], f"{module}.{name}", f"{uri}#{kind}-{name}", ""


def _write(app, exception):
    if exception or app.builder.format != "html":
        return
    outdir = Path(app.srcdir) / app.config.mltac2_api_outdir
    skip = outdir.relative_to(app.srcdir).as_posix()
    entries = [*_pages(app.env, app.builder, skip), *_objects(app.env, app.builder)]
    if outdir.is_dir():
        entries += _ltac2(app, outdir)
    seen, out = set(), []
    for entry in entries:
        if entry not in seen:
            seen.add(entry)
            out.append(list(entry))
    target = Path(app.outdir) / "_static" / "suggestions-data.js"
    target.write_text("window.CAMLTAC_SUGGESTIONS=" + json.dumps(out, ensure_ascii=False) + ";\n")


def setup(app):
    app.setup_extension("mltac2_api")  # for ``mltac2_api_outdir``
    app.connect("config-inited", _add_static)
    app.connect("build-finished", _write)
    app.add_js_file("suggestions-data.js")
    app.add_js_file("search-suggest.js")
    app.add_css_file("search-suggest.css")
    return {"parallel_read_safe": True, "parallel_write_safe": True}
