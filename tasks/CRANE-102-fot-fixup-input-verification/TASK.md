# Task CRANE-102: Strengthen _purchaseQuote() Tests with Fix-Up Input Verification

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-047
**Worktree:** `test/fot-fixup-input-verification`
**Origin:** Code review suggestion from CRANE-047

---

## Description

Strengthen `_purchaseQuote()` tests by proving the "fix-up input" calculation works. Currently, the deterministic tests compute a `requiredInput` estimate (quotedInput adjusted by `(1-tax)^-1`) but never execute a swap with that input to demonstrate it achieves the desired output.

Adding a second swap (with fresh pool or reset state) would make the underestimation story airtight.

(Created from code review of CRANE-047)

## Dependencies

- CRANE-047: Add Fee-on-Transfer Token Integration Tests (parent task - complete)

## User Stories

### US-CRANE-102.1: Fix-Up Input Verification

As a developer, I want FoT tests to prove the corrected input calculation actually achieves the desired output so that the underestimation fix is verified end-to-end.

**Acceptance Criteria:**
- [ ] Add test that computes `requiredInput` from `quotedInput` adjustment
- [ ] Execute swap with `requiredInput` on fresh pool state
- [ ] Assert received output equals (or is within rounding of) `desiredOutput`
- [ ] Ensure state isolation (fresh pair per test or snapshot/revert)
- [ ] Tests pass
- [ ] Build succeeds

## Technical Details

**Fix-Up Formula:**
```solidity
// quotedInput underestimates because pool receives less
// requiredInput = quotedInput / (1 - taxRate)
uint256 requiredInput = quotedInput * 10000 / (10000 - taxBps);
```

**Test Pattern:**
1. Get `quotedInput` from `_purchaseQuote()`
2. Compute `requiredInput` with tax adjustment
3. Create fresh pool state (snapshot/revert or new pair)
4. Execute swap with `requiredInput`
5. Assert received >= desiredOutput

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol

## Inventory Check

Before starting, verify:
- [ ] CamelotV2_feeOnTransfer.t.sol exists
- [ ] `_purchaseQuote()` tests exist

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
