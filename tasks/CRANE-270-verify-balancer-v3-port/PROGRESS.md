# Progress Log: CRANE-270

## Current Checkpoint

**Last checkpoint:** Preflight inventory + local Balancer V3 spec suite passes; fork suites skip without `INFURA_KEY`
**Next step:** Run fork parity harness with `INFURA_KEY` set and record diffs/gaps in `tasks/CRANE-270-verify-balancer-v3-port/REVIEW.md`
**Build status:** ✅ forge build (from local spec suite runs)
**Test status:** ✅ port comparison preflight passes; ⚠️ fork parity scenarios skipped when `INFURA_KEY` unset

---

## Session Log

### 2026-02-11 - Fork Harness Findings (consolidated)

- Canonical fork pattern to follow: `test/foundry/fork/ethereum_main/balancerV3/TestBase_BalancerV3WeightedFork.sol` (fork block `21_700_000`, rpc alias `ethereum_mainnet_infura`, skip if pool missing/stale/no-liquidity).
- Upstream mainnet addresses live in `contracts/constants/networks/ETHEREUM_MAIN.sol` (Vault/Router/mock weighted pool + `WETH9` + `PERMIT2`).
- Deployment examples for ported diamonds (Vault/Router) exist and should be mirrored in the harness:
  - `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.t.sol`
  - `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterVaultIntegration.t.sol`
  - `contracts/protocols/dexes/balancer/v3/router/diamond/TestBase_BalancerV3Router.sol`
- Permit2 allowance flow for router tests confirmed in `contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol`.
- Weighted pool DFPkg behavior confirmed in `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol` (sorts token configs + weights together; `postDeploy()` registers pool and sets swap fee to `5e16`).
- JSON artifact write pattern confirmed in `contracts/protocols/cdps/sky/test/ScriptTools.sol` (use `vm.serialize*` + `vm.writeJson`).
- Existing fork parity test template found at `test/foundry/fork/ethereum/balancer/v3/BalancerV3TestMock_Parity.t.sol` (use as style reference).

### 2026-02-11 - Direction Change: Gap Report Location

- Per user direction: do NOT write `out/test-artifacts/CRANE-270/GAPS.md`.
- Record gap/diff analysis in `tasks/CRANE-270-verify-balancer-v3-port/REVIEW.md` instead (alongside any parity harness results).

### 2026-02-11 - Direction Change: Artifact Output Location

- Per user direction: do NOT write any CRANE-270 artifacts under `out/test-artifacts/CRANE-270/`.
- Write any scenario outputs/artifacts under `tasks/CRANE-270-verify-balancer-v3-port/` (use `tasks/CRANE-270-verify-balancer-v3-port/artifacts/` for JSON).

### 2026-02-11 - Task Created (moved from IDXEX-109)

- Task created under Crane tasks for submodule-local worktree launch
- TASK.md populated with Crane-relative paths and preflight steps

### 2026-02-11 - Preflight + Current Findings

- Worktree is on branch `feature/CRANE-270-verify-balancer-v3-port`.
- Working tree currently has modifications/untracked:
  - Modified: `test/foundry/spec/protocols/dexes/balancer/v3/BalancerV3_PortComparison.t.sol`, `cache_forge/solidity-files-cache.json`
  - Untracked: `.claude/backlog-agent.local.md`, `PROMPT.md`, and some `out/` build artifacts.
- Port inventory directories confirmed present at `contracts/protocols/dexes/balancer/v3/`:
  - `hooks/`, `pool-constProd/`, `pool-gyro/`, `pool-stable/`, `pool-utils/`, `pool-weighted/`, `pools/`, `rateProviders/`, `reclamm/`, `router/`, `test/`, `utils/`, `vault/`.
- Upstream/reference directory confirmed present at `contracts/external/balancer/v3/`:
  - `interfaces/`, `pool-cow/`, `pool-gyro/`, `pool-hooks/`, `pool-stable/`, `pool-utils/`, `pool-weighted/`, `solidity-utils/`, `standalone-utils/`, `vault/`.
- Existing fork parity infrastructure for Balancer V3 already exists under:
  - `test/foundry/fork/ethereum_main/balancerV3/` (e.g. `TestBase_BalancerV3WeightedFork.sol`, `BalancerV3WeightedPool_Fork.t.sol`).
  - These tests use the repo convention of gating fork execution on `INFURA_KEY` and `vm.skip(true)` before `vm.createSelectFork("ethereum_mainnet_infura", ...)`.
- `foundry.toml` defines `ethereum_mainnet_infura = "https://mainnet.infura.io/v3/${INFURA_KEY}"`.
- CRANE-270 scaffold test file exists: `test/foundry/spec/protocols/dexes/balancer/v3/BalancerV3_PortComparison.t.sol` (currently a placeholder smoke test).

### 2026-02-11 - Note for Step F (fork run command)

- Per user direction: for Step F, do NOT inline `INFURA_KEY` in the command. Rely on the environment being set outside the invocation (or tests will skip when unset).

### 2026-02-11 - Test Runs (local)

- Ran Balancer V3 spec tests under `test/foundry/spec/protocols/dexes/balancer/v3/*.t.sol`:
  - Result: PASS (large suite; includes DFPkg integration tests, facet/interface selector tests, router/vault diamond tests, hooks examples, reclamm tests, etc.).
  - Note: `test/foundry/spec/protocols/dexes/balancer/v3/BalancerV3_PortComparison.t.sol` is still a placeholder smoke test.
- Ran Balancer V3 fork suites under `test/foundry/fork/ethereum_main/balancerV3/*.t.sol` without setting `INFURA_KEY`:
  - `BalancerV3CowPool_Fork.t.sol`: PASS (12 tests)
  - `BalancerV3Gyro2CLP_Fork.t.sol`: SKIP in `setUp()`
  - `BalancerV3GyroECLP_Fork.t.sol`: SKIP in `setUp()`
  - `BalancerV3WeightedPool_Fork.t.sol`: SKIP in `setUp()`
  - This matches the expected fork gating behavior when `INFURA_KEY` is not present.

### 2026-02-11 - CRANE-270 Fork Parity Harness Notes (to apply)

- Continuation prompt + constraints captured into `PROMPT.md` for context-resume safety.
- Canonical fork base to follow: `test/foundry/fork/ethereum_main/balancerV3/TestBase_BalancerV3WeightedFork.sol`
  - Fork block pinned: `21_700_000`
  - RPC alias: `ethereum_mainnet_infura`
  - Uses `pool.code.length` + `try/catch` around `vault.getPoolTokenInfo` and a nonzero-balance check to skip stale/no-liquidity pools.
- Mainnet constants for fork parity:
  - `contracts/constants/networks/ETHEREUM_MAIN.sol` provides `BALANCER_V3_VAULT`, `BALANCER_V3_ROUTER`, `BALANCER_V3_MOCK_WEIGHTED_POOL`, `BALANCER_V3_WEIGHTED_POOL_FACTORY`, `WETH9`, `PERMIT2`.
- Router Permit2 allowance flow (retail mode):
  - `IERC20(token).approve(PERMIT2, type(uint256).max)`
  - `IPermit2(PERMIT2).approve(token, router, amount, expiration)`
  - Permit2 interface: `contracts/interfaces/protocols/utils/permit2/IPermit2.sol` (allowance approval is in `IAllowanceTransfer.approve`).
- Weighted pool DFPkg behaviors (important for deterministic matching):
  - `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol`
  - `calcSalt()` and `processArgs()` sort `tokenConfigs` and `normalizedWeights` together.
  - `postDeploy()` registers the pool with the vault and sets swap fee to `5e16` (5%).
  - LiquidityManagement flags set via `_liquidityManagement()` (notably `enableDonation: true`, `disableUnbalancedLiquidity: false`).
- PoolInfo / bounds implementation for weighted pools:
  - No extra “mock pool-info” facet is required; pool-info + swap-fee bounds + invariant bounds live in:
    - `contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolFacet.sol`
    - and/or `contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolTarget.sol`
- JSON artifact writing pattern for Foundry tests:
  - `contracts/protocols/cdps/sky/test/ScriptTools.sol` shows `vm.serialize*` + `vm.writeJson` usage.
- Repo convention reminder (do not undo): `out/` and `cache_forge/` are being committed to share artifacts and speed builds.
