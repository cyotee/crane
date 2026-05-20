# Frax port — status and remaining work

**Last updated:** 2026-06-04

This document summarizes the Crane port of [Frax Finance `frax-solidity`](https://github.com/FraxFinance/frax-solidity) into `contracts/protocols/tokens/stable/frax/`, with Hardhat JS tests rewritten as Foundry specs and fork tests.

**Authoritative plan:** [`docs/superpowers/plans/2026-06-02-frax-port.md`](superpowers/plans/2026-06-02-frax-port.md)  
**Design / audit notes:** [`docs/superpowers/specs/2026-06-02-frax-port-design.md`](superpowers/specs/2026-06-02-frax-port-design.md)  
**Machine-readable inventory:** [`scripts/frax-port/js-test-inventory.json`](../scripts/frax-port/js-test-inventory.json)  
**Coverage matrix (regenerate):** `python3 scripts/frax-port/build_coverage_matrix.py` → [`scripts/frax-port/coverage-matrix.json`](../scripts/frax-port/coverage-matrix.json)

---

## Goal (from plan)

- Port ~585 upstream `.sol` files (28 subdirectories) under `contracts/protocols/tokens/stable/frax/`.
- Port 3 upstream Foundry tests and **129** Hardhat `.js` tests as Crane Foundry tests.
- Compile and run under Crane toolchain: Solidity **^0.8.35**, **`via_ir` disabled**, `optimizer_runs = 1`, EVM **cancun**.
- Chain-specific JS tests → `test/foundry/fork/<chain>/protocols/tokens/stable/frax/`.

---

## Current snapshot

| Area | Status |
|------|--------|
| **Contracts** | ~599 `.sol` files under `contracts/protocols/tokens/stable/frax/` (mirror of upstream tree). Pre-0.8 modernization may still be incomplete per file; run `forge build` for full-tree health. |
| **Spec tests (local / mock)** | **168 tests**, **24** `.t.sol` files, **0 failures** (last verified 2026-06-04). |
| **Fork tests (Ethereum mainnet)** | **11** `.t.sol` files, **10** suites; **39 passed**, **3 skipped** when RPC available (requires `ALCHEMY_KEY` / `INFURA_KEY` or public RPC). |
| **Upstream JS inventory** | **129** files tracked in coverage matrix. |
| **`lib/frax-solidity` submodule** | Still present (Phase 8 removal not done). |

### Verify commands

```bash
# Non-fork spec suite (CI-friendly)
forge test --match-path "test/foundry/spec/protocols/tokens/stable/frax/**"

# Ethereum fork suite (needs RPC)
forge test --match-path "test/foundry/fork/ethereum/protocols/tokens/stable/frax/**"

# Regenerate coverage matrix
python3 scripts/frax-port/build_coverage_matrix.py
```

### Heavy BAMM fuzz (optional)

```bash
FRAX_BAMM_HEAVY_FUZZ=1 forge test --match-path "test/foundry/spec/protocols/tokens/stable/frax/BAMM/BAMMFuzzTest.t.sol"
```

---

## Test port progress (129 Hardhat JS files)

Counts from `scripts/frax-port/coverage-matrix.json` (2026-06-04):

| `portStatus` | Count | Meaning |
|--------------|------:|---------|
| **complete** | 24 | Foundry spec (or fork) covers upstream scenarios at intended parity level. |
| **partial** | 15 | Started; gaps remain (see below). |
| **not-started** | 37 | No Foundry port yet. |
| **deferred** | 41 | `old_tests/` — plan default is defer unless explicitly requested. |
| **fixture** | 12 | `truffle-fixture*.js` — fold into fork `setUp()`, not standalone tests. |

**Buckets closed:** `BAMM`, `Fraxbonds`.

**Session work not yet reflected in matrix:** `old_tests/StakingRewardsDualV5-Tests.js` and `old_tests/CommunalFarm-Tests.js` have partial Foundry specs but are still classified as **deferred** in the matrix until the script is updated.

### Complete (24 upstream JS paths)

- `BAMM/` — all 4 (+ fuzz)
- `Fraxbonds/SlippageAuction.js`
- `CPITrackerOracle-Tests.js`, `ComboOracle_SLP_UniV2_UniV3-Tests.js`, `UniV3TWAPOracle-Tests.js` (fork)
- `CrossChainCanonical-Tests.js`, `FPI-FPIS-Tests.js`, `FPIControllerPool-Tests.js` (fork)
- `FraxGaugeFXSRewardsDistributor-Tests.js`
- `Fraxferry/Fraxferry-test.js`
- `Fraxoracle/StateProver-test.js`
- `Fraxswap-FraxswapRange-test.js`, `Fraxswap-UniswapV2-test.js`, TWAMM + uniV2 JS paths (spec)
- `FrxETH/FrxETHMiniRouter-Tests.js` (fork)
- `Governance_Slap_2.js` (fork)
- `LeveragePool-test.js`, `TWAMM_AMO-Tests.js` (fork)
- `veFXSYieldDistributorV4-Tests.js`

### Partial (15) — what’s missing

| Bucket / file | Foundry location | Gaps |
|---------------|------------------|------|
| **Fraxoracle** | `test/foundry/spec/.../Fraxoracle/` | `Fraxoracle-test.js`: live merkle round sync. `StateRootOracle.js`: proof-based `proofStateRoot` (fixtures exist; full RPC proof harness TBD). |
| **FraxferryV2** | `FraxferryV2/FerryV2_test.t.sol` | L2→L1 captain path done; **L1→L2 `disembark` / `collect`** deferred. |
| **Fraxswap** (12 JS) | spec + `Fraxswap_Router_Fork_Test.t.sol` | Core TWAMM / range / router unit tests done. Open: brick-pause, router multi-DEX `ethereumOutput*` scripts, `twamm-utils.js`, `utilities.js`, router utils. |

### Not started (37) — priority groups

**Top-level spec (11)** — mainnet / heavy dependencies:

- `veFXS-Tests.js`, `FraxGaugeController-Tests.js`
- `FraxFarmRageQuitter-Tests.js`, `FraxLiquidityBridger-Tests.js`, `FraxMiddlemanGauge-Tests.js`
- `FraxUnifiedFarm_ERC20-Tests.js` (+ KyberSwapElastic, PosRebase, UniV3)
- `veFPIS-Tests.js`, `veFPISYieldDistributorV5-Tests.js`

**`Lending_AMOs/` (4):** AaveAMO, KashiAMO, Rari-AMO, TruefiAMO.

**Multi-chain fork (22):** under `__ARBITRUM`, `__AURORA`, `__AVALANCHE`, `__BSC`, `__FANTOM`, `__HARMONY`, `__MOONBEAM`, `__MOONRIVER`, `__OPTIMISM`, `__POLYGON` — target `test/foundry/fork/<chain>/protocols/tokens/stable/frax/`.

### Deferred `old_tests/` (41)

Legacy Hardhat suite (Core, Curve AMO, Convex AMO, old FPI, FXSRewards, pool tests, etc.). Port only if full historical parity is required.

**Already ported as partial mocks (still “deferred” in matrix):**

- `StakingRewardsDualV5_Test.t.sol` (7 tests)
- `CommunalFarm_Test.t.sol` (9 tests)

---

## Spec test layout (local)

Path: `test/foundry/spec/protocols/tokens/stable/frax/`

| Area | Files | Notes |
|------|------:|-------|
| **BAMM** | 4 | Bucket **complete**; optional `FRAX_BAMM_HEAVY_FUZZ=1`. |
| **Fraxbonds** | 1 | Slippage auction — bucket **complete**. |
| **Fraxswap** | 8 | TWAMM, range, router (local). |
| **Fraxoracle** | 3 + fixtures | State prover, local oracle tests; proofs partial. |
| **Fraxferry / FraxferryV2** | 2 | v1 + v2 partial. |
| **Staking** | 4 | veFXS yield distributor, gauge distributor, DualV5, CommunalFarm (mocks). |
| **FPI, ERC20, LeveragePool** | 3 | |

**Mocks:** `contracts/protocols/tokens/stable/frax/mocks/` — `MintableERC20`, `MockVeFXS`, `MockFraxGaugeController`, `MockUniswapV2Pair`, `MockSaddleD4LP`, Convex stubs, etc.

**Bucket status sidecars:** `scripts/frax-port/bamm-bucket-status.json`, `fraxbonds-bucket-status.json`, `staking-bucket-status.json`.

---

## Fork test layout (Ethereum only)

Path: `test/foundry/fork/ethereum/protocols/tokens/stable/frax/`

| File | Upstream / purpose |
|------|-------------------|
| `TestBase_FraxEthereumFork.sol` | RPC fallback (Alchemy → Infura → public); `vm.skip` if all fail. |
| `FraxEthereumAddresses` (in base file) | Mainnet address constants. |
| `Oracle/*` | CPI tracker, ComboOracle, UniV3 TWAP. |
| `FPI/FPIControllerPool_Tests.t.sol` | FPI controller pool. |
| `Misc_AMOs/TWAMM_AMO_Tests.t.sol` | TWAMM AMO. |
| `Fraxswap/Fraxswap_Router_Fork_Test.t.sol` | Router swaps vs live pools. |
| `FrxETH/FrxETHMiniRouter_Test.t.sol` | Mini router. |
| `Governance/Governance_Slap_2_Tests.t.sol` | Governance. |
| `FXS/FXSDisableVoteTracking.t.sol` | Pinned block `17_198_193`. |
| `veFPIS/veFPISProxy.t.sol` | veFPIS proxy. |

**RPC config** (`foundry.toml`): `ethereum_mainnet_alchemy`, `ethereum_mainnet_infura`, `ethereum_mainnet_public`.

### Is the fork adequate for our own tests?

**Yes, as a starter for Ethereum integration tests** against deployed Frax contracts: inherit `TestBase_FraxEthereumFork`, use `FraxEthereumAddresses`, fund via whale `prank` patterns.

**Limitations:**

- **Ethereum only** — no L2 fork bases yet.
- Most tests use **latest** mainnet head (non-deterministic over time); prefer `_forkEthereumAtBlock` for stable CI.
- **Skip on RPC failure** — suite can pass with fork tests skipped; use env-gated “fail if no fork” for mandatory CI if needed.
- Not a substitute for **local mock specs** when testing Crane diamonds/packages in isolation.

---

## Staking bucket detail

| Upstream JS | Status | Foundry |
|-------------|--------|---------|
| `veFXSYieldDistributorV4-Tests.js` | complete | `veFXSYieldDistributorV4_Test.t.sol` |
| `FraxGaugeFXSRewardsDistributor-Tests.js` | complete | `FraxGaugeFXSRewardsDistributor_Test.t.sol` |
| `old_tests/StakingRewardsDualV5-Tests.js` | partial (mocks) | `StakingRewardsDualV5_Test.t.sol` |
| `old_tests/CommunalFarm-Tests.js` | partial (mocks) | `CommunalFarm_Test.t.sol` |
| `veFXS-Tests.js` | not-started | needs veFXS Vyper or mainnet fork |
| `FraxGaugeController-Tests.js` | not-started | needs gauge controller Vyper or extended mock |
| `FraxUnifiedFarm_*` | not-started | heavy LP / Convex / gauge deps |
| `FraxFarmRageQuitter-Tests.js` | not-started | mainnet farm + impersonation |

---

## Plan phases — remaining work

| Phase | Description | Status |
|-------|-------------|--------|
| **1–2** | Dependency audit, external deps, scaffold | Largely done (see design doc). |
| **3** | Copy contracts (28 subdirs) | Largely done (~599 files). |
| **4** | Pre-0.8 modernization | Ongoing verification via `forge build`; not formally signed off. |
| **5** | Port 3 upstream Foundry tests | Done (BAMM spec; FXS / veFPIS on Ethereum fork). |
| **6** | Rewrite 129 JS tests | **~24 complete, ~15 partial, ~37 not-started, ~41 deferred**, 12 fixtures. |
| **7.1** | Non-fork test gate | Spec suite green (168 tests). Document skips and partial parity. |
| **7.2** | Fork gate per chain | Ethereum fork exists; **22** chain JS tests not ported. |
| **7.3** | Documentation | This file + design doc progress log; optional `contracts/.../frax/README.md`. |
| **8** | Remove `lib/frax-solidity` submodule | Not started. |

---

## Recommended next steps (priority order)

1. **Close partial buckets:** Fraxoracle merkle + proof harness; FerryV2 L1→L2; Fraxswap router output / pause utilities.
2. **Staking / governance:** `veFXS` + `FraxGaugeController` (fork or fixture); then `FraxUnifiedFarm_*`.
3. **Integrations:** Rage quitter, liquidity bridger, middleman gauge (mainnet fork).
4. **`Lending_AMOs/`** (4 tests).
5. **Multi-chain forks** (22 tests) + absorb **12** truffle fixtures into per-chain `setUp()`.
6. **Update coverage matrix** for StakingRewardsDualV5 / CommunalFarm partial status.
7. **Fork hardening for reuse:** pinned blocks, optional `FRAX_FORK_REQUIRED=1`, shared `fundERC20` helpers.
8. **Phase 7–8:** CI policy, design doc finalization, submodule removal.

**Explicitly deprioritized unless requested:** bulk `old_tests/` (39 remaining), CI wiring (`test:frax-spec` npm scripts).

---

## Known constraints

- **Never enable `via_ir`** in `foundry.toml` — use struct refactors for stack-too-deep.
- **TWAMM / proceeds tests:** fund sell token; measure balance delta around `executeVirtualOrders` / withdraw; `rewardFactor` as `uint256` with `1e18` precision.
- **Do not edit `foundry.toml` remappings** without explicit approval (per project rules).
- **BAMM fuzz:** default reduced iteration count; `FRAX_BAMM_HEAVY_FUZZ=1` for upstream-scale fuzz.

---

## Related tooling

| Path | Purpose |
|------|---------|
| `scripts/frax-port/build_coverage_matrix.py` | Regenerate `coverage-matrix.json` from inventory + on-disk tests. |
| `scripts/frax-port/js-test-inventory.json` | Full list of 129 upstream JS test paths. |
| `test/foundry/spec/protocols/tokens/stable/frax/Fraxoracle/StateProverFixtures.sol` | Fixed proofs from upstream JS for local StateProver tests. |