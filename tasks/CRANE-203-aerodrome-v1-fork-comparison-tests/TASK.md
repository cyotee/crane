# Task CRANE-203: Add Aerodrome V1 Fork Comparison Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-02-02
**Dependencies:** CRANE-148 (archived)
**Worktree:** `test/aerodrome-v1-fork-comparison`

---

## Description

Add Base mainnet fork tests that validate Crane Aerodrome V1 math and service helpers against real Aerodrome V1 pools.

Important repo constraints:
- Do not add new tests that depend on deprecated `AerodromService.sol` (see CRANE-172); use `AerodromServiceVolatile` / `AerodromServiceStable`.
- Fork tests must use existing repo convention: skip when `INFURA_KEY` is not set and use the `base_mainnet_infura` rpc alias.
- Use `contracts/constants/networks/BASE_MAIN.sol` for addresses.

Scope note: much of the Aerodrome service code routes through Aerodrome's router; "router vs service" swap parity is often tautological. Prioritize parity against on-chain pool math (e.g. pool amount out / metadata) and quote helpers.

## Dependencies

- CRANE-148: Verify Aerodrome Contract Port Completeness (archived)

## User Stories

### US-CRANE-203.1: Fork Test Base

As a developer, I want a Base fork TestBase for Aerodrome so tests share setup and are reproducible.

**Acceptance Criteria:**
- [x] Create `test/foundry/fork/base_main/aerodrome/TestBase_AerodromeFork.sol`
- [x] Fork gating: tests must skip when `INFURA_KEY` is unset
- [x] Fork uses `vm.createSelectFork("base_mainnet_infura", blockNumber)`
- [x] Addresses pulled from `BASE_MAIN` (at minimum `AERODROME_POOL_FACTORY`, `AERODROME_ROUTER`)

### US-CRANE-203.2: Volatile Pool Quote Parity (Core Deliverable)

As a developer, I want volatile quotes and swap math to match deployed pools.

**Acceptance Criteria:**
- [x] For an existing volatile pool with nonzero reserves, validate `AerodromeUtils` / `AerodromServiceVolatile` amount-out calculations against on-chain pool/router execution
- [x] Include tests for multiple trade sizes and both swap directions
- [x] Validate fee handling (Aerodrome uses a 10_000 denominator)

### US-CRANE-203.3: Stable Pool Quote Parity (Core Deliverable)

As a developer, I want stable pool quote math (solver) to match deployed pools.

**Acceptance Criteria:**
- [x] For an existing stable pool with nonzero reserves, validate `AerodromServiceStable` / `AerodromeUtils` amount-out calculations against on-chain pool/router execution
- [x] Include tests for multiple trade sizes and both swap directions

### US-CRANE-203.4: Minimal Execution Sanity

As a developer, I want one end-to-end swap test so failures show up as obvious execution issues.

**Acceptance Criteria:**
- [x] Execute one swap through the mainnet router on a known pool with a funded impersonated account
- [x] Assert balances change as expected and output amount matches quote within integer equality (when quoting method matches the router/pool)

## Technical Details

### Directory Structure

```
test/foundry/fork/base_main/
└── aerodrome/
    ├── TestBase_AerodromeFork.sol
    ├── AerodromeVolatileUtils_Fork.t.sol
    └── AerodromeStableUtils_Fork.t.sol
```

### Inventory Check

- [x] `contracts/constants/networks/BASE_MAIN.sol` contains Aerodrome addresses
- [x] `contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceVolatile.sol` exists
- [x] `contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol` exists
- [x] `contracts/utils/math/AerodromeUtils.sol` exists
- [x] `foundry.toml` includes `base_mainnet_infura`

## Completion Criteria

- [x] Tests pass: `forge test --match-path "test/foundry/fork/base_main/aerodrome/**"`
- [x] Tests skip gracefully when `INFURA_KEY` is not set

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
