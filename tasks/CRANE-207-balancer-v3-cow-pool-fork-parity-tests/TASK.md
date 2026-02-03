# Task CRANE-207: Add Balancer V3 CoW Pool Fork Parity Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-02
**Dependencies:** CRANE-146 (complete), CRANE-191 (complete)
**Worktree:** `test/balancer-v3-cow-fork-parity`
**Priority:** HIGH

---

## Description

Add Ethereum mainnet fork tests that validate Crane's ported Balancer V3 CoW pool implementation against a deployed CoW pool.

Repo constraints / clarifications:
- Fork tests must skip when `INFURA_KEY` is not set (not `RPC_URL`).
- Use `ETHEREUM_MAIN.BALANCER_V3_VAULT` for the vault address (do not hardcode; previous task text had a Base vault address here).
- Avoid requiring pool registration / permissioned deployers; prefer parity against an existing deployed pool using math entrypoints and hook configuration reads.

## Dependencies

- CRANE-146: Refactor Balancer V3 CoW Pool Package (complete)
- CRANE-191: Add DFPkg for CoW Pool and Router Initialization (complete)

## User Stories

### US-CRANE-207.1: Fork Test Base

As a developer, I want a CoW fork TestBase so tests share setup and are reproducible.

**Acceptance Criteria:**
- [ ] Create `test/foundry/fork/ethereum_main/balancerV3/TestBase_BalancerV3CowFork.sol`
- [ ] Fork gating: tests must skip when `INFURA_KEY` is unset
- [ ] Use `ETHEREUM_MAIN.BALANCER_V3_VAULT` and other required Balancer constants from `ETHEREUM_MAIN`

### US-CRANE-207.2: CoW Pool Math/Hook Parity (Core)

As a developer, I want the ported CoW pool to match the deployed pool for the behaviors Crane depends on.

**Acceptance Criteria:**
- [ ] Identify a deployed CoW pool address to use as the comparison baseline (either already in constants or added as a new constant in a separate task)
- [ ] Compare at least:
  - `getHookFlags()` (or equivalent hook config read)
  - `getNormalizedWeights()`
  - `computeInvariant` / `computeBalance` / `onSwap` (where exposed)
- [ ] Validate trusted-router gating behavior (reject swaps from non-trusted router) if accessible from the deployed pool interface

### US-CRANE-207.3: Router Swap+Donate Parity (Out of Scope)

The repo currently cannot rely on permissioned / multi-contract flows for mainnet vs local parity in a stable way on forks.

**Acceptance Criteria:**
- [ ] Do not require router swap+donate parity as part of this task's completion

## Technical Details

### Directory Structure

```
test/foundry/fork/ethereum_main/balancerV3/
├── TestBase_BalancerV3CowFork.sol
└── BalancerV3CowPool_Fork.t.sol
```

### Inventory Check

- [ ] Ported CoW pool contracts exist and compile
- [ ] `contracts/constants/networks/ETHEREUM_MAIN.sol` provides `BALANCER_V3_VAULT`
- [ ] `foundry.toml` includes `ethereum_mainnet_infura`

## Completion Criteria

- [ ] Tests pass: `forge test --match-path "test/foundry/fork/ethereum_main/balancerV3/**Cow**"`
- [ ] Tests skip gracefully when `INFURA_KEY` is not set

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
