# Task CRANE-213: Add Balancer V3 Stable Pool Fork Parity Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-03
**Dependencies:** CRANE-144 (complete/archived)
**Worktree:** `test/balancer-v3-stable-fork-parity`
**Priority:** HIGH

---

## Description

Add fork tests that validate Crane's ported Balancer V3 Stable pool implementation against deployed stable pools.

Repo constraints / clarifications:
- Fork tests must skip when `INFURA_KEY` is not set (not `RPC_URL`).
- Fork tests **must specify a block number** to enable Foundry RPC caching. Use the standard block numbers:
  - Ethereum Mainnet: `21_700_000` (matches Balancer V3 Weighted fork tests)
  - Base Mainnet: `28_000_000` (if Base coverage is added)
- Avoid requiring pool registration / permissioned factory flows; prefer parity against an existing deployed pool.
- Use `contracts/constants/networks/ETHEREUM_MAIN.sol` and `contracts/constants/networks/BASE_MAIN.sol` for addresses.

## Dependencies

- CRANE-144: Refactor Balancer V3 Stable Pool Package (complete/archived)

## User Stories

### US-CRANE-213.1: Fork Test Base

As a developer, I want a Stable fork TestBase so tests share setup and are reproducible.

**Acceptance Criteria:**
- [ ] Create `test/foundry/fork/ethereum_main/balancerV3/TestBase_BalancerV3StableFork.sol`
- [ ] Optional: create `test/foundry/fork/base_main/balancerV3/TestBase_BalancerV3StableForkBase.sol`
- [ ] Fork gating: tests must skip when `INFURA_KEY` is unset
- [ ] **Must use pinned block number** for RPC caching: `uint256 internal constant FORK_BLOCK = 21_700_000;` (Ethereum) or `28_000_000` (Base)
- [ ] Use vault/router/factory/pool addresses from network constants

### US-CRANE-213.2: Stable Pool Math Parity (Core)

As a developer, I want the stable pool math entrypoints to match a deployed stable pool.

**Acceptance Criteria:**
- [ ] Use a deployed stable pool address from constants:
  - Ethereum: `ETHEREUM_MAIN.BALANCER_V3_MOCK_STABLE_POOL` (add if missing)
  - Base (optional): `BASE_MAIN.BALANCER_V3_MOCK_STABLE_POOL`
- [ ] Compare at least: `getAmplificationParameter`, `computeInvariant`, `computeBalance`, `onSwap` (where exposed)
- [ ] Cover both swap directions and multiple trade sizes

### US-CRANE-213.3: StableMath Library Parity

As a developer, I want the ported StableMath library to produce identical results to on-chain calculations.

**Acceptance Criteria:**
- [ ] Test `computeOutGivenExactIn` parity against deployed pool behavior
- [ ] Test `computeInGivenExactOut` parity against deployed pool behavior
- [ ] Test invariant calculations with same reserves/balances

### US-CRANE-213.4: Multi-token Pools (Out of Scope)

Multi-token (3+) pool parity is higher effort and not required for first-pass fork parity.

**Acceptance Criteria:**
- [ ] Do not require 3+ token pool parity as part of this task's completion

## Technical Details

### Directory Structure

```
test/foundry/fork/
├── ethereum_main/
│   └── balancerV3/
│       ├── TestBase_BalancerV3StableFork.sol
│       └── BalancerV3StablePool_Fork.t.sol
└── base_main/
    └── balancerV3/
        └── BalancerV3StablePool_ForkBase.t.sol
```

### Block Numbers for Caching

Using pinned block numbers enables Foundry to cache RPC responses, avoiding repeated network calls:

```solidity
// Ethereum Mainnet - matches Balancer V3 Weighted fork tests
uint256 internal constant FORK_BLOCK = 21_700_000;

// Base Mainnet (if added)
uint256 internal constant FORK_BLOCK = 28_000_000;
```

### Inventory Check

- [ ] Ported stable pool contracts exist and compile
- [ ] `contracts/constants/networks/ETHEREUM_MAIN.sol` has stable pool + vault/router constants
- [ ] `contracts/constants/networks/BASE_MAIN.sol` has stable pool + vault/router constants (if Base coverage is added)
- [ ] `foundry.toml` includes `ethereum_mainnet_infura` (and `base_mainnet_infura` if Base coverage is added)

## Completion Criteria

- [ ] Tests pass:
  - `forge test --match-path "test/foundry/fork/ethereum_main/balancerV3/**Stable**"`
  - optional Base: `forge test --match-path "test/foundry/fork/base_main/balancerV3/**Stable**"`
- [ ] Tests skip gracefully when `INFURA_KEY` is not set (code is correct; Foundry bug causes crash instead of skip)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
