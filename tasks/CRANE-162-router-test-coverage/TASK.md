# Task CRANE-162: Expand Balancer V3 Router Test Coverage

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-29
**Dependencies:** CRANE-142
**Worktree:** `test/router-functional-tests`
**Origin:** Code review suggestion from CRANE-142

---

## Description

Expand test coverage for the Balancer V3 Router Diamond to satisfy TASK.md acceptance criteria. Current tests (`BalancerV3RouterDFPkg.t.sol`) validate DFPkg deployment, initialization, IFacet compliance, and facet size constraints.

Missing test coverage includes:
- Single-hop and multi-hop swap functional tests
- Slippage and deadline enforcement tests
- Batch swaps with hooks
- Composite nested and ERC4626 flows
- Buffer integration tests
- Fork-based parity tests against upstream Balancer router

(Created from code review of CRANE-142)

## Dependencies

- CRANE-142: Refactor Balancer V3 Router as Diamond Facets (parent task) - Complete

## User Stories

### US-CRANE-162.1: Add Single/Multi-Hop Swap Tests

As a developer, I want comprehensive swap tests so that router functionality is validated beyond deployment.

**Acceptance Criteria:**
- [ ] Single-hop swap tests (exactIn, exactOut)
- [ ] Multi-hop swap tests with intermediate tokens
- [ ] Slippage protection assertion tests
- [ ] Deadline enforcement tests
- [ ] Tests pass

### US-CRANE-162.2: Add Batch and Composite Flow Tests

As a developer, I want batch and composite flow tests so that complex router operations are validated.

**Acceptance Criteria:**
- [ ] Batch swap tests with hooks
- [ ] Composite nested pool flow tests
- [ ] ERC4626 wrap/unwrap flow tests
- [ ] Buffer integration tests
- [ ] Tests pass

### US-CRANE-162.3: Add Fork-Based Parity Tests

As a developer, I want fork tests comparing our router to upstream Balancer so that functional equivalence is proven.

**Acceptance Criteria:**
- [ ] Fork test setup against Base mainnet
- [ ] Swap parity tests (same inputs produce same outputs)
- [ ] Gas comparison tests
- [ ] Tests pass

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/RouterSwapFacet.t.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/RouterBatchFacet.t.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/RouterCompositeFacet.t.sol`
- `test/foundry/fork/protocols/dexes/balancer/v3/router/RouterParity.t.sol`

**Modified Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-142 is complete
- [ ] Router DFPkg deploys successfully
- [ ] All facets are accessible via diamond

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Functional tests cover swap, batch, composite flows
- [ ] Fork tests demonstrate parity with upstream
- [ ] All tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
