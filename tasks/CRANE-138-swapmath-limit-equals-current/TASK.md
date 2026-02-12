# Task CRANE-138: Test SwapMath Edge Case Where Limit Equals Current

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-21
**Dependencies:** CRANE-086
**Worktree:** `test/swapmath-limit-equals-current`
**Origin:** Code review suggestion from CRANE-086

---

## Description

The sqrtPriceLimit fuzz test explicitly excludes the case where `sqrtPriceLimitX96 == sqrtPriceCurrentX96` via the `vm.assume()` constraints. This edge case (where the swap is already at the limit) could be worth testing separately to verify the library handles it gracefully.

(Created from code review of CRANE-086)

## Dependencies

- CRANE-086: Add Explicit sqrtPriceLimit Bound Test (Complete - parent task)

## User Stories

### US-CRANE-138.1: Test Limit Equals Current Edge Case

As a developer, I want to verify that SwapMath handles the edge case where the limit equals the current price so that I know the library behaves gracefully in this boundary condition.

**Acceptance Criteria:**
- [ ] Add test case for `sqrtPriceLimitX96 == sqrtPriceCurrentX96`
- [ ] Document expected behavior (likely no swap occurs or specific handling)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-086 is complete
- [ ] SwapMath.fuzz.t.sol exists
- [ ] Understand expected behavior when limit == current from Uniswap V4 source

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-path '**/uniswap/v4/libraries/SwapMath.fuzz.t.sol'` passes
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
