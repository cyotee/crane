# Task CRANE-174: Add Router getWeth/getPermit2 Validation

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-167
**Worktree:** `test/router-weth-permit2-validation`
**Origin:** Code review suggestion from CRANE-167

---

## Description

Add Behavior helpers and tests for `IRouterCommon.getWeth()` and `IRouterCommon.getPermit2()` to match the existing `getVault()` validation pattern. Currently, the TestBase deploys mocks for WETH and Permit2 but the Behavior library only validates `getVault()`, leaving part of the router's common configuration unverified.

(Created from code review of CRANE-167)

## Dependencies

- CRANE-167: Add TestBase and Behavior Patterns to Router Tests (parent task - Complete)

## User Stories

### US-CRANE-174.1: Add getWeth Validation

As a developer, I want Behavior helpers for `getWeth()` validation so that router WETH configuration is verified consistently.

**Acceptance Criteria:**
- [ ] Add `expect_IRouterCommon_getWeth()` to Behavior_IRouter.sol
- [ ] Add `hasValid_IRouterCommon_getWeth()` to Behavior_IRouter.sol
- [ ] Add `isValid_IRouterCommon_getWeth()` to Behavior_IRouter.sol
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-174.2: Add getPermit2 Validation

As a developer, I want Behavior helpers for `getPermit2()` validation so that router Permit2 configuration is verified consistently.

**Acceptance Criteria:**
- [ ] Add `expect_IRouterCommon_getPermit2()` to Behavior_IRouter.sol
- [ ] Add `hasValid_IRouterCommon_getPermit2()` to Behavior_IRouter.sol
- [ ] Add `isValid_IRouterCommon_getPermit2()` to Behavior_IRouter.sol
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-174.3: Add Test Coverage

As a developer, I want tests that verify getWeth/getPermit2 configuration so that router initialization is fully covered.

**Acceptance Criteria:**
- [ ] Add tests mirroring the `getVault()` checks in BalancerV3RouterDFPkg.t.sol
- [ ] Tests verify WETH address matches deployed mock
- [ ] Tests verify Permit2 address matches deployed mock
- [ ] All tests pass

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/Behavior_IRouter.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-167 is complete
- [ ] Behavior_IRouter.sol exists with getVault() pattern
- [ ] TestBase_BalancerV3Router.sol deploys WETH and Permit2 mocks

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
