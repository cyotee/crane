# Code Review: CRANE-270

**Reviewer:** (pending)
**Review Started:** (pending)
**Status:** Pending

---

## Clarifying Questions

(Questions asked during review will be recorded here)

---

## Review Findings

(Findings will be documented here during code review)

### Fork Parity Harness Status

- Implemented `test/foundry/spec/protocols/dexes/balancer/v3/BalancerV3_PortComparison.t.sol` upstream-only parity checks for the mock weighted pool:
  - Invariant parity: `WeightedMath.computeInvariant{Down,Up}` vs `IBasePool.computeInvariant`.
  - Balance parity: `WeightedMath.computeBalanceOutGivenInvariant` vs `IBasePool.computeBalance`.
  - Quote parity (best-effort): `WeightedMath.computeOutGivenExactIn` vs `IRouter.querySwapSingleTokenExactIn` (skips if query reverts).
- Artifact output:
  - Wrote a non-fork preflight JSON artifact to `tasks/CRANE-270-verify-balancer-v3-port/artifacts/preflight.json`.
- Fork scenario JSON artifacts will be written to `tasks/CRANE-270-verify-balancer-v3-port/artifacts/` when `INFURA_KEY` is set.

### Port-vs-Upstream Execution Parity (Weighted Pools)

- Extended `test/foundry/spec/protocols/dexes/balancer/v3/BalancerV3_PortComparison.t.sol` with best-effort end-to-end parity tests that execute BOTH upstream and locally-deployed operations:
  - `swapSingleTokenExactIn` exec parity (requires `BALANCER_V3_WEIGHTED_POOL` to be pinned).
  - `swapSingleTokenExactOut` exec parity (requires `BALANCER_V3_WEIGHTED_POOL` to be pinned).
  - `addLiquidityUnbalanced` exec parity (requires `BALANCER_V3_WEIGHTED_POOL` to be pinned).
  - `removeLiquidityProportional` exec parity (requires `BALANCER_V3_WEIGHTED_POOL` to be pinned).
- Local pool is initialized with raw token balances cloned from upstream `getPoolTokenInfo()` and static swap fee matched via `getStaticSwapFeePercentage()`.
- Artifacts (written before asserts so failures still snapshot state):
  - `tasks/CRANE-270-verify-balancer-v3-port/artifacts/port-weighted-swapExactIn-exec.json`
  - `tasks/CRANE-270-verify-balancer-v3-port/artifacts/port-weighted-swapExactOut-exec.json`
  - `tasks/CRANE-270-verify-balancer-v3-port/artifacts/port-weighted-addLiquidityUnbalanced-exec.json`
  - `tasks/CRANE-270-verify-balancer-v3-port/artifacts/port-weighted-removeLiquidityProportional-exec.json`
- Fork selection pins a block number (`21_700_000`) for determinism and RPC caching.

### Existing Fork Parity Coverage (Already In Repo)

- Weighted pool math parity vs deployed mainnet pool is covered by `test/foundry/fork/ethereum_main/balancerV3/BalancerV3WeightedPool_Fork.t.sol` (uses `test/foundry/fork/ethereum_main/balancerV3/TestBase_BalancerV3WeightedFork.sol`).
  - Validates `WeightedMath.computeInvariant{Down,Up}` parity against `IBasePool(pool).computeInvariant`.
  - Validates `WeightedMath.computeBalanceOutGivenInvariant` parity against `IBasePool(pool).computeBalance`.
  - Validates swap math indirectly by exercising `WeightedMath.computeOutGivenExactIn` and `WeightedMath.computeInGivenExactOut` (pool `onSwap` is Vault-only, so direct calls would revert).
- Gyro (2CLP + ECLP) parity scaffolding exists under `test/foundry/fork/ethereum_main/balancerV3/`:
  - `test/foundry/fork/ethereum_main/balancerV3/BalancerV3Gyro2CLP_Fork.t.sol`
  - `test/foundry/fork/ethereum_main/balancerV3/BalancerV3GyroECLP_Fork.t.sol`
  - These are fork-gated and skip if the "mock" Gyro pools are not initialized / have no liquidity at the pinned fork block.
- CoW pool tests exist at `test/foundry/fork/ethereum_main/balancerV3/BalancerV3CowPool_Fork.t.sol`.
  - Note: these are primarily spec/library parity checks; live on-chain parity depends on CoW pool deployment availability.
- Foundry config update:
  - Updated `foundry.toml` `fs_permissions` to allow writing to `./tasks/CRANE-270-verify-balancer-v3-port/artifacts`.

### Open Items / Gaps

- Port-vs-upstream comparison for end-to-end operations (swap + add/remove liquidity) is not completed.
  - `test/foundry/spec/protocols/dexes/balancer/v3/BalancerV3_PortComparison.t.sol` contains an initial port-vs-upstream `querySwapSingleTokenExactIn` test, but it currently SKIPs because the mainnet weighted pool factory address in `contracts/constants/networks/ETHEREUM_MAIN.sol` has `code.length == 0` at fork block `21_700_000`.
  - Workaround: run with `BALANCER_V3_WEIGHTED_POOL=0x...` set to a known-live pool address at that fork block.
- Missing fork parity suites for add/remove liquidity scenarios (weighted/stable/constProd) against live deployed pools.

### Port Gap Found: WeightedPoolDFPkg missing VaultAwareRepo init

- `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol` did not initialize `BalancerV3VaultAwareRepo`.
- This breaks `postDeploy()` which calls `_registerPoolWithBalV3Vault(...)` via `BalancerV3BasePoolFactory`, since the factory uses `BalancerV3VaultAwareRepo._balancerV3Vault().registerPool(...)`.
- Fix applied:
  - Initialize `BalancerV3VaultAwareRepo` in the package constructor with `pkgInit.balancerV3Vault`.
  - Also initialize it in `initAccount()` with the immutable `BALANCER_V3_VAULT` (matches `BalancerV3ConstantProductPoolDFPkg` pattern).

### CRANE-270 Note: Gap Report Location

- Do NOT write `out/test-artifacts/CRANE-270/GAPS.md`.
- Record all gaps/diffs in this file: `tasks/CRANE-270-verify-balancer-v3-port/REVIEW.md`.

### CRANE-270 Note: Artifact Output Location

- Do NOT write any CRANE-270 artifacts under `out/test-artifacts/CRANE-270/`.
- Write scenario JSON artifacts under `tasks/CRANE-270-verify-balancer-v3-port/artifacts/`.

---

## Suggestions

(Actionable suggestions for follow-up tasks)

---

## Review Summary

**Findings:** (pending)
**Suggestions:** (pending)
**Recommendation:** (pending)

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
