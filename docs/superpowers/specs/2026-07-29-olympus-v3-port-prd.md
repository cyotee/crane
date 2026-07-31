---
project: Olympus V3 (Bophades) port into Crane under olympus/v3
version: 1.0
status: draft
created: 2026-07-29
last_updated: 2026-07-29
owner: Crane core
decisions_locked: 2026-07-29
related:
  - docs/superpowers/plans/2026-07-29-olympus-v3-port.md
  - docs/archive/internal-plans/OLYMPUS_V3_PORTING_PRD.md
  - docs/archive/internal-plans/DEFI_PORTING_PRD.md
  - .claude/skills/crane-porting/SKILL.md
  - .claude/skills/crane-porting-verification/SKILL.md
  - .claude/skills/crane-testing/SKILL.md
  - contracts/protocols/tokens/stable/olympus/v2/
  - docs/archive/skills/olympus-v2/   # destination for archived v2 skills
upstream:
  - https://github.com/OlympusDAO/olympus-v3
official_docs:
  - https://docs.olympusdao.finance/
  - https://docs.olympusdao.finance/main/contracts/addresses
  - https://github.com/fullyallocated/Default
---

# PRD: Port Olympus V3 (Bophades) into Crane (`olympus/v3`)

## 0. Locked product decisions (2026-07-29)

| Topic | Decision |
|-------|----------|
| **Domain home** | `contracts/protocols/tokens/stable/olympus/v3/` (user-specified) |
| **Relationship to existing `olympus/v2`** | **Keep both.** v2 remains for research and comparative testing. v3 is a **new** port tree, not a rename that deletes v2. |
| **Skills** | **Archive** active Olympus skills that target v2 into the repo (`docs/archive/skills/olympus-v2/`). **Write new** skills for v3 (architecture, operations, crane-olympus). Archived skills stay available for developers who need the v2 path. |
| **First merge (“done” minimum)** | **Match current v2 completeness:** Kernel + core modules/policies + hermetic suite equivalent to what v2 already ships; same class of exclusions (bridges, proposal sims, heavy deposit/bond/fork suites). **Plus** Service + Aware + TestBase wrappers (new relative to v2). |
| **Crane wrappers** | **Required for DoD:** `*Service` + `*AwareRepo` + `TestBase_*` (+ Behaviors for consumer-facing APIs). **Not** required for first merge: Diamond Facet-Target-Repo / DFPkg. |
| **Upstream pin** | **Pin at execution time** to the then-current `OlympusDAO/olympus-v3` commit (typically `develop` HEAD). Do **not** force the historical v2 pin. Record full hash in `VENDOR.md`. Re-pin is allowed later with documented diff. |
| **License** | **AGPL-3.0-only** (upstream SPDX). Compatible with faithful vendoring; record in `VENDOR.md`. |
| **viaIR** | **Forbidden.** Fix stack-too-deep with structs / helpers. |
| **Foundry profile** | New profile `olympus_v3_port` pointing at v3 trees. **Do not break** existing `olympus_port` (v2). |

### 0.1 Context: what already exists

Crane already vendors a **slice** of the same upstream repo under a historically misnamed path:

| Item | Value |
|------|-------|
| Path | `contracts/protocols/tokens/stable/olympus/v2/` |
| Upstream | [OlympusDAO/olympus-v3](https://github.com/OlympusDAO/olympus-v3) |
| Pin (v2) | `0af8d56dbe78850d120f077b355dcecee56cb83f` |
| Domain `.sol` | ~158 |
| Hermetic tests | `test/foundry/spec/protocols/tokens/stable/olympus/v2/` (~150) |
| Profile | `FOUNDRY_PROFILE=olympus_port` |
| Active skills | `olympus-architecture`, `olympus-operations`, `crane-olympus` (all path to **v2**) |

Upstream `src/` (excluding tests/scripts/proposals) is ~**261** `.sol` files; v2 intentionally omitted DEPOS, many policies (Operator, Heart, Cooler policies, bonds, deposits, bridges), bridge/governance externals, etc.

**This PRD is not “port Olympus for the first time.”** It is:

1. A **correctly named v3 home** for a full (or fuller) Default Framework port.
2. A **dual-tree** research setup (v2 frozen as reference; v3 is the forward surface).
3. The place where **Crane wrappers** (Service / Aware / TestBase) first land for Olympus.
4. The place where **agent skills** are rewritten for v3 and v2 skills are archived in-repo.

---

## 1. Purpose

Port **Olympus V3 (Bophades)** smart contracts from
[OlympusDAO/olympus-v3](https://github.com/OlympusDAO/olympus-v3) into Crane as a
**faithful domain port** with shared dependencies remapped to Crane’s existing
external trees, under:

```text
contracts/protocols/tokens/stable/olympus/v3/
```

so that:

1. Hermetic Foundry tests can deploy real Kernel / modules / policies (not mocks of the SUT).
2. Strategy and Diamond consumers get idiomatic **Service / Aware / TestBase** helpers.
3. Agents and developers use **v3-path skills** as the default Olympus surface.
4. The existing **v2 tree remains** for side-by-side research and regression comparison.

This PRD is the **authoritative definition of what to port, in what order, and when it is done**.

---

## 2. Problem statement

| Asset | Status |
|-------|--------|
| Partial olympus-v3 domain under `olympus/v2` | Present (core Kernel/modules/policies + hermetic suite) |
| Empty target directory | `contracts/protocols/tokens/stable/olympus/v3/` |
| Active skills still binding agents to v2 | Present — must archive and replace |
| Crane Service / Aware / TestBase for Olympus | **Missing** (v2 is domain+tests only) |
| Network constants for live Kernel / OHM / Cooler | Incomplete / not standardized for v3 fork gates |
| Correct path naming (`v3` for olympus-v3) | **Missing** as the canonical forward tree |

Without a dedicated v3 port + wrappers:

- New work keeps landing on a misnamed tree.
- Integrators re-implement Kernel install / permission wiring.
- Skills and docs drift from the path users asked for.
- Expanding scope (DEPOS, Cooler policies, forks) has no clear home.

---

## 3. Goals

### 3.1 Minimum merge (first ship — required)

Parity with **current v2 completeness**, plus wrappers and skill migration.

| ID | Goal | Measurable outcome |
|----|------|--------------------|
| **G1** | Faithful domain port under `olympus/v3` | Upstream domain subset compiles under Crane solc **0.8.35** |
| **G2** | Shared-dep remap | Reuse / expand `contracts/external/...`; `@crane/contracts/...` imports; **no** private OZ/Solmate under olympus |
| **G3** | Kernel hermetic suite | Install module, activate policy, permission gates behave like upstream |
| **G4** | Core modules hermetic | MINTR, TRSRY, ROLES, INSTR, VOTES, RANGE, CHREG, BLREG, RGSTY, DLGTE (+ PRICE surface matching v2) |
| **G5** | Core policies + utils hermetic | RolesAdmin, Minter, Emergency, TreasuryCustodian, policy enablers/utils, etc. (v2 set) |
| **G6** | Protocol tokens + Cooler external (v2 set) | OlympusERC20 / Cooler stack used by hermetic tests |
| **G7** | Foundry profile `olympus_v3_port` | `ffi`+`ast` for Quabi; isolated `src`/`test`/`out`/`cache` |
| **G8** | Crane wrappers | `OlympusKernelService` (or equivalent) + AwareRepo + `TestBase_OlympusV3` |
| **G9** | Behaviors | At least Behaviors for Kernel consumer surface + ROLES/MINTR touch points used by Service |
| **G10** | Skills migration | v2 skills archived under `docs/archive/skills/olympus-v2/`; new v3 skills active |
| **G11** | VENDOR.md | Pin, license, included/excluded inventory, adaptations |

### 3.2 Follow-up (same program, not required for first merge)

| ID | Goal | Measurable outcome |
|----|------|--------------------|
| **G12** | DEPOS module + deposit facility policies | Hermetic deposit / receipt paths |
| **G13** | Cooler V2 policy stack (MonoCooler, LTV oracle, treasury borrower) | Hermetic Cooler loan lifecycle |
| **G14** | Operator / Heart / Clearinghouse / Bond stack | As needed by IndexedEx consumers |
| **G15** | PRICE.v2 feed suite | Hermetic + optional fork price reads |
| **G16** | Profile-gated mainnet fork binds | Kernel / OHM / Cooler `code.length > 0` + one live op |
| **G17** | Network constants | `ETHEREUM_MAIN` (and L2s as needed) Olympus addresses from official docs / olymsig |
| **G18** | Diamond FTR / DFPkg (optional) | Only if a product explicitly needs Kernel-in-Diamond packaging |
| **G19** | CODEBASE_MAP + `docs/protocols/status.md` | v3 documented as forward port; v2 noted as research pin |

---

## 4. Non-goals

| Non-goal | Rationale |
|----------|-----------|
| Deleting or rewriting the v2 tree in this program | Dual research trees; v2 stays until a **separate** cleanup decision |
| Forcing pin equality with v2’s `0af8d56` | Pin at execution time to current upstream |
| CCIP / LayerZero bridge policies in minimum merge | Heavy external stacks; phase later |
| forge-proposal-simulator / `src/proposals/**` / olymsig scripts | Ops tooling, not domain runtime for Crane consumers |
| Upstream `src/test/sim/**` ffi shell sims | Out of scope for Crane suite |
| Full 500+ upstream unit tests in first merge | Match v2 completeness first; expand deliberately |
| Nesting private OZ / Solmate / Uni under olympus | Expand `contracts/external` then remap |
| Enabling `viaIR` | Forbidden |
| Claiming official Olympus partnership | Port is independent engineering work |
| Diamond Facet / DFPkg packaging in first merge | Explicitly deferred unless product pull |

---

## 5. Non-negotiable policy

Aligned with `crane-porting`, `crane-porting-verification`, and `DEFI_PORTING_PRD` A.4–A.6:

1. **Faithful domain, remapped deps.** Olympus contracts stay logic-equivalent to the pinned commit; OZ/Solmate/clones/Uniswap go through `@crane/contracts/external/...`.
2. **No new git submodules.** Copy sources in; pin in `VENDOR.md`.
3. **No new Foundry remapping aliases** for Olympus packages; use `@crane/` imports (profile may reuse existing `@openzeppelin/` → external v4 like v2 profile).
4. **No private dependency trees** under `olympus/v3/**/dependencies/`.
5. **Production-first tests.** Never `vm.mockCall` Kernel / modules / policies as SUT; deploy ported bytecode or bind live forks.
6. **OZ major must match semantics.** Upstream uses OZ **4.8** and **5.3** in parallel — route correctly; never silently swap OZ-semantic code onto Crane-native Ownable/Context.
7. **Pragma:** relax exact pins only as needed for Crane **0.8.35**; document each relaxation.
8. **Dual-tree isolation:** v3 changes must not break `FOUNDRY_PROFILE=olympus_port` v2 suite.
9. **AGPL-3.0-only:** preserve SPDX headers; note copy obligations in `VENDOR.md`.

---

## 6. Users and use cases

### 6.1 Primary users

| User | Need |
|------|------|
| Crane / IndexedEx strategy authors | Hermetic Kernel + MINTR/TRSRY/ROLES for OHM-related strategies |
| Protocol integrators | Service helpers for install/activate/grant and common policy calls |
| CI / agents | Reproducible `olympus_v3_port` profile and TestBase setup |
| Researchers | Side-by-side v2 vs v3 trees and archived v2 skills |

### 6.2 Core use cases (minimum merge)

1. **Hermetic Kernel bootstrap:** deploy Kernel → install MINTR/TRSRY/ROLES → activate RolesAdmin + Minter → grant role → mint OHM via policy.
2. **Permission negative path:** unpermissioned caller reverts with module policy errors.
3. **Service path:** Crane test uses `OlympusKernelService` / aware addresses without raw ABI glue.
4. **Quabi godmode fixtures:** module tests that need AST still work under `olympus_v3_port` (`ffi`+`ast`).
5. **Research compare:** v2 suite still runnable independently.

---

## 7. Upstream inventory

**Repo:** [OlympusDAO/olympus-v3](https://github.com/OlympusDAO/olympus-v3)  
**License:** AGPL-3.0-only  
**Framework:** Default Framework (Kernel / Module / Policy)  
**Solidity (upstream):** multi-version via `compilation_restrictions` (default **0.8.15**; some 0.8.24 bridge paths)  
**Crane target solc:** **0.8.35**

### 7.1 Source layout (upstream `src/`)

```text
src/
├── Kernel.sol
├── Submodules.sol
├── bases/           # Enabler, Rescueable, rate limiter, asset manager bases
├── external/        # OHM token, Cooler, clones, bridge, governance
├── interfaces/
├── libraries/
├── modules/         # MINTR TRSRY ROLES INSTR VOTES RANGE CHREG BLREG RGSTY DLGTE PRICE DEPOS
├── policies/        # Admin, Cooler, deposits, price, bonds, bridges, BLV, …
├── periphery/       # Cooler composites/migrator, CCIP/LZ bridges
├── proposals/       # EXCLUDE from Crane domain
├── scripts/         # EXCLUDE from Crane domain
└── test/            # Selective port → test/foundry/spec/.../olympus/v3
```

### 7.2 Modules

| Keycode | Role | Minimum merge |
|---------|------|---------------|
| MINTR | Mint/burn OHM | **Yes** |
| TRSRY | Treasury assets / debt | **Yes** |
| ROLES | Policy roles | **Yes** |
| INSTR | Instruction batches | **Yes** |
| VOTES | Voting power | **Yes** |
| RANGE | RBS range state | **Yes** |
| CHREG | Clearinghouse registry | **Yes** |
| BLREG | Boosted liquidity registry | **Yes** |
| RGSTY | Contract registry | **Yes** |
| DLGTE | Gov delegation | **Yes** |
| PRICE | Price module (+ submodules) | **Partial** (match v2; expand G15) |
| DEPOS | Deposit facility module | **Follow-up (G12)** |

### 7.3 Policies — minimum vs later

**Minimum (align with v2 presence):**  
RolesAdmin, Minter, Emergency, TreasuryCustodian, ContractRegistryAdmin, Burner / LegacyBurner, ReserveMigrator, ReserveWrapper, Parthenon, VohmVault, policy `utils/*`, core `interfaces/*` needed by those.

**Follow-up:**  
cooler/* (MonoCooler, …), deposits/*, price/* feeds, Operator, Heart, Clearinghouse, Bond*, EmissionManager, BoostedLiquidity/*, bridge/*, CrossChainBridge, Distributor, LoanConsolidator, YieldRepurchaseFacility, pOLY, V1Migrator, etc.

### 7.4 Dependency substitution map

| Upstream dep | Crane target | Notes |
|--------------|--------------|-------|
| OZ 4.8 (`openzeppelin`) | `contracts/external/openzeppelin-contracts-v4/` | Primary for much of Default Framework code |
| OZ 5.3 (`openzeppelin-new`) | `contracts/external/openzeppelin-contracts-v5/` | Where upstream already uses 5.x APIs |
| solmate | `contracts/external/solmate/` | Expand if missing symbols |
| clones-with-immutable-args | `contracts/external/clones-with-immutable-args/` | Cooler / clone receipts |
| uniswap-v3-core / periphery | `contracts/external/uniswap/v3-*` | OracleLibrary etc.; do not break Crane IERC20 routing on TransferHelper |
| base64 | external base64 if present / expand | DEPOS renderer when G12 lands |
| forge-std | project `lib/forge-std` | Do not nest private forge-std |
| chainlink-ccip / LZ / safe-smart-account | **Defer** with bridge/proposal exclusions | Only if a later phase needs them |
| forge-proposal-simulator | **Out** | Non-domain |

**Import rule:** all new/edited code uses `@crane/contracts/...` (and existing profile remaps only as already established for olympus).

### 7.5 Pin policy

At **copy time**:

```bash
git ls-remote https://github.com/OlympusDAO/olympus-v3.git HEAD
# or develop tip
```

Record in `contracts/protocols/tokens/stable/olympus/v3/VENDOR.md`:

- full commit hash  
- date  
- license  
- included/excluded inventory  
- pragma / import adaptations  

Do **not** require equality with v2’s pin. Note the delta from v2 pin in VENDOR.md if useful for researchers.

---

## 8. Architecture and target layout

### 8.1 Domain path (user-specified)

Unlike Morpho’s `external/` + `protocols/` split, Olympus **Default Framework** domain already lives under Crane’s protocols tree (same pattern as v2). Keep domain sources in:

```text
contracts/protocols/tokens/stable/olympus/v3/
```

Crane wrappers live **alongside** domain code (not nested inside Kernel.sol trees):

```text
contracts/protocols/tokens/stable/olympus/v3/
├── Kernel.sol
├── Submodules.sol
├── bases/
├── external/
├── interfaces/          # upstream + thin Crane re-exports if needed
├── libraries/
├── modules/
├── policies/
├── periphery/
├── VENDOR.md
├── services/            # Crane-native
│   └── OlympusKernelService.sol   # name may refine
├── aware/               # Crane-native
│   └── OlympusKernelAwareRepo.sol
├── stubs/               # hermetic deploy helpers if needed (real ports, not mocks)
└── test/bases/
    ├── TestBase_OlympusV3.sol
    └── TestBase_OlympusV3_Fork.sol   # follow-up G16
```

### 8.2 Tests

```text
test/foundry/spec/protocols/tokens/stable/olympus/v3/
├── Kernel.t.sol
├── bases/
├── libraries/
├── modules/
├── policies/
├── lib/quabi/            # Quabi path/jq adapted for out_olympus_v3_port
├── mocks/                # only non-SUT harnesses
├── services/             # Service / Aware tests
└── (later) fork/
```

### 8.3 Foundry profile

Add `[profile.olympus_v3_port]` modeled on `olympus_port`:

| Setting | Value |
|---------|-------|
| `src` | `contracts/protocols/tokens/stable/olympus/v3` |
| `test` | `test/foundry/spec/protocols/tokens/stable/olympus/v3` |
| `out` | `out_olympus_v3_port` |
| `cache_path` | `cache_olympus_v3_port` |
| `solc` | `0.8.35` |
| `optimizer_runs` | `1` (Crane default) |
| `via_ir` | `false` |
| `ffi` / `ast` | `true` (Quabi) |
| remappings | Mirror v2 profile (`@crane/`, OZ v4 alias, solmate, clones) |

**Keep** `[profile.olympus_port]` pointed at **v2** unchanged.

### 8.4 Crane wrapper surface (required)

| Symbol | Responsibility |
|--------|----------------|
| `OlympusKernelAwareRepo` | Store Kernel (+ optional OHM, ROLES, MINTR, TRSRY addresses) in Diamond-friendly storage slot |
| `OlympusKernelService` | Stateless helpers: `executeAction` wrappers, install/activate sequences, typed module lookups, common mint/role ops via active policies |
| `TestBase_OlympusV3` | Deploy Kernel + core modules + admin policies; expose labeled addresses; Quabi-ready |
| `Behavior_IKernel` / focused Behaviors | Validate action results, permission reverts, dependency configuration |
| Optional later | CoolerService, DepositService when G12–G13 land |

**Not required for first merge:** Facet / DFPkg wrapping Kernel (Default Framework is already modular; Diamond packaging is a product decision).

### 8.5 Dual-tree rules

| Rule | Detail |
|------|--------|
| No shared mutable state | Separate `out_*` / `cache_*` |
| No cross-imports of domain | v3 must not import v2 domain files (or vice versa) |
| Shared deps only via external | Both trees remap to the same OZ/solmate/clones |
| Skills | Active skills → v3 only; archived → v2 |

---

## 9. Skills program

### 9.1 Archive (required)

Move **copies** of current skills into an in-repo archive so developers retaining v2 can still load them:

```text
docs/archive/skills/olympus-v2/
├── README.md                 # why archived; path to live v2 domain; how to use
├── olympus-architecture/
├── olympus-operations/
└── crane-olympus/
```

Also mirror under `.grok/skills` archives if those are the active Grok copies (keep both Claude and Grok trees consistent).

Archive `README.md` must state:

- Domain path: `contracts/protocols/tokens/stable/olympus/v2`
- Profile: `FOUNDRY_PROFILE=olympus_port`
- Forward work uses v3 skills + `olympus/v3`

### 9.2 New active skills (required for DoD)

| Skill | Role |
|-------|------|
| `olympus-architecture` | Kernel/module/policy map; **paths → v3** |
| `olympus-operations` | End-user/operator flows against v3 port |
| `crane-olympus` | Build/test/Service/TestBase for v3; profile `olympus_v3_port` |

Remove or replace the **active** skill bodies so they no longer default to v2 (except a short “legacy v2 archive” pointer).

---

## 10. Network constants (follow-up G16–G17)

Minimum merge **does not** require full fork suites. When fork work starts:

| Constant group | Source |
|----------------|--------|
| Kernel, modules, policies | [Olympus docs addresses](https://docs.olympusdao.finance/main/contracts/addresses), [olymsig](https://github.com/OlympusDAO/olymsig), upstream `src/scripts/env.json` |
| OHM / gOHM / sOHM | Same |
| Cooler V2 | Cooler deployment sequences in upstream README |

Place under `contracts/constants/networks/` (e.g. `ETHEREUM_MAIN`) with clear `OLYMPUS_*` naming.  
Fork tests: **opt-in** via RPC env + `FOUNDRY_PROFILE=olympus_v3_port` (or a dedicated fork profile).

---

## 11. Functional requirements

### 11.1 Domain vendoring (P0 — minimum)

| ID | Requirement |
|----|-------------|
| FR-D1 | Copy selected domain sources into `olympus/v3` from pinned upstream |
| FR-D2 | Rewrite imports to `@crane/...` / external OZ majors |
| FR-D3 | `VENDOR.md` complete |
| FR-D4 | `FOUNDRY_PROFILE=olympus_v3_port forge build` green without viaIR |
| FR-D5 | Domain set ≥ v2 completeness (modules/policies/externals listed in §7) |
| FR-D6 | v2 suite still green under `olympus_port` after v3 work (no regressions) |

### 11.2 Hermetic verification (P0)

| ID | Requirement |
|----|-------------|
| FR-H1 | Port/adapt Kernel + module + base + policy util tests from v2 suite shape |
| FR-H2 | Quabi godmode works with `out_olympus_v3_port` |
| FR-H3 | Exact asserts / typed expectRevert; production-first (no SUT mocks) |
| FR-H4 | `FOUNDRY_PROFILE=olympus_v3_port forge test` green for in-tree suite |

### 11.3 Crane wrappers (P0)

| ID | Requirement |
|----|-------------|
| FR-W1 | `OlympusKernelAwareRepo` with hierarchical slot name (e.g. `protocols.tokens.stable.olympus.v3.kernel.aware`) |
| FR-W2 | `OlympusKernelService` covers install/activate + at least one MINTR and one ROLES happy path |
| FR-W3 | `TestBase_OlympusV3` deploys real Kernel graph |
| FR-W4 | Service tests inherit TestBase / CraneTest as appropriate |
| FR-W5 | Behaviors for consumer-facing wrappers |

### 11.4 Skills & docs (P0)

| ID | Requirement |
|----|-------------|
| FR-S1 | Archive v2 skills under `docs/archive/skills/olympus-v2/` |
| FR-S2 | Active skills rewritten for v3 paths + profile |
| FR-S3 | AGENTS.md / Claude.md skill pointers still discover olympus skills |

### 11.5 Expansion (P1+)

| ID | Requirement |
|----|-------------|
| FR-X1 | DEPOS + deposit policies (G12) |
| FR-X2 | Cooler V2 policies (G13) |
| FR-X3 | Operator/Heart/Clearinghouse/Bonds as consumer-driven (G14) |
| FR-X4 | Fork binds + constants (G16–G17) |

---

## 12. Test strategy

Follow `crane-porting-verification` and production-first rules in `crane-testing`.

| Layer | What | Pass criteria |
|-------|------|---------------|
| **Compile** | v3 domain + wrappers | `olympus_v3_port forge build` |
| **Hermetic** | Real Kernel/modules/policies | Primary flows green |
| **Behavior** | Consumer APIs / Service | Behaviors green |
| **Wrapper** | Service + Aware + TestBase | End-to-end install/mint/role |
| **Regression** | Existing v2 suite | `olympus_port forge test` still green |
| **Fork** | Later | Profile-gated; documented addresses |
| **Adversarial** | Later if wrappers custody assets | `crane-adversarial-testing` |

### 12.1 Commands

```bash
# v3 port
FOUNDRY_PROFILE=olympus_v3_port forge build
FOUNDRY_PROFILE=olympus_v3_port forge test
FOUNDRY_PROFILE=olympus_v3_port forge test --match-path \
  'test/foundry/spec/protocols/tokens/stable/olympus/v3/**'

# v2 must remain green
FOUNDRY_PROFILE=olympus_port forge test
```

### 12.2 Suggested bootstrap sequence for TestBase_OlympusV3

1. Deploy `OlympusERC20` (OHM) as required by MINTR.
2. Deploy `Kernel`.
3. Deploy modules: MINTR, TRSRY, ROLES (minimum), then remaining core modules.
4. `executeAction(InstallModule, …)` for each.
5. Deploy RolesAdmin + Minter (+ Emergency as needed).
6. `executeAction(ActivatePolicy, …)`.
7. Grant roles; run Service smoke (mint approval + mint).

---

## 13. Phased delivery

| Phase | Deliverable | Exit criteria |
|-------|-------------|---------------|
| **0 — Inventory & pin** | Dependency map; chosen commit hash; include/exclude list | Written into draft VENDOR.md |
| **1 — Vendor core domain** | Kernel, bases, libs, core modules/policies/external Cooler/OHM | `olympus_v3_port forge build` |
| **2 — Hermetic suite** | Tests + Quabi under v3 test path | Full in-tree `forge test` green |
| **3 — Wrappers** | Service + Aware + TestBase + Behaviors | Wrapper tests green |
| **4 — Skills** | Archive v2; ship v3 skills | Agents resolve v3 paths |
| **5 — Docs** | CODEBASE_MAP / status notes | Documented dual-tree |
| **6 — Expand (optional)** | DEPOS, Cooler policies, forks, constants | Per G12–G17 |

**Minimum mergeable port = Phases 0–4** (Phase 5 strongly preferred in the same PR or immediate follow-up).

### 13.1 Bootstrap strategy (implementation note)

Acceptable approaches for Phase 1–2:

1. **Copy-forward from v2** then re-diff against pinned upstream (fast; risk of carrying v2 adaptations).
2. **Fresh vendor from upstream pin** then re-apply Crane remaps (cleaner pin fidelity).

Either is allowed; **must** end at the execution-time pin, with VENDOR.md listing adaptations. Prefer (2) if time allows; prefer (1) if the goal is speed to wrappers with known-good tests.

---

## 14. Definition of done

A PR implementing this PRD is **done** for minimum merge when **all** hold:

- [ ] Domain under `contracts/protocols/tokens/stable/olympus/v3/` with complete `VENDOR.md` (pin ≠ forced to v2)
- [ ] Shared deps remapped; no private OZ/Solmate under olympus/v3
- [ ] Completeness ≥ current v2 domain/test class (exclusions documented)
- [ ] `FOUNDRY_PROFILE=olympus_v3_port forge build` green (`via_ir=false`)
- [ ] `FOUNDRY_PROFILE=olympus_v3_port forge test` green for in-tree suite
- [ ] `FOUNDRY_PROFILE=olympus_port forge test` still green (v2 untouched / non-regressed)
- [ ] `OlympusKernelService` + `OlympusKernelAwareRepo` + `TestBase_OlympusV3` present and tested
- [ ] Behaviors for consumer-facing surface
- [ ] v2 skills archived under `docs/archive/skills/olympus-v2/` with README
- [ ] Active `olympus-architecture`, `olympus-operations`, `crane-olympus` point at **v3**
- [ ] No new git submodules; no unauthorized remapping aliases; no viaIR
- [ ] AGPL SPDX preserved; NatSpec on **new** Crane wrappers per `crane-natspec`

**Not required for minimum DoD:** DEPOS full stack, Cooler policy suite, mainnet forks, Diamond DFPkg.

---

## 15. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Dual trees drift / confusion | Skills + CODEBASE_MAP clearly mark v3 forward / v2 research; profiles isolated |
| Copying v2 freezes old bugs vs upstream tip | Pin at execution time; document delta from v2 pin |
| Quabi / AST path breaks | Isolate `out_olympus_v3_port`; update path/jq scripts |
| OZ 4 vs 5 mix | Explicit routing table in VENDOR.md; never Crane-native Ownable for OZ semantics |
| Optimizer_runs mismatch (upstream 10k / 10 / 5k vs Crane 1) | Accept size/gas differences for hermetic; document; do not enable viaIR |
| Operator / MonoCooler size limits | Exclude from minimum; if added later, use compilation_restrictions carefully without viaIR |
| AGPL obligations | Preserve headers; VENDOR.md notes distribution duties |
| Scope creep (bridges, proposals) | Hard non-goals; phase list |

---

## 16. Open questions (non-blocking)

These may be resolved during Phase 0 without blocking PRD acceptance:

1. Exact Service API naming (`OlympusKernelService` vs `OlympusDefaultFrameworkService`).
2. Whether PRICE module files copy at v2 depth or slightly expanded.
3. Whether Cooler **external** contracts stay in minimum (recommended **yes**, matching v2) even if Cooler **policies** wait for G13.
4. Preferred archive path duplication for `.grok/skills` vs only `docs/archive/skills`.

---

## 17. References

| Resource | Path / URL |
|----------|------------|
| Upstream | https://github.com/OlympusDAO/olympus-v3 |
| Default Framework | https://github.com/fullyallocated/Default |
| Existing v2 port | `contracts/protocols/tokens/stable/olympus/v2/` |
| Existing v2 VENDOR | `…/olympus/v2/VENDOR.md` |
| crane-porting | `.claude/skills/crane-porting/SKILL.md` |
| crane-porting-verification | `.claude/skills/crane-porting-verification/SKILL.md` |
| Morpho PRD (format exemplar) | `docs/superpowers/specs/2026-07-27-morpho-port-prd.md` |
| Pons PRD (locked-decisions exemplar) | `docs/superpowers/specs/2026-07-28-pons-port-prd.md` |
| Official addresses | https://docs.olympusdao.finance/main/contracts/addresses |

---

## 18. Summary for implementers

1. **Pin** olympus-v3 at execution time → vendor into `olympus/v3` with remaps.
2. Bring hermetic suite to **≥ v2 completeness**.
3. Add **Service + Aware + TestBase** (required).
4. **Archive** v2 skills; **write** v3 skills.
5. Keep **v2 tree and `olympus_port` profile** working for research.
6. Expand DEPOS / Cooler policies / forks only after minimum merge.
