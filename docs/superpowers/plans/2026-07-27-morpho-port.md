# Morpho Port Implementation Plan

> **For agentic workers:** Use `subagent-driven-development` or `executing-plans`. Steps use checkbox (`- [ ]`) syntax for tracking.  
> **PRD (requirements):** [`docs/superpowers/specs/2026-07-27-morpho-port-prd.md`](../specs/2026-07-27-morpho-port-prd.md)  
> **Skills (mandatory):** `crane-porting`, `crane-porting-verification`, `crane-testing`  
> **Exemplar parity tests in this repo:**  
> - `test/foundry/fork/ethereum_main/uniswapV3/UniswapV3PortedSwapParity_Fork.t.sol`  
> - `test/foundry/fork/base_main/slipstream/SlipstreamForkParity.t.sol`  
> - Bold full upstream-test port: `test/foundry/spec/protocols/staking/liquity/v2/`

---

## Goal

Port Morpho Blue (+ IRM, oracles), MetaMorpho V1.1, Public Allocator, **Vault V2**, and **Bundler3** into Crane such that:

1. Domain sources compile under Crane with shared deps remapped.
2. **Upstream Foundry suites are ported** into Crane’s test tree and **pass**.
3. Crane-native **TestBase / Behavior / Service** surfaces exist and pass.
4. **Fork parity tests** prove ported bytecode matches live Morpho for the **same operations on the same economic state** (exact asserts; no “something changed”).

### Locked decisions (2026-07-27)

| Topic | Decision |
|-------|----------|
| **First mergeable scope** | **Full stack:** Blue + IRM + oracles + MetaMorpho V1.1 + Public Allocator + **Vault V2 + Bundler3** (not Blue-only). URD/MORPHO token remain P2 unless needed for Vault/Bundler tests. |
| **Upstream tests** | **All portable tests must pass.** Port every Foundry case for in-scope packages; skip only with written reason **and** replacement coverage. |
| **Fork parity** | **Matching new markets** on live Morpho singleton **and** local ported Morpho: identical `MarketParams`, same ops, **exact** state equality (Uni V3 / Slipstream pattern). Live liquid-market replay optional extra, not a substitute. |
| **Upstream pin** | **Bytecode matching live deploy** on ETH/Base (and other fork targets as added). Record pin + license (GPL vs historical BUSL) in each `VENDOR.md`. Prefer tag/commit whose codehash aligns with `ETHEREUM_MAIN.MORPHO` / `BASE_MAIN.MORPHO`. |

---

## Architecture

| Layer | Path |
|-------|------|
| Vendored domain | `contracts/external/morpho/{blue,blue-irm,blue-oracles,metamorpho-v1.1,public-allocator,vault-v2,bundler3}/` |
| Crane wrappers | `contracts/protocols/lending/morpho/{blue,metamorpho,vault-v2,bundler}/` |
| Ported upstream hermetic tests | `test/foundry/spec/protocols/lending/morpho/{blue,metamorpho}/upstream/` |
| Crane hermetic / Behavior / Service tests | `test/foundry/spec/protocols/lending/morpho/{blue,metamorpho}/` |
| Fork live bind + **parity** | `test/foundry/fork/ethereum_main/morpho/` and `test/foundry/fork/base_main/morpho/` |
| Network constants | `contracts/constants/networks/*` (already seeded) |

**Tech stack:** Solidity `^0.8.35`, Foundry, no `viaIR`. EVM: Prague (project default).

**Upstream pins (verify at copy; record in each `VENDOR.md`):**

| Package | Repo | Pin target |
|---------|------|------------|
| Blue | morpho-org/morpho-blue | release/tag matching live bytecode (docs cite `v1.0.0`; main is now **GPL-2.0-or-later**) |
| IRM | morpho-org/morpho-blue-irm | `v1.0.0` or live-matching tag |
| Oracles | morpho-org/morpho-blue-oracles | tag matching factory on chain |
| MetaMorpho | morpho-org/metamorpho-v1.1 | release/commit from address tables |
| Public Allocator | morpho-org/public-allocator | `v1.0.0` |
| Vault V2 / Bundler3 | morpho-org/vault-v2, bundler3 | latest release (Phase 5) |

---

## Testing requirements (non-negotiable)

Aligned with `crane-porting-verification` layers 1–6 (+ fork parity as layer 4 hard gate).

| # | Layer | Requirement | Location |
|---|-------|-------------|----------|
| **T1** | Compile | Ported domain + wrappers build; `@crane/` imports only | `forge build` |
| **T2** | **Upstream suite ported** | Morpho’s own Foundry tests adapted and **green** under Crane | `test/foundry/spec/.../upstream/` |
| **T3** | Hermetic TestBase | Real Morpho bytecode via ports/stubs; primary lending flows | `TestBase_MorphoBlue`, `TestBase_MetaMorpho` |
| **T4** | Behavior | Consumer interfaces (`IMorpho`, ERC4626 MetaMorpho) | `Behavior_*` + declaration tests |
| **T5** | Service / Aware | Crane wrappers with exact deltas | `*.t.sol` under `spec/...` |
| **T6** | **Fork state parity** | Same inputs + same starting state → **exact** same outputs vs live Morpho | `fork/{ethereum_main,base_main}/morpho/*Parity*` |
| **T7** | Fork live ops | Happy-path supply/borrow/repay or vault deposit on live market | `*Fork.t.sol` |
| **T8** | Adversarial (P1+) | Liquidation edges, reentrancy where wrappers hold value | after wrappers stable |

### Upstream suites to port (inventory)

#### Morpho Blue (`morpho-org/morpho-blue` `test/`) — ~29 Solidity files

| Group | Files | Notes |
|-------|-------|-------|
| Base / helpers | `BaseTest.sol`, `helpers/*`, `MarketParamsLibTest.sol` | Adapt imports; keep structure |
| Integration | `integration/*IntegrationTest.sol` (13 files) | supply, borrow, repay, withdraw, liquidate, callbacks, auth, interest, createMarket, … |
| Libraries | `libraries/*`, `libraries/periphery/*` | MathLib, SafeTransferLib, MorphoLib, MorphoBalancesLib, … |
| Invariant | `InvariantTest.sol`, `invariant/*` | Port handlers; target local Morpho |

#### MetaMorpho V1.1 (`morpho-org/metamorpho-v1.1` `test/`)

| Group | Files |
|-------|-------|
| Core vault | `ERC4626Test.sol`, `ERC4626ComplianceTest.sol`, `FeeTest.sol`, `MarketTest.sol`, … |
| Roles / governance | `RoleTest.sol`, `GuardianTest.sol`, `TimelockTest.sol`, `RevokeTest.sol` |
| Allocation | `ReallocateIdleTest.sol`, `ReallocateWithdrawTest.sol` |
| Factory / other | `MetaMorphoFactoryTest.sol`, `DeploymentTest.sol`, `PermitTest.sol`, `ReentrancyTest.sol`, … |
| Helpers | `helpers/*` |

**Port rule:** rewrite imports to `@crane/...`; point SUT at vendored contracts; preserve test intent and exact assertions. Do **not** weaken asserts to make tests pass. If an upstream test depends on an unavailable external (e.g. specific mainnet token), adapt fixture to mintable ERC20 + hermetic Morpho **or** mark skip with written reason and replace with fork case.

Header on every ported test file:

```solidity
// Ported from morpho-org/<repo>@<commit> — path: <upstream path>
// SPDX: preserve upstream SPDX
```

### Fork parity strategy (must implement)

Two complementary designs (both required for Blue; MetaMorpho uses the vault variant).

#### A. Matching-market parity (primary — mirrors Uni V3 / Slipstream)

On a **pinned fork** of Ethereum (and Base):

1. Bind **live** `IMorpho` at `ETHEREUM_MAIN.MORPHO` / `BASE_MAIN.MORPHO`.
2. Deploy **local** Morpho from Crane-ported bytecode (`new Morpho(...)` or factory path).
3. Deploy **identical** AdaptiveCurveIRM (or bind live IRM if bytecode-compatible) and a **shared** oracle (hermetic mock oracle with fixed price, or identical ChainlinkOracleV2 config).
4. `createMarket` with **identical** `MarketParams` on live Morpho **and** local Morpho.
5. Fund actors; run the **same sequence** (supply → supplyCollateral → borrow → accrue/time warp → repay → withdraw).
6. Assert **exact equality** of:
   - market totals (`totalSupplyAssets`, `totalSupplyShares`, `totalBorrowAssets`, `totalBorrowShares`),
   - position shares/assets for actors,
   - token balances of Morpho singleton and users,
   - post-op health / liquidation eligibility where applicable.

Use mintable ERC20s or real fork tokens with `deal` — same amounts both sides.

#### B. Live market view/math parity (secondary)

On pinned fork against a **known liquid market**:

1. Read `MarketParams` + market state + positions from **live** Morpho.
2. Assert periphery lib helpers (MorphoBalancesLib / MorphoLib) on **live** Morpho match direct storage reads.
3. Execute one small supply/withdraw (or staticcall views) and assert preview helpers match execution deltas.

Document market id / loan-collateral pair in NatSpec.

#### C. Codehash / binding gates

- `assertGt(liveMorpho.code.length, 0)`
- Optional: `keccak256(liveMorpho.code)` vs expected (document if CREATE2 vanity code differs by chain).

### Assertion standards (LR-7)

- Exact expected values / deltas — not “balance increased”.
- `vm.expectEmit` with full data when events matter.
- `vm.expectRevert` with selectors.
- No `vm.mockCall` on Morpho / MetaMorpho SUT.
- Pin `DEFAULT_FORK_BLOCK` from network constants for reproducibility.

### Commands (run from Crane root)

```bash
# Compile
rm -rf cache out && forge build

# Ported upstream + hermetic Morpho Blue
forge test --match-path 'test/foundry/spec/protocols/lending/morpho/blue/**' -vv

# MetaMorpho
forge test --match-path 'test/foundry/spec/protocols/lending/morpho/metamorpho/**' -vv

# Fork parity (requires RPC)
forge test --match-path 'test/foundry/fork/ethereum_main/morpho/**' -vv
forge test --match-path 'test/foundry/fork/base_main/morpho/**' -vv
```

Do **not** claim a phase complete without path-scoped green output (or recorded skip reason for RPC-only fork when hermetic still passes).

---

## Conventions

### Pragma

- Rewrite domain/test pragmas to `^0.8.35` unless a documented reason requires a tighter pin; record in `VENDOR.md`.

### Imports

| From (upstream) | To (Crane) |
|-----------------|------------|
| `src/...` Morpho domain | `@crane/contracts/external/morpho/blue/...` (or package path) |
| OZ paths | `@crane/contracts/external/openzeppelin-contracts/...` (correct major) |
| forge-std | `forge-std/...` (unchanged) |
| Relative inside vendored package | Prefer convert cross-package edges to `@crane/` |

**Do not** add Morpho-specific remapping aliases. Expand shared `external/` first if a symbol is missing.

### Commit messages

```
feat(morpho-port): <scope> (Phase <N>.<task>)
```

### License

- Preserve upstream SPDX per file.
- Record license + pin in each package `VENDOR.md`.
- Note: morpho-blue **main** is GPL-2.0-or-later; older tags may still be BUSL — pin explicitly.

---

## Phase 0 — Gates and scaffolding

### Task 0.1: Confirm pins and licenses

- [x] **Step 1:** For each P0 repo, choose git tag/commit; record codehash of live Morpho on ETH if possible (`cast code` / `cast keccak`).
- [x] **Step 2:** Fill license table in PRD open decision D1 / this plan’s VENDOR stubs.
- [x] **Step 3:** Write empty `VENDOR.md` templates under planned external paths (status: planned).

### Task 0.2: Scaffold directories

- [x] **Step 1:** Create:

```bash
mkdir -p contracts/external/morpho/{blue,blue-irm,blue-oracles,metamorpho-v1.1,public-allocator}
mkdir -p contracts/protocols/lending/morpho/blue/{interfaces,services,aware,stubs,test/bases}
mkdir -p contracts/protocols/lending/morpho/metamorpho/{interfaces,services,aware,stubs,test/bases}
mkdir -p test/foundry/spec/protocols/lending/morpho/blue/{upstream/{integration,libraries,invariant,helpers},unit,behavior}
mkdir -p test/foundry/spec/protocols/lending/morpho/metamorpho/{upstream,unit,behavior}
mkdir -p test/foundry/fork/ethereum_main/morpho
mkdir -p test/foundry/fork/base_main/morpho
```

- [ ] **Step 2:** Confirm network Morpho constants exist (ETH/Base/OP/Arb/Sepolia/Base Sepolia/Robinhood/BC).

### Task 0.3: Clone reference trees (temporary)

- [ ] **Step 1:** Shallow-clone or sparse-checkout P0 repos into a **scratch** dir (not a permanent submodule), e.g. `/tmp/morpho-port-src/` or `tmp/morpho/` gitignored.
- [ ] **Step 2:** Inventory `src/` and `test/` file lists; attach counts to this plan’s progress note if they differ from inventory above.

**Phase 0 exit:** pins chosen, dirs ready, constants present, scratch clones available.

---

## Phase 1 — Vendor Morpho Blue stack (compile)

### Task 1.1: Vendor morpho-blue domain

**Files:** copy `src/` → `contracts/external/morpho/blue/` (Morpho.sol, interfaces, libraries, mocks used by tests).

- [ ] **Step 1:** Copy domain sources (include `src/mocks` needed by upstream tests).
- [ ] **Step 2:** Remap imports; expand OZ/external if needed.
- [ ] **Step 3:** Write `contracts/external/morpho/blue/VENDOR.md`.
- [ ] **Step 4:** `forge build` — fix errors without viaIR.
- [ ] **Step 5:** Commit `feat(morpho-port): vendor morpho-blue (Phase 1.1)`.

### Task 1.2: Vendor blue-irm

- [ ] Copy AdaptiveCurve IRM + libs → `contracts/external/morpho/blue-irm/`.
- [ ] Remap; VENDOR.md; compile; commit.

### Task 1.3: Vendor blue-oracles

- [ ] Copy ChainlinkOracleV2 + factory → `contracts/external/morpho/blue-oracles/`.
- [ ] Remap Chainlink interfaces to Crane; VENDOR.md; compile; commit.

**Phase 1 exit:** Blue + IRM + oracles compile under Crane.

---

## Phase 2 — Port Morpho Blue **upstream** tests (T2)

> This phase is required. Passing Crane-only smoke tests is **not** enough.

### Task 2.1: Port helpers + BaseTest

**Target:** `test/foundry/spec/protocols/lending/morpho/blue/upstream/`

- [ ] Port `test/helpers/*` and `BaseTest.sol`.
- [ ] Point Morpho deploy path at `@crane/contracts/external/morpho/blue/...`.
- [ ] Port `MarketParamsLibTest.sol`.
- [ ] `forge test --match-path '.../morpho/blue/upstream/**' -vv` — green or fix.
- [ ] Commit.

### Task 2.2: Port library unit tests

- [ ] Port `test/libraries/*.sol` and `test/libraries/periphery/*.sol`.
- [ ] Run path-scoped forge test; commit.

### Task 2.3: Port integration suite

Port **all** of:

- AccrueInterest, Authorization, Borrow, Callbacks, CreateMarket, ExtSload  
- Liquidate, OnlyOwner, Repay  
- Supply, SupplyCollateral, Withdraw, WithdrawCollateral  

- [ ] Adapt fixtures only as needed; keep exact asserts.
- [ ] Full integration path green.
- [ ] Commit.

### Task 2.4: Port invariant suite

- [ ] Port `InvariantTest.sol` + `invariant/*`.
- [ ] Wire handlers to local Morpho; ensure Foundry invariant discovery works.
- [ ] Run with reasonable depth (document if reduced for CI time).
- [ ] Commit.

**Phase 2 exit:** Full Morpho Blue upstream suite green under Crane (`T2` for Blue).

---

## Phase 3 — Crane Blue TestBase, Behaviors, Service (T3–T5)

### Task 3.1: Hermetic stubs + TestBase_MorphoBlue

**Files:**

- `contracts/protocols/lending/morpho/blue/stubs/` (if needed for deploy helpers)
- `contracts/protocols/lending/morpho/blue/test/bases/TestBase_MorphoBlue.sol`

- [ ] Deploy Morpho + AdaptiveCurveIRM + mock IOracle + mintable loan/collateral ERC20s.
- [ ] `createMarket` helper; fund actors; `vm.label`.
- [ ] Idempotent `setUp` pattern (parent chain if using CraneTest/WETH later).
- [ ] Commit.

### Task 3.2: Behavior_IMorpho (+ market helpers)

- [ ] Implement Behavior for consumer-facing reads/ops Crane will use.
- [ ] Declaration tests under `spec/.../blue/behavior/`.
- [ ] Commit.

### Task 3.3: MorphoBlueService + AwareRepo

- [ ] `MorphoBlueService` for supply/borrow/repay/withdraw/liquidate/createMarket + Id helpers.
- [ ] `MorphoBlueAwareRepo` for morpho/irm/oracleFactory.
- [ ] Unit tests with **exact** balance/share deltas.
- [ ] Commit.

### Task 3.4: Crane hermetic flow suite

- [ ] One file covering full lifecycle: create → supply → collateral → borrow → time warp interest → repay → withdraw → liquidate edge.
- [ ] Exact asserts; expectEmit where useful.
- [ ] Commit.

**Phase 3 exit:** T3–T5 green for Blue without RPC.

---

## Phase 4 — Fork tests + **state parity** (T6–T7)

### Task 4.1: TestBase_MorphoBlue_Fork (Ethereum)

**Files:**

- `contracts/protocols/lending/morpho/blue/test/bases/TestBase_MorphoBlueFork.sol`  
  **or** `test/foundry/fork/ethereum_main/morpho/TestBase_MorphoBlueFork.sol`

- [ ] `vm.createSelectFork(rpc, ETHEREUM_MAIN.DEFAULT_FORK_BLOCK)`.
- [ ] Bind `IMorpho(ETHEREUM_MAIN.MORPHO)`, IRM, oracle factory.
- [ ] `assertGt(code.length, 0)` for core addresses.
- [ ] Commit.

### Task 4.2: MorphoBluePortedMarketParity_Fork (Ethereum) — **required**

**File:** `test/foundry/fork/ethereum_main/morpho/MorphoBluePortedMarketParity_Fork.t.sol`

Pattern (like UniswapV3PortedSwapParity):

- [ ] Deploy **local** Morpho from ported bytecode on the fork.
- [ ] Use shared mock oracle + AdaptiveCurveIRM (deploy local IRM **or** bind live IRM address if same interface and tests allow).
- [ ] Create matching markets on live + local Morpho with identical `MarketParams`.
- [ ] Run identical supply / collateral / borrow / (optional warp) / repay / withdraw.
- [ ] Assert **exact** equality of market aggregates, positions, and ERC20 balances between the two Morpho instances’ users (and consistent internal totals per instance).
- [ ] At least two scenarios: (1) pure supply/withdraw, (2) full borrow cycle.
- [ ] Optional: liquidation parity with oracle price drop on both sides.
- [ ] Commit.

### Task 4.3: MorphoBlueLiveMarket_Fork (Ethereum)

- [ ] Pick a documented liquid market (loan/collateral/oracle/IRM/LLTV in NatSpec).
- [ ] View parity: MorphoBalancesLib vs raw market/position state.
- [ ] One small live user op (supply or repay dust) **or** pure view-only if op requires special tokens — prefer real op with `deal` when possible.
- [ ] Commit.

### Task 4.4: Base mainnet fork mirrors

- [ ] `TestBase_MorphoBlueFork` for Base + `BASE_MAIN` constants.
- [ ] Ported market parity on Base (`MorphoBluePortedMarketParity_Fork.t.sol` under `base_main/morpho/`).
- [ ] Commit.

**Phase 4 exit:** T6–T7 green with RPC; parity tests prove same-state result matching.

---

## Phase 5 — MetaMorpho V1.1 + Public Allocator

### Task 5.1: Vendor MetaMorpho + Public Allocator

- [ ] Vendor domain sources; remap deps (depends on Blue).
- [ ] VENDOR.md; compile; commit.

### Task 5.2: Port MetaMorpho **upstream** tests (T2)

- [ ] Port `metamorpho-v1.1/test/**` → `test/foundry/spec/protocols/lending/morpho/metamorpho/upstream/`.
- [ ] Wire to hermetic Blue from Phase 2/3.
- [ ] All portable cases green; document any skipped with reason.
- [ ] Commit.

### Task 5.3: TestBase_MetaMorpho + Service + ERC4626 Behavior

- [ ] Hermetic vault factory deploy over Blue markets.
- [ ] MetaMorphoService (deposit/withdraw/reallocate/roles as needed).
- [ ] Reuse/adapt `Behavior_ERC4626` for MetaMorpho.
- [ ] Commit.

### Task 5.4: MetaMorpho fork + parity

- [ ] Live factory code binding (`MORPHO_METAMORPHO_FACTORY_V1_1`).
- [ ] Parity: create vault on fork via factory path if possible, **or** deploy local MetaMorpho implementation over matching Blue markets and compare deposit/withdraw share math to a live vault with same asset (document methodology if live vault config differs).
- [ ] Minimum: hermetic upstream green + live factory bind + one live vault ERC4626 preview/deposit parity against a known vault address (document address in NatSpec).
- [ ] Commit.

**Phase 5 exit:** MetaMorpho upstream ported + Crane wrappers + fork checks.

---

## Phase 6 — Vault V2 + Bundler3 (P1)

### Task 6.1: Vendor vault-v2 + bundler3

- [ ] Vendor; VENDOR.md; compile.

### Task 6.2: Smoke hermetic + optional upstream subset

- [ ] Port high-value upstream tests if present and portable; otherwise Crane smokes for factory + adapter + deposit.
- [ ] Bundler3 multicall smoke: supplyCollateral + borrow (or deposit).
- [ ] Fork bind factories/bundler addresses.

### Task 6.3: Fork parity smoke (optional but preferred)

- [ ] Same multicall encoding against live Bundler3 vs local if deployable; or live-only path with exact balance deltas.

---

## Phase 7 — Docs, skills, DoD

### Task 7.1: Documentation

- [ ] Update `docs/CODEBASE_MAP.md` Morpho section.
- [ ] Update `docs/protocols/status.md` / lending docs.
- [ ] Mark PRD status `active` → progress; then `complete` when P0 DoD met.
- [ ] Progress log at bottom of this plan.

### Task 7.2: Skills

- [x] Author `.claude/skills/` Morpho family (architecture, blue ops, vault ops) per `writing-skills` / `skill-authoring`.
  - Installed: `morpho-architecture`, `morpho-blue-operations`, `morpho-vaults`, `crane-morpho` (mirrored under `.grok/skills/` via symlink).

### Task 7.3: Final verification checklist

Copy into PR description when done:

- [ ] `forge build` clean for Morpho packages
- [ ] All P0 `VENDOR.md` pins + licenses
- [ ] No private OZ/Solady under Morpho packages
- [ ] **Morpho Blue upstream suite ported and green**
- [ ] **MetaMorpho upstream suite ported and green** (P0 vault)
- [ ] Hermetic TestBase + Service + Behavior green
- [ ] **Ethereum MorphoBluePortedMarketParity_Fork green (exact state parity)**
- [ ] **Base MorphoBluePortedMarketParity_Fork green**
- [ ] Live market fork bind tests green
- [ ] Path-scoped forge test logs attached / CI green
- [ ] CODEBASE_MAP + skills updated or ticketed

---

## Suggested execution order (summary)

```text
0 Gates/scaffold
  → 1 Vendor Blue stack
  → 2 Port Blue upstream tests          ← mandatory
  → 3 Crane Blue TestBase/Service/Behavior
  → 4 Fork parity + live fork           ← mandatory
  → 5 MetaMorpho vendor + upstream tests + fork
  → 6 Vault V2 / Bundler3
  → 7 Docs/skills/DoD
```

**Mergeable port = Phases 0–6** (full stack including Vault V2 + Bundler3, all portable upstream tests, matching-market fork parity).  
URD / token (former P2) remain optional follow-up unless a ported test requires them.

---

## Risk notes for implementers

| Risk | Handling |
|------|----------|
| Live Morpho is singleton — cannot “replace” it | Parity uses **second local Morpho** on same fork with **matching new markets**, not storage clone |
| AdaptiveCurveIRM stateful | Prefer deploy local IRM for matching markets; don’t share IRM storage between live and local unless intentional |
| Oracle | Use deterministic mock oracle for parity markets; live market tests use real oracles |
| Interest accrual time | Use same `vm.warp` on both sides after same block timestamp base |
| Fee / LLTV enablement | `enableIrm` / `enableLltv` as owner on local Morpho before createMarket |
| Test runtime | Upstream + invariant + dual-chain fork is heavy; keep path-scoped CI jobs |

---

## Progress log

| Date | Note |
|------|------|
| 2026-07-27 | Plan v1.0 written from PRD + crane-porting-verification + upstream inventories |
| 2026-07-27 | Locked: full stack (incl. Vault V2 + Bundler3); all portable upstream tests; matching-market fork parity; live bytecode pin |
| 2026-07-27 | **Phase 0 done:** pins (Blue `v1.0.0` 55d2d99, IRM `v1.0.0` a7d9cce, Oracles `v2.0.0` 07a9a69, MetaMorpho bcc0031, PA `v1.0.0` 7271fbd, VaultV2 9d4ec65, Bundler3 9afc2f4); live ETH Morpho codehash `0xfa259fa3…`, Base `0xaa76348c…`; dirs + VENDOR stubs; scratch `/tmp/morpho-port-src`; `FOUNDRY_PROFILE=morpho_port` |
| 2026-07-27 | **Phase 1 done:** Blue+IRM+oracles vendored, remapped, `FOUNDRY_PROFILE=morpho_port forge build` green (domain) |
| 2026-07-27 | **Phase 2 done:** 27 upstream Blue test files ported; **144/144 green** under morpho_port |
| 2026-07-27 | **Phase 3 done:** TestBase_MorphoBlue, MorphoBlueService, MorphoBlueAwareRepo, Behavior_IMorpho + hermetic lifecycle (4/4 green) |
| 2026-07-27 | **Phase 4:** ETH/Base fork bases + PortedMarketParity + LiveMarket written; run with Alchemy RPC |
| 2026-07-27 | **Phase 5–6 domain:** MetaMorpho V1.1 + PA + Vault V2 + Bundler3 vendored; domain compile green; MetaMorpho TestBase + lifecycle + Vault/Bundler smoke added |
| 2026-07-27 | **Phase 4 green:** ETH parity 2/2, Base parity 2/2; LiveMarket soft-skips if known market id missing at fork block |
| 2026-07-27 | **MetaMorpho upstream:** 195 portable tests green; skipped Reentrancy (no IERC777 in Crane OZ) with SKIPPED.md + Crane lifecycle replacement |
| 2026-07-27 | **Phase 7:** CODEBASE_MAP Morpho section updated; Morpho skill family installed (architecture / blue-ops / vaults / crane-morpho) |

---

## References

- PRD: `docs/superpowers/specs/2026-07-27-morpho-port-prd.md`
- DEFI program: `docs/archive/internal-plans/DEFI_PORTING_PRD.md` §§C.3–C.4
- Skills: `crane-porting`, `crane-porting-verification`, `crane-testing`
- morpho-blue tests: https://github.com/morpho-org/morpho-blue/tree/main/test  
- metamorpho-v1.1 tests: https://github.com/morpho-org/metamorpho-v1.1/tree/main/test  
- Addresses: https://docs.morpho.org/developers/contracts/addresses/
