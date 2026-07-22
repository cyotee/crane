# Archive policy

This directory holds **historical or non-product** material that should not appear in the public docs navigation (`docs/SUMMARY.md`) or mdBook site.

## What stays in this repo

| Path | Purpose |
|------|---------|
| `internal-plans/` | Small set of historical PRDs, porting notes, and funding/governance drafts moved off the repo root |
| `audits/` | Third-party audit PDFs kept thin in-tree for convenience |

## Bulk history (external)

Large generated bulk (gap-report mirrors, HTML research scrapes) lives in a separate repository so clones of Crane stay product-focused:

**https://github.com/cyotee/crane-archive**

Do not re-import those trees into this default branch.

## Rules

1. Product documentation belongs under `docs/` with a `SUMMARY.md` entry — not under `archive/`.
2. Prefer short, curated notes over dumping agent session logs.
3. Funding / token narratives are not part of the framework front door; historical drafts may remain under `internal-plans/`.
