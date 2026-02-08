# Task CRANE-242: Add Fix-Up Sanity Assertion to FoT Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** CRANE-102
**Worktree:** `test/fixup-sanity-assertion`
**Origin:** Code review suggestion from CRANE-102

---

## Description

The fix-up input tests in CRANE-102 compute `requiredInput = quotedInput * 10000 / (10000 - taxBps)` but don't explicitly assert that the fix-up exceeds the naive quote. Adding `assertGt(requiredInput, quotedInput)` makes the test self-documenting about *why* the fix-up is needed.

(Created from code review of CRANE-102)

## Dependencies

- CRANE-102: Strengthen _purchaseQuote() Tests with Fix-Up Input Verification (complete)

## User Stories

### US-CRANE-242.1: Add Self-Documenting Sanity Assertion

As a developer, I want an explicit assertion that the fix-up input exceeds the naive quote, so that the test clearly documents the purpose of the fix-up formula.

**Acceptance Criteria:**
- [ ] Add `assertGt(requiredInput, quotedInput, "Fix-up should exceed naive quote for non-zero tax")` after the fix-up computation in deterministic tests
- [ ] Add the same assertion in the fuzz test
- [ ] No other logic changes
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol - Add assertGt assertions

## Inventory Check

Before starting, verify:
- [ ] CamelotV2_feeOnTransfer.t.sol exists
- [ ] Fix-up tests from CRANE-102 are present

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
