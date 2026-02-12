# Task CRANE-140: Align Fee Test Naming with Assertions

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-21
**Dependencies:** CRANE-088
**Worktree:** `fix/swapmath-fee-test-rename`
**Origin:** Code review suggestion from CRANE-088

---

## Description

Rename `testFuzz_computeSwapStep_feeNonNegative` and update its NatSpec to reflect what it actually tests. The test no longer asserts non-negativity (which is always true for uint256); it now asserts `feePips == 0 => feeAmount == 0`. The name and documentation should match the actual assertion.

(Created from code review of CRANE-088)

## Dependencies

- CRANE-088: Remove Minor Test Cruft from SwapMath Fuzz Tests (Complete - parent task)

## User Stories

### US-CRANE-140.1: Rename Fee Test for Clarity

As a developer, I want test names to accurately describe what they test so that the test suite is self-documenting and easy to understand.

**Acceptance Criteria:**
- [ ] Rename `testFuzz_computeSwapStep_feeNonNegative` to reflect actual assertion (e.g., `testFuzz_computeSwapStep_zeroFeePipsImpliesZeroFeeAmount`)
- [ ] Update NatSpec comment to describe the actual invariant being tested
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-088 is complete
- [x] SwapMath.fuzz.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` succeeds
- [ ] Tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
