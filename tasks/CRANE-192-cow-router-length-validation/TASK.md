# Task CRANE-192: Add Input Length Validation in CoW Router Settlement Paths

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-31
**Dependencies:** CRANE-146
**Worktree:** `fix/cow-router-length-validation`
**Origin:** Code review suggestion from CRANE-146

---

## Description

Add explicit `require` statements or custom errors to enforce array length validation in CoW router settlement paths:
- `donationAmounts.length == tokens.length`
- `transferAmountHints.length == tokens.length`

This prevents out-of-bounds reverts and provides clearer failure modes for callers. Currently, mismatched array lengths would cause opaque reverts when accessing array indices.

(Created from code review of CRANE-146)

## Dependencies

- CRANE-146: Refactor Balancer V3 CoW Pool Package (parent task, complete)

## User Stories

### US-CRANE-192.1: Validate Donation Amounts Array Length

As a caller, I want clear error messages when `donationAmounts` length doesn't match `tokens` length so that I can debug integration issues quickly.

**Acceptance Criteria:**
- [ ] Custom error defined: `error CowRouter_ArrayLengthMismatch(uint256 expected, uint256 actual)`
- [ ] Validation added before processing donation amounts
- [ ] Test verifies revert with correct error on mismatch

### US-CRANE-192.2: Validate Transfer Amount Hints Array Length

As a caller, I want clear error messages when `transferAmountHints` length doesn't match `tokens` length.

**Acceptance Criteria:**
- [ ] Validation added before processing transfer hints
- [ ] Test verifies revert with correct error on mismatch

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterTarget.sol`

**New/Modified Test Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/pools/cow/CowRouterFacet.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-146 is complete
- [ ] CowRouterTarget.sol exists

## Implementation Notes

1. Add custom error to reduce bytecode vs string reverts
2. Place validation early in function to fail fast
3. Consider bytecode size impact - this should be minimal with custom errors
4. Follow existing error naming patterns in the codebase

## Bytecode Size Consideration

The review notes this is a safety/usability improvement. Custom errors are more gas-efficient than string reverts and add minimal bytecode. Verify contract stays within 24KB limit after changes.

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Contract size verified within limits

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
