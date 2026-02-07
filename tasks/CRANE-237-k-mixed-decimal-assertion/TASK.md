# Task CRANE-237: Add k() Assertion for Mixed-Decimal Pair

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** CRANE-099
**Worktree:** `test/k-mixed-decimal-assertion`
**Origin:** Code review suggestion from CRANE-099

---

## Description

Add a direct `assertEq` test for `k()` on the `mixedDecimalPair` (6+8 decimals) to verify that the precision-multiplier normalization in `_k()` works correctly across decimal combinations. Currently, `test_cubicInvariant_calculation` only tests the 18-decimal pair.

(Created from code review of CRANE-099)

## Dependencies

- CRANE-099: Add Direct Assertion for Cubic Invariant _k() (parent task)

## User Stories

### US-CRANE-237.1: Verify k() with mixed-decimal tokens

As a developer, I want to directly assert the cubic invariant `_k()` formula on a mixed-decimal pair so that precision-multiplier normalization is validated against the expected formula.

**Acceptance Criteria:**
- [ ] Test calls `k()` on a mixed-decimal pair (6+8 decimals) and asserts against the expected cubic invariant formula
- [ ] Expected K computation applies precision multipliers to normalize balances to 18 decimals before applying `xy(x^2 + y^2)`
- [ ] Assertion uses `assertEq` for exact match
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_stableSwap.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-099 is complete
- [ ] `CamelotPair.sol` has `k()` wrapper function
- [ ] `mixedDecimalPair` fixture exists in the test file

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
