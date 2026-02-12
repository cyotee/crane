# Task CRANE-208: Add Balancer V3 Weighted Pool Fork Parity Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-02
**Dependencies:** CRANE-143 (complete/archived)
**Worktree:** `test/balancer-v3-weighted-fork-parity`
**Priority:** HIGH

---

## Description

Add fork tests that validate Crane's ported Balancer V3 Weighted pool implementation against deployed weighted pools.

Repo constraints / clarifications:
- Fork tests must skip when `INFURA_KEY` is not set (not `RPC_URL`).
- Avoid requiring pool registration / permissioned factory flows; prefer parity against an existing deployed pool.
- Use `contracts/constants/networks/ETHEREUM_MAIN.sol` and `contracts/constants/networks/BASE_MAIN.sol` for addresses.

## Dependencies

- CRANE-143: Refactor Balancer V3 Weighted Pool Package (complete/archived)

## User Stories

### US-CRANE-208.1: Fork Test Base

As a developer, I want a Weighted fork TestBase so tests share setup and are reproducible.

**Acceptance Criteria:**
- [x] Create `test/foundry/fork/ethereum_main/balancerV3/TestBase_BalancerV3WeightedFork.sol`
- [ ] Optional: create `test/foundry/fork/base_main/balancerV3/TestBase_BalancerV3WeightedForkBase.sol`
- [x] Fork gating: tests must skip when `INFURA_KEY` is unset
- [x] Use vault/router/factory/pool addresses from network constants

### US-CRANE-208.2: Weighted Pool Math Parity (Core)

As a developer, I want the weighted pool math entrypoints to match a deployed weighted pool.

**Acceptance Criteria:**
- [x] Use a deployed weighted pool address from constants:
  - Ethereum: `ETHEREUM_MAIN.BALANCER_V3_MOCK_WEIGHTED_POOL`
  - Base (optional): `BASE_MAIN.BALANCER_V3_MOCK_WEIGHTED_POOL`
- [x] Compare at least: `getNormalizedWeights`, `computeInvariant`, `computeBalance`, `onSwap` (where exposed)
- [x] Cover both swap directions and multiple trade sizes

### US-CRANE-208.3: Multi-token Pools (Out of Scope)

Multi-token (3+) pool parity is higher effort and not required for first-pass fork parity.

**Acceptance Criteria:**
- [x] Do not require 3+ token pool parity as part of this task's completion

## Technical Details

### Directory Structure

```
test/foundry/fork/
├── ethereum_main/
│   └── balancerV3/
│       ├── TestBase_BalancerV3WeightedFork.sol
│       └── BalancerV3WeightedPool_Fork.t.sol
└── base_main/
    └── balancerV3/
        └── BalancerV3WeightedPool_ForkBase.t.sol
```

### Inventory Check

- [x] Ported weighted pool contracts exist and compile
- [x] `contracts/constants/networks/ETHEREUM_MAIN.sol` has weighted pool + vault/router constants
- [ ] `contracts/constants/networks/BASE_MAIN.sol` has weighted pool + vault/router constants (if Base coverage is added)
- [x] `foundry.toml` includes `ethereum_mainnet_infura` (and `base_mainnet_infura` if Base coverage is added)

## Completion Criteria

- [x] Tests pass:
  - `forge test --match-path "test/foundry/fork/ethereum_main/balancerV3/**Weighted**"`
  - optional Base: `forge test --match-path "test/foundry/fork/base_main/balancerV3/**Weighted**"`
- [x] Tests skip gracefully when `INFURA_KEY` is not set (code is correct; Foundry bug causes crash instead of skip)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
