# Task CRANE-127: Assert Zero-Fee Outcome in Safe Boundary Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-18
**Dependencies:** CRANE-073
**Worktree:** `test/zero-fee-assertion`
**Origin:** Code review suggestion from CRANE-073

---

## Description

Tighten the "safe boundary" fee test (`test_calculateFeePortionForPosition_safeBoundary_succeeds`) to assert the expected zero-fee outcome for the chosen inputs.

Given the test's inputs where `claimable < initial`, the expected behavior is `feeA == 0` and `feeB == 0`. Currently the test checks bounds but not this specific expected outcome.

(Created from code review of CRANE-073)

## Dependencies

- CRANE-073: Tighten Non-Revert Assertions in Overflow Tests (parent task - complete)

## User Stories

### US-CRANE-127.1: Explicit Zero-Fee Assertion

As a developer, I want the safe boundary fee test to assert the expected zero-fee outcome so that the test verifies specific behavior rather than just bounds.

**Acceptance Criteria:**
- [ ] Add `assertEq(feeA, 0)` and `assertEq(feeB, 0)` assertions to `test_calculateFeePortionForPosition_safeBoundary_succeeds`
- [ ] Verify this matches expected mathematical behavior for the chosen inputs
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_OverflowBoundary.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-073 is complete
- [ ] Test file exists with the target test function

## Completion Criteria

- [ ] Zero-fee assertions added
- [ ] Mathematical justification documented in test comment
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
