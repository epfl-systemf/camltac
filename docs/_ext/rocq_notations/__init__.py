"""Styling and a small ``prodn`` directive for coqrst-like grammar productions.

The extension ships the stylesheet and the ``RocqNotations`` font (edited
upstream to center every character, needed for the sub/superscript badges).

Usage::

    .. prodn::
       term ::= fun {+ @binder } => @term
       | @term {*, @term }
       | {| forall | exists } @binder , @term

* ``name ::= prod`` starts a production (``+=`` also accepted); a line
  starting with ``|`` continues the previous one.
* ``@name`` is a hole, linked to the definition of ``name`` if there is one;
  everything else is literal. Definitions are registered as grammar tokens,
  so ```:token:`name` ``` links to them from anywhere.
* ``.. cmd:: <notation>`` documents a command: the notation is the signature
  (same syntax as a production), the indented body is the description, and
  ``:name:`` makes it referenceable with ```:cmd:`name` ```. ``attr`` works
  the same way for attributes (role ``:attribute:``).
* ``.. example:: [title]`` renders its body in an "Example" box.
* ``{+ x}``, ``{* x}``, ``{? x}`` are repeats / optionals; a separator may
  follow the symbol: ``{+, x}``.
* ``{| a | b }`` is a choice. ``%{``, ``%}``, ``%|``, ``%@`` escape.
"""
import re
from html import escape
from pathlib import Path

from docutils import nodes
from docutils.parsers.rst import directives
from sphinx import addnodes
from sphinx.util.docutils import SphinxDirective
from sphinx.util.nodes import make_id

_STATIC = Path(__file__).parent / "static"


def _add_static(app, config):
    config.html_static_path.append(str(_STATIC))


# One token of notation syntax; exactly one named group is set per match.
_TOKEN = re.compile(
    r"""
      %(?P<esc>.)                            # %{ %} %| %@ ...: a literal character
    | \{(?P<sym>[+*?])(?P<sep>[^\s]*)\s       # {+ / {* / {? with an optional separator
    | (?P<choice>\{\|\s*)                     # {|  opens a choice
    | @(?P<hole>[\w'-]+)                     # @name
    | (?P<delim>[}|])                        # closes a repeat/choice, or separates choice blocks
    | (?P<text>[^%{}|@]+|.)                  # literal text
    """,
    re.S | re.X,
)

# A production line: ``name ::= prod`` / ``name += prod``, or ``| prod`` (continuation).
_LINE = re.compile(r"^\s*(?:(?P<nt>\S+)\s+(?P<op>::=|\+=)|(?P<cont>\|))\s*(?P<prod>.*)$")


def _trim(items):
    """Strip whitespace at both ends of a list of HTML strings / nodes."""
    items = list(items)
    if items and isinstance(items[0], str):
        items[0] = items[0].lstrip()
    if items and isinstance(items[-1], str):
        items[-1] = items[-1].rstrip()
    return items


def _hole(name):
    ref = addnodes.pending_xref(
        "", nodes.inline(name, name, classes=["hole"]),
        refdomain="std", reftype="token", reftarget=name, refexplicit=True, refwarn=False)
    return ref


def _repeat(sym, sep, body):
    """HTML for ``{<sym><sep> body}``: the body followed by a sup/sub badge."""
    badges = f'<span class="notation-sup">{sym}</span>'
    if sep:
        badges += f'<span class="notation-sub">{escape(sep)}</span>'
    wrapper = "repeat-wrapper-with-sub" if sep else "repeat-wrapper"
    return [f'<span class="{wrapper}"><span class="repeat">', *body, f"</span>{badges}</span>"]


def _choice(blocks):
    """HTML for ``{| a | b }``, given the parsed blocks."""
    out = ['<span class="alternative">']
    for i, block in enumerate(blocks):
        if i:
            out.append('<span class="alternative-separator"></span>')
        out += ['<span class="alternative-block">', *block, "</span>"]
    out.append("</span>")
    return out


def _parse(src):
    """Parse notation text into a list of HTML strings and pending_xref nodes."""
    toks = list(_TOKEN.finditer(src))
    pos = 0  # index of the next token to consume

    def seq(stop):
        """Parse tokens up to (not including) a delimiter in ``stop``."""
        nonlocal pos
        out = []
        while pos < len(toks):
            tok = toks[pos]
            if tok["delim"] and tok["delim"] in stop:
                break
            pos += 1
            if tok["esc"]:
                out.append(escape(tok["esc"]))
            elif tok["sym"]:
                body = _trim(seq("}"))
                pos += 1  # the closing }
                out += _repeat(tok["sym"], tok["sep"], body)
            elif tok["choice"]:
                blocks = [_trim(seq("|}"))]
                while pos < len(toks) and toks[pos]["delim"] == "|":
                    pos += 1
                    blocks.append(_trim(seq("|}")))
                pos += 1  # the closing }
                out += _choice(blocks)
            elif tok["hole"]:
                out.append(_hole(tok["hole"]))
            else:
                out.append(escape(tok["delim"] or tok["text"]))
        return out

    return seq("")


def _to_nodes(items):
    """Merge consecutive HTML strings into raw nodes."""
    out, buf = [], []
    for it in items:
        if isinstance(it, str):
            buf.append(it)
        else:
            if buf:
                out.append(nodes.raw("", "".join(buf), format="html"))
                buf = []
            out.append(it)
    if buf:
        out.append(nodes.raw("", "".join(buf), format="html"))
    return out


class ProdnDirective(SphinxDirective):
    has_content = True

    def run(self):
        std = self.env.get_domain("std")
        items = ['<span class="prodn-table"><span class="prodn-row-group">']
        for line in self.content:
            m = _LINE.match(line)
            if not m:
                raise self.error(f"cannot parse production line: {line!r}")
            nt, op = (m["nt"] or "", m["op"] or "|")
            ident = ""
            if nt:
                node_id = make_id(self.env, self.state.document, "grammar-token-", nt)
                # `+=` extends an existing definition: keep the first anchor.
                if ("token", nt) not in std.objects:
                    std.note_object("token", nt, node_id, location=self.get_location())
                    ident = f' id="{node_id}"'
            items += [
                '<span class="prodn-row">',
                f'<span class="prodn-cell-nonterminal"{ident}>{escape(nt)}</span>',
                f'<span class="prodn-cell-op">{escape(op)}</span>',
                '<span class="prodn-cell-production"><span class="notation">',
                *_parse(m["prod"]),
                "</span></span></span>",
            ]
        items.append("</span></span>")
        # References must sit in a TextElement, hence the inline wrapper.
        wrapper = nodes.inline()
        wrapper += _to_nodes(items)
        container = nodes.container(classes=["prodn"])
        container += wrapper
        return [container]


class CmdDirective(SphinxDirective):
    """A documented object: its notation as signature, description indented below."""

    kind = "cmd"

    has_content = True
    required_arguments = 1
    final_argument_whitespace = True
    option_spec = {"name": directives.unchanged}

    def run(self):
        sig = " ".join(self.arguments[0].split())
        name = self.options.get("name")
        ident = ""
        if name:
            node_id = make_id(self.env, self.state.document, f"{self.kind}-", name)
            self.env.get_domain("std").note_object(
                f"{self.kind}-ref", name, node_id, location=self.get_location())
            ident = f' id="{node_id}"'
        wrapper = nodes.inline()
        wrapper += _to_nodes([
            f'<span class="cmd-signature {self.kind}-signature"{ident}><span class="notation">',
            *_parse(sig),
            "</span></span>",
        ])
        signature = nodes.container(classes=[self.kind])
        signature += wrapper
        body = nodes.container(classes=["cmd-body"])
        self.state.nested_parse(self.content, self.content_offset, body)
        return [signature, body]


class AttrDirective(CmdDirective):
    """An attribute (``local``, ``libraries``, ...), documented like a command."""

    kind = "attr"


class ExampleDirective(SphinxDirective):
    """An example box (as in the Rocq refman); an optional argument is the title."""

    has_content = True
    optional_arguments = 1
    final_argument_whitespace = True

    def run(self):
        title = " ".join(self.arguments[0].split()) if self.arguments else ""
        box = nodes.container(classes=["example"])
        label = "Example" + (f": {title}" if title else "")
        box += nodes.paragraph(label, label, classes=["example-title"])
        self.state.nested_parse(self.content, self.content_offset, box)
        return [box]


def setup(app):
    app.add_directive("example", ExampleDirective)
    app.add_directive("prodn", ProdnDirective)
    app.add_directive("cmd", CmdDirective)
    # Registers the ``:cmd:`` role resolving to ``cmd`` entries (the generic
    # ``cmd-ref`` directive it also creates is unused).
    app.add_crossref_type("cmd-ref", "cmd", "%s", nodes.literal)
    app.add_directive("attr", AttrDirective)
    app.add_crossref_type("attr-ref", "attribute", "%s", nodes.literal)
    app.connect("config-inited", _add_static)
    app.add_css_file("https://fonts.googleapis.com/css2?family=Lato:wght@400;700&display=swap")
    app.add_css_file("rocq-notations.css")
    return {"version": "0.1", "parallel_read_safe": True, "parallel_write_safe": True}
