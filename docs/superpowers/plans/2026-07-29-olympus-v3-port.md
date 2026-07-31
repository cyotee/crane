# Olympus V3 (Bophades) Port Implementation Plan

> **For agentic workers:** Use `subagent-driven-development` or `executing-plans`. Steps use checkbox (`- [ ]`) syntax for tracking.  
> **PRD (requirements):** [`docs/superpowers/specs/2026-07-29-olympus-v3-port-prd.md`](../specs/2026-07-29-olympus-v3-port-prd.md)  
> **Archive pointer:** [`docs/archive/internal-plans/OLYMPUS_V3_PORTING_PRD.md`](../../archive/internal-plans/OLYMPUS_V3_PORTING_PRD.md)  
> **Skills (mandatory):** `crane-porting`, `crane-porting-verification`, `crane-testing`, `crane-architecture`, `crane-code-style`, `crane-natspec`  
> **Exemplar patterns in this repo:**  
> - Existing Olympus domain (research tree): `contracts/protocols/tokens/stable/olympus/v2/`  
> - Existing hermetic suite + Quabi: `test/foundry/spec/protocols/tokens/stable/olympus/v2/`  
> - Profile: `[profile.olympus_port]` in `foundry.toml`  
> - Service / Aware / TestBase: `contracts/protocols/lending/morpho/blue/`  
> - Port profile pattern: `[profile.morpho_port]`, `[profile.pons_port]`

---

## Goal

Port **Olympus V3 (Bophades)** from [OlympusDAO/olympus-v3](https://github.com/OlympusDAO/olympus-v3) into Crane such that:

1. Domain sources under `contracts/protocols/tokens/stable/olympus/v3/` compile with shared deps remapped to `@crane/contracts/external/...`.
2. Hermetic Foundry suite matches **current v2 completeness** (Kernel, core modules/policies, bases, Cooler/OHM externals, Quabi godmode).
3. Crane-native **Service + AwareRepo + TestBase + Behaviors** exist and pass (new relative to v2).
4. Active agent skills point at **v3**; v2 skills are **archived in-repo** under `docs/archive/skills/olympus-v2/`.
5. Existing **v2 tree and `olympus_port` profile remain green** for research/comparison.

### Locked decisions (2026-07-29) — do not re-litigate

| Topic | Decision |
|-------|----------|
| **Domain path** | `contracts/protocols/tokens/stable/olympus/v3/` |
| **v2 tree** | **Keep** for research/testing; do not delete or break |
| **Skills** | Archive v2 → `docs/archive/skills/olympus-v2/`; write new active v3 skills |
| **First merge** | ≥ v2 domain/test completeness **+** Service/Aware/TestBase **+** skill migration |
| **Wrappers** | Service + Aware + TestBase required; **no** Diamond FTR/DFPkg in minimum |
| **Pin** | Execution-time upstream commit (typically `develop` HEAD); **not** forced to v2’s `0af8d56` |
| **License** | AGPL-3.0-only — preserve SPDX |
| **viaIR** | Forbidden |
| **Profile** | New `olympus_v3_port`; leave `olympus_port` → v2 |

---

## Architecture

| Layer | Path |
|-------|------|
| Domain (faithful) | `contracts/protocols/tokens/stable/olympus/v3/` |
| Crane wrappers | `…/olympus/v3/{services,aware,stubs,test/bases}/` |
| Hermetic tests | `test/foundry/spec/protocols/tokens/stable/olympus/v3/` |
| Foundry profile | `[profile.olympus_v3_port]` in `foundry.toml` |
| Vendor note | `…/olympus/v3/VENDOR.md` |
| Research tree (frozen forward) | `…/olympus/v2/` + `[profile.olympus_port]` |
| Active skills | `.claude/skills/{olympus-architecture,olympus-operations,crane-olympus}/` (+ `.grok/skills/` mirrors) |
| Archived v2 skills | `docs/archive/skills/olympus-v2/` |

**Tech stack:** Solidity **0.8.35**, Foundry, **no `viaIR`**, `optimizer_runs=1` (Crane default), `ffi=true`, `ast=true` (Quabi).

**Upstream pin (confirm at copy):**

| Item | Value |
|------|--------|
| Repo | https://github.com/OlympusDAO/olympus-v3 |
| Branch tip (research day) | `develop` @ `0af8d56…` — **re-resolve at execution** |
| License | AGPL-3.0-only |
| v2 reference pin | `0af8d56dbe78850d120f077b355dcecee56cb83f` (research only) |

### Domain include set (minimum = v2 completeness)

| Area | Include |
|------|---------|
| Core | `Kernel.sol`, `Submodules.sol` |
| Modules | MINTR, TRSRY, ROLES, INSTR, VOTES, RANGE, CHREG, BLREG, RGSTY, DLGTE, PRICE (v2 depth) |
| Bases / libraries / interfaces | Full set required by core modules/policies |
| Policies | RolesAdmin, Minter, Emergency, TreasuryCustodian, ContractRegistryAdmin, Burner, LegacyBurner, ReserveMigrator, ReserveWrapper, Parthenon, VohmVault, `policies/utils/*`, needed `policies/interfaces/*` |
| External | OlympusERC20, OlympusAuthority, OwnedERC20, ClaimTransfer, clones, Cooler stack |
| Periphery | CoolerComposites, CoolerV2Migrator, PeripheryEnabler (+ interfaces) — **not** CCIP/LZ bridges |

### Explicit exclusions (minimum)

| Exclusion | Reason |
|-----------|--------|
| `src/scripts/**`, `src/proposals/**` | Ops / proposal simulator |
| `src/test/sim/**` | ffi/shell sim |
| `policies/bridge/**`, `periphery/bridge/**`, `external/bridge/**`, CrossChainBridge | CCIP/LZ stacks |
| DEPOS module + deposit facility policies | Follow-up G12 |
| Cooler **policies** (MonoCooler, …) | Follow-up G13 (Cooler **external** stays in min) |
| Operator, Heart, Clearinghouse, Bond*, EmissionManager, BLV suite | Follow-up G14 |
| PRICE.v2 full feed suite | Follow-up G15 |
| `*Fork*` tests | Follow-up G16 |

---

## Testing requirements (non-negotiable)

| # | Layer | When | Requirement |
|---|-------|------|-------------|
| **T1** | Compile | Min | Domain + wrappers build under `olympus_v3_port`; `@crane/` imports; no viaIR |
| **T2** | Hermetic suite | Min | ≥ v2 class: Kernel, modules, bases, policy utils, libraries |
| **T3** | Quabi / AST | Min | Godmode fixtures work with `out_olympus_v3_port` |
| **T4** | TestBase | Min | `TestBase_OlympusV3` deploys real Kernel graph |
| **T5** | Service / Aware | Min | Install/activate + MINTR + ROLES happy paths; exact deltas |
| **T6** | Behavior | Min | Consumer-facing Kernel / Service surface |
| **T7** | v2 regression | Min | `FOUNDRY_PROFILE=olympus_port forge test` still green |
| **T8** | Fork bind | Follow-up | Live Kernel/OHM `code.length > 0` + optional op |
| **T9** | Expansion suites | Follow-up | DEPOS / Cooler policies / Operator as added |

### Assertion standards (LR-7)

- Exact expected values / permission reverts with selectors.
- `vm.expectEmit` when consumer-facing events matter.
- **No** `vm.mockCall` on Kernel / modules / policies SUT.
- Production-first: real ported bytecode only.
- Struct-ize Service params if stack-too-deep (never viaIR).

### Commands

```bash
# From Crane repo root

# v3 port
rm -rf cache_olympus_v3_port out_olympus_v3_port
FOUNDRY_PROFILE=olympus_v3_port forge build
FOUNDRY_PROFILE=olympus_v3_port forge test
FOUNDRY_PROFILE=olympus_v3_port forge test --match-path \
  'test/foundry/spec/protocols/tokens/stable/olympus/v3/**' -vv

# v2 must remain green after every phase that could touch shared external
FOUNDRY_PROFILE=olympus_port forge test

# Focused
FOUNDRY_PROFILE=olympus_v3_port forge test --match-contract Kernel -vvv
FOUNDRY_PROFILE=olympus_v3_port forge test --match-path \
  'test/foundry/spec/protocols/tokens/stable/olympus/v3/services/**' -vv
```

Do **not** claim a phase complete without path-scoped green output (or a written residual + waiver for follow-up-only layers).

---

## Conventions

### Bootstrap strategy (choose in OV0; execute in OV1)

| Option | When | How |
|--------|------|-----|
| **A. Fresh vendor (preferred if pin ≠ v2)** | Pin moved or clean fidelity wanted | Copy from upstream pin → remap → port tests from v2 suite adapted to new paths |
| **B. Copy-forward from v2 then re-diff** | Speed; pin still near `0af8d56` | `cp -R v2 → v3` (domain+tests) → re-apply upstream delta if pin differs → fix paths/Quabi |

Both end at execution-time pin + `@crane/` remaps. Record choice in `VENDOR.md`.

### Pragma

- Relax exact pins to `^0.8.35` / `>=0.8.15` as needed for Crane solc; document in `VENDOR.md`.

### Imports

| From | To |
|------|-----|
| Upstream `src/...` relative / remaps | `@crane/contracts/protocols/tokens/stable/olympus/v3/...` |
| OZ 4.x | `@crane/contracts/external/openzeppelin-contracts-v4/...` (or profile `@openzeppelin/` → v4) |
| OZ 5.x | `@crane/contracts/external/openzeppelin-contracts-v5/...` |
| solmate | `@crane/contracts/external/solmate/...` or profile `solmate/` |
| clones | `@crane/contracts/external/clones-with-immutable-args/...` or `clones/` |
| Uni V3 OracleLibrary | `@crane/contracts/external/uniswap/v3-periphery/...` |
| forge-std | `forge-std/...` |

**Never** nest private OZ/Solmate under `olympus/v3/`.  
**Never** import domain files from `olympus/v2` into `olympus/v3` (or vice versa).

### Storage slots (AwareRepo)

Use hierarchical names, e.g.:

```text
protocols.tokens.stable.olympus.v3.kernel.aware
```

### Commit messages

```text
feat(olympus-v3-port): <scope> (OV<phase>.<task>)
```

### NatSpec (Crane wrappers only)

- Full NatSpec + include-tags + `@custom:signature` / `@custom:selector` on new Service/Aware public/external APIs per `crane-natspec`.
- Domain keeps upstream NatSpec.

---

## Work packages overview

| ID | Package | Ship stage | Exit |
|----|---------|------------|------|
| **OV0** | Pin, inventory, strategy, profile sketch, scaffold dirs | Gate | Written pin + include/exclude + bootstrap choice |
| **OV1** | Vendor domain into `olympus/v3` + remap + `VENDOR.md` + profile | **Minimum** | `olympus_v3_port forge build` green |
| **OV2** | Hermetic suite + Quabi under v3 test path | **Minimum** | Full in-tree `forge test` green |
| **OV3** | Service + Aware + TestBase + Behaviors | **Minimum** | Wrapper tests green |
| **OV4** | Archive v2 skills; write v3 skills | **Minimum** | Active skills → v3 paths |
| **OV5** | CODEBASE_MAP / status / AGENTS pointers | Preferred | Docs dual-tree note |
| **OV6** | v2 regression gate (run throughout; final check) | **Minimum** | `olympus_port` still green |
| **OV7** | DEPOS + deposits (G12) | Follow-up | Hermetic deposit path |
| **OV8** | Cooler V2 policies (G13) | Follow-up | Loan lifecycle |
| **OV9** | Operator / Heart / Clearinghouse / Bonds (G14) | Follow-up | As consumer needs |
| **OV10** | Network constants + fork binds (G16–G17) | Follow-up | Profile-gated fork green |

**First mergeable port = OV0 + OV1 + OV2 + OV3 + OV4 + OV6** (OV5 strongly preferred in same PR or immediate follow-up).

---

## Phase OV0 — Gates and scaffolding

**Goal:** No surprises on pin, deps, or include set before bulk copy.

### OV0.1 — Pin upstream

- [ ] Shallow-clone or `git ls-remote` [OlympusDAO/olympus-v3](https://github.com/OlympusDAO/olympus-v3) `develop` (or default branch).
- [ ] Record **full commit SHA** for `VENDOR.md` (do not force v2 pin).
- [ ] Note delta from v2 pin `0af8d56d…` (same / N commits / files changed) in a short progress note or VENDOR draft.
- [ ] Confirm SPDX AGPL-3.0-only on `Kernel.sol`.

### OV0.2 — Include/exclude inventory

- [ ] Diff upstream `src/` (excl. test/scripts/proposals) against `olympus/v2` file list.
- [ ] Produce a table: **in min**, **follow-up**, **out** (bridges/proposals/sim).
- [ ] Confirm Cooler **external** in min; Cooler **policies** follow-up.
- [ ] Confirm DEPOS absent from min.

### OV0.3 — Dependency inventory vs Crane external

- [ ] Map OZ 4.8 / OZ 5.3 / solmate / clones / Uni V3 / base64 symbols used by **min** set.
- [ ] For any missing symbol: plan **expand external first** (list files).
- [ ] Flag anything that would pull CCIP/LZ into min (must not).

### OV0.4 — Bootstrap strategy decision

- [ ] Choose **A (fresh vendor)** or **B (copy-forward from v2)** based on pin delta.
- [ ] Write decision one-liner into VENDOR draft.

### OV0.5 — Scaffold directories + profile sketch

- [ ] Create:

```bash
mkdir -p contracts/protocols/tokens/stable/olympus/v3/{services,aware,stubs,test/bases}
mkdir -p test/foundry/spec/protocols/tokens/stable/olympus/v3/{bases,libraries,modules,policies,lib/quabi,mocks,services}
mkdir -p docs/archive/skills/olympus-v2
```

- [ ] Draft `[profile.olympus_v3_port]` block (do not break `olympus_port`):

```toml
[profile.olympus_v3_port]
ffi = true
ast = true
src = "contracts/protocols/tokens/stable/olympus/v3"
test = "test/foundry/spec/protocols/tokens/stable/olympus/v3"
out = "out_olympus_v3_port"
cache_path = "cache_olympus_v3_port"
libs = ["lib", "node_modules"]
solc = "0.8.35"
optimizer = true
optimizer_runs = 1
via_ir = false
allow_internal_expect_revert = true
# skip list: mirror olympus_port Uni NFTDescriptor / heavy unused periphery as needed
legacy_assertions = true
# remappings: mirror olympus_port (@crane/, OZ v4 alias, solmate, clones)
```

- [ ] Sketch Quabi `path.sh` / `jq.sh` targets → `out_olympus_v3_port`.

**Phase OV0 exit:** pin SHA, include/exclude table, bootstrap choice, dirs + profile draft ready.

---

## Phase OV1 — Vendor domain + compile

**Goal:** Faithful domain under `olympus/v3` builds with remapped deps.

### OV1.1 — Copy domain sources

**If strategy B (copy-forward):**

- [ ] Copy domain tree from `olympus/v2/**` → `olympus/v3/**` (exclude any accidental wrappers if none).
- [ ] If pin ≠ v2: re-diff against upstream pin and apply source deltas for included files only.

**If strategy A (fresh):**

- [ ] Copy included paths from upstream `src/` → `olympus/v3/` (preserve structure: Kernel, modules, policies, …).
- [ ] Do **not** copy `proposals/`, `scripts/`, bridge trees, DEPOS (unless later phase).

### OV1.2 — Remap imports

- [ ] Rewrite all imports to `@crane/...` / external OZ majors / solmate / clones / Uni.
- [ ] Grep for forbidden patterns:

```bash
rg -n 'dependencies/|@openzeppelin/contracts-upgradeable|src/modules|src/policies' \
  contracts/protocols/tokens/stable/olympus/v3 || true
rg -n 'olympus/v2' contracts/protocols/tokens/stable/olympus/v3 || true
```

- [ ] Expand `contracts/external/**` if any required symbol missing; re-run build.
- [ ] **Do not** change Uni V3 periphery `TransferHelper` IERC20 path in ways that break Frax/other co-imports (known v2 footgun).

### OV1.3 — Pragma + VENDOR.md

- [ ] Normalize pragmas for 0.8.35 multi-compile as needed; document.
- [ ] Write `contracts/protocols/tokens/stable/olympus/v3/VENDOR.md` using crane-porting template:
  - upstream URL, pin, copy date, license
  - include/exclude inventory
  - adaptations (pragma, imports, Quabi, optimizer)
  - note dual-tree: v2 path + pin for research

### OV1.4 — Foundry profile live

- [ ] Add `[profile.olympus_v3_port]` to `foundry.toml` (final, not draft).
- [ ] Confirm `[profile.olympus_port]` still points at **v2**.
- [ ] `FOUNDRY_PROFILE=olympus_v3_port forge build` green without viaIR.
- [ ] Fix stack-too-deep with structs only if introduced by remaps (unlikely on domain).

### OV1.5 — Commit

- [ ] Commit: `feat(olympus-v3-port): vendor domain + olympus_v3_port profile (OV1)`.

**Phase OV1 exit:** `olympus_v3_port forge build` green; VENDOR.md complete; v2 profile untouched.

---

## Phase OV2 — Hermetic suite + Quabi

**Goal:** In-tree tests ≥ v2 completeness, all green under `olympus_v3_port`.

### OV2.1 — Port / copy test tree

- [ ] Copy or re-port from `test/foundry/spec/protocols/tokens/stable/olympus/v2/**` → `…/olympus/v3/**`.
- [ ] Expected shape (from v2): `Kernel.t.sol`, `bases/`, `libraries/`, `modules/`, `policies/`, `mocks/`, `lib/quabi/`.
- [ ] Rewrite imports: `olympus/v2` → `olympus/v3`; any `out_olympus_port` → `out_olympus_v3_port`.

### OV2.2 — Quabi adaptation

- [ ] Update `lib/quabi/path.sh` (and `jq.sh` if needed) to resolve artifacts under `out_olympus_v3_port`.
- [ ] Ensure `fs_permissions` on profile allow read of `./out_olympus_v3_port`.
- [ ] Spot-check one godmode module test that uses Quabi.

### OV2.3 — Fixtures and mocks

- [ ] Non-SUT mocks only (tokens, etc.) under `mocks/`.
- [ ] Confirm no test mocks Kernel/modules as SUT.
- [ ] Align deploy helpers with domain constructor signatures at pin (fix if upstream changed).

### OV2.4 — Green suite

- [ ] `FOUNDRY_PROFILE=olympus_v3_port forge test` — **all green**.
- [ ] If failures due to upstream pin delta: fix domain/tests to match pin (do not weaken asserts).
- [ ] Document any intentional skip with written reason **and** replacement coverage (prefer fix over skip).

### OV2.5 — Commit

- [ ] Commit: `feat(olympus-v3-port): hermetic suite + Quabi (OV2)`.

**Phase OV2 exit:** Full v3 hermetic suite green; Quabi works; exclusions still documented in VENDOR.md.

---

## Phase OV3 — Service, Aware, TestBase, Behaviors

**Goal:** Crane consumer surface for Kernel bootstrap and core module ops.

### OV3.1 — `TestBase_OlympusV3`

**File:** `contracts/protocols/tokens/stable/olympus/v3/test/bases/TestBase_OlympusV3.sol`

- [ ] Deploy OHM (`OlympusERC20` or port equivalent) as required by MINTR.
- [ ] Deploy `Kernel`.
- [ ] Deploy and `InstallModule`: MINTR, TRSRY, ROLES (minimum), then remaining core modules used by suite.
- [ ] Deploy and `ActivatePolicy`: RolesAdmin, Minter (+ Emergency if needed for later tests).
- [ ] Idempotent `setUp`; `vm.label` all contracts.
- [ ] Expose addresses for Service tests.
- [ ] Prefer inheriting only what is needed (CraneTest optional if no Diamond factories required yet).

### OV3.2 — `OlympusKernelAwareRepo`

**File:** `contracts/protocols/tokens/stable/olympus/v3/aware/OlympusKernelAwareRepo.sol`

- [ ] Storage slot: hierarchical keccak name (PRD §8.5).
- [ ] Dual `_layoutStruct` / parameterized overloads per crane-architecture.
- [ ] Fields: `kernel`, optional `ohm`, `mintr`, `treasury`, `roles` (keep minimal; expand later).
- [ ] `_initialize` / getters; no business logic.

### OV3.3 — `OlympusKernelService`

**File:** `contracts/protocols/tokens/stable/olympus/v3/services/OlympusKernelService.sol`

- [ ] Stateless library; use structs for multi-arg sequences.
- [ ] Minimum API surface:
  - `installModule(Kernel, Module)`
  - `activatePolicy(Kernel, Policy)`
  - `getModule(Kernel, Keycode)` / typed helpers for MINTR/ROLES/TRSRY
  - Happy-path helpers used by strategies: e.g. grant role via RolesAdmin, increase mint approval + mint via Minter policy (as authorized actors)
- [ ] Do **not** bypass Kernel permissions; Service encodes correct call paths only.
- [ ] NatSpec + include-tags + selectors on external/public surface if any; internal library can document via NatSpec without selectors where pure helpers.

### OV3.4 — Behaviors

- [ ] `Behavior_IKernel` (or focused Behaviors) for:
  - module install / policy activate effects
  - permissioned module call success vs `Module_PolicyNotPermitted` (or upstream selector)
- [ ] Place next to wrappers or under `test/…` infra consistent with Morpho `Behavior_IMorpho`.
- [ ] Declaration tests that exercise Behavior against `TestBase_OlympusV3` instance.

### OV3.5 — Wrapper tests

**Path:** `test/foundry/spec/protocols/tokens/stable/olympus/v3/services/`

- [ ] Test: Service-driven install/activate matches direct Kernel actions.
- [ ] Test: MINTR mint path with exact OHM balance delta.
- [ ] Test: ROLES grant/revoke as applicable with exact role checks.
- [ ] Test: unpermissioned call reverts with expected selector.
- [ ] Test: AwareRepo initialize + getters round-trip.

### OV3.6 — Commit

- [ ] Commit: `feat(olympus-v3-port): Service + Aware + TestBase + Behaviors (OV3)`.

**Phase OV3 exit:** T4–T6 green under `olympus_v3_port`.

---

## Phase OV4 — Skills migration

**Goal:** Active skills teach v3; v2 skills preserved in archive.

### OV4.1 — Archive v2 skills

- [ ] Copy current skill trees into archive (preserve content; do not only delete):

```bash
# From Crane root — adjust if paths differ
mkdir -p docs/archive/skills/olympus-v2
cp -R .claude/skills/olympus-architecture docs/archive/skills/olympus-v2/
cp -R .claude/skills/olympus-operations docs/archive/skills/olympus-v2/
cp -R .claude/skills/crane-olympus docs/archive/skills/olympus-v2/
# Optional: also snapshot .grok/skills copies if they differ
```

- [ ] Write `docs/archive/skills/olympus-v2/README.md`:
  - Domain: `contracts/protocols/tokens/stable/olympus/v2`
  - Profile: `FOUNDRY_PROFILE=olympus_port`
  - Forward work: active skills + `olympus/v3`
  - Pin reference from v2 VENDOR.md

### OV4.2 — Rewrite active skills for v3

Update **both** `.claude/skills/` and `.grok/skills/` mirrors:

| Skill | Changes |
|-------|---------|
| `olympus-architecture` | Paths → `olympus/v3`; module catalog; dual-tree note; link archive |
| `olympus-operations` | Call flows against v3 imports; Cooler external vs policy follow-up |
| `crane-olympus` | Profile `olympus_v3_port`; Service/Aware/TestBase; commands; Quabi out path |

- [ ] SKILL.md descriptions still trigger on Olympus/Bophades/Kernel keywords.
- [ ] Short “Legacy v2” subsection pointing at archive + research tree.
- [ ] Refresh `references/*` paths that hardcode `olympus/v2`.

### OV4.3 — Discovery docs

- [ ] If `docs/reference/agent-skills.md` lists Olympus paths, update to v3 + archive note.
- [ ] Grep for stale skill path claims:

```bash
rg -n 'olympus/v2' .claude/skills/olympus-* .claude/skills/crane-olympus \
  .grok/skills/olympus-* .grok/skills/crane-olympus 2>/dev/null || true
```

### OV4.4 — Commit

- [ ] Commit: `docs(olympus-v3-port): archive v2 skills; rewrite active skills for v3 (OV4)`.

**Phase OV4 exit:** Active skills resolve v3; archive usable for v2 researchers.

---

## Phase OV5 — Documentation (preferred with merge)

**Goal:** Humans and agents see dual-tree layout.

### OV5.1 — CODEBASE_MAP / status

- [ ] Update `docs/CODEBASE_MAP.md` (or protocol section) with `olympus/v3` domain + wrappers.
- [ ] Note `olympus/v2` as research pin of same upstream family.
- [ ] Update `docs/protocols/status.md` if it tracks port maturity.

### OV5.2 — AGENTS / Claude pointers

- [ ] Ensure AGENTS.md / Claude.md skill list still discovers olympus skills (names unchanged is fine).
- [ ] Optional: one line under protocol porting that v3 is forward home.

### OV5.3 — Commit

- [ ] Commit: `docs(olympus-v3-port): dual-tree status and CODEBASE_MAP (OV5)`.

**Phase OV5 exit:** Docs match on-disk layout.

---

## Phase OV6 — Regression gate (continuous + final)

Run after OV1, OV2, OV3, and before merge:

- [ ] `FOUNDRY_PROFILE=olympus_port forge test` green.
- [ ] Confirm no shared-external change broke other profiles (if external expanded: spot-check default `forge build` or known dependents).
- [ ] Confirm v3 suite still green after skill/doc-only commits (no-op expected).

**Phase OV6 exit:** Both profiles green on same commit.

---

## Phase OV7 — Follow-up: DEPOS + deposits (G12)

> Not required for first merge.

- [ ] Vendor `modules/DEPOS/**` + deposit policies/interfaces/libraries needed to compile.
- [ ] Expand external (base64, etc.) as required.
- [ ] Hermetic tests: create deposit / receipt / redeem smoke.
- [ ] Extend TestBase optionally.
- [ ] Update VENDOR.md include list.

---

## Phase OV8 — Follow-up: Cooler V2 policies (G13)

- [ ] Vendor `policies/cooler/**` (+ related oracles/borrower interfaces).
- [ ] Wire hermetic Cooler loan request/clear/repay path using existing Cooler **external**.
- [ ] Watch contract size (upstream uses special optimizer runs for MonoCooler) — **no viaIR**; use compilation_restrictions carefully if needed.
- [ ] Service helpers optional (`CoolerService`).

---

## Phase OV9 — Follow-up: market / RBS stack (G14)

- [ ] Operator, Heart, Clearinghouse, Bond* as driven by IndexedEx consumers.
- [ ] Port upstream unit tests selectively; keep exclusions explicit.

---

## Phase OV10 — Follow-up: constants + forks (G16–G17)

- [ ] Add `OLYMPUS_*` addresses to `contracts/constants/networks/ETHEREUM_MAIN.sol` (and L2s if needed) from official docs / olymsig / `env.json`.
- [ ] `TestBase_OlympusV3_Fork`: `vm.createSelectFork`, bind Kernel/OHM, `code.length > 0`.
- [ ] Optional: one small live view or permissioned-safe read.
- [ ] Document RPC env vars; profile-gate if needed.

---

## Definition of done (minimum merge)

Copy into PR description:

- [ ] Domain at `contracts/protocols/tokens/stable/olympus/v3/` with complete `VENDOR.md` (execution-time pin)
- [ ] Completeness ≥ v2 domain/test class; exclusions listed
- [ ] Shared deps remapped; no private OZ/Solmate under olympus/v3
- [ ] `FOUNDRY_PROFILE=olympus_v3_port forge build` green (`via_ir=false`)
- [ ] `FOUNDRY_PROFILE=olympus_v3_port forge test` green
- [ ] `OlympusKernelService` + `OlympusKernelAwareRepo` + `TestBase_OlympusV3` + Behaviors present and tested
- [ ] v2 skills archived under `docs/archive/skills/olympus-v2/` with README
- [ ] Active olympus skills point at **v3** (+ `.grok` mirrors)
- [ ] `FOUNDRY_PROFILE=olympus_port forge test` still green
- [ ] No new git submodules; no unauthorized remapping aliases; AGPL SPDX preserved
- [ ] NatSpec on new Crane wrappers

**Not required:** DEPOS full stack, Cooler policies, Operator/Heart/bonds, mainnet forks, Diamond DFPkg.

---

## Risk checklist (during execution)

| Risk | What to do |
|------|------------|
| Pin moved far past v2 | Prefer strategy A; budget extra OV2 fix time |
| Quabi path wrong | Fail godmode tests early; fix path.sh before chasing logic |
| OZ 4/5 mix | Route per file; never Crane Ownable for OZ semantics |
| Accidental v2 breakage | Run OV6 after every phase |
| Scope creep (bridges) | Refuse; open OV7+ only with explicit ask |
| MonoCooler size later | Defer to OV8; optimizer profile without viaIR |

---

## Suggested PR slicing

| PR | Contents |
|----|----------|
| **PR1** | OV0–OV1 (vendor + profile + build) |
| **PR2** | OV2 (hermetic suite green) |
| **PR3** | OV3 (wrappers) |
| **PR4** | OV4–OV6 (skills + docs + final dual green) |

Single large PR is acceptable if CI time allows; prefer PR1+PR2 first so research can start on v3 compile early.

---

## Progress log

| Date | Note |
|------|------|
| 2026-07-29 | Plan authored from PRD locked decisions; no code executed yet. |
| 2026-07-29 | Minimum merge executed: domain+suite under `olympus/v3`, `olympus_v3_port`, Service/Aware/TestBase/Behaviors, skills archived+rewritten; v2 regression green (751 v3 tests, 741 v2). |

---

## References

| Resource | Location |
|----------|----------|
| PRD | `docs/superpowers/specs/2026-07-29-olympus-v3-port-prd.md` |
| v2 VENDOR | `contracts/protocols/tokens/stable/olympus/v2/VENDOR.md` |
| v2 domain | `contracts/protocols/tokens/stable/olympus/v2/` |
| v2 tests | `test/foundry/spec/protocols/tokens/stable/olympus/v2/` |
| Morpho Service exemplar | `contracts/protocols/lending/morpho/blue/` |
| Upstream | https://github.com/OlympusDAO/olympus-v3 |
| Addresses | https://docs.olympusdao.finance/main/contracts/addresses |
