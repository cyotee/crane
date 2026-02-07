# Task CRANE-099: Add Direct Assertion for Cubic Invariant _k()

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-045
**Worktree:** `test/stableswap-k-assertion`
**Origin:** Code review suggestion from CRANE-045

---

## Description

Add a direct assertion for the cubic invariant `_k()` in stable swap tests. Currently, `test_cubicInvariant_calculation()` computes `expectedK` but never asserts it against an on-chain value. The test checks `getAmountOut()` is close to input minus fee, which doesn't actually prove `_k()` implements the correct formula.

(Created from code review of CRANE-045)

## Dependencies

- CRANE-045: Add Camelot V2 Stable Swap Pool Tests (parent task - complete)

## User Stories

### US-CRANE-099.1: Cubic Invariant Direct Assertion

As a developer, I want the stable swap tests to directly assert the cubic invariant formula so that bugs in `_k()` implementation are caught by regression tests.

**Acceptance Criteria:**
- [ ] Add testing-only view method `k()` on CamelotPair stub returning `_k(reserve0, reserve1)`
- [ ] Update `test_cubicInvariant_calculation()` to compare computed expectedK against stub's `k()` return value
- [ ] Assert the formula: `xy(x^2 + y^2)` or equivalent `x^3y + y^3x`
- [ ] Test fails if `_k()` math changes unexpectedly
- [ ] Tests pass
- [ ] Build succeeds

## Technical Details

**Cubic Invariant Formula:**
```solidity
// Normalized form
k = x * y * (x^2 + y^2)
// Or equivalent
k = x^3 * y + y^3 * x
```

**Approach:**
1. Add `k()` view method to CamelotPair stub
2. Compute expected K in test using same formula
3. Assert expected K matches stub's `k()` return

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_stableSwap.t.sol
- contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol (add `k()` helper)

## Inventory Check

Before starting, verify:
- [ ] CamelotV2_stableSwap.t.sol exists
- [ ] CamelotPair.sol stub has `_k()` internal function
- [ ] `test_cubicInvariant_calculation()` test exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
