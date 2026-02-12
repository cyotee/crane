# Task CRANE-130: Add Direction Assertion to SwapMath Fully-Spent Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-18
**Dependencies:** CRANE-080
**Worktree:** `fix/swapmath-direction-assertion`
**Origin:** Code review suggestion from CRANE-080

---

## Description

In `test_goldenVector_exactIn_oneForZero_fullySpent`, add an assertion that `sqrtPriceNext > sqrtPriceCurrent` (or `>=`) to make the directionality explicit in addition to the "did not reach target" assertion. The test already validates the exact outputs, so this is optional, but it makes intent clearer.

(Created from code review of CRANE-080)

## Dependencies

- CRANE-080: Add SwapMath Golden Vector Tests (parent task - Complete)

## User Stories

### US-CRANE-130.1: Explicit Direction Verification

As a developer, I want the swap direction to be explicitly asserted in test cases so that the test intent is immediately clear and any direction bugs are caught.

**Acceptance Criteria:**
- [ ] Add `assertGe(sqrtPriceNext, sqrtPriceCurrent)` or similar assertion in `test_goldenVector_exactIn_oneForZero_fullySpent`
- [ ] Comment explains why direction assertion is included
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-080 is complete
- [x] SwapMath.t.sol exists with `test_goldenVector_exactIn_oneForZero_fullySpent` test

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
