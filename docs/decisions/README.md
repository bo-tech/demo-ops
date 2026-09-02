# Decisions

This directory contains decision records. See [0000-use-adr.md](0000-use-adr.md)
for why we use this approach.

For new ADRs, please use [adr-template.md](adr-template.md) as basis. It is
intentionally kept minimal; where a decision needs more, pick the sections you
need from the [full MADR template](https://adr.github.io/madr/#full-template).

More information on MADR is available at <https://adr.github.io/madr/>.

General information about architectural decision records is available at
<https://adr.github.io/>.

## Cross-Referencing

Each ADR has a MyST label for Sphinx cross-referencing. Place the label after
the YAML frontmatter and before the heading:

```markdown
---
date: 2026-01-06
---

(adr-0001)=
# ADR-0001 Decision title
```

Reference ADRs using the `{ref}` role with an explicit short title:

```markdown
See {ref}`ADR-0001 <adr-0001>` for details.
```

The heading carries both the number and the full title, so a reference
without its own text drops that whole title into the sentence.

## Immutability

ADRs are immutable after acceptance. Do not edit the substance of an accepted ADR.

When a decision changes, create a new ADR rather than editing the old one.
Add ``Supersedes {ref}`ADR-NNNN <adr-NNNN>`.`` to the new record and
``Superseded by {ref}`ADR-NNNN <adr-NNNN>`.`` to the one it replaces. That
forward reference is the only permitted edit to an accepted ADR, and the pair
preserves the decision-making history.
