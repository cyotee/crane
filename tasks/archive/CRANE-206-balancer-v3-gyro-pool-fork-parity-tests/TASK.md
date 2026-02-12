# Task CRANE-206: Add Balancer V3 Gyro Pool Fork Parity Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-02-02
**Completed:** 2026-02-03
**Dependencies:** CRANE-145 (complete)
**Worktree:** `test/balancer-v3-gyro-fork-parity`
**Priority:** HIGH

---

## Description

Add fork tests that validate Crane's ported Balancer V3 Gyro pool implementations against mainnet Gyro pools.

Repo constraints / clarifications:
- Fork tests must skip when `INFURA_KEY` is not set (not `RPC_URL`).
- Avoid requiring pool registration / permissioned factory flows; these are brittle on forks.
- Prefer parity against existing deployed pools using "pure" math entrypoints (e.g., `computeInvariant`, `computeBalance`, `onSwap`) and on-chain reads.
- Use `contracts/constants/networks/ETHEREUM_MAIN.sol` and `contracts/constants/networks/BASE_MAIN.sol` for addresses.

## Dependencies

- CRANE-145: Refactor Balancer V3 Gyro Pool Package (complete)

## User Stories

### US-CRANE-206.1: Fork Test Base

As a developer, I want a Gyro fork TestBase so tests share setup and are reproducible.

**Acceptance Criteria:**
- [x] Create `test/foundry/fork/ethereum_main/balancerV3/TestBase_BalancerV3GyroFork.sol`
- [ ] Optional: create `test/foundry/fork/base_main/balancerV3/TestBase_BalancerV3GyroForkBase.sol`
- [x] Fork gating: tests must skip when `INFURA_KEY` is unset
- [x] Use vault/router/factory addresses from `ETHEREUM_MAIN` / `BASE_MAIN`

### US-CRANE-206.2: 2-CLP Parity (Core)

As a developer, I want Gyro 2-CLP math entrypoints to match a deployed mainnet Gyro 2-CLP pool.

**Acceptance Criteria:**
- [x] Select an existing deployed Gyro 2-CLP pool from network constants (e.g. `*_MOCK_GYRO_2CLP_POOL`)
- [x] Compare at least: `computeInvariant`, `computeBalance`, and `onSwap` results between:
  - the deployed pool, and
  - the ported implementation executed locally with identical inputs
- [x] Cover both swap directions and multiple trade sizes

### US-CRANE-206.3: ECLP Parity (Core)

As a developer, I want Gyro ECLP math entrypoints to match a deployed mainnet Gyro ECLP pool.

**Acceptance Criteria:**
- [x] Select an existing deployed Gyro ECLP pool from network constants (e.g. `BLANACER_V3_MOCK_GYRO_ECLP_POOL`)
- [x] Compare `computeInvariant`, `computeBalance`, and `onSwap` results between mainnet and local ported code

## Technical Details

### Directory Structure

```
test/foundry/fork/
├── ethereum_main/
│   └── balancerV3/
│       ├── TestBase_BalancerV3GyroFork.sol
│       ├── BalancerV3Gyro2CLP_Fork.t.sol
│       └── BalancerV3GyroECLP_Fork.t.sol
└── base_main/
    └── balancerV3/
        └── BalancerV3Gyro_ForkBase.t.sol
```

### Inventory Check

- [x] Ported Gyro pool contracts exist and compile
- [x] `contracts/constants/networks/ETHEREUM_MAIN.sol` has Gyro addresses
- [x] `contracts/constants/networks/BASE_MAIN.sol` has Gyro addresses (if Base coverage is added)
- [x] `foundry.toml` includes `ethereum_mainnet_infura` (and `base_mainnet_infura` if Base coverage is added)

## Completion Criteria

- [x] Tests pass:
  - `forge test --match-path "test/foundry/fork/ethereum_main/balancerV3/**Gyro**"`
  - optional Base: `forge test --match-path "test/foundry/fork/base_main/balancerV3/**Gyro**"`
- [x] Tests skip gracefully when `INFURA_KEY` is not set

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
