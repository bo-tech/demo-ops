# Configuration file for the Sphinx documentation builder.

from pathlib import Path

# -- Project information -----------------------------------------------------

project = "demo-ops"
copyright = "%Y, Johannes Bornhold"
author = "Johannes Bornhold"

version = "0.0.1"
release = version + "-dev"


# -- General configuration ---------------------------------------------------

extensions = [
    "myst_parser",
    "sphinx.ext.extlinks",
    "sphinx.ext.ifconfig",
    "sphinx.ext.intersphinx",
    "sphinx.ext.todo",
]

templates_path = ["_templates"]

exclude_patterns = [
    ".DS_Store",
    "Thumbs.db",
    "_build",
    "decisions/README.md",
    "decisions/adr-template.md",
    "README.md",
]


# -- Options for HTML output -------------------------------------------------

html_theme = "sphinx_book_theme"

html_static_path = []


# -- Options for PDF output -------------------------------------------------

latex_documents = [
    ("index", "demo-ops.tex", project, author, "manual"),
]


# Vendored rather than fetched: a nix build has no network. Refresh
# with docs/update-inventory-files.sh when a referenced label moves.
_business_operations_inventory = (
    Path(__file__).parent / "_inventory/business-operations.inv"
)

intersphinx_mapping = {
    "bo": (
        "https://business-operations.codeberg.page/business-operations/",
        (str(_business_operations_inventory), None),
    ),
}
