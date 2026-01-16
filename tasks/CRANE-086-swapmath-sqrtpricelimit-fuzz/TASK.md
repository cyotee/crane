# Task CRANE-086: Add Explicit sqrtPriceLimit Bound Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-034
**Worktree:** `test/swapmath-sqrtpricelimit-fuzz`
**Origin:** Code review suggestion from CRANE-034

---

## Description

Add a fuzz test that generates `(sqrtPriceCurrentX96, sqrtPriceNextTickX96, sqrtPriceLimitX96)`, derives `sqrtPriceTargetX96 = getSqrtPriceTarget(zeroForOne, sqrtPriceNextTickX96, sqrtPriceLimitX96)`, then asserts `sqrtPriceNextX96` returned by `computeSwapStep` never crosses `sqrtPriceLimitX96`.

The current tests bound `sqrtPriceNextX96` vs the *target*, which is correct for `computeSwapStep` in isolation, but an explicit limit-based assertion maps 1:1 to the acceptance criterion wording and validates the intended call composition used by pool swap loops.

(Created from code review of CRANE-034)

## Dependencies

- CRANE-034: Add Uniswap V4 SwapMath Fuzz Tests (Complete - parent task)

## User Stories

### US-CRANE-086.1: Add sqrtPriceLimit Bound Fuzz Test

As a developer, I want a fuzz test that validates sqrtPriceNextX96 never crosses sqrtPriceLimitX96 so that the swap loop composition is validated.

**Acceptance Criteria:**
- [ ] Fuzz test generates (sqrtPriceCurrentX96, sqrtPriceNextTickX96, sqrtPriceLimitX96)
- [ ] Test derives sqrtPriceTargetX96 via getSqrtPriceTarget
- [ ] Test asserts sqrtPriceNextX96 never crosses sqrtPriceLimitX96
- [ ] Tests pass with default fuzz runs
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-034 is complete
- [x] SwapMath.fuzz.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` succeeds
- [ ] Tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
