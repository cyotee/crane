# Public Release Inventory Report

## 1. Metadata

| Field | Value |
|-------|-------|
| Date (UTC) | 2026-07-21 |
| Branch | `main` |
| HEAD (short) | `681a1e65` |
| Spec | [INVENTORY_GOAL.md](../../INVENTORY_GOAL.md) v0.2 |
| Parent PRD | [PRD_PUBLIC_RELEASE.md](../../PRD_PUBLIC_RELEASE.md) |
| Goal type | Analysis only (no cleanup applied) |

### Counts

| Metric | Value |
|--------|------:|
| Z0 root files (`find . -maxdepth 1 -type f`, excl. `.git`) | **47** |
| Z3 `tasks/` files | **774** |
| Z3 active `CRANE-*` dirs | **97** |
| Z3 archived `CRANE-*` dirs | **176** |
| Z3 tracked paths | **774** |
| Z4 product docs (`*.md`/`*.adoc`, excl. archive) | **43** |
| Z5 `docs/archive/reports` files (tracked) | **~17,816** |
| Z5 `docs/archive/research-scrapes` files (tracked) | **~1,083** |
| Z5 `docs/archive/audits` files (tracked) | **17** |
| `contracts/external` files | **~4,454** |
| `contracts/protocols` files | **~2,502** |
| Leaf inventory rows (tables below; hierarchy, not unique files) | see §2 |

---

## 2. Executive summary

- **Largest public risk:** `docs/archive/reports` (~17.8k tracked files, mostly gap-report mirrors) plus `research-scrapes` (~1k HTML/assets) dominate clone noise.
- **Locked purge:** entire `tasks/` tree (774 files, 97 active + 176 archived CRANE dirs) → **DELETE**; do not complete tasks; no GitHub Issues replacement.
- **Root war room:** ~20 planning/PRD/log/review files at repo root must MOVE/DELETE/GITIGNORE before announcement.
- **Generated tracked junk:** `COVERAGE*.log`, `reports/` (32), `tmp/` (4), `output/` (1) should leave git tracking.
- **Build artifacts:** `out/` (~5.8k), `book/`, `cache*`, `.mdbook-src/` already untracked / gitignored — confirm ignore completeness.
- **Agent surface (OD-2):** `.claude/`, `.agents/`, `.grok/`, skills → **KEEP** as public agent surface.
- **Funding (OD-3):** strip `BANKR_LAUNCH.md`, `GOVERNANCE.md` (funding narrative), `docs/funding/*` from front door via MOVE/ARCHIVE_THIN.
- **Audits (OD-4):** `docs/archive/audits` KEEP thin in-tree (17 PDFs).
- **Certora (OD-5):** `certora/` KEEP.
- **Protocols (OD-6):** mixed maturity — core factories/access/tokens **stable**; many lending/perps/CDP trees **vendored** or **port-in-progress**.
- **Dependencies:** five git submodules under `lib/` (forge-std, OZ, chainlink-local, battlechain-lib, gitlawb-contracts).
- **Dual lockfiles:** both `package-lock.json` and `yarn.lock` present — human REVIEW.
- **No cleanup performed** in this goal; only this report (and `docs/roadmap/`) written.

### Disposition counts (leaf path-table rows only)

Counted from zone path tables in §4 (rows whose first cell is a `` `path` `` and whose disposition cell is an allowed code). Hierarchical parents and children are both counted when both appear as rows (e.g. `test/` and `test/foundry/spec/access/`). Z9 “config notes” non-path rows are excluded.

| Disposition | Rows | Notes |
|-------------|-----:|-------|
| KEEP | 124 | Product docs, core contracts, agent tooling, certora, licenses, config essentials |
| MOVE | 19 | Root PRDs/plans + funding front-door paths |
| ARCHIVE_THIN | 12 | Superpowers plans/specs, historical plans |
| REVIEW | 11 | Bulk archive gap/scrapes (OD-1), dual locks, snapshots, README.adoc, hardhat dual config, design.yaml, test/hardhat, gitlawb |
| DELETE | 8 | `tasks/` + agent prompts + generated root logs/reviews |
| GITIGNORE | 8 | out/book/cache/tmp/reports/output tracking |
| KEEP_INTERNAL | 1 | Aave v4 `VENDOR_PROVENANCE.md` |
| EXTERNALIZE | 0 | Not defaulted for bulk archive (OD-1) |
| **Total** | **183** | Sum of disposition codes above (= path-table leaf rows inventoried) |

---

## 3. Locked decisions (echo)

### Product locks

1. **`tasks/` → DELETE entirely** (active + archive + INDEX + TEMPLATE). Count only; **no** body/title scan (OD-7). Do **not** complete any CRANE task.
2. **No GitHub Issues** (or other tracker) as replacement in this project.
3. **Analysis only** — this report does not mutate product trees or delete tasks/archive.

### Owner decisions OD-1…OD-7

| # | Topic | Decision | Applied in inventory |
|---|--------|----------|----------------------|
| OD-1 | Bulk `docs/archive` gap/scrapes | **REVIEW only** | `docs/archive/reports`, `research-scrapes` → `REVIEW`, **no recommended default** |
| OD-2 | Agent tooling | **Public agent surface** | `.claude/`, `.agents/`, `.grok/`, `.opencode/`, `.sisyphus/` → **KEEP** |
| OD-3 | Funding / DAOSYS / Bankr | **Strip from front door** | Root funding files + `docs/funding/*` → **MOVE** / **ARCHIVE_THIN** |
| OD-4 | Audit PDFs | **KEEP thin in-tree** | `docs/archive/audits` → **KEEP** |
| OD-5 | `certora/` | **KEEP** | **KEEP** |
| OD-6 | Protocol maturity | **Disposition + Maturity** | Z6 tables include Maturity column |
| OD-7 | Tasks scan | **Count + DELETE only** | Z3 single tree row |

---

## 4. Zone inventories (Z0–Z9)

Disposition codes: `KEEP` | `KEEP_INTERNAL` | `MOVE` | `ARCHIVE_THIN` | `EXTERNALIZE` | `DELETE` | `GITIGNORE` | `REVIEW`.

### Z0 — Repo root files (47)

| Path | Kind | Tracked? | Size/Count | Role | Disposition | Target / notes |
|------|------|----------|------------|------|-------------|----------------|
| `.gitbook.yaml` | file | yes | 307 B | GitBook config | KEEP | Product docs pipeline |
| `.gitignore` | file | yes | 1.1 KB | Ignore rules | KEEP | Extend in cleanup wave for logs/tmp/reports |
| `.gitmodules` | file | yes | 584 B | Submodule pins | KEEP | |
| `AAVE_DEPS_INVENTORY.md` | file | yes | 30 KB | Aave dep inventory | MOVE | `docs/archive/internal-plans/AAVE_DEPS_INVENTORY.md` |
| `AGENTS.md` | file | yes | 35 KB | Agent/contributor guide | KEEP | Public agent surface |
| `Aave_Vendored_Dependencies_Dedup_Plan.md` | file | yes | 16 KB | Dedup plan | MOVE | `docs/archive/internal-plans/` |
| `BANKR_LAUNCH.md` | file | yes | 5.4 KB | Token launch playbook | MOVE | OD-3: `docs/archive/internal-plans/bankr-launch.md` (or roadmap/history) |
| `CLAUDE.md` | file | yes | 1.0 KB | Agent bootstrap pointer | KEEP | Public agent surface |
| `COVERAGE.log` | file | yes | 255 KB | Generated coverage | DELETE | Also GITIGNORE pattern `*.log` / `COVERAGE*` |
| `COVERAGE_SUMMARY.log` | file | yes | 134 KB | Generated coverage | DELETE | Same |
| `DEDUPLICATION.md` | file | yes | 84 KB | Dedup audit | MOVE | `docs/archive/internal-plans/` |
| `DEFI_PORTING_GAP_ANALYSIS.md` | file | yes | 15 KB | Port gap analysis | MOVE | `docs/archive/internal-plans/` or `docs/roadmap/history/` |
| `DEFI_PORTING_PRD.md` | file | yes | 28 KB | Historical port PRD | MOVE | `docs/archive/internal-plans/` |
| `DEFI_PORTING_PRIORITIZATION.md` | file | yes | 13 KB | Port prioritization | MOVE | same |
| `DEFI_RESEARCH.md` | file | yes | 27 KB | Research notes | MOVE | same |
| `DEPLOYMENT_PRIORITY.md` | file | yes | 12 KB | Deploy priority notes | MOVE | same |
| `GAP_REPORT.md` | file | yes | 254 KB | Generated gap dump | DELETE | Superseded by archive gap tree; no product value at root |
| `GOVERNANCE.md` | file | yes | 21 KB | Governance + funding narrative | MOVE | OD-3 strip front door → `docs/archive/internal-plans/GOVERNANCE.md` |
| `INVENTORY_GOAL.md` | file | no* | 18 KB | This inventory goal spec | MOVE | After project: `docs/roadmap/INVENTORY_GOAL.md` (KEEP at root until cleanup waves done is OK) |
| `LICENSE` | file | yes | 35 KB | Root license | KEEP | Clarify multi-license in README later |
| `MIGRATION_ConstProdUtils_Tests.md` | file | yes | 9.6 KB | Migration notes | MOVE | `docs/archive/internal-plans/` |
| `PRD.md` | file | yes | 25 KB | Historical framework PRD | MOVE | `docs/archive/internal-plans/PRD-framework-2026-01.md` |
| `PRD_PUBLIC_RELEASE.md` | file | no* | 18 KB | Public-release project PRD | MOVE | `docs/roadmap/PRD_PUBLIC_RELEASE.md` when waves start |
| `PROMPT.md` | file | yes | 26 KB | Agent session prompt | DELETE | Internal agent prompt |
| `README.md` | file | yes | 9.0 KB | Public front door | KEEP | Rewrite in packaging wave (strip funding pitch) |
| `RESUMPTION_PROMPT.md` | file | yes | 8.9 KB | Agent resumption | DELETE | |
| `SLIPSTREAM_ANALYSIS.md` | file | yes | 5.9 KB | Analysis notes | MOVE | `docs/archive/internal-plans/` |
| `Superchain_Testing_Guide.md` | file | yes | 6.1 KB | Testing guide | MOVE | Promote only if accurate → else archive; target `docs/archive/internal-plans/` |
| `TEST_COVERAGE_REPORT.md` | file | yes | 14 KB | Coverage report | DELETE | Generated/stale |
| `UNIFIED_REVIEW_PLAN.md` | file | yes | 4.7 KB | Review plan | MOVE | `docs/archive/internal-plans/` |
| `VENDORED_DEPENDENCY_DUPLICATION_AUDIT.md` | file | yes | 15 KB | Vendoring audit | MOVE | `docs/archive/internal-plans/` |
| `book.toml` | file | yes | 723 B | mdBook config | KEEP | |
| `crane.code-workspace` | file | yes | 269 B | VS Code workspace | KEEP | Contributor ergonomics |
| `crane_solidity_review.md` | file | yes | 273 KB | One-off review dump | DELETE | Or ARCHIVE_THIN off default if must keep; default DELETE |
| `cspell.config.yaml` | file | yes | 441 B | Spellcheck | KEEP | |
| `design.yaml` | file | yes | 268 B | Design tooling config | REVIEW | Confirm still used; default KEEP if referenced |
| `foundry.lock` | file | yes | 3.4 KB | Foundry lock | KEEP | |
| `foundry.toml` | file | yes | 14 KB | Foundry config | KEEP | |
| `hardhat.config.js` | file | yes | 528 B | Hardhat (JS) | REVIEW | Dual with `.ts`; default KEEP until consolidate |
| `hardhat.config.ts` | file | yes | 475 B | Hardhat (TS) | REVIEW | same |
| `package-lock.json` | file | yes | 269 KB | npm lock | REVIEW | Dual lock with yarn — pick one package manager |
| `package.json` | file | yes | 2.2 KB | npm package | KEEP | |
| `remappings.txt` | file | yes | 390 B | Sol remappings | KEEP | |
| `skills-lock.json` | file | yes | 28 KB | Skills lock | KEEP | Public agent surface |
| `slither.config.json` | file | yes | 259 B | Slither config | KEEP | |
| `tsconfig.json` | file | yes | 232 B | TS config | KEEP | |
| `yarn.lock` | file | yes | 152 KB | Yarn lock | REVIEW | Dual lock with npm |

\* `INVENTORY_GOAL.md` / `PRD_PUBLIC_RELEASE.md` may be untracked until committed; present on disk and inventoried.

**Z0 row count: 47** (matches `find . -maxdepth 1 -type f`).

---

### Z1 — Root support directories

| Path | Kind | Tracked? | Size/Count | Role | Disposition | Target / notes |
|------|------|----------|------------|------|-------------|----------------|
| `reports/` | dir | yes (32) | 32 files | Engine pre/post JSON reports | GITIGNORE | Untrack; add to `.gitignore` |
| `snapshots/` | dir | yes (21) | 21 files | Foundry gas snapshots | REVIEW | If CI uses them → KEEP; else GITIGNORE. **Recommended default: KEEP** if referenced by forge; else ignore |
| `tmp/` | dir | yes (4) | 4 files | Local compile logs | GITIGNORE | Untrack + ignore |
| `output/` | dir | yes (1) | 1 file | Local output | GITIGNORE | Untrack + ignore |
| `cache/` | dir | no (0) | 7 files | Hardhat cache | GITIGNORE | Already ignored |
| `cache_forge/` | dir | no (0) | 1 file | Forge cache | GITIGNORE | Already ignored |
| `book/` | dir | no (0) | 72 files | mdBook build output | GITIGNORE | Already ignored |
| `out/` | dir | no (0) | 5830 files | Forge artifacts | GITIGNORE | Already ignored |
| `images/` | dir | yes (2) | 2 files | Docs/diagram assets | KEEP | |
| `theme/` | dir | yes (1) | 1 file | mdBook theme hook | KEEP | |
| `utils/` | dir | yes (6) | 6 files | Asset helper texts | KEEP | |
| `licenses/` | dir | yes (4) | 4 files | Apache/MIT/BSL/GGPL texts | KEEP | Multi-license set |
| `certora/` | dir | yes (136) | 136 files | Formal verification specs/harnesses | KEEP | OD-5 |
| `scripts/` | dir | yes (21) | 21 files | Docs build, natspec, foundry scripts, frax-port | KEEP | Subpath `scripts/frax-port/` could later ARCHIVE_THIN |

---

### Z2 — Dot dirs / tooling

| Path | Kind | Tracked? | Size/Count | Role | Disposition | Target / notes |
|------|------|----------|------------|------|-------------|----------------|
| `.github/` | dir | yes (2) | 2 files | CI/workflows | KEEP | |
| `.gitignore` | file | yes | — | (also Z0) | KEEP | |
| `.gitmodules` | file | yes | — | (also Z0) | KEEP | |
| `.gitbook.yaml` | file | yes | — | (also Z0) | KEEP | |
| `.claude/` | dir | yes (~347 paths) | ~226 files on disk | Skills + agent config | KEEP | OD-2 public agent surface |
| `.agents/` | dir | yes (740) | 740 files | Agent skill/plugin copies | KEEP | OD-2 |
| `.grok/` | dir | yes (~145 paths) | ~24 files on disk | Grok skills | KEEP | OD-2 |
| `.opencode/` | dir | no (0) | 24 files | OpenCode local | KEEP | OD-2; ensure not secret-bearing; currently untracked |
| `.sisyphus/` | dir | yes (2) | 2 files | Agent plans | KEEP | OD-2 public agent surface (small) |
| `.vscode/` | dir | yes (1) | 1 file | Editor settings | KEEP | |
| `.cartographer/` | dir | yes (8) | 8 files | Codebase map tooling | KEEP | |
| `.cspell/` | dir | yes (3) | 3 files | Spell dictionaries | KEEP | |
| `.mdbook-src/` | dir | no (0) | 34 files | Generated mdBook src | GITIGNORE | Already in `.gitignore` |

---

### Z3 — tasks/

| Path | Kind | Tracked? | Size/Count | Role | Disposition | Target / notes |
|------|------|----------|------------|------|-------------|----------------|
| `tasks/` | tree | yes (774) | 774 files; 97 active CRANE-* dirs; 176 archive CRANE-* dirs; INDEX.md + TEMPLATE.md | Historical in-repo agent task system | **DELETE** | OD-7: count only. Entire tree removed in cleanup Wave A. No GitHub Issues migration. No body scan. |

---

### Z4 — Product documentation (43 files)

| Path | Kind | Tracked? | Size/Count | Role | Disposition | Target / notes |
|------|------|----------|------------|------|-------------|----------------|
| `docs/SUMMARY.md` | file | yes | — | GitBook/mdBook nav | KEEP | Remove Funding section in packaging wave |
| `docs/README.md` | file | yes | — | Docs intro | KEEP | |
| `docs/README.adoc` | file | yes | — | AsciiDoc alternate home | REVIEW | **Recommended default: KEEP** until mdBook/AsciiDoc pipeline dropped; then DELETE or consolidate into README.md |
| `docs/getting-started.md` | file | yes | — | Onboarding | KEEP | |
| `docs/CODEBASE_MAP.md` | file | yes | — | Architecture map | KEEP | |
| `docs/access/multi-step-ownable.md` | file | yes | — | Product page | KEEP | |
| `docs/access/operable.md` | file | yes | — | Product page | KEEP | |
| `docs/concepts/building-with-crane.md` | file | yes | — | Concept | KEEP | |
| `docs/concepts/dfpkg.md` | file | yes | — | Concept | KEEP | |
| `docs/concepts/facet-target-repo.md` | file | yes | — | Concept | KEEP | |
| `docs/concepts/guard-functions.md` | file | yes | — | Concept | KEEP | |
| `docs/concepts/registries.md` | file | yes | — | Concept | KEEP | |
| `docs/concepts/storage-slots.md` | file | yes | — | Concept | KEEP | |
| `docs/deployment/battlechain.md` | file | yes | — | Deploy gate | KEEP | |
| `docs/deployment/create3.md` | file | yes | — | CREATE3 | KEEP | |
| `docs/deployment/dfpkg.md` | file | yes | — | DFPkg deploy | KEEP | |
| `docs/deployment/factory-services.md` | file | yes | — | FactoryService | KEEP | |
| `docs/development/code-style.md` | file | yes | — | Style | KEEP | |
| `docs/development/natspec.md` | file | yes | — | NatSpec | KEEP | |
| `docs/development/testing.md` | file | yes | — | Testing | KEEP | |
| `docs/funding/bankr-launch.md` | file | yes | — | Funding playbook | **MOVE** | OD-3 → `docs/archive/internal-plans/bankr-launch.md`; drop from SUMMARY |
| `docs/tokens/erc20.md` | file | yes | — | Tokens | KEEP | |
| `docs/protocols/dexes.md` | file | yes | — | DEX hub | KEEP | |
| `docs/protocols/lending.md` | file | yes | — | Lending hub | KEEP | |
| `docs/protocols/balancer/v3/Balancer_V3_Lifecycle.md` | file | yes | — | Protocol deep-dive | KEEP | Optional SUMMARY link |
| `docs/protocols/uniswap/v4/Uniswap_V4_Lifecycle.md` | file | yes | — | Protocol deep-dive | KEEP | |
| `docs/protocols/lending/euler/v1/EulerV1_Lifecycle.md` | file | yes | — | Protocol deep-dive | KEEP | |
| `docs/protocols/lending/euler/v1/EulerV1_Wrapper_Value_Design.md` | file | yes | — | Design proposal | ARCHIVE_THIN | → `docs/archive/internal-plans/` |
| `docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md` | file | yes | — | Port provenance | KEEP_INTERNAL | Not SUMMARY front door |
| `docs/reference/interfaces.md` | file | yes | — | Interfaces ref | KEEP | |
| `docs/reference/agent-skills.md` | file | yes | — | Skills index | KEEP | |
| `docs/utilities/overview.md` | file | yes | — | Utils hub | KEEP | |
| `docs/utilities/sets.md` | file | yes | — | Sets | KEEP | |
| `docs/utilities/math-const-prod.md` | file | yes | — | ConstProdUtils | KEEP | |
| `docs/superpowers/plans/2026-05-17-aave-v4-port.md` | file | yes | — | Internal plan | ARCHIVE_THIN | → `docs/archive/internal-plans/` |
| `docs/superpowers/plans/2026-05-17-aave-v4-test-fixes.md` | file | yes | — | Internal plan | ARCHIVE_THIN | same |
| `docs/superpowers/plans/2026-05-20-bc-erc20permit-pilot.md` | file | yes | — | Internal plan | ARCHIVE_THIN | same |
| `docs/superpowers/plans/2026-05-20-bc-erc20permit-pilot-progress.md` | file | yes | — | Progress log | ARCHIVE_THIN | same |
| `docs/superpowers/plans/2026-05-30-bold-port.md` | file | yes | — | Internal plan | ARCHIVE_THIN | same |
| `docs/superpowers/plans/2026-06-02-frax-port.md` | file | yes | — | Internal plan | ARCHIVE_THIN | same |
| `docs/superpowers/plans/2026-07-17-gitbook-documentation.md` | file | yes | — | Docs work plan | ARCHIVE_THIN | same |
| `docs/superpowers/specs/2026-05-30-bold-port-design.md` | file | yes | — | Design spec | ARCHIVE_THIN | same |
| `docs/superpowers/specs/2026-06-02-frax-port-design.md` | file | yes | — | Design spec | ARCHIVE_THIN | same |

**Note:** `docs/protocols/pendle/*.pdf` exist (not md/adoc) — treat as KEEP_INTERNAL protocol reference assets if retained; not counted in Z4 43.

---

### Z5 — docs/archive/ (immediate children + bulk policy)

| Path | Kind | Tracked? | Size/Count | Role | Disposition | Target / notes |
|------|------|----------|------------|------|-------------|----------------|
| `docs/archive/README.md` | file | yes | 1 | Archive policy index | KEEP | Expand with policy after waves |
| `docs/archive/PLAN.md` | file | yes | 1 | Historical plan | ARCHIVE_THIN | Stay under archive or merge into internal-plans |
| `docs/archive/UNIFIED_PLAN.md` | file | yes | 1 | Historical unified plan | ARCHIVE_THIN | same |
| `docs/archive/audits/` | dir | yes | 17 files | Third-party audit PDFs (Pendle etc.) | **KEEP** | OD-4 KEEP thin in-tree; add short index README |
| `docs/archive/code/` | dir | yes | 1 file | Extracted adoc snippet | KEEP | Harmless thin archive |
| `docs/archive/internal-plans/` | dir | yes | 6 files | Historical engineering plans | KEEP | Destination for MOVE/ARCHIVE_THIN from root & superpowers |
| `docs/archive/reports/` | tree | yes | **~17,816 files** | Gap-report mirrors of contracts/tests/docs | **REVIEW** | OD-1: **no recommended default**. Risk: dominates git clone. Size/risk only. |
| `docs/archive/research-scrapes/` | tree | yes | **~1,083 files** | Saved HTML + asset trees (Balancer hack series) | **REVIEW** | OD-1: **no recommended default**. Large binary-ish asset noise. |

---

### Z6 — contracts/ (Maturity required)

#### Z6a — Top-level packages & root files

| Path | Kind | Tracked? | Size/Count | Role | Maturity | Disposition | Target / notes |
|------|------|----------|------------|------|----------|-------------|----------------|
| `contracts/GeneralErrors.sol` | file | yes | 1 | Shared errors | stable | KEEP | |
| `contracts/InitBcService.sol` | file | yes | 1 | BattleChain init | stable | KEEP | |
| `contracts/InitDevService.sol` | file | yes | 1 | Dev/test factory bootstrap | stable | KEEP | |
| `contracts/StyleGuide.sol` | file | yes | 1 | Style template | stable | KEEP | |
| `contracts/access/` | dir | yes | 22 | Operable, ERC8023, reentrancy | stable | KEEP | |
| `contracts/bounties/` | dir | yes | 18 | BountyBoard DFPkg | experimental | KEEP | Honest status in docs |
| `contracts/constants/` | dir | yes | 16 | Network/protocol constants | stable | KEEP | |
| `contracts/external/` | dir | yes | **4454** | Vendored upstream libs | vendored | KEEP | Document as vendored; size driver |
| `contracts/factories/` | dir | yes | 26 | CREATE3 + Diamond package factory | stable | KEEP | Core |
| `contracts/interfaces/` | dir | yes | 151 | Canonical interfaces | stable | KEEP | |
| `contracts/introspection/` | dir | yes | 30 | ERC165/2535/8109 | stable | KEEP | |
| `contracts/metatx/` | dir | yes | 1 | ERC2771 context | experimental | KEEP | |
| `contracts/protocols/` | dir | yes | 2502 | Protocol namespace | experimental | KEEP | See Z6b per package |
| `contracts/proxies/` | dir | yes | 3 | Minimal Diamond callback proxy | stable | KEEP | |
| `contracts/proxy/` | dir | yes | 2 | Clones/Proxy helpers | experimental | KEEP | |
| `contracts/registries/` | dir | yes | 27 | Facet/package/target registries | stable | KEEP | |
| `contracts/script/` | dir | yes | 2 | Script helpers | experimental | KEEP | |
| `contracts/test/` | dir | yes | 29 | CraneTest, behaviors, stubs | stable | KEEP | |
| `contracts/tokens/` | dir | yes | 62 | ERC20/721/4626 FTR | stable | KEEP | |
| `contracts/utils/` | dir | yes | 55 | Sets, math, crypto | stable | KEEP | |

#### Z6b — Protocol packages (one level under family)

| Path | Kind | Tracked? | Size/Count | Role | Maturity | Disposition | Target / notes |
|------|------|----------|------------|------|----------|-------------|----------------|
| `contracts/protocols/cdps/liquity/` | dir | yes | 129 | Liquity/Bold port | vendored | KEEP | Status: vendored port |
| `contracts/protocols/cdps/sky/` | dir | yes | 84 | Sky/Maker DSS + harness | experimental | KEEP | |
| `contracts/protocols/dexes/aerodrome/` | dir | yes | 87 | Aerodrome + Slipstream services | stable | KEEP | Mature integration |
| `contracts/protocols/dexes/balancer/` | dir | yes | 151 | Balancer V3 Diamond port | stable | KEEP | Deepest DEX port |
| `contracts/protocols/dexes/camelot/` | dir | yes | 11 | Camelot V2 service | stable | KEEP | |
| `contracts/protocols/dexes/uniswap/` | dir | yes | 295 | Uni V2/V3/V4 mix | experimental | KEEP | Mixed completeness |
| `contracts/protocols/l2s/superchain/` | dir | yes | 22 | Superchain FTR packages | experimental | KEEP | |
| `contracts/protocols/launchpads/ape-express/` | dir | yes | 1 | Launchpad stub | port-in-progress | KEEP | Near-empty |
| `contracts/protocols/launchpads/uniswap/` | dir | yes | 35 | CCA auction | vendored | KEEP | |
| `contracts/protocols/lending/aave/` | dir | yes | 365 | Aave v3/v4 trees | vendored | KEEP | Not Crane FTR |
| `contracts/protocols/lending/euler/` | dir | yes | 246 | Euler v1 tree | vendored | KEEP | |
| `contracts/protocols/oracles/chainlink/` | dir | yes | 3 | Aggregator interfaces | vendored | KEEP | |
| `contracts/protocols/perps/pendle/` | dir | yes | 434 | Pendle V2 vendored | vendored | KEEP | |
| `contracts/protocols/staking/reliquary/` | dir | yes | 20 | Reliquary service | experimental | KEEP | |
| `contracts/protocols/tokens/stable/` | dir | yes | 596 | Frax stable stack | port-in-progress | KEEP | Large incomplete port |
| `contracts/protocols/tokens/wrappers/` | dir | yes | 5 | WETH/WAPE aware | stable | KEEP | |
| `contracts/protocols/utils/gsn/` | dir | yes | 2 | GSN forwarder | vendored | KEEP | |
| `contracts/protocols/utils/permit2/` | dir | yes | 15 | Permit2 + Aware | stable | KEEP | |
| `contracts/protocols/wallets/gnosis/` | dir | yes | 1 | GPv2SafeERC20 | vendored | KEEP | |

---

### Z7 — test/

| Path | Kind | Tracked? | Size/Count | Role | Disposition | Target / notes |
|------|------|----------|------------|------|-------------|----------------|
| `test/` | dir | yes | ~1119 | Test root | KEEP | |
| `test/foundry/` | dir | yes | — | Foundry suite | KEEP | |
| `test/foundry/spec/` | dir | yes | — | Spec tests (mirror contracts) | KEEP | |
| `test/foundry/spec/access/` | dir | yes | 6 | Access specs | KEEP | |
| `test/foundry/spec/factories/` | dir | yes | 5 | Factory specs | KEEP | |
| `test/foundry/spec/introspection/` | dir | yes | 11 | ERC165/2535 specs | KEEP | |
| `test/foundry/spec/pilot/` | dir | yes | 1 | BattleChain pilot | KEEP | |
| `test/foundry/spec/protocols/` | dir | yes | 936 | Protocol specs | KEEP | Largest test bulk |
| `test/foundry/spec/tokens/` | dir | yes | 17 | Token specs | KEEP | |
| `test/foundry/spec/utils/` | dir | yes | 75 | Utils/math specs | KEEP | |
| `test/foundry/spec/test/` | dir | yes | 1 | Meta test | KEEP | |
| `test/foundry/fork/` | dir | yes | — | Fork tests (networks) | KEEP | |
| `test/hardhat/` | dir | yes | 2 | Hardhat specs | REVIEW | **Recommended default: KEEP** if CI runs hardhat; else ARCHIVE_THIN |

---

### Z8 — lib/ (submodules)

| Path | Kind | Tracked? | Size/Count | Role | Disposition | Target / notes |
|------|------|----------|------------|------|-------------|----------------|
| `lib/forge-std` | submodule | gitlink | ~69 files | Foundry std | KEEP | Required |
| `lib/openzeppelin-contracts` | submodule | gitlink | ~1011 files | OZ contracts | KEEP | Required / remapped |
| `lib/chainlink-local` | submodule | gitlink | ~5258 files | Chainlink local testing | KEEP | Large; needed for VRF/local |
| `lib/battlechain-lib` | submodule | gitlink | ~7634 files | BattleChain | KEEP | Security gate path |
| `lib/gitlawb-contracts` | submodule | gitlink | ~99 files | Gitlawb contracts | REVIEW | **Recommended default: KEEP** if used in-tree; else drop submodule |

From `.gitmodules`: all five paths registered as submodules.

---

### Z9 — Config notes

| Topic | Finding | Disposition |
|-------|---------|-------------|
| Package managers | Both `package-lock.json` and `yarn.lock` tracked | REVIEW — pick one |
| Dual Hardhat configs | `hardhat.config.js` + `hardhat.config.ts` | REVIEW — consolidate |
| `package.json` scripts | Present (test-all / hardhat / etc.) | KEEP package.json |
| Foundry primary | `foundry.toml` + `forge` is main Solidity path | KEEP |
| `skills-lock.json` | Pins agent skills | KEEP (OD-2) |
| `design.yaml` | Unclear consumers | REVIEW — default KEEP |
| Remappings | `remappings.txt` + foundry.toml remappings | KEEP |

---

## 5. Cross-cutting findings

### Duplicates / overlap

- `BANKR_LAUNCH.md` (root) ↔ `docs/funding/bankr-launch.md` — both OD-3 MOVE candidates.
- Historical plans: root `UNIFIED_REVIEW_PLAN.md` ↔ `docs/archive/UNIFIED_PLAN.md`.
- Docs home: `docs/README.md` vs `docs/README.adoc`.
- Dual package locks and dual Hardhat configs.

### Generated / should-not-track

| Path | Issue |
|------|--------|
| `COVERAGE.log`, `COVERAGE_SUMMARY.log` | Tracked generated logs |
| `reports/`, `tmp/`, `output/` | Tracked local/engine outputs |
| `out/`, `book/`, `cache*`, `.mdbook-src/` | Untracked (good); keep ignored |
| `GAP_REPORT.md`, `crane_solidity_review.md` | Huge one-off dumps at root |

### Docs drift suspects (paths only)

- Root `README.md` claims “270+ tracked tasks”, “production-grade”, funding/token narrative — conflicts with OD-3 and task deletion.
- Protocol hub docs may overstate completeness vs Z6 maturity (`vendored` / `port-in-progress`).
- Selector/interface ID hardcodes in README vs live code — re-verify in packaging wave.

### License surface

- Root `LICENSE` plus `licenses/LICENSE-{APACHE,MIT,BSL-1.1,GGPL}` — multi-license; public README must state what applies to core vs ports/vendored.

### Clone-size drivers (approx.)

| Rank | Path | ~Files |
|-----:|------|-------:|
| 1 | `docs/archive/reports` | 17,816 |
| 2 | `lib/battlechain-lib` (checkout) | 7,634 |
| 3 | `out/` (untracked) | 5,830 |
| 4 | `lib/chainlink-local` | 5,258 |
| 5 | `contracts/external` | 4,454 |
| 6 | `contracts/protocols` | 2,502 |
| 7 | `docs/archive/research-scrapes` | 1,083 |
| 8 | `lib/openzeppelin-contracts` | 1,011 |
| 9 | `test/foundry/spec/protocols` | 936 |
| 10 | `tasks/` | 774 |

---

## 6. Recommended cleanup waves (future execution — not this goal)

1. **Wave A — Purge & ignore**  
   - DELETE entire `tasks/`  
   - DELETE root logs/prompts (`COVERAGE*`, `PROMPT.md`, `RESUMPTION_PROMPT.md`, `GAP_REPORT.md`, `TEST_COVERAGE_REPORT.md`, `crane_solidity_review.md`)  
   - GITIGNORE + untrack `reports/`, `tmp/`, `output/`  
   - Tighten `.gitignore`

2. **Wave B — Root MOVE**  
   - MOVE DEFI_*, AAVE_*, DEDUPLICATION*, audits, migration, review plans → `docs/archive/internal-plans/`  
   - MOVE `PRD.md`, eventually `PRD_PUBLIC_RELEASE.md` / `INVENTORY_GOAL.md` → `docs/roadmap/`  
   - OD-3: MOVE `BANKR_LAUNCH.md`, `GOVERNANCE.md`

3. **Wave C — Docs front door**  
   - MOVE `docs/funding/*`; ARCHIVE_THIN `docs/superpowers/**`  
   - Drop Funding from `SUMMARY.md`  
   - Human decision on OD-1 bulk archive rows (`reports`, `research-scrapes`)  
   - Keep audits thin (OD-4)

4. **Wave D — Public packaging**  
   - Rewrite `README.md` (framework-first, honest maturity)  
   - SECURITY.md / CONTRIBUTING.md  
   - License blurb  
   - Docs build + forge build smoke  

5. **Wave E (optional)** — dual lock/Hardhat consolidate; scoped NatSpec on core only.

---

## 7. Human decision checklist

| # | Question | Inventory row(s) | Recommended default |
|---|----------|------------------|---------------------|
| H1 | What to do with ~17.8k `docs/archive/reports`? | Z5 `docs/archive/reports/` (REVIEW) | **None (OD-1)** — decide EXTERNALIZE vs DELETE vs keep |
| H2 | What to do with ~1k `docs/archive/research-scrapes`? | Z5 `docs/archive/research-scrapes/` (REVIEW) | **None (OD-1)** |
| H3 | Keep Foundry `snapshots/` tracked? | Z1 `snapshots/` (REVIEW) | KEEP if CI uses; else GITIGNORE |
| H4 | npm vs yarn (dual locks)? | Z0 `package-lock.json`, `yarn.lock` (REVIEW) | Pick one; delete the other lockfile |
| H5 | Keep both Hardhat configs? | Z0 `hardhat.config.js`, `hardhat.config.ts` (REVIEW) | Consolidate to one |
| H6 | Keep `docs/README.adoc` alongside README.md? | Z4 `docs/README.adoc` (REVIEW) | KEEP until AsciiDoc pipeline retired |
| H7 | Is `lib/gitlawb-contracts` required for public Crane? | Z8 `lib/gitlawb-contracts` (REVIEW) | KEEP if referenced; else remove submodule |
| H8 | Keep `design.yaml`? | Z0 `design.yaml` (REVIEW) | KEEP if tooling uses it |
| H9 | Soft-delete vs hard-delete huge review dumps (`crane_solidity_review`)? | Z0 DELETE rows (not REVIEW) | DELETE preferred |
| H10 | Announce with vendored Aave/Euler/Pendle trees in-tree? | Z6 KEEP/vendored packages | KEEP with honest maturity labels in docs |
| H11 | Keep `test/hardhat/` in the public suite? | Z7 `test/hardhat/` (REVIEW) | **KEEP** if CI/docs run Hardhat; else ARCHIVE_THIN or drop with Hardhat consolidation |

---

## 8. Success attestation

### SC-1 — Deliverable exists

- [x] File exists: `docs/roadmap/PUBLIC_RELEASE_INVENTORY.md`
- [x] Directory `docs/roadmap/` exists

### SC-2 — Structure complete

- [x] Sections §1–§8 present in order
- [x] Disposition vocabulary used (allowed codes only)

### SC-3 — Coverage

- [x] Z0: 47 rows = `find . -maxdepth 1 -type f` count **47**
- [x] Z1: all listed paths present with rows
- [x] Z2: all listed paths present with rows
- [x] Z3: tasks tree DELETE + counts (774 files; 97 active; 176 archive)
- [x] Z4: 43 product doc files enumerated
- [x] Z5: every immediate child of `docs/archive/` inventoried; bulk OD-1 REVIEW
- [x] Z6: every immediate child of `contracts/` + protocol one-level packages; **Maturity** column
- [x] Z7: test major subtrees
- [x] Z8: every `lib/*` child
- [x] Z9: config notes

### SC-4 — Locked decisions

- [x] tasks → DELETE, count-only, OD-7
- [x] No GitHub Issues replacement
- [x] Analysis-only stated
- [x] OD-1…OD-7 echoed in §3

### SC-5 — Actionability

- [x] MOVE rows have targets
- [x] REVIEW rows have questions; OD-1 bulk rows have **no** recommended default
- [x] Z6 Maturity present
- [x] Agent tooling KEEP (OD-2)
- [x] Funding strip (OD-3)
- [x] Audits KEEP thin (OD-4)
- [x] certora KEEP (OD-5)
- [x] §6 cleanup waves listed

### SC-6 — No unauthorized mutations

- [x] Inventory goal did not delete `tasks/` or bulk `docs/archive`
- [x] Expected write: `docs/roadmap/PUBLIC_RELEASE_INVENTORY.md` (+ directory)

### Verification command output (orchestrator run 2026-07-21; skeptic fix re-run)

```
scripts/verify_public_release_inventory.sh → ALL CHECKS PASSED
  Z0 47==47
  §2 Total 183 == path-table rows 183
  all 11 REVIEW paths restated in §7 (incl. test/hardhat/ as H11)
  tasks/ still present (analysis-only)
```

### Verification command output (earlier artifacts)
```
--- inventory_exists.txt ---
PASS: inventory exists
-rw-r--r--  1 cyotee  staff  32296 Jul 20 22:09 docs/roadmap/PUBLIC_RELEASE_INVENTORY.md

--- z0_count.txt ---
z0_find_count=47
z0_table_rows=47
z0_match=
z0_find=47
PASS_Z0=True

--- verify_script_run.txt ---
PASS: report exists: docs/roadmap/PUBLIC_RELEASE_INVENTORY.md
PASS: docs/roadmap exists
PASS: section ## 1. Metadata
PASS: section ## 2. Executive summary
PASS: section ## 3. Locked decisions
PASS: section ## 4. Zone inventories
PASS: section ## 5. Cross-cutting findings
PASS: section ## 6. Recommended cleanup waves
PASS: section ## 7. Human decision checklist
PASS: section ## 8. Success attestation
PASS: zone Z0
PASS: zone Z1
PASS: zone Z2
PASS: zone Z3
PASS: zone Z4
PASS: zone Z5
PASS: zone Z6
PASS: zone Z7
PASS: zone Z8
PASS: zone Z9
PASS: Z0 row count 47 == find count 47
PASS: text: DELETE
PASS: text: OD-1
PASS: text: OD-2
PASS: text: OD-3
PASS: text: OD-4
PASS: text: OD-5
PASS: text: OD-6
PASS: text: OD-7
PASS: text: GitHub Issues
PASS: text: Maturity
PASS: text: certora
PASS: text: public agent
PASS: tasks DELETE disposition present
PASS: disposition codes present in tables
PASS: tasks/ still present (analysis-only)
ALL CHECKS PASSED
exit=0

--- git_status.txt ---
?? INVENTORY_GOAL.md
?? PRD_PUBLIC_RELEASE.md
?? docs/roadmap/
PASS: tasks still present
PASS: no tasks deletion staged

--- disposition_codes.txt ---
codes_in_tables: ['ARCHIVE_THIN', 'DELETE', 'EXTERNALIZE', 'GITIGNORE', 'KEEP', 'KEEP_INTERNAL', 'MOVE', 'REVIEW']
all_allowed: True
has_most: True

```


---

*End of inventory report. Execution of cleanup waves requires separate approval.*
