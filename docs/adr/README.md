# Architecture Decision Records

**Format:** Lightweight MADR. Each ADR is a separate Markdown file named `NNNN-kebab-case-title.md`, numbered sequentially and never renumbered. An ADR is immutable once merged — to overturn one, write a new ADR with status `Supersedes NNNN` and update the superseded ADR's header to point forward.

**Template:**

```markdown
# ADR NNNN — <Short Title>

**Status:** Proposed | Accepted | Superseded by NNNN | Deprecated
**Date:** YYYY-MM-DD
**Deciders:** <names>
**Tags:** <comma-separated — e.g. product, infra, scheduling>

## Context
What problem are we deciding on, and what forces push on the decision?

## Decision
What we chose. One or two short paragraphs.

## Consequences
What becomes true because of this decision. Include the good, the bad, and the follow-ups required.

## Alternatives Considered
What else we looked at, and why we declined each.
```

## Index

| # | Title | Status | Date |
|---|---|---|---|
| [0001](0001-schedule-alignment-with-little-500.md) | Schedule alignment with the real IU Little 500 | Accepted | 2026-04-22 |
