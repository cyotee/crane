# Archive policy

This directory holds **historical or non-product** material that should not appear in the public docs navigation (`docs/SUMMARY.md`) or mdBook site.

## What stays in this repo

| Path | Purpose |
|------|---------|
| `internal-plans/` | Small set of historical PRDs, porting notes, and funding/governance drafts moved off the repo root |
| `audits/` (if present) | Third-party audit PDFs kept thin in-tree for convenience |

## What lives elsewhere

Large generated bulk (gap-report mirrors, HTML research scrapes, and similar) is **not** kept on the default branch. Historical copies live in the separate archive repository:

- **[cyotee/crane-archive](https://github.com/cyotee/crane-archive)** (created as part of the public release)

If that repository is not yet published, treat bulk scrapes as intentionally removed from the public surface.

## Rules

1. Product documentation belongs under `docs/` with a `SUMMARY.md` entry — not under `archive/`.
2. Do not re-import gap mirrors, coverage dumps, or HTML scrapes into this tree.
3. Prefer short, curated notes over dumping agent session logs.
