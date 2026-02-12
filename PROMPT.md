# Agent Task Assignment

**Task:** CRANE-270 - Verify Ported Balancer V3 for Production Deployment
**Repo:** Crane Framework
**Mode:** Implementation
**Task Directory:** tasks/CRANE-270-verify-balancer-v3-port/

## Dependencies

| Dependency | Status | Title |
|------------|--------|-------|

## Required Reading

1. `tasks/CRANE-270-verify-balancer-v3-port/TASK.md` - Full requirements
2. `tasks/CRANE-270-verify-balancer-v3-port/PROGRESS.md` - Prior work and current state

## Instructions

1. Read TASK.md to understand requirements
2. Read PROGRESS.md to see what's been done
3. Continue work from where you left off
4. **Update PROGRESS.md** as you work (newest entries first)
5. When complete, output: `<promise>PHASE_DONE</promise>`
6. If blocked, output: `<promise>BLOCKED: [reason]</promise>`

## On Context Compaction

If your context is compacted or you're resuming work:
1. Re-read this PROMPT.md
2. Re-read PROGRESS.md for your prior state
3. Continue from the last recorded progress

## Completion Checklist

Before marking complete, verify:
- [ ] All acceptance criteria in TASK.md are checked
- [ ] PROGRESS.md has final summary
- [ ] All tests pass
- [ ] Build succeeds

## Troubleshooting

**If you encounter "not a git repository" errors in submodules:**

1. Try: `git submodule update --init --recursive`
2. If that fails: `git submodule deinit -f --all && git submodule update --init --recursive`
3. If still failing, output: `<promise>BLOCKED: Submodules broken, needs worktree reinitialization</promise>`

## Continuation Prompt (CRANE-270)

You are continuing work in the **Crane Framework** repo worktree on branch:
`feature/CRANE-270-verify-balancer-v3-port`

### High-level goal

Build **Ethereum mainnet-fork parity tests** that compare real operations between:

- (A) Upstream Balancer V3 contracts deployed on Ethereum mainnet (accessed via fork)
- (B) Crane-local port deployed into the same fork (from `contracts/protocols/dexes/balancer/v3/`)

Persist results as JSON under:

- `tasks/CRANE-270-verify-balancer-v3-port/artifacts/`

### Persisting constraints / requirements

- Do NOT modify anything under `contracts/external/balancer/v3/` (upstream reference). Fixes belong in `contracts/protocols/dexes/balancer/v3/`.
- All fork tests must be gated on `INFURA_KEY` exactly like existing fork tests:

```solidity
string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
if (bytes(infuraKey).length == 0) vm.skip(true);
vm.createSelectFork("ethereum_mainnet_infura", blockNumber);
```

- Do not inline `INFURA_KEY` in run commands; rely on environment.
- Critically important: keep `tasks/CRANE-270-verify-balancer-v3-port/PROGRESS.md` updated with findings + checkpoints.
- Repo convention/decision: `out/` and `cache_forge/` are being committed to share artifacts and speed builds (re-affirm in PROGRESS).

### Change requested by user

- Do NOT write `out/test-artifacts/CRANE-270/GAPS.md`.
- Put all gap/diff analysis in `tasks/CRANE-270-verify-balancer-v3-port/REVIEW.md`.

### Artifact output location (updated)

- Do NOT write any artifacts under `out/test-artifacts/CRANE-270/`.
- Write scenario JSON artifacts under `tasks/CRANE-270-verify-balancer-v3-port/artifacts/`.

### What we did so far (confirmed by reading repo files)

1) Checked current task progress log
- File: `tasks/CRANE-270-verify-balancer-v3-port/PROGRESS.md`
- It currently logs: task created, preflight findings, existing fork infra, foundry rpc alias, local spec suite pass, fork suites skipped without `INFURA_KEY`.
- It does NOT yet include the additional implementation findings below (add them next).

2) Confirmed the CRANE-270 comparison test is still a placeholder
- File: `test/foundry/spec/protocols/dexes/balancer/v3/BalancerV3_PortComparison.t.sol`
- It only has a scaffold + `assertTrue(true)` smoke test.
- This is the primary file to implement.

3) Identified the canonical fork base behavior and constants to reuse
- File: `test/foundry/fork/ethereum_main/balancerV3/TestBase_BalancerV3WeightedFork.sol`
- Fork block pinned: `21_700_000`
- Uses `vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK)`
- Robust “skip if stale/no-liquidity” logic:
  - `pool.code.length` checks
  - `try/catch` around `vault.getPoolTokenInfo`
  - liquidity check based on balances
- Uses mainnet constants from `ETHEREUM_MAIN`

4) Confirmed mainnet addresses required for fork parity
- File: `contracts/constants/networks/ETHEREUM_MAIN.sol`
- `PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3`
- `WETH9 = 0xC02a...`
- Balancer V3:
  - `BALANCER_V3_VAULT = 0xbA1333...`
  - `BALANCER_V3_ROUTER = 0xAE563E...`
  - `BALANCER_V3_MOCK_WEIGHTED_POOL = 0x527d0E...`
  - `BALANCER_V3_WEIGHTED_POOL_FACTORY = 0x230a59...`

5) Confirmed how to deploy Crane-local Vault/Router/Pool diamonds in tests
- Vault + router wiring pattern is demonstrated in:
  - `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterVaultIntegration.t.sol`
- Key point: `BalancerV3VaultDFPkg.deployVault(...)` and `BalancerV3RouterDFPkg.deployRouter(...)` deploy diamonds via the diamond factory already booted in `CraneTest.setUp()`.

6) Confirmed Permit2 allowance flow requirements for the router
- Router uses Permit2 in “retail mode” (permit2 != address(0)); you must:
  1) `IERC20(token).approve(PERMIT2, max)`
  2) `IPermit2(PERMIT2).approve(token, router, amount, expiration)`
- Permit2 interface location:
  - `contracts/interfaces/protocols/utils/permit2/IPermit2.sol`
  - allowance approval function is in `IAllowanceTransfer.approve(...)`.

7) Confirmed WeightedPoolDFPkg important behaviors (for local pool deployment)
- File: `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol`
- `calcSalt()` and `processArgs()` sort `tokenConfigs` and `normalizedWeights` together to keep alignment.
- `postDeploy()` registers the pool with its vault via `_registerPoolWithBalV3Vault(...)`.
- `postDeploy()` uses swap fee `5e16` (5%).
- Liquidity management flags are set in `_liquidityManagement()` (notably `enableDonation: true`, `disableUnbalancedLiquidity: false`).

8) Located the “PoolInfo / bounds” implementation for weighted pools
- There is no separate mock pool-info facet needed for weighted pools in the port:
  - Pool info + swap fee bounds + invariant ratio bounds are covered by:
    - `contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolFacet.sol`
    - and/or `contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolTarget.sol`
- This matters when constructing the weighted pool DFPkg init arguments: the `defaultPoolInfoFacet`, `standardSwapFeePercentageBoundsFacet`, and `unbalancedLiquidityInvariantRatioBoundsFacet` can likely be satisfied by `BalancerV3PoolFacet` (confirm in code usage when implementing).

9) Found an existing pattern for writing JSON artifacts in Foundry tests
- File: `contracts/protocols/cdps/sky/test/ScriptTools.sol`
- Uses `vm.serialize*` + `vm.writeJson`.
- Reuse this pattern in the comparison harness to write artifacts into `out/test-artifacts/CRANE-270/`.

### What we're doing now

1) Update `tasks/CRANE-270-verify-balancer-v3-port/PROGRESS.md` with the additional findings above.
2) Implement the real fork parity harness in `test/foundry/spec/protocols/dexes/balancer/v3/BalancerV3_PortComparison.t.sol`.

### Next steps (concrete implementation plan)

Step A — Update PROGRESS.md (must do first)
- Append a new dated entry under “Session Log” including:
  - Fork harness constants: fork block `21_700_000`, rpc alias `ethereum_mainnet_infura`.
  - Upstream addresses used: vault/router/mock weighted pool + Permit2/WETH9.
  - Permit2 2-step approval requirement for router operations.
  - WeightedPoolDFPkg behaviors: sorts tokens+weights; `postDeploy` registers pool; swapFee = `5e16`.
  - Where pool-info + swap-fee-bounds + invariant-bounds functionality lives.
  - JSON artifact writing pattern reference (`ScriptTools.sol`).

Step B — Implement fork gating + fork selection in `BalancerV3_PortComparison.t.sol`
- In `setUp()`:
  - `CraneTest.setUp()`
  - `INFURA_KEY` gating and `vm.skip(true)` if missing
  - `vm.createSelectFork("ethereum_mainnet_infura", 21_700_000);`

Step C — Define upstream subjects
- Use `ETHEREUM_MAIN.BALANCER_V3_VAULT`, `...ROUTER`, `...MOCK_WEIGHTED_POOL`.
- Add stale/no-liquidity skip logic similar to `TestBase_BalancerV3WeightedFork.sol`.

Step D — Deploy Crane-local vault + router + weighted pool into the fork
- Deploy Vault diamond via `BalancerV3VaultDFPkg` with permissive mock authorizer + mock fee controller.
- Deploy Router diamond via `BalancerV3RouterDFPkg` pointing at the local vault, but using real mainnet `WETH9` and `PERMIT2`.

Step E — Seed and initialize local pool
- Read upstream pool token list + normalized weights.
- Build `TokenConfig[]` for local pool.
- Deploy local weighted pool via `BalancerV3WeightedPoolDFPkg` and initialize.
- Fund LP with `deal()` for both tokens.
- Approve via Permit2 (token->permit2 + permit2->router allowance).

Step F — Execute parity scenarios and write JSON artifacts
- Start with 4 scenarios:
  1) `swapSingleTokenExactIn`
  2) `swapSingleTokenExactOut`
  3) add liquidity (unbalanced or proportional)
  4) `removeLiquidityProportional`
- Write JSON to `out/test-artifacts/CRANE-270/<scenario>.json`.

Step G — Run command (no inlined key)
- `forge test --match-contract BalancerV3_PortComparison -vvv`
- With no `INFURA_KEY`, it should skip; with it set, it should fork and emit artifacts.
