# Task CRANE-241: Add FoT Output Token Fix-Up Verification Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** CRANE-102
**Worktree:** `test/fot-output-fixup-verification`
**Origin:** Code review suggestion from CRANE-102

---

## Description

CRANE-102 verified fix-up input adjustment when the FoT token is the *input* token (selling FoT to buy standard). There is a complementary scenario: when the *output* token is FoT, `_saleQuote()` overestimates because the recipient gets less than the pool sends. Add tests verifying a corresponding fix-down: `actualReceived = quotedOutput * (10000 - taxBps) / 10000`.

(Created from code review of CRANE-102)

## Dependencies

- CRANE-102: Strengthen _purchaseQuote() Tests with Fix-Up Input Verification (complete)

## User Stories

### US-CRANE-241.1: Verify FoT Output Token Sale Quote Adjustment

As a developer, I want tests that verify the sale quote fix-down formula for FoT output tokens, so that integrators know the expected adjustment when the output token has a transfer tax.

**Acceptance Criteria:**
- [ ] Add deterministic tests for 1%, 5%, and 10% tax rates on the output token
- [ ] Compute `actualReceived = quotedOutput * (10000 - taxBps) / 10000` and verify against swap result
- [ ] Add fuzz test covering tax range [1, 5000] bps
- [ ] Assert `actualReceived <= quotedOutput` (fix-down always reduces)
- [ ] Assert actual swap output matches the fix-down estimate within 1 wei
- [ ] State isolation: fresh pair or snapshot/revert per test
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol - Add new test section

## Inventory Check

Before starting, verify:
- [ ] CamelotV2_feeOnTransfer.t.sol exists
- [ ] Existing FoT test helpers work for output-token scenarios

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
