# Task CRANE-026: Strengthen Overflow Boundary Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-006
**Worktree:** `test/overflow-boundary-tests`
**Origin:** Code review suggestion from CRANE-006

---

## Description

The new invariant test file includes "near overflow" cases, but the chosen magnitudes (`1e38`) likely do not exercise true overflow risk in `_saleQuote` (given the extra feeDenominator scaling).

Add explicit overflow-expecting tests for:
1. The quadratic path in `_swapDepositSaleAmt`
2. Multi-multiply paths such as `_calculateFeePortionForPosition`

The goal is to assert "reverts (no wrap)", especially around multi-multiply expressions. It's fine to accept reverts on overflow; the value is proving that checked arithmetic catches the overflow rather than wrapping.

(Created from code review of CRANE-006)

## Dependencies

- CRANE-006: Constant Product & Bonding Math Review (parent task - now archived)

## User Stories

### US-CRANE-026.1: Prove Overflow Safety in ConstProdUtils

As a developer relying on ConstProdUtils, I want tests proving that overflow conditions revert cleanly so that I can trust the library won't produce silently incorrect results.

**Acceptance Criteria:**
- [ ] Add tests for quadratic path overflow in `_swapDepositSaleAmt`
- [ ] Add tests for multi-multiply overflow in `_calculateFeePortionForPosition`
- [ ] Use `vm.expectRevert()` to prove revert behavior (not wrap)
- [ ] Document which input magnitudes trigger overflow
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_InvariantPreservation.t.sol`

OR

**New Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_OverflowBoundary.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-006 is complete (archived)
- [ ] Affected test file exists: `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_InvariantPreservation.t.sol`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
