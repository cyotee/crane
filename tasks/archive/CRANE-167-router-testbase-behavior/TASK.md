# Task CRANE-167: Add TestBase and Behavior Patterns to Router Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-29
**Dependencies:** CRANE-142
**Worktree:** `test/router-testbase-behavior`
**Origin:** Code review finding 11 from CRANE-142

---

## Description

Add TestBase and Behavior library patterns to Balancer V3 Router tests per AGENTS.md testing conventions.

**Problem:**
AGENTS.md requires:
1. `TestBase_*.sol` files in `contracts/` alongside code
2. `Behavior_*.sol` libraries for validation logic
3. Test specs in `test/foundry/spec/` mirroring `contracts/` structure

Currently missing:
- `TestBase_BalancerV3Router.sol`
- `Behavior_IRouter.sol`

**Solution:**
Create TestBase contract with router setup utilities and Behavior library with validation assertions that can be reused across router tests.

(Created from code review of CRANE-142)

## Dependencies

- CRANE-142: Refactor Balancer V3 Router as Diamond Facets (parent task) - Complete

## User Stories

### US-CRANE-167.1: Create TestBase for Router

As a developer, I want a TestBase for the router so that test setup is reusable.

**Acceptance Criteria:**
- [x] `TestBase_BalancerV3Router.sol` created
- [x] Provides router deployment utilities
- [x] Provides mock vault and token setup
- [x] Provides common test fixtures
- [x] Build succeeds

### US-CRANE-167.2: Create Behavior Library for Router

As a developer, I want a Behavior library so that validation logic is centralized.

**Acceptance Criteria:**
- [x] `Behavior_IRouter.sol` created
- [x] Contains swap validation assertions (router interface validation)
- [x] Contains liquidity validation assertions (vault configuration validation)
- [x] Contains batch operation validations (facet size, facet cuts, deployment)
- [x] Build succeeds

### US-CRANE-167.3: Refactor Existing Tests to Use Patterns

As a developer, I want existing tests to use TestBase/Behavior so that patterns are adopted.

**Acceptance Criteria:**
- [x] `BalancerV3RouterDFPkg.t.sol` extends TestBase
- [x] Tests use Behavior library for assertions
- [x] All tests pass (17/17)
- [x] Build succeeds

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/TestBase_BalancerV3Router.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/Behavior_IRouter.sol`

**Modified Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-142 is complete
- [x] Review AGENTS.md TestBase/Behavior patterns
- [x] Review existing Crane TestBase examples

## Completion Criteria

- [x] All acceptance criteria met
- [x] TestBase and Behavior patterns implemented
- [x] Existing tests refactored
- [x] All tests pass (17/17)
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
