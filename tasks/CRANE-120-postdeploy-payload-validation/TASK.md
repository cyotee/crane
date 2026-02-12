# Task CRANE-120: Tighten postDeploy Call Expectations

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-061
**Worktree:** `feature/postdeploy-payload-validation`
**Origin:** Code review suggestion from CRANE-061 (Suggestion 3)

---

## Description

Validate the full `registerPool(...)` call payload (token configs, hooks, fee params, and caller) rather than only checking that a call happened.

Currently, the test asserts "registration happened" and "pool address matches," but does not assert the token config array content, the hooks contract, swap fee, pause window end, or the caller identity (e.g., `lastPoolFactory`).

The existing `MockBalancerV3Vault` already emits `PoolRegistered(...)`, so this can be done without invasive changes.

(Created from code review of CRANE-061)

## Dependencies

- CRANE-061: Add DFPkg Deployment Integration Test (parent task)

## User Stories

### US-CRANE-120.1: Assert registration caller identity

As a developer, I want to verify the caller identity during vault registration so that factory authorization is validated.

**Acceptance Criteria:**
- [ ] Test asserts `lastPoolFactory` equals expected factory address
- [ ] Tests pass with caller validation

### US-CRANE-120.2: Validate full registerPool payload

As a developer, I want to validate the full `registerPool(...)` call payload so that all parameters are verified.

**Acceptance Criteria:**
- [ ] Test validates token config array content
- [ ] Test validates hooks contract address
- [ ] Test validates swap fee parameters
- [ ] Test validates pause window end
- [ ] Optionally decode `PoolRegistered` event for full payload validation

## Files to Create/Modify

**Modified Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-061 is complete
- [ ] MockBalancerV3Vault emits PoolRegistered event
- [ ] Integration test file exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
