# Configuration file for the Sphinx documentation builder.

# -- Project information -----------------------------------------------------

project = 'demo-ops'
copyright = 'joh@bo-tech.de'
author = 'joh@bo-tech.de'

version = '0.0.1'
release = version + '-dev'


# -- General configuration ---------------------------------------------------

extensions = [
    'myst_parser',
    'sphinx.ext.extlinks',
    'sphinx.ext.ifconfig',
    'sphinx.ext.intersphinx',
    'sphinx.ext.todo',
]

templates_path = ['_templates']

exclude_patterns = [
    '.DS_Store',
    'Thumbs.db',
    '_build',
    'decisions/README.md',
    'decisions/adr-template.md',
    'README.md',
]


# -- Options for HTML output -------------------------------------------------

html_theme = "sphinx_book_theme"

html_static_path = []


# -- Options for PDF output -------------------------------------------------

latex_documents = [
    ('index', 'demo-ops.tex', project, author, 'manual'),
]


intersphinx_mapping = {}
