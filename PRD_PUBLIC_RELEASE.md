---
project: Crane Public Release Readiness
version: 0.1
status: draft
created: 2026-07-20
last_updated: 2026-07-20
owner: TBD
related:
  - INVENTORY_GOAL.md
  - docs/roadmap/PUBLIC_RELEASE_INVENTORY.md  # produced by inventory goal
---

# PRD: Crane Public Release Readiness

## 1. Vision

Prepare the Crane repository for a **public announcement** as a professional open-source Diamond-first (ERC2535) Solidity framework—not as an internal agent workroom.

After this project, a first-time visitor (human or AI agent) should see a coherent product: clear value proposition, curated documentation, honest maturity labels, clean root layout, and no abandoned task backlog or research dump at the front door.

## 2. Problem Statement

Crane’s **implementation core is substantial** (factories, Facet-Target-Repo patterns, protocol ports, TestBase/Behavior infrastructure, agent skills). The **repository surface is not public-ready**:

1. **Root is a war room** — planning PRDs, gap reports, coverage logs, migration notes, and agent resumption prompts sit beside `README.md`.
2. **Process artifacts dominate git history/noise** — `tasks/` holds ~97 active and ~176 archived CRANE-* work items; none of these should remain as open product work for a public launch.
3. **`docs/archive/` is enormous** — ~18.9k tracked files (gap-report mirrors, research scrapes with full HTML asset trees, nested report copies). This inflates clone size and signals “internal dump,” not “product docs.”
4. **Documentation drift risk** — product docs under `docs/` + `SUMMARY.md` are a solid spine, but root claims, agent prompts, and old plans are not reconciled with current code.
5. **Standards conformity is uneven** — known repo rules (NatSpec/include-tags, production-first testing, no viaIR, Facet-Target-Repo conventions) are not uniformly applied; public release should not pretend otherwise without a focused pass.
6. **Outstanding work must not be finished for launch** — the backlog of CRANE tasks is **to be removed**, not completed. Public launch is a hygiene and packaging project, not a feature-completion project.

## 3. Goals

### 3.1 Primary goals

| ID | Goal |
|----|------|
| G1 | **Public surface** — Root and primary docs present Crane as a product, not an agent scratchpad. |
| G2 | **Remove task system** — Delete (or fully purge from the default branch) all CRANE task directories and task index machinery; do **not** complete outstanding tasks. |
| G3 | **Archive or relocate internal knowledge** — PRDs, research, plans, and historical gap material leave the front door; valuable material is preserved under a deliberate archive/roadmap layout (or an external archive repo). |
| G4 | **Curated documentation** — `docs/` + mdBook/GitHub Pages nav (`SUMMARY.md`) is the single public knowledge base; status of experimental ports is honest. |
| G5 | **Artifact hygiene** — Generated logs, build outputs, and ephemeral reports are gitignored and untracked. |
| G6 | **Launch baseline** — README, license clarity, security contact, contributing note, and a green critical path (`forge build`, curated tests, docs build). |
| G7 | **Standards spotlight (scoped)** — Targeted conformity on core public APIs only; no full-codebase rewrite before announcement. |

### 3.2 Success metrics

| Metric | Target |
|--------|--------|
| Root markdown/logs | Only intentional public/project files at repo root (see §7 keep list). |
| `tasks/` | **Gone** from the default branch entirely. No replacement task system or GitHub Issues. |
| `docs/archive` bulk | Not part of the default public tree noise; either thinned, moved off-branch, or split to a separate archive repo. |
| Docs nav | `docs/SUMMARY.md` builds cleanly; no links to removed task/PRD paths. |
| Clone impression | `README.md` install + docs path works in under 5 minutes for a new contributor. |
| CI / local verify | `forge build` succeeds; agreed test subset green; docs build script succeeds. |
| Claims honesty | README/docs do not claim unaudited completeness, finished ports, or BattleChain production without evidence. |

## 4. Non-goals

| Non-goal | Rationale |
|----------|-----------|
| Completing any outstanding CRANE-* task | Explicit product decision: **remove**, do not finish. |
| Full protocol port completion (Aave, Euler, etc.) | Separate roadmap; optional thin status pages only. |
| Full NatSpec/style rewrite of entire monorepo | Out of scope for announcement; scoped core pass only. |
| History rewrite / filter-repo on day one | Optional later if clone size requires it; not required for first public tag. |
| New major features, bounty board product, token launch execution | Funding/governance docs may be curated; execution is out of scope. |
| Replacing agent skills (`.claude/skills/`) | Keep; ensure public docs point to them correctly. |
| Changing core architecture (Diamond, CREATE3, DFPkg) | Hygiene project only. |

## 5. Discovery inventory (as of 2026-07-20)

### 5.1 Strengths (keep and present)

- Diamond-first framework with Facet-Target-Repo, DFPkg, CREATE3 factories.
- Documented agent skills under `.claude/skills/` and AGENTS.md guidance.
- Product docs tree: `docs/` with concepts, deployment, development, access, tokens, protocols, utilities, reference.
- mdBook/GitHub Pages pipeline (`book.toml`, `scripts/build_docs_pages.sh`; `book/` already gitignored).
- Foundry stack (Solidity 0.8.30), multi-license files under `licenses/`.
- Substantial `contracts/` + `test/foundry/spec/` implementation surface.

### 5.2 Root-level cruft (tracked markdown / logs)

| File | Classification (proposed) |
|------|---------------------------|
| `README.md` | **Keep** — rewrite for public launch. |
| `AGENTS.md` | **Keep** — agent/contributor source of truth. |
| `CLAUDE.md` | **Keep** (thin pointer) or fold into AGENTS.md. |
| `LICENSE` + `licenses/*` | **Keep**. |
| `GOVERNANCE.md` | **Keep or move** to `docs/governance/` if public; else archive. |
| `BANKR_LAUNCH.md` | **Move** → `docs/funding/` (duplicate of funding narrative). |
| `PRD.md` | **Archive** (historical framework PRD) → `docs/archive/internal-plans/` or `docs/roadmap/history/`. |
| `PRD_PUBLIC_RELEASE.md` | **Keep** (this document) until project complete; then archive under `docs/roadmap/`. |
| `PROMPT.md`, `RESUMPTION_PROMPT.md` | **Remove or archive** — internal agent session prompts. |
| `DEFI_PORTING_PRD.md`, `DEFI_PORTING_GAP_ANALYSIS.md`, `DEFI_PORTING_PRIORITIZATION.md`, `DEFI_RESEARCH.md` | **Archive** → roadmap/history. |
| `AAVE_DEPS_INVENTORY.md`, `Aave_Vendored_Dependencies_Dedup_Plan.md`, `DEDUPLICATION.md`, `VENDORED_DEPENDENCY_DUPLICATION_AUDIT.md` | **Archive** → internal engineering history. |
| `DEPLOYMENT_PRIORITY.md`, `UNIFIED_REVIEW_PLAN.md`, `MIGRATION_ConstProdUtils_Tests.md`, `SLIPSTREAM_ANALYSIS.md`, `Superchain_Testing_Guide.md` | **Archive** — promote only if still accurate into real docs. |
| `GAP_REPORT.md`, `TEST_COVERAGE_REPORT.md`, `crane_solidity_review.md` | **Archive or delete** — generated/one-off reviews (large). |
| `COVERAGE.log`, `COVERAGE_SUMMARY.log` | **Delete from git** + gitignore. |

### 5.3 Tasks

| Location | Count (approx.) | Decision |
|----------|-----------------|----------|
| `tasks/CRANE-*` (active) | ~97 directories | **DELETE entirely** — do not complete. |
| `tasks/archive/CRANE-*` | ~176 directories | **DELETE entirely** (historical agent work logs). |
| `tasks/INDEX.md`, `tasks/TEMPLATE.md` | 2 files | **DELETE** with the tasks tree. |

**No replacement** in-repo task system and **no GitHub Issues** for this project. Future work tracking is out of scope for public-release hygiene; do not invent a substitute tracker during cleanup.

### 5.4 Documentation archive bulk

| Path | Issue |
|------|--------|
| `docs/archive/reports/gap/` | Massive mirrored gap markdown (contracts + tests + nested docs copies). |
| `docs/archive/research-scrapes/` | Full saved HTML pages + asset trees (js/webp/jpg). |
| `docs/archive/audits/` | Third-party audit PDFs (Pendle, etc.) — decide keep vs external. |
| `docs/archive/internal-plans/` | Small set of useful historical plans. |
| `docs/superpowers/plans/` | Internal planning; not product nav. |

**Tracked `docs/archive/` files:** ~18,926 (dominant git noise).

### 5.5 Generated / local artifacts

| Path | Status |
|------|--------|
| `book/`, `.mdbook-src/`, `out/`, `cache_forge/` | Already gitignored. |
| `reports/` | ~32 tracked JSON engine reports — **untrack + gitignore** unless intentional fixtures. |
| `tmp/` | Local logs — ensure gitignored. |
| `snapshots/` | May be intentional Foundry gas snapshots — **review keep vs ignore**. |
| `.gitignore` | Duplicate Hardhat blocks; incomplete for coverage logs / tmp / reports. |

### 5.6 Product docs spine (preserve)

Canonical public docs (from `docs/SUMMARY.md`):

- Getting started, concepts (Facet-Target-Repo, slots, guards, DFPkg, registries)
- Deployment (CREATE3, DFPkg, factory services, BattleChain)
- Development (style, NatSpec, testing)
- Access, tokens, protocols overview, utilities, reference, funding

These are the **source of truth** after cleanup. Drift fixes apply here first.

## 6. Requirements

### 6.1 Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Remove entire `tasks/` tree (active + archive + index/template) from the default branch. | P0 |
| FR-2 | Remove or relocate all root cruft per §5.2; leave only approved root files. | P0 |
| FR-3 | Establish docs layout: product docs + `docs/roadmap/` (future) + thin archive policy. | P0 |
| FR-4 | Reduce or relocate `docs/archive` bulk so default clone is not dominated by scrapes/gap mirrors. | P0 |
| FR-5 | Update `README.md` for public audience (value, install, docs, license, security, honesty of scope). | P0 |
| FR-6 | Fix `docs/SUMMARY.md` and internal doc links after moves/deletes. | P0 |
| FR-7 | Tighten `.gitignore`; untrack generated logs/reports. | P0 |
| FR-8 | Add or refresh `SECURITY.md` and short `CONTRIBUTING.md`. | P1 |
| FR-9 | Reconcile license messaging (root LICENSE vs `licenses/*`) in README. | P1 |
| FR-10 | Status labels for protocol integrations (stable / experimental / port-in-progress). | P1 |
| FR-11 | Scoped standards pass on core factories, access, tokens, DFPkg (NatSpec/patterns only where broken on public paths). | P2 |
| FR-12 | Verify docs build + forge build + agreed test subset. | P0 |
| FR-13 | Tag a public preview release (e.g. `v0.x.0-public-preview`) after checklist. | P1 |

### 6.2 Explicit task-removal policy

1. **Do not implement** outstanding CRANE task PROMPT/acceptance criteria.
2. **Delete the entire `tasks/` tree** — no stubs, no archive of task folders, no GitHub Issues migration.
3. Optional one-line note in CHANGELOG only: “Pre-public in-repo CRANE task system removed.”
4. Inventory goal (`INVENTORY_GOAL.md`) does **not** mine task bodies for completion; task zone is count + DELETE only. If a rare design note must survive, extract it **before** the delete wave—not by keeping `tasks/`.

### 6.3 Archive policy

| Content type | Policy |
|--------------|--------|
| Product docs | Remain in `docs/` and `SUMMARY.md`. |
| Future work / active PRDs | `docs/roadmap/` (curated, short, maintained). |
| Historical plans / old PRDs / research writeups | `docs/archive/internal-plans/` or external `crane-archive` repo. |
| Gap report mirrors / HTML scrapes | **Out of default branch** preferred (orphan branch, submodule, or separate repo). Leave a short index if needed. |
| Third-party audits | Keep only if licensing allows and useful; otherwise external link. |
| Agent session prompts | Delete. |

### 6.4 Proposed target layout (post-project)

```text
/
  README.md
  LICENSE
  AGENTS.md
  CLAUDE.md                 # optional thin pointer
  SECURITY.md
  CONTRIBUTING.md
  GOVERNANCE.md             # or docs/governance/
  foundry.toml, package.json, ...
  contracts/
  test/
  scripts/
  docs/
    SUMMARY.md
    getting-started.md
    concepts/ deployment/ development/ ...
    roadmap/                # future plans (curated)
      README.md
      PUBLIC_RELEASE.md     # this PRD after completion (optional)
    archive/
      README.md             # policy + index only
      internal-plans/       # small set of historical plans
  .claude/skills/           # agent skills (kept)
```

No `tasks/` directory.

## 7. Phased delivery plan

### Phase 0 — Align (this PRD)

- Approve this PRD and the keep/archive/delete matrix.
- Confirm archive strategy for bulk `docs/archive` (in-tree thin vs separate repo vs orphan branch).
- Confirm public claims (BattleChain, funding/token language, “production-grade”).

### Phase 1 — Task purge + root hygiene

1. Extract any rare design notes worth keeping (manual spot-check of high-value task titles only if needed).
2. Delete `tasks/` entirely.
3. Move root planning/research files per §5.2.
4. Delete coverage logs; untrack reports; update `.gitignore`.
5. Single PR: “chore: remove task system and root cruft.”

### Phase 2 — Docs architecture + public README

1. Create `docs/roadmap/` and thin `docs/archive/README.md` policy.
2. Relocate or externalize bulk archive.
3. Rewrite README for public launch; wire docs links.
4. Fix SUMMARY and broken links; rebuild mdBook.
5. PR: “docs: public surface and archive policy.”

### Phase 3 — Launch packaging

1. `SECURITY.md`, `CONTRIBUTING.md`, license blurb.
2. Protocol status honesty pass.
3. Verification: build, tests, docs.
4. Release tag + announcement draft outline (not marketing copy in-repo unless desired).

### Phase 4 — Scoped standards (optional pre- or post-announce)

1. Core path NatSpec / pattern fixes only.
2. No viaIR; no mass refactors.
3. Document known debt in `docs/roadmap/` rather than silent omission.

## 8. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Deleting tasks loses unique design decisions | Spot-extract before purge; prefer Issues for anything still actionable. |
| Moving 19k archive files in one PR is unreviewable | Prefer `git rm` of bulk trees + separate archive location; or orphan branch without review of every file. |
| Public claims overstate maturity | Explicit status labels; soften README “production-grade” language where unproven. |
| Link rot after moves | Scripted link check on `docs/`; run mdBook build in CI. |
| Nested submodule / `lib/` / `contracts/external` size | Out of scope for v1 tidy unless clone size blocks announce; document. |

## 9. Open questions (resolve in Phase 0)

1. **Bulk archive destination:** in-repo thin index only, orphan branch, or separate `crane-archive` repository?
2. **GOVERNANCE / BANKR / DAOSYS token narrative:** public-facing, docs-only, or strip for framework-only announcement?
3. **Audit PDFs under `docs/archive/audits`:** keep, move out, or drop?
4. **`snapshots/`:** intentional CI fixtures or cruft?
5. **Release channel:** GitHub only vs also package registry; version scheme (`0.x` preview vs `1.0`)?
6. **Security contact:** email, GitHub private reporting, BattleChain Safe Harbor only?
7. **Should historical framework `PRD.md` remain citable** under archive, or is this public-release PRD the only in-repo PRD after cleanup?

## 10. Acceptance criteria (definition of done)

- [ ] No `tasks/` directory on the default branch.
- [ ] No outstanding CRANE tasks completed as part of this project (removal only).
- [ ] Repo root free of planning dumps, coverage logs, and agent resumption prompts (except this PRD until archived).
- [ ] Public docs nav builds; getting-started path works from README.
- [ ] Archive policy documented; bulk scrapes/gap mirrors no longer dominate the default tree.
- [ ] `.gitignore` covers generated artifacts; previously tracked junk untracked.
- [ ] SECURITY + CONTRIBUTING present (or explicitly deferred with owner approval).
- [ ] Verification commands green for agreed scope.
- [ ] Public preview tag cut (if approved).

## 11. Out-of-band references (do not re-import as root files)

These were discovered as part of inventory and are **candidates for archive**, not new root clutter:

- Historical product PRD: current root `PRD.md`
- DeFi porting suite: `DEFI_*`
- Dedup / vendoring audits: `DEDUPLICATION.md`, `VENDORED_*`, `AAVE_*`
- Gap / coverage / review dumps: `GAP_REPORT.md`, `COVERAGE*`, `crane_solidity_review.md`
- Prior unified plans: `docs/archive/UNIFIED_PLAN.md`, `UNIFIED_REVIEW_PLAN.md`

## 12. Suggested execution mode

Treat as a **proper project with small reviewable PRs**:

1. PR: task purge + gitignore + root file moves  
2. PR: docs archive policy + bulk reduction  
3. PR: README + SECURITY + CONTRIBUTING + link fixes  
4. Optional PR: scoped core standards  
5. Tag release  

No feature work. No task completion. Hygiene and public packaging only.

---

## Appendix A — Initial keep list (repo root after Phase 1)

**Intended keep:**

- `README.md`, `LICENSE`, `licenses/`, `AGENTS.md`, `CLAUDE.md`
- `GOVERNANCE.md` (if public) or moved under docs
- `PRD_PUBLIC_RELEASE.md` (until project closes)
- Build/config: `foundry.toml`, `foundry.lock`, `remappings.txt`, `package.json`, `package-lock.json` / `yarn.lock`, `hardhat.config.*`, `tsconfig.json`, `book.toml`, `cspell.config.yaml`, `slither.config.json`, `design.yaml` (review), `.gitmodules`, `.gitignore`, `.gitbook.yaml`
- Source trees: `contracts/`, `test/`, `scripts/`, `docs/`, `lib/`, `certora/` (if public), `.claude/`, `.github/`, `images/`, `theme/`, `utils/` as needed

**Intended gone from root:** all files in §5.2 marked archive/delete, plus entire `tasks/`.

## Appendix B — Relationship to existing framework PRD

Root `PRD.md` (2026-01-12) describes Crane the **product framework** (patterns, factories, users). This document (`PRD_PUBLIC_RELEASE.md`) describes the **release-readiness project** only.

When this project completes:

- Archive historical `PRD.md` under `docs/archive/internal-plans/` or `docs/roadmap/history/`.
- Either keep a short living product PRD under `docs/roadmap/` or rely on README + docs as the product spec.
- Archive this public-release PRD as completed project documentation.
