# Task CRANE-114: Add Explicit Negative Tests for Weight Validation

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-055
**Worktree:** `test/weight-validation-negative-tests`
**Origin:** Code review suggestion from CRANE-055

---

## Description

Add unit tests that explicitly assert reverts for `ZeroWeight()` and `WeightsMustSumToOne()` errors during weighted pool initialization. This strengthens regression coverage for the weight validation behavior implemented in CRANE-055.

(Created from code review of CRANE-055 - Suggestion 2)

## Dependencies

- CRANE-055: Implement Balancer V3 Weighted Pool Facet/Target (parent task)

## User Stories

### US-CRANE-114.1: Add zero weight revert test

As a developer, I want tests for zero weight rejection so that the validation behavior is explicitly documented and protected from regression.

**Acceptance Criteria:**
- [ ] Add test asserting `ZeroWeight()` revert when any weight is 0
- [ ] Test covers various zero weight positions (first, middle, last)
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-114.2: Add weights-must-sum-to-one revert test

As a developer, I want tests for weight sum validation so that invalid weight configurations are explicitly rejected.

**Acceptance Criteria:**
- [ ] Add test asserting `WeightsMustSumToOne()` revert when weights don't sum to 1e18
- [ ] Test covers under-sum and over-sum cases
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New or Modified Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.t.sol (new or extend existing)

## Inventory Check

Before starting, verify:
- [ ] CRANE-055 is complete/archived
- [ ] `ZeroWeight()` error exists in BalancerV3WeightedPoolRepo.sol
- [ ] Existing weighted pool tests exist as reference

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests follow Crane testing patterns
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
