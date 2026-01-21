# Task CRANE-137: Remove Redundant vm.assume in SwapMath Fuzz Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-21
**Dependencies:** CRANE-086
**Worktree:** `fix/swapmath-redundant-assume`
**Origin:** Code review suggestion from CRANE-086

---

## Description

Lines 438-444 of the SwapMath fuzz test use `vm.assume()` to enforce direction constraints on `sqrtPriceLimitX96`. However, since `zeroForOne` is derived from `sqrtPriceLimitX96 < sqrtPriceCurrentX96` on line 434, the subsequent `vm.assume()` calls are logically redundant (if zeroForOne is true, then limit is already < current by definition).

The `vm.assume()` calls do correctly skip edge cases where limit == current (neither strictly less nor greater), which is valid behavior. The current implementation is correct but could be simplified.

(Created from code review of CRANE-086)

## Dependencies

- CRANE-086: Add Explicit sqrtPriceLimit Bound Test (Complete - parent task)

## User Stories

### US-CRANE-137.1: Simplify Redundant Assumptions

As a developer, I want to remove redundant vm.assume() calls so that the test code is cleaner while maintaining the same behavior.

**Acceptance Criteria:**
- [ ] Remove redundant vm.assume() calls that duplicate the zeroForOne derivation logic
- [ ] Keep the edge case exclusion (limit == current) behavior
- [ ] Tests pass with same fuzz run count
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol:438-444

## Inventory Check

Before starting, verify:
- [x] CRANE-086 is complete
- [ ] SwapMath.fuzz.t.sol exists with the vm.assume() calls

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-path '**/uniswap/v4/libraries/SwapMath.fuzz.t.sol'` passes
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
