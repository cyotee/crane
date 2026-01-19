# Task CRANE-081: Add SqrtPriceMath Custom Error Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-033
**Worktree:** `test/sqrtpricemath-errors`
**Origin:** Code review suggestion from CRANE-033

---

## Description

Add explicit tests for remaining SqrtPriceMath custom errors: `NotEnoughLiquidity()` and `PriceOverflow()`. These are minimal deterministic test cases to cover the assembly-based guard rails.

(Created from code review of CRANE-033)

## Dependencies

- CRANE-033: Add Uniswap V4 Pure Math Unit Tests (Complete - parent task)

## User Stories

### US-CRANE-081.1: Add Error Revert Tests

As a developer, I want explicit tests for SqrtPriceMath error conditions so that the assembly-based guard rails are verified.

**Acceptance Criteria:**
- [x] Test case for `NotEnoughLiquidity()` revert
- [x] Test case for `PriceOverflow()` revert
- [x] Tests are small and targeted (no fuzzing required)
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-033 is complete
- [x] SqrtPriceMath.t.sol exists

## Completion Criteria

- [x] All acceptance criteria met
- [x] `forge test --match-path 'test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.t.sol'` passes
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
