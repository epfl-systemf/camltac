# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'Camltac'
copyright = '2026, Dario Halilovic (<a href="https://systemf.epfl.ch">SYSTEMF @ EPFL</a>)'
author = 'Dario Halilovic'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

import re
from pygments import token
from pygments.lexer import RegexLexer, DelegatingLexer, bygroups, using
from pygments.lexers import OcamlLexer
from alectryon.pygments_lexer import CoqLexer

# We use a custom lexer for highlighting OCaml code in ocaml:{{ … }} snippets.
class EmbeddedLexer(RegexLexer):
    name = 'EmbeddedOCaml'
    aliases, filenames = [], []
    flags = re.DOTALL
    tokens = {
        'root': [
            ('(ocaml)(:[{][{])(.+?)([}][}])',
             bygroups(token.Keyword, token.Operator, using(OcamlLexer), token.Operator)),
            ('(ocaml)(:[(])(.+?)([)])',
             bygroups(token.Keyword, token.Operator, using(OcamlLexer), token.Operator)),
            ('.', token.Other), # ← This indicates the "host" language
        ]
    }

class CamltacLexer(DelegatingLexer, CoqLexer):
    name = 'Coq'
    def __init__(self, **options):
        super().__init__(CoqLexer, EmbeddedLexer, **options)

# Tell Alectryon to use our lexer
import alectryon.pygments_lexer
alectryon.pygments_lexer.CoqLexer = CamltacLexer

import os, sys
sys.path.insert(0, os.path.abspath('_ext'))

extensions = ['alectryon.sphinx', 'sphinx_copybutton', 'rocq_notations',
              'sphinx.ext.intersphinx', 'mltac2_api',
              'search_suggest']

# Holes in `prodn` productions such as @ident or @term link to Rocq's grammar.
intersphinx_mapping = {'rocq': ('https://rocq-prover.org/doc/master/refman/', None)}

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'shibuya'
html_static_path = ['_static']
html_css_files = ['alectryon-dark.css', 'hlist.css', 'sidebar.css']

pygments_style = 'catppuccin-latte'
pygments_dark_style = 'catppuccin-mocha'
