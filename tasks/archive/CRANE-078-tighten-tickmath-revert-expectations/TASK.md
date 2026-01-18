# Task CRANE-078: Tighten TickMath Revert Expectations

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-032
**Worktree:** `fix/tickmath-revert-expectations`
**Origin:** Code review suggestion from CRANE-032 (Suggestion 1)

---

## Description

Replace bare `vm.expectRevert()` calls with explicit revert reasons in the TickMath fuzz tests. This makes failures more diagnostic and reduces the chance of masking unrelated reverts.

(Created from code review of CRANE-032)

## Dependencies

- CRANE-032: Add TickMath Bijection Fuzz Tests (parent task - completed)

## User Stories

### US-CRANE-078.1: Explicit Revert Expectations

As a developer, I want TickMath tests to use explicit revert reasons so that test failures are more diagnostic and don't mask unrelated reverts.

**Acceptance Criteria:**
- [ ] Replace `vm.expectRevert()` with `vm.expectRevert(bytes("T"))` for out-of-range tick inputs to `getSqrtRatioAtTick`
- [ ] Replace `vm.expectRevert()` with `vm.expectRevert(bytes("R"))` for out-of-range sqrtPrice inputs to `getTickAtSqrtRatio`
- [ ] Verify revert reasons match the actual TickMath library behavior
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v3/libraries/TickMath.t.sol

**Reference Files:**
- lib/v3-core/contracts/libraries/TickMath.sol (check actual revert reasons)

## Inventory Check

Before starting, verify:
- [x] CRANE-032 is complete
- [x] TickMath.t.sol exists with revert tests

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test --match-path test/foundry/spec/protocols/dexes/uniswap/v3/libraries/TickMath.t.sol`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
