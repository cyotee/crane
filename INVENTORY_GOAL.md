---
project: Crane Public Release — Full Repository Inventory
version: 0.2
status: ready-to-launch
created: 2026-07-20
last_updated: 2026-07-20
parent: PRD_PUBLIC_RELEASE.md
goal_type: analysis-only
---

# Goal: Produce Public-Release Inventory Report

## Feasibility

**Yes — this is feasible** with parallel read-only subagents.

| Constraint | Approach |
|------------|----------|
| `docs/` alone is ~19k files (mostly `docs/archive`) | Inventory **by tree policy**, not line-by-line prose for every scrape asset. Every *path class* still gets an explicit disposition. |
| `contracts/` ~7.4k files, `lib/` ~14k | Core Crane vs ports vs vendored/submodules classified at **directory / package** level; root of each major package listed. |
| `tasks/` ~774 files | **No analysis of task content for completion.** Record size/count only; disposition is **DELETE entirely** (locked decision). |
| Goal must be checkable | Success condition below is binary and file-based. |

This goal is **analysis only**. It does **not** delete files, complete tasks, open GitHub Issues, or refactor code. Execution of dispositions is a later goal/PR under `PRD_PUBLIC_RELEASE.md`.

### Locked product decisions (do not re-open in inventory)

1. **`tasks/` — DELETE entirely** (active + archive + INDEX + TEMPLATE). Do not complete any CRANE task. Do not replace with GitHub Issues. **Count + DELETE only** — no body scan, no extract proposals from task PROMPTs.
2. **Future work tracking** — not GitHub Issues; out of scope for this inventory (no replacement system required in the report).
3. **Public release** is hygiene/packaging, not feature completion.

### Owner decisions (clarified 2026-07-20 — bind inventory agents)

| # | Topic | Decision | Inventory rule |
|---|--------|----------|----------------|
| OD-1 | Bulk `docs/archive` (gap mirrors, research scrapes, etc.) | **REVIEW only** | Use disposition `REVIEW` for bulk subtrees. **No recommended default** (EXTERNALIZE/DELETE). State size/risk and leave human-gated. |
| OD-2 | Agent tooling (`.claude/`, `.agents/`, `.grok/`, `.opencode/`, `.sisyphus/`) | **Public agent surface** | Prefer `KEEP` (public agent surface). Note in Role that these are intentional public agent artifacts; README/docs should point at them later. Do **not** mark as KEEP_INTERNAL solely for being agent-related. |
| OD-3 | Funding / DAOSYS / Bankr narrative | **Archive / strip from front door** | Framework-only public front door. Root `BANKR_LAUNCH.md`, `GOVERNANCE.md` (if funding-heavy), and `docs/funding/*` → prefer `MOVE`/`ARCHIVE_THIN` away from primary nav (e.g. under `docs/archive/…` or `docs/roadmap/history/`). Do not leave funding as primary README narrative. |
| OD-4 | Third-party audit PDFs (`docs/archive/audits/`) | **KEEP thin in-tree** | Prefer `KEEP` or `ARCHIVE_THIN` (index + PDFs retained in-tree under archive). Not EXTERNALIZE/DELETE by default. |
| OD-5 | `certora/` | **KEEP** | Disposition `KEEP` as public engineering/research artifact. |
| OD-6 | `contracts/protocols/*` depth | **Disposition + maturity** | Z6 tables **must** include a **Maturity** column: `stable` \| `experimental` \| `port-in-progress` \| `vendored` \| `unknown` (justify unknown briefly). |
| OD-7 | `tasks/` scan depth | **Count + DELETE only** | No title mining, no extract scan. |

---

## Goal statement

Produce a single inventory report at:

```text
docs/roadmap/PUBLIC_RELEASE_INVENTORY.md
```

that classifies **every in-scope repository path** (see scope) with a recommended disposition so a human can approve keep / archive / delete / externalize decisions before cleanup PRs.

---

## Scope

### In scope (must appear in inventory)

| Zone | Path(s) | Granularity |
|------|---------|-------------|
| Z0 | Repo root files (`find . -maxdepth 1 -type f`) | **Per file** |
| Z1 | Root directories that are not source trees: `reports/`, `snapshots/`, `tmp/`, `output/`, `cache/`, `cache_forge/`, `book/`, `out/`, `images/`, `theme/`, `utils/`, `licenses/`, `certora/`, `scripts/` | **Per top-level path**; deeper only if disposition needs it |
| Z2 | Dot dirs / tooling: `.github/`, `.gitignore`, `.gitmodules`, `.gitbook.yaml`, `.claude/`, `.agents/`, `.grok/`, `.opencode/`, `.sisyphus/`, `.vscode/`, `.cartographer/`, `.cspell/`, `.mdbook-src/` | **Per directory** (+ note if gitignored / should be). Agent trees → **KEEP** (OD-2 public agent surface). |
| Z3 | `tasks/` | **Tree-level only**: file count, active vs archive counts; disposition = **DELETE** (OD-7: no body/title scan) |
| Z4 | `docs/` excluding bulk archive | **Per file** under product docs (`docs/*.md`, `docs/access/`, `concepts/`, `deployment/`, `development/`, `funding/`, `protocols/`, `reference/`, `tokens/`, `utilities/`, `superpowers/`). **Funding paths (OD-3):** strip from front door — `MOVE`/`ARCHIVE_THIN`, remove from primary `SUMMARY` nav recommendation. |
| Z5 | `docs/archive/` | **Per immediate child** + policy for bulk subtrees. **Bulk gap/scrapes (OD-1):** `REVIEW` only, no recommended default. **Audits (OD-4):** KEEP thin in-tree. |
| Z6 | `contracts/` | **Per top-level package** under `contracts/` and one level under `contracts/protocols/*` (and note `contracts/external` size). **Required Maturity column (OD-6).** |
| Z7 | `test/` | **Per major subtree** under `test/foundry/spec/` (mirror of contracts) |
| Z8 | `lib/` | **Per submodule / dependency** (from `.gitmodules` + `lib/*`) |
| Z9 | Config at root already in Z0; also note `package.json` scripts, dual lockfiles if relevant | Covered in Z0 + short “config notes” section |

### Out of scope (do not deep-inventory)

- File contents of every Solidity file under `contracts/external` or full protocol ports (classify directory only).
- Completing, ranking, or rewriting CRANE tasks.
- Implementing cleanup.
- `node_modules` if present.
- Git object history / filter-repo plans (optional note only).

---

## Disposition vocabulary (required)

Every inventory row **must** use exactly one of:

| Code | Meaning |
|------|---------|
| `KEEP` | Remains on default branch as public/product/tooling surface. |
| `KEEP_INTERNAL` | Remains on default branch but is contributor/agent-only (e.g. AGENTS.md, skills); not marketed as end-user docs. |
| `MOVE` | Relocate to a new path (target path required). |
| `ARCHIVE_THIN` | Keep a short summary/index in-tree; full body goes to archive location (specify). |
| `EXTERNALIZE` | Remove from default branch; store outside (orphan branch, separate archive repo, or release asset). Path of external home can be TBD. |
| `DELETE` | Remove from default branch and stop tracking; no archival value. |
| `GITIGNORE` | Should not be tracked; add/fix ignore rules + untrack if currently tracked. |
| `REVIEW` | Disposition needs human decision; inventory must state **why**. **Recommended default is required unless OD-1 applies** (bulk `docs/archive` gap/scrapes: no recommended default — size/risk only). |

Optional modifiers (append in notes, not as separate codes):

- `public` / `experimental` / `vendored` / `generated` / `sensitive`

### Maturity labels (Z6 required — OD-6)

| Label | Meaning |
|-------|---------|
| `stable` | Treated as production-oriented Crane surface (factories, core access/tokens, mature integrations). |
| `experimental` | Present and usable in-tree but not announced as production-complete. |
| `port-in-progress` | Partial port / incomplete integration. |
| `vendored` | Upstream-faithful vendored code / external dependency copy. |
| `unknown` | Insufficient signal; brief note required. |

---

## Required report structure

The deliverable `docs/roadmap/PUBLIC_RELEASE_INVENTORY.md` **must** contain these sections in order:

### 1. Metadata

- Date, branch name, git HEAD short SHA
- Link to `PRD_PUBLIC_RELEASE.md` and this goal file
- Counts: total root files inventoried, total directory rows, tasks file count, docs/archive tracked count if available

### 2. Executive summary

- 10–20 bullets: biggest public risks, largest bulk trees, locked decisions
- Table: disposition counts (`KEEP`, `DELETE`, …)

### 3. Locked decisions (echo)

- `tasks/` → DELETE entire tree (count only; no body scan)
- No GitHub Issues replacement in this project
- Analysis-only; no mutations
- Full table of **Owner decisions OD-1…OD-7** (copy from this goal)

### 4. Zone inventories (Z0–Z9)

For each zone, a markdown table with columns:

```text
| Path | Kind | Tracked? | Size/Count | Role | Disposition | Target / notes |
```

**Z6 only** — add column:

```text
| Path | Kind | Tracked? | Size/Count | Role | Maturity | Disposition | Target / notes |
```

- **Path** — repo-relative  
- **Kind** — file | dir | tree | submodule  
- **Tracked?** — yes / no / partial (from `git ls-files` or ignore status)  
- **Size/Count** — bytes for small files, or file count for trees  
- **Role** — one line (product docs, agent skill, generated, historical plan, …)  
- **Maturity** — Z6 only; see maturity labels  
- **Disposition** — code from vocabulary  
- **Target / notes** — required for `MOVE` / `ARCHIVE_THIN` / `EXTERNALIZE` / `REVIEW` (for OD-1 bulk archive REVIEW rows: notes = size/risk only, **no** recommended default)

### 5. Cross-cutting findings

- Duplicate content (e.g. `BANKR_LAUNCH.md` vs `docs/funding/`)
- Generated artifacts currently tracked
- Docs drift suspects (claim vs code) — list paths only, no full rewrite
- License surface (`LICENSE` vs `licenses/*`)
- Clone-size drivers (top 10 by file count or approximate size)

### 6. Recommended cleanup waves (for later execution — not this goal)

Ordered PR plan, e.g.:

1. Wave A: DELETE `tasks/` + DELETE logs + GITIGNORE  
2. Wave B: root MOVE/ARCHIVE  
3. Wave C: EXTERNALIZE docs/archive bulk  
4. Wave D: README / SECURITY / CONTRIBUTING  

### 7. Human decision checklist

Every `REVIEW` row restated as a yes/no or A/B question for the owner.

### 8. Success attestation

Checklist matching § Success condition below, filled by the orchestrating agent when done.

---

## Subagent plan (recommended orchestration)

Launch **read-only explore agents** in parallel. Orchestrator merges into one report (no agent writes the final file except the orchestrator, or one designated writer).

| Agent | Zone(s) | Prompt focus |
|-------|---------|--------------|
| **A — Root & config** | Z0, Z1, Z9 | Every root file; reports/snapshots/tmp/book/out; .gitignore coverage |
| **B — Tooling dots** | Z2 | `.claude`, `.agents`, `.grok`, `.sisyphus`, `.github`, etc. OD-2: agent trees = **KEEP** public agent surface |
| **C — Tasks** | Z3 | Counts only; DELETE; OD-7: no titles/bodies |
| **D — Product docs** | Z4 | Every product doc file; SUMMARY alignment; OD-3 funding strip from front door |
| **E — Docs archive** | Z5 | Children of `docs/archive`; OD-1 bulk = REVIEW no default; OD-4 audits = KEEP thin |
| **F — Contracts map** | Z6 | Top-level `contracts/*` and protocol packages; **Maturity column** (OD-6) |
| **G — Tests & scripts** | Z7 + `scripts/` + `certora/` | Mirror structure; OD-5 certora = KEEP |
| **H — Dependencies** | Z8 | `.gitmodules`, each `lib/*` purpose and public necessity |

### Merge rules

1. Orchestrator resolves path conflicts (one disposition per path).  
2. Prefer more specific path over parent tree when both appear.  
3. If two agents disagree, mark `REVIEW` with both rationales.  
4. Do not invent paths that do not exist on disk.

### Parallelism note

Agents **must not** mutate the repo. Use `explore` / read-only capability. Writer step runs only after all zone tables exist in the merge.

---

## Success condition

The goal is **DONE** when **all** of the following are true:

### SC-1 — Deliverable exists

- [ ] File exists: `docs/roadmap/PUBLIC_RELEASE_INVENTORY.md`
- [ ] Directory `docs/roadmap/` exists (create if needed when writing the report)

### SC-2 — Structure complete

- [ ] Report contains all required sections §1–§8 (Metadata through Success attestation)
- [ ] Disposition vocabulary used consistently (only allowed codes)

### SC-3 — Coverage completeness (checkable)

- [ ] **Z0:** Every file from `find . -maxdepth 1 -type f` (excluding `.git`) has a table row  
- [ ] **Z1:** Every path in the Z1 list that exists on disk has a row  
- [ ] **Z2:** Every path in the Z2 list that exists on disk has a row  
- [ ] **Z3:** `tasks/` has a single tree disposition `DELETE` with active/archive file counts  
- [ ] **Z4:** Every `*.md` / `*.adoc` under product doc dirs (see Z4 path list) has a row **or** is listed under an explicit “enumerated file list” appendix with disposition  
- [ ] **Z5:** Every **immediate child** of `docs/archive/` has a row; bulk subtrees have explicit EXTERNALIZE/DELETE/ARCHIVE_THIN policy  
- [ ] **Z6:** Every immediate child of `contracts/` has a row  
- [ ] **Z7:** `test/` top-level and `test/foundry/spec/` major children have rows  
- [ ] **Z8:** Every immediate child of `lib/` has a row  

**Verification command (orchestrator must run and paste exit summary into §8):**

```bash
# Example checks — adapt if needed; must be recorded in the report
test -f docs/roadmap/PUBLIC_RELEASE_INVENTORY.md
find . -maxdepth 1 -type f ! -name .git | wc -l   # match Z0 row count
test ! -d tasks || true   # tasks still exists during inventory; disposition DELETE only
```

Z0 row count in the report must equal `find . -maxdepth 1 -type f | grep -vc '^\./\.git$'` (or equivalent).

### SC-4 — Locked decisions reflected

- [ ] Report states `tasks/` → **DELETE** (entire tree), no complete-tasks option, count-only (OD-7)  
- [ ] Report states **no GitHub Issues** as work-tracking replacement for this project  
- [ ] Report states this goal is analysis-only (no cleanup performed as part of inventory)  
- [ ] Report §3 echoes **OD-1…OD-7** accurately  

### SC-5 — Actionability

- [ ] Every `MOVE` row has a target path  
- [ ] Every `REVIEW` row has a human question; **recommended default required except OD-1 bulk archive rows** (those: size/risk only, no default)  
- [ ] Z6 protocol/package rows include **Maturity** (OD-6)  
- [ ] Agent tooling paths use **KEEP** as public agent surface (OD-2), unless a specific path is clearly generated junk (`GITIGNORE`)  
- [ ] Funding front-door paths recommend strip/archive (OD-3)  
- [ ] `docs/archive/audits` recommends KEEP thin in-tree (OD-4)  
- [ ] `certora/` is **KEEP** (OD-5)  
- [ ] §6 lists ordered cleanup waves for a future execution goal  
- [ ] Disposition count table in §2 sums to total rows inventoried (or explains hierarchy double-count rule: “leaf rows only”)

### SC-6 — No unauthorized mutations

- [ ] Git status shows **no** deletions of `tasks/` or bulk archive as part of this goal (inventory only). Creating `docs/roadmap/PUBLIC_RELEASE_INVENTORY.md` (and empty `docs/roadmap/` if needed) is the only expected write.

---

## Failure conditions (goal is NOT done)

- Report missing zones or using vague dispositions (“maybe later”, “clean up”) without a code  
- Task bodies analyzed for completion or “should finish CRANE-xxx” recommendations  
- Partial root file list  
- Only executive summary without tables  
- Cleanup already performed without a separate approved execution goal  

---

## Goal command prompt (copy-paste)

Use the following as the goal prompt:

```text
Goal: Produce docs/roadmap/PUBLIC_RELEASE_INVENTORY.md per INVENTORY_GOAL.md (v0.2).

Parent: PRD_PUBLIC_RELEASE.md.

Locked:
- tasks/ → DELETE entirely; count only; do not complete any task; no body/title scan (OD-7).
- No GitHub Issues replacement.
- Analysis only (write inventory report only).

Owner decisions (must follow):
- OD-1 bulk docs/archive gap/scrapes → REVIEW only, NO recommended default.
- OD-2 agent tooling trees → KEEP as public agent surface.
- OD-3 funding/Bankr/DAOSYS narrative → strip from front door (MOVE/ARCHIVE_THIN).
- OD-4 audit PDFs → KEEP thin in-tree.
- OD-5 certora/ → KEEP.
- OD-6 contracts/protocols → disposition + Maturity column.
- OD-7 tasks → count + DELETE only.

Method:
1. Read INVENTORY_GOAL.md and PRD_PUBLIC_RELEASE.md fully.
2. Spawn parallel read-only explore subagents for zones Z0–Z9 as specified.
3. Merge into docs/roadmap/PUBLIC_RELEASE_INVENTORY.md with all required sections, disposition codes, OD table, Z6 maturity.
4. Verify SC-1 through SC-6; fill Success attestation with command output (Z0 count match, file exists).
5. Do not delete tasks/, do not move bulk archives, do not edit product code — only write the inventory report (and docs/roadmap/ if needed).

Success: All checkboxes in INVENTORY_GOAL.md “Success condition” are satisfied and recorded in the report §8.
```

---

## After this goal (not in scope)

A separate execution goal will:

1. Apply approved dispositions (starting with DELETE `tasks/`).  
2. Perform root hygiene and archive externalization.  
3. Public README / SECURITY / CONTRIBUTING.  

That work must wait for human review of `PUBLIC_RELEASE_INVENTORY.md` `REVIEW` rows and wave order.

---

## Appendix — Approximate scale (pre-inventory snapshot)

Recorded 2026-07-20 for planning; agents must re-measure:

| Path | ~Files |
|------|--------|
| `docs/` | ~18,975 |
| `lib/` | ~14,071 |
| `contracts/` | ~7,405 |
| `out/` (generated) | ~5,830 |
| `test/` | ~1,119 |
| `tasks/` | ~774 |
| `.agents/` | ~740 |
| `.claude/` | ~226 |
| `certora/` | ~136 |
| Root files | ~45+ |

Largest public-risk bulk: `docs/archive` (~18.9k tracked files historically).
