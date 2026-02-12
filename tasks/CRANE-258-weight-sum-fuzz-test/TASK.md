# Task CRANE-258: Add Fuzz Test for Weight Sum Validation

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-114
**Worktree:** `test/CRANE-258-weight-sum-fuzz-test`
**Origin:** Code review suggestion from CRANE-114

---

## Description

Add a fuzz test that generates N weights (2-8 tokens) summing to exactly `FixedPoint.ONE` and confirms `_initialize()` succeeds without reverting. This complements the existing deterministic negative tests in CRANE-114 by verifying that valid weight combinations are never incorrectly rejected.

(Created from code review of CRANE-114 - Suggestion 1)

## Dependencies

- CRANE-114: Add Explicit Negative Tests for Weight Validation (parent task)

## User Stories

### US-CRANE-258.1: Add fuzz test for valid weight sums

As a developer, I want a fuzz test that generates valid weight combinations so that I have confidence no valid pool configuration is incorrectly rejected by the weight validation logic.

**Acceptance Criteria:**
- [ ] Add fuzz test that generates 2-8 weights summing to exactly `FixedPoint.ONE`
- [ ] Test confirms `_initialize()` succeeds for all fuzzed inputs
- [ ] Test verifies stored weights match the input weights after initialization
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-114 is complete
- [ ] `BalancerV3WeightedPoolRepo.t.sol` exists with existing deterministic tests
- [ ] `FixedPoint.ONE` constant is available

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
