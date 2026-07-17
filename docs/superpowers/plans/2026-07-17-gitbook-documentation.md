# GitBook Documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Parallelism:** Prefer `dispatching-parallel-agents` / multiple `spawn_subagent` workers for Wave 1–3 content tasks. Wave 0 and Wave 4 are sequential gates. Wave 5 is a single integration owner.

**Goal:** Make Crane’s `docs/` tree a clean, publishable GitBook space (Git Sync–ready): unique `SUMMARY.md` pages, LR-2 content coverage, no bulk/internal noise under the GitBook root, and consistent cross-links for agents and humans.

**Architecture:** GitBook Git Sync on repo `cyotee/crane` with `.gitbook.yaml` → `root: ./docs/`. Navigation is exclusively `docs/SUMMARY.md` (TOC only; each Markdown path appears **once**). Public docs live in curated section folders. Everything that conflicts with publishing (gap reports, audit dumps, HTML scrapes, internal plans/specs that are not product docs) moves under `docs/archive/`. Content work is split into independent page-ownership workstreams executed by parallel subagents; a final integration agent owns cross-references, duplicate-path removal, redirects, and publish checklist.

**Tech Stack:** Markdown (GitHub-flavored), Mermaid where already used, `.gitbook.yaml`, GitBook Git Sync, existing Crane sources (`AGENTS.md`, `PRD.md` LR-2/LR-4, skills under `.claude/skills/`, contracts for accuracy). NatSpec selectors/interfaceIds: **only** values from `docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md` if still present after archive, or the canonical path recorded in Wave 0 (`docs/archive/.../CENTRALLY_COMPUTED_NATSPEC_VALUES.md` or root-level pointer). Prefer quoting selectors already present in current published-facing docs rather than inventing new ones.

## Global Constraints

- **GitBook SUMMARY rule:** Never list the same Markdown file path twice in `docs/SUMMARY.md` (GitBook maps one file → one URL).
- **SUMMARY is TOC only:** No long prose, LR essays, or code dumps in `SUMMARY.md`—links and section headings only.
- **Public vs internal:** Only curated product/agent docs stay at the top of `docs/`. Bulk/internal material goes to `docs/archive/` (preserve history; do not delete unless user requests).
- **No viaIR / no Solidity refactors** as part of this plan unless a doc example is wrong; docs-only work.
- **LR-2 required areas** (from `PRD.md`): CREATE3 package chain setup; explicit DiamondPackageCallBackFactory public reuse; registries purpose/population/usage; ported protocols + TestBases; protocol utils; general utils/Sets/ConstProdUtils; agent-focused getting-started / building-with-crane / reuse (LR-4) language.
- **LR-4 phrases** must remain accurate where present: reuse of already deployed and verified code; agent risk of inadvertent changes; gas savings from not redeploying bytecode; “deploy once, attach everywhere” / “agent-proof reuse”.
- **Link style:** Prefer relative links from page to page (e.g. `../deployment/create3.md`). Prefer section anchors only when the target heading exists.
- **Subagent isolation:** Each content subagent owns a **disjoint file set**. No two parallel agents edit the same file. Integration agent is the only writer of `SUMMARY.md`, `.gitbook.yaml`, and cross-link sweep after content freezes.
- **Commits:** Prefer one commit per Wave (or per major workstream if large). Do not force-push.
- **Plans location:** This plan lives at `docs/superpowers/plans/…`. Wave 0 may move `docs/superpowers/` into archive; if so, re-link this plan’s path in the final handoff note (or leave `docs/superpowers/plans/` unarchived until the plan finishes—prefer **defer archiving superpowers until Wave 5** so execution tracking stays stable).

---

## Target Information Architecture (public tree)

After completion, the **GitBook-visible** tree under `docs/` should look like this (files may already exist; “NEW” means create or split):

```text
docs/
├── README.md                          # Intro / home
├── SUMMARY.md                         # TOC only, unique paths
├── getting-started.md
├── concepts/
│   ├── building-with-crane.md
│   ├── facet-target-repo.md
│   ├── storage-slots.md
│   ├── guard-functions.md
│   ├── dfpkg.md                       # NEW (conceptual DFPkg; link to deployment/dfpkg)
│   └── registries.md                  # NEW (split from CODEBASE_MAP)
├── deployment/
│   ├── create3.md                     # chain setup + DPCF reuse
│   ├── dfpkg.md
│   ├── factory-services.md
│   └── battlechain.md
├── development/
│   ├── code-style.md
│   ├── natspec.md
│   └── testing.md
├── access/
│   ├── multi-step-ownable.md
│   └── operable.md
├── tokens/
│   └── erc20.md
├── protocols/
│   ├── dexes.md
│   ├── lending.md
│   └── (optional deeper pages only if linked once from SUMMARY)
├── utilities/                         # NEW folder
│   ├── sets.md                        # NEW
│   ├── math-const-prod.md             # NEW (ConstProdUtils + related)
│   └── overview.md                    # NEW (collections, crypto, helpers index)
├── reference/
│   ├── interfaces.md
│   ├── agent-skills.md
│   └── codebase-map.md                # MOVE/rename from CODEBASE_MAP.md (optional; or keep name)
├── funding/
│   └── bankr-launch.md                # COPY from root BANKR_LAUNCH.md
└── archive/                           # NOT in SUMMARY
    ├── reports/                       # was docs/reports
    ├── audits/
    ├── research-scrapes/              # Balancer hack HTML + _files
    ├── internal-plans/                # porting plans, gauge guides, etc.
    └── ...
```

**Root config (unchanged intent):**

```yaml
# .gitbook.yaml at repository root
root: ./docs/
structure:
  readme: README.md
  summary: SUMMARY.md
```

Optional later: `redirects:` for renamed paths (`CODEBASE_MAP.md` → `reference/codebase-map.md`).

---

## File Ownership Map (for parallel agents)

| Workstream ID | Owns (write) | Reads (read-only) | Must not touch |
|---------------|--------------|-------------------|----------------|
| W0-archive | Moves into `docs/archive/**`, update any root pointers if needed | — | Public page content rewrites |
| W1-ia | Skeleton `docs/SUMMARY.md` draft only if sequential; prefer Wave 5 owns final SUMMARY | Current SUMMARY | Content body pages |
| W2-getting-started | `docs/getting-started.md`, `docs/README.md` | AGENTS, PRD LR-2/4, deployment pages | SUMMARY, utilities/* |
| W3-concepts | `docs/concepts/*` (incl. NEW dfpkg.md, registries.md) | CODEBASE_MAP, deployment/dfpkg, create3 | SUMMARY, protocols/* |
| W4-deployment | `docs/deployment/*` | contracts factories, AGENTS, crane-deployment skill | concepts/registries.md (link only) |
| W5-development | `docs/development/*` | crane-testing, crane-natspec, crane-code-style | protocols/* |
| W6-access-tokens | `docs/access/*`, `docs/tokens/*` | contracts access/tokens, skills | deployment/* |
| W7-protocols | `docs/protocols/dexes.md`, `docs/protocols/lending.md` (+ existing lifecycle pages if kept public) | protocol TestBases, skills | utilities/* |
| W8-utilities | `docs/utilities/*` (all NEW) | `contracts/utils/**`, CODEBASE_MAP utilities sections | CODEBASE_MAP rewrite (link only) |
| W9-reference-funding | `docs/reference/*`, `docs/funding/bankr-launch.md`, optional CODEBASE_MAP move | AGENTS, BANKR_LAUNCH.md, interfaces | SUMMARY final |
| W10-integration | `docs/SUMMARY.md`, `.gitbook.yaml`, cross-link pass on all public pages, redirects, broken-link fix | Everything | Do not re-expand archived bulk |

---

## Parallel Execution Model

```text
Wave 0 (sequential gate)
  └─ Archive conflicts → freeze public tree inventory

Wave 1 (sequential, short)
  └─ Page inventory + target SUMMARY skeleton (committed as draft or as plan artifact)
  └─ Create empty NEW file stubs with title + “owned by workstream” so parallel agents don’t collide on mkdir

Wave 2 (PARALLEL subagents — max practical concurrency)
  ├─ W2-getting-started
  ├─ W3-concepts
  ├─ W4-deployment
  ├─ W5-development
  ├─ W6-access-tokens
  ├─ W7-protocols
  ├─ W8-utilities
  └─ W9-reference-funding

Wave 3 (PARALLEL polish — optional second pass per workstream)
  └─ Each subagent re-reads its pages for: LR-2 coverage checklist for its domain, examples, headings for anchors

Wave 4 (sequential)
  └─ W10-integration: SUMMARY unique paths, cross-links, redirects, archive README, link checker

Wave 5 (sequential human + agent)
  └─ Publish checklist (GitBook account steps for human); agent prepares repo only
```

**Subagent prompt template (paste into each spawn):**

```text
You are implementing GitBook docs workstream <ID> for Crane.
Read: docs/superpowers/plans/2026-07-17-gitbook-documentation.md (this plan), AGENTS.md, PRD.md LR-2/LR-4.
Own ONLY these files: <list>.
Do NOT edit SUMMARY.md, .gitbook.yaml, or other workstreams’ files.
Do NOT invent NatSpec selectors; use only existing documented central values.
Write/update Markdown with clear H1/H2, code fences, relative cross-links to sibling public pages (even if target is stub).
When done: list files changed + remaining risks for integration.
```

---

## Wave 0 — Archive Conflicts (sequential)

### Task 0: Move non-publishable material under `docs/archive/`

**Files:**
- Create: `docs/archive/README.md` (index of what was archived and why)
- Move (git mv preferred): see inventory below
- Modify: none of the public guide bodies yet
- Leave in place for now: curated guides listed in Target IA; `docs/superpowers/` until plan execution completes (archive in Task 0b optional at end)

**Inventory to archive (conflicts with clean GitBook root):**

| Source | Destination | Why |
|--------|-------------|-----|
| `docs/reports/` | `docs/archive/reports/` | ~70MB / 17k+ gap reports; not product docs |
| `docs/audits/` | `docs/archive/audits/` | PDF audit dumps; optional later curated links |
| `docs/Balancer Hack*.html` + `*_files/` | `docs/archive/research-scrapes/` | Offline HTML scrapes, large assets |
| `docs/archive/PLAN.md`, `UNIFIED_PLAN.md` | keep under `docs/archive/` | already archived |
| `docs/EULER_PORTING_PLAN.md` | `docs/archive/internal-plans/` | internal porting |
| `docs/frax-port-status.md` | `docs/archive/internal-plans/` | internal |
| `docs/GAUGE_INTEGRATION_GUIDE.md` | `docs/archive/internal-plans/` | not in public SUMMARY |
| `docs/RELiquary_POOL_OPENER_SPEC.md` | `docs/archive/internal-plans/` | internal spec |
| `docs/TRAIL_OF_BITS_PLUGIN_GUIDE.md` | `docs/archive/internal-plans/` | tooling internal |
| `docs/code/` (adoc extracts) | `docs/archive/code/` | generation/extract surface, not GitBook nav |
| Root-level noise only if under docs — do **not** move repo-root `AGENTS.md` / `PRD.md` | — | stay at repo root |

**CENTRALLY_COMPUTED_NATSPEC_VALUES.md:** Today it lives under `docs/reports/gap/`. After move, record the new path in `docs/archive/README.md` and in agent skills only if they hardcode the old path (out of scope unless broken links are trivial). Public docs should not depend on browsing gap reports.

- [ ] **Step 1: Create archive index**

Create `docs/archive/README.md`:

```markdown
# Docs Archive

Material moved out of the GitBook publish surface (`docs/` root used by `.gitbook.yaml`).

| Archived path | Former path | Reason |
|---------------|-------------|--------|
| `reports/` | `docs/reports/` | Gap reports / bulk generated markdown |
| `audits/` | `docs/audits/` | Third-party audit PDFs |
| `research-scrapes/` | Balancer Hack HTML dumps | Offline research, not framework docs |
| `internal-plans/` | Various `docs/*_PLAN*.md` guides | Porting/status internal |

These paths are **not** listed in `docs/SUMMARY.md` and should not be GitBook pages.
```

- [ ] **Step 2: `git mv` bulk directories**

```bash
mkdir -p docs/archive/research-scrapes docs/archive/internal-plans
git mv docs/reports docs/archive/reports
git mv docs/audits docs/archive/audits
# HTML scrapes — quote paths with spaces
git mv "docs/Balancer Hack, Part 1_ The Numbers Were Slightly Wrong — And _Slightly_ Was Enough.html" docs/archive/research-scrapes/
git mv "docs/Balancer Hack, Part 1_ The Numbers Were Slightly Wrong — And _Slightly_ Was Enough_files" docs/archive/research-scrapes/
git mv "docs/Balancer Hack, Part 2_ Depleting the Pool - by nonseodion.html" docs/archive/research-scrapes/
git mv "docs/Balancer Hack, Part 2_ Depleting the Pool - by nonseodion_files" docs/archive/research-scrapes/
git mv "docs/Balancer Hack, Part 3_ Turning Rounding Errors into Invariant Collapse.html" docs/archive/research-scrapes/
git mv "docs/Balancer Hack, Part 3_ Turning Rounding Errors into Invariant Collapse_files" docs/archive/research-scrapes/
git mv docs/EULER_PORTING_PLAN.md docs/archive/internal-plans/
git mv docs/frax-port-status.md docs/archive/internal-plans/
git mv docs/GAUGE_INTEGRATION_GUIDE.md docs/archive/internal-plans/
git mv docs/RELiquary_POOL_OPENER_SPEC.md docs/archive/internal-plans/
git mv docs/TRAIL_OF_BITS_PLUGIN_GUIDE.md docs/archive/internal-plans/
git mv docs/code docs/archive/code
```

- [ ] **Step 3: Verify public top-level is lean**

```bash
ls -la docs/
# Expect: README, SUMMARY, getting-started, section dirs, archive/, superpowers/ (temporary), CODEBASE_MAP.md
# Expect NOT: reports/, audits/, Balancer Hack*, large internal plans at top level
du -sh docs/archive docs
```

- [ ] **Step 4: Commit Wave 0**

```bash
git add -A docs/archive docs/
git status
git commit -m "docs: archive non-GitBook material under docs/archive"
```

**Done when:** GitBook root no longer holds reports/audits/scrapes/internal plans; archive README lists destinations.

---

## Wave 1 — Stubs & SUMMARY Skeleton (sequential, short)

### Task 1: Create NEW page stubs and draft unique SUMMARY

**Files:**
- Create: `docs/concepts/dfpkg.md`, `docs/concepts/registries.md`, `docs/utilities/overview.md`, `docs/utilities/sets.md`, `docs/utilities/math-const-prod.md`, `docs/funding/bankr-launch.md` (stub ok)
- Create or keep: target SUMMARY skeleton (Wave 5 may replace; Wave 1 may write **draft** `docs/SUMMARY.draft.md` to avoid half-broken live SUMMARY—or overwrite SUMMARY carefully with unique paths only)
- Modify: prefer writing `docs/SUMMARY.md` only when every linked path exists (stubs count)

**Target SUMMARY (unique paths — final form for integration):**

```markdown
# Summary

* [Introduction](README.md)
* [Getting Started](getting-started.md)

## Concepts

* [Building with Crane](concepts/building-with-crane.md)
* [Facet-Target-Repo](concepts/facet-target-repo.md)
* [Storage Slots](concepts/storage-slots.md)
* [Guard Functions and Modifiers](concepts/guard-functions.md)
* [DFPkg Pattern](concepts/dfpkg.md)
* [Registries](concepts/registries.md)

## Deployment

* [CREATE3 & New Chain Setup](deployment/create3.md)
* [Diamond Factory Packages](deployment/dfpkg.md)
* [Factory Services](deployment/factory-services.md)
* [BattleChain Security Gate](deployment/battlechain.md)

## Development

* [Code Style](development/code-style.md)
* [NatSpec and Documentation](development/natspec.md)
* [Testing Patterns](development/testing.md)

## Access Control

* [Multi-Step Ownable (ERC8023)](access/multi-step-ownable.md)
* [Operable](access/operable.md)

## Tokens

* [ERC20 + Permit + DFPkg](tokens/erc20.md)

## Protocols

* [DEX Integrations](protocols/dexes.md)
* [Lending Protocols](protocols/lending.md)

## Utilities

* [Utilities Overview](utilities/overview.md)
* [Sets and Set Repos](utilities/sets.md)
* [ConstProdUtils & Math](utilities/math-const-prod.md)

## Reference

* [Key Interfaces](reference/interfaces.md)
* [AI Agent Skills](reference/agent-skills.md)
* [Codebase Map](CODEBASE_MAP.md)

## Funding

* [BankrBot Token Launch](funding/bankr-launch.md)
```

**Rules for this skeleton:**
- Each path appears **exactly once**.
- No LR-2 essay at the bottom.
- No duplicate links to `getting-started.md` / `CODEBASE_MAP.md` for “virtual” sections—those become real pages under concepts/utilities.

- [ ] **Step 1: Create directories and stubs**

```bash
mkdir -p docs/utilities docs/funding docs/concepts
```

Each NEW stub starts as:

```markdown
# <Title>

> Status: stub for GitBook IA. Owned by workstream <ID>. Expand in Wave 2.

## Overview

(Placeholder)

## See also

- [Getting Started](../getting-started.md)
```

- [ ] **Step 2: Write unique `docs/SUMMARY.md`** (replace current multi-link + essay version)

Move old SUMMARY prose (LR-2 section) into archive if useful:

```bash
mkdir -p docs/archive/internal-plans
cp docs/SUMMARY.md docs/archive/internal-plans/SUMMARY-pre-gitbook.md
# then write new SUMMARY.md content (unique paths only)
```

- [ ] **Step 3: Copy Bankr launch stub from root**

```bash
cp BANKR_LAUNCH.md docs/funding/bankr-launch.md
# Front-matter note at top: public docs copy; root BANKR_LAUNCH.md remains source of truth until funding workstream decides
```

- [ ] **Step 4: Commit Wave 1**

```bash
git add docs/SUMMARY.md docs/concepts/dfpkg.md docs/concepts/registries.md docs/utilities docs/funding
git commit -m "docs: GitBook IA stubs and unique SUMMARY navigation"
```

**Done when:** `SUMMARY.md` links only to existing files; `rg -o '\(([^)#]+\.md)' docs/SUMMARY.md -r '$1' | sort | uniq -c` shows all counts = 1.

---

## Wave 2 — Parallel Content Workstreams

Orchestrator: spawn **one subagent per workstream** (W2–W9) with disjoint file ownership. Use `general-purpose` or docs-focused agents; capability `read-write`. Do **not** give them `SUMMARY.md`.

### Task 2A — Getting Started & Home (W2)

**Files:**
- Modify: `docs/getting-started.md`, `docs/README.md`
- Read: `PRD.md` LR-2/LR-4, `AGENTS.md`, `deployment/create3.md`, `deployment/dfpkg.md`

**Content requirements:**
- Prerequisites, install/build (`forge build`), CraneTest bootstrap at high level
- **Required GitBook areas** summarized with links out (not full dumps): chain setup → create3; DPCF reuse → create3/dfpkg; registries → concepts/registries; protocols → protocols/*; utilities → utilities/*
- Agent section: skills under `.claude/skills/` (repo) + global install note per PRD LR-3
- LR-4 security + cost rationale (verbatim-quality, already partially present—tighten, link out)
- Remove reliance on gap-report paths

- [ ] Expand/edit getting-started for public readers + agents
- [ ] Keep README.md as short GitBook home (scope, facet reuse mermaid if valid, how to navigate)
- [ ] Report completion with anchor list for integration (`##` headings)

### Task 2B — Concepts (W3)

**Files:**
- Modify: `docs/concepts/building-with-crane.md`, `facet-target-repo.md`, `storage-slots.md`, `guard-functions.md`
- Create/expand: `docs/concepts/dfpkg.md`, `docs/concepts/registries.md`

**Content requirements:**
- `dfpkg.md`: conceptual DFPkg (PkgInit/PkgArgs on **interface**, facetCuts, initAccount, postDeploy, salt)—link to `deployment/dfpkg.md` for operational detail
- `registries.md`: FacetRegistry, PackageRegistry, CallTargetRegistry—purpose, population via Create3 deploy paths, `canonical*` consumer usage, test asserts via Behavior; **do not** duplicate entire CODEBASE_MAP
- Storage slots: ERC1967 `DEFAULT_SLOT` form per LR-6 where documenting pattern
- Cross-link to deployment + testing without owning those files

- [ ] Fill stubs; ensure each page has single H1 matching SUMMARY title intent
- [ ] Pull registry prose out of CODEBASE_MAP into registries.md (leave CODEBASE_MAP as map/overview)

### Task 2C — Deployment (W4)

**Files:**
- Modify: `docs/deployment/create3.md`, `dfpkg.md`, `factory-services.md`, `battlechain.md`

**Content requirements:**
- **create3.md must include:** Create3FactoryDFPkg / chain presence bootstrap; **explicit** “DiamondPackageCallBackFactory does not need per-chain redeploy; public reuse”; interfaceId `0x949da331` only if already in central values / current docs; deploy flow diagram or steps; link to registries concept page
- **dfpkg.md:** package lifecycle, interface structs rule, calcSalt/initAccount/postDeploy
- **factory-services.md:** FactoryService conventions (salt from type name, vm.label)
- **battlechain.md:** security gate role for production confidence (keep concise)

- [ ] Expand thin pages (battlechain currently short; factory-services short)
- [ ] Ensure create3 carries LR-2 DPCF reuse statement prominently (H2)

### Task 2D — Development (W5)

**Files:**
- Modify: `docs/development/code-style.md`, `natspec.md`, `testing.md`

**Content requirements:**
- testing.md: CraneTest, TestBase_*, Behavior_*, handlers, production-first (no mocking SUT), LR-7 highlights without turning into full AGENTS paste
- natspec.md: include-tags, custom tags, verification approach; do not require readers to open archived gap tree
- code-style: StyleGuide pointers, no viaIR, stack-too-deep via structs

- [ ] Align examples with AGENTS.md patterns
- [ ] Link to protocols + utilities for “how ports use TestBases”

### Task 2E — Access & Tokens (W6)

**Files:**
- Modify: `docs/access/multi-step-ownable.md`, `docs/access/operable.md`, `docs/tokens/erc20.md`

**Content requirements:**
- Operable / MultiStepOwnable as Facet-Target-Repo examples
- ERC20 DFPkg path for deployable token diamonds
- Link to concepts + deployment for “how this attaches”

### Task 2F — Protocols (W7)

**Files:**
- Modify: `docs/protocols/dexes.md`, `docs/protocols/lending.md`
- Optionally leave deeper lifecycle pages (`protocols/balancer/v3/...`) **out of SUMMARY** unless integration adds them as unique entries; if kept on disk but unlisted, they won’t be primary nav (GitBook may still import files—prefer move non-nav protocol research to `docs/archive/protocol-notes/` if noisy)

**Content requirements:**
- Per major port family: AwareRepo, *Service, stubs vs mocks terminology, TestBase inheritance examples (Camelot/Aerodrome/Uniswap/Balancer/Aave/Euler as applicable)
- Protocol-specific utils callouts + link to `utilities/*`
- Integration steps + test usage (LR-2)

- [ ] Ensure dexes + lending are agent-usable without reading entire CODEBASE_MAP

### Task 2G — Utilities (W8)

**Files:**
- Create/expand: `docs/utilities/overview.md`, `sets.md`, `math-const-prod.md`

**Content requirements:**
- Sets: AddressSet/Bytes32Set/Bytes4Set + *SetRepo patterns (1-indexed, _add/_remove/_values)—from architecture docs / AddressSetRepo
- ConstProdUtils: quotes, reserve sorting, LP helpers; who consumes (Camelot/Aerodrome services, tests)
- overview: collections, cryptography, helpers index with links into `contracts/utils/` by name

- [ ] This workstream **owns** content that previously forced 7× links to CODEBASE_MAP in SUMMARY

### Task 2H — Reference & Funding (W9)

**Files:**
- Modify: `docs/reference/interfaces.md`, `docs/reference/agent-skills.md`, `docs/CODEBASE_MAP.md` (trim to map; point registries/utils to new pages)
- Modify: `docs/funding/bankr-launch.md` (from copy of root `BANKR_LAUNCH.md`)

**Content requirements:**
- CODEBASE_MAP: keep navigation/architecture overview; **dedupe** long registries/utils sections into links to new pages (edit carefully so parallel agents don’t race—W9 owns CODEBASE_MAP only)
- agent-skills: map skill names → tasks; link getting-started
- funding: publishable subset of Bankr launch runbook; mark deferred spikes clearly

**Parallel gate:** W9 must not edit files owned by W3/W8; only link to them.

- [ ] Trim CODEBASE_MAP duplication
- [ ] bankr-launch readable standalone under docs/

### Task 2I — Orchestrator checklist after parallel wave

- [ ] Collect each subagent’s “files changed + heading list”
- [ ] Confirm no file ownership collisions via `git status` / `git diff --name-only`
- [ ] Do **not** start integration until all W2–W9 report done or explicitly waived

```bash
git add docs/
git commit -m "docs: parallel GitBook content expansion (wave 2)"
```

---

## Wave 3 — Per-workstream polish (parallel, optional but recommended)

### Task 3: Domain polish subagents (same ownership as Wave 2)

Each subagent re-opens **only its files** and checks:

| Check | Pass criteria |
|-------|----------------|
| H1 present once | First line heading matches page purpose |
| LR-2 local | Domain’s required bullets covered or linked |
| Code blocks | Solidity fences compile conceptually; no fake selectors |
| See also | 3–8 relative links to other public pages |
| No archive links | No `docs/archive/reports/...` required reading |
| No SUMMARY edits | Unchanged |

- [ ] Spawn polish agents (can batch by combining small workstreams)
- [ ] Commit: `docs: polish GitBook pages per domain (wave 3)`

---

## Wave 4 — Integration Pass (sequential, single owner)

### Task 4: Cross-cutting integration (W10)

**Files:**
- Modify: `docs/SUMMARY.md` (final), `.gitbook.yaml` (redirects if needed), **all public pages** for cross-links only
- Create: `docs/archive/README.md` updates if paths changed
- Create: optional `docs/.gitbookignore` **only if** GitBook supports it for the account—**verify current GitBook docs before relying on it**; default strategy is archive + SUMMARY, not ignore files

**Subagent role:** one integration agent (or human-guided main session). Skills: systematic broken-link fix, SUMMARY uniqueness.

- [ ] **Step 1: SUMMARY uniqueness audit**

```bash
rg -o '\(([^)#]+\.md)' docs/SUMMARY.md -r '$1' | sort | uniq -c | sort -rn
# All counts must be 1. Fail if any >1.
```

- [ ] **Step 2: Every SUMMARY link exists**

```bash
while read -r f; do
  [ -f "docs/$f" ] || echo "MISSING $f"
done < <(rg -o '\(([^)#]+\.md)' docs/SUMMARY.md -r '$1' | sort -u)
```

- [ ] **Step 3: Cross-reference matrix (minimum)**

Integration agent ensures these **bidirectional** link pairs exist (add “See also” sections if missing):

| From | To |
|------|-----|
| getting-started | create3, dfpkg, registries, testing, utilities/overview, building-with-crane |
| create3 | registries, dfpkg, getting-started, factory-services |
| concepts/dfpkg | deployment/dfpkg, create3 |
| concepts/registries | create3, CODEBASE_MAP or reference, testing |
| testing | protocols/dexes, protocols/lending, utilities/sets, getting-started |
| protocols/* | testing, utilities/math-const-prod, deployment/dfpkg |
| utilities/* | CODEBASE_MAP (overview), testing, protocols/dexes |
| README | getting-started, SUMMARY not needed |

- [ ] **Step 4: Strip residual multi-purpose anti-patterns**

- Remove any remaining “link the same file under five SUMMARY bullets” patterns
- Remove LR essays from SUMMARY if reintroduced
- Replace absolute GitHub URLs with relative links where both ends are in `docs/`

- [ ] **Step 5: `.gitbook.yaml` redirects (if renames happened)**

Example if CODEBASE_MAP path changes:

```yaml
root: ./docs/

structure:
  readme: README.md
  summary: SUMMARY.md

redirects:
  CODEBASE_MAP.md: CODEBASE_MAP.md
  # example future:
  # old/getting-started.md: getting-started.md
```

Only add redirects for real renames.

- [ ] **Step 6: Root README pointer**

Modify repo root `README.md` (if not already clear) with a single docs entrypoint:

```markdown
## Documentation

GitBook-oriented docs live in [`docs/`](docs/) with navigation in [`docs/SUMMARY.md`](docs/SUMMARY.md).
```

(Keep change minimal.)

- [ ] **Step 7: Link check script (lightweight)**

```bash
# Extract markdown links to .md files from public docs (exclude archive)
rg -o '\]\(([^)]+\.md)(#[^)]*)?\)' docs --glob '!archive/**' --glob '!superpowers/**' -r '$1' | sort -u | head
# Manually or script: resolve relative to each file’s directory
```

Optional small script `scripts/check_docs_links.sh` (only if quick):

```bash
#!/usr/bin/env bash
set -euo pipefail
# For each docs/**/*.md except archive/superpowers, resolve relative .md links and test -f
fail=0
while IFS= read -r -d '' file; do
  dir=$(dirname "$file")
  # rg links in file...
done < <(find docs -name '*.md' ! -path 'docs/archive/*' ! -path 'docs/superpowers/*' -print0)
exit $fail
```

- [ ] **Step 8: Commit integration**

```bash
git add docs/ .gitbook.yaml README.md scripts/check_docs_links.sh 2>/dev/null || true
git commit -m "docs: GitBook integration pass — unique SUMMARY, cross-links, link hygiene"
```

**Done when:**
1. SUMMARY unique + all targets exist  
2. Cross-reference matrix satisfied  
3. No required reader path into `docs/archive/reports`  
4. Public `docs/` top-level is navigable without bulk dirs  

---

## Wave 5 — Publish Readiness (repo complete; human for GitBook UI)

### Task 5: Publish checklist (agent prepares; human executes GitBook)

**Agent (repo) checklist:**

- [ ] `.gitbook.yaml` valid at repo root  
- [ ] `docs/SUMMARY.md` TOC-only + unique paths  
- [ ] `docs/README.md` is suitable home page  
- [ ] Archive documented  
- [ ] Root README points to docs  
- [ ] Optional: open PR describing GitBook sync steps  

**Human (GitBook UI) checklist:**

- [ ] Create GitBook org/space “Crane”  
- [ ] Configure → GitHub Sync → install GitBook GitHub app on `cyotee/crane`  
- [ ] Branch: `main` (or docs PR branch)  
- [ ] Initial direction: **GitHub → GitBook**  
- [ ] Verify sidebar matches SUMMARY  
- [ ] Spot-check: Getting Started, CREATE3, Registries, Testing, Utilities  
- [ ] Set space visibility + optional custom domain  
- [ ] Add public docs URL to root README / Bankr metadata when live  

**Out of scope for agents without credentials:** GitBook login, GitHub app install approval, DNS.

---

## Optional Task 0b — Archive superpowers after plan execution

When this plan is fully executed and no longer needed in-tree for agents:

```bash
mkdir -p docs/archive/internal-plans
git mv docs/superpowers docs/archive/internal-plans/superpowers
```

Update any references. Prefer doing this **after** Wave 4 so the plan path remains stable during work.

---

## Verification Plan (definition of done)

| # | Check | Command / method |
|---|--------|------------------|
| 1 | SUMMARY uniqueness | `uniq -c` all counts = 1 |
| 2 | SUMMARY targets exist | file existence loop |
| 3 | No bulk at docs root | `ls docs` — no reports/audits/scrapes |
| 4 | LR-2 coverage | Manual matrix: each PRD bullet has a dedicated page or clear section + SUMMARY entry |
| 5 | DPCF reuse statement | `rg -n "does not need|not need to be redeployed|public reuse" docs/deployment/create3.md` |
| 6 | Registries page exists | `test -f docs/concepts/registries.md` |
| 7 | Utilities pages exist | `test -f docs/utilities/sets.md` etc. |
| 8 | Cross-links | Matrix in Task 4 |
| 9 | GitBook config | `test -f .gitbook.yaml` && root is `./docs/` |
| 10 | Build unaffected | `forge build` still works (docs-only should not break) |

LR-2 coverage matrix (integration fills status):

| PRD requirement | Primary page |
|-----------------|--------------|
| CREATE3 package chain setup | `deployment/create3.md` |
| DPCF no per-chain redeploy | `deployment/create3.md` (+ mention in getting-started) |
| Registries detailed | `concepts/registries.md` |
| Ported protocols + tests | `protocols/dexes.md`, `protocols/lending.md`, `development/testing.md` |
| Protocol utilities | protocols pages + `utilities/math-const-prod.md` |
| Sets / general utils | `utilities/sets.md`, `utilities/overview.md` |
| Agent getting started / building | `getting-started.md`, `concepts/building-with-crane.md` |
| LR-4 reuse rationale | `getting-started.md` (+ brief on README) |

---

## Risk Register

| Risk | Mitigation |
|------|------------|
| Parallel agents edit same file | Hard ownership table; integration-only SUMMARY |
| GitBook imports unlisted files as orphan pages | Archive bulk; keep only intentional MD under public tree |
| Moving reports breaks skill/doc paths | Archive README; fix only high-traffic pointers; skills update separate task |
| Duplicate content CODEBASE_MAP vs new pages | W9 trims map; W3/W8 own detail |
| SUMMARY essay creeps back | Integration rejects prose in SUMMARY |
| Subagent invents selectors | Prompt forbids; use existing doc values only |
| Large `git mv` of reports | Single Wave 0 commit; warn on slow git |

---

## Effort Estimate (agent-hours, approximate)

| Wave | Effort | Parallelism |
|------|--------|-------------|
| 0 Archive | 0.5–1h | Sequential |
| 1 Stubs + SUMMARY | 0.5h | Sequential |
| 2 Content | 4–10h wall / ~1–2h wall if 7 agents | **High** |
| 3 Polish | 1–2h wall | High |
| 4 Integration | 1–2h | Sequential |
| 5 Publish | 0.5h agent + human GitBook | Human-gated |

---

## Execution Handoff

**Plan complete and saved to** `docs/superpowers/plans/2026-07-17-gitbook-documentation.md`.

**Recommended execution mode:** Subagent-driven with explicit waves:

1. Main session runs **Wave 0 → Wave 1** (sequential).  
2. Main session **spawns parallel subagents** for Wave 2 (Tasks 2A–2H).  
3. Optional parallel Wave 3 polish.  
4. Main session or single integration subagent runs **Wave 4**.  
5. Human completes **Wave 5** GitBook UI.

**Skills to load when executing:**
- `dispatching-parallel-agents` / `spawn_subagent` for Wave 2–3  
- `subagent-driven-development` for task gates  
- `crane-architecture`, `crane-deployment`, `crane-testing` as read-only references for content accuracy  
- `verification-before-completion` before claiming publish-ready  

**Which approach?**  
1. **Subagent-Driven (recommended)** — parallel Wave 2 as designed  
2. **Inline Execution** — same waves, single session (slower)

---

## Self-Review (plan quality)

| Spec item | Task coverage |
|-----------|----------------|
| Archive conflicts to `docs/archive/` | Task 0 |
| Unique SUMMARY / GitBook rules | Tasks 1, 4 |
| Parallel content work | Tasks 2A–2H |
| Integration cross-links | Task 4 |
| LR-2 required areas | Tasks 2A–2G + matrix |
| Missing `concepts/dfpkg.md`, Bankr under docs | Tasks 1, 2B, 2H |
| Publish path | Task 5 |
| No placeholder “TBD” content steps | Concrete file lists + SUMMARY body + commands |

**Placeholder scan:** No TBD/implement-later for required pages; optional link-check script marked optional.

**Consistency:** Workstream IDs and file ownership aligned across waves; integration is sole SUMMARY owner after Wave 1 skeleton.
