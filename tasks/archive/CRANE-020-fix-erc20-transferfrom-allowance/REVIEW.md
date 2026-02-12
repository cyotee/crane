# Code Review: CRANE-020

**Reviewer:** Claude Agent
**Review Started:** 2026-01-14
**Review Completed:** 2026-01-14
**Status:** Complete

---

## Review Checklist

### Deliverables Present
- [x] `ERC20Target.transferFrom()` calls `_transferFrom()`
- [x] New test for unauthorized transfer revert
- [x] Test for exceeds allowance revert
- [x] Test for allowance deduction

### Quality Checks
- [x] Fix is minimal and targeted (single line change)
- [x] No regressions introduced (124 tests pass)
- [x] Tests cover the specific bug scenarios

### Build Verification
- [x] `forge build` passes
- [x] `forge test` passes (124 ERC20 tests)

---

## Verification Details

### Implementation Review

**File:** `contracts/tokens/ERC20/ERC20Target.sol:37-39`

```solidity
function transferFrom(address owner, address recipient, uint256 amount) external returns (bool) {
    ERC20Repo._transferFrom(owner, recipient, amount);
    return true;
}
```

✅ **Correct:** Calls `_transferFrom()` which internally:
1. Calls `_spendAllowance(layout, owner, msg.sender, amount)` (line 133)
2. Then calls `_transfer(layout, owner, recipient, amount)` (line 135)

The allowance check occurs in `_spendAllowance()` (lines 74-84) which:
- Reverts with `ERC20InsufficientAllowance` if allowance < amount
- Deducts the amount from the allowance via `_approve()`

### Test Coverage Verification

**File:** `test/foundry/spec/tokens/ERC20/ERC20Target_EdgeCases.t.sol`

| Test | Purpose | Verified |
|------|---------|----------|
| `test_transferFrom_withoutAllowance_reverts()` | No approval = revert | ✅ |
| `test_transferFrom_exceedsAllowance_reverts()` | Partial approval enforced | ✅ |
| `test_transferFrom_decreasesAllowance()` | Allowance deducted correctly | ✅ |
| `test_transferFrom_withAllowance_succeeds()` | Happy path + zero allowance after | ✅ |

### Invariant Test Verification

All invariant tests pass:
- `invariant_allowances_consistent()` - Confirms handler's expected allowances match actual
- `invariant_totalSupply_equals_sumBalances()` - Total supply preserved
- `invariant_nonnegative()` - No underflows

---

## Acceptance Criteria Status

From TASK.md:

- [x] `ERC20Target.transferFrom()` calls `ERC20Repo._transferFrom()` instead of `_transfer()`
- [x] Allowance is properly deducted after successful transfer
- [x] Transfer reverts when allowance is insufficient
- [x] Existing tests pass
- [x] New test verifies unauthorized transfer reverts

---

## Review Findings

No issues found. The fix is correct and complete.

---

## Suggestions

### Suggestion 1: TASK.md example signature discrepancy
**Priority:** P3 (docs)
**Description:** TASK.md shows `_transferFrom(msg.sender, owner, recipient, amount)` with explicit spender parameter, but the actual `ERC20Repo._transferFrom()` derives spender from `msg.sender` internally (3 params: owner, recipient, amount).
**Affected Files:**
- `tasks/CRANE-020-fix-erc20-transferfrom-allowance/TASK.md`
**Impact:** None on implementation correctness; documentation-only.
**Notes:** The implemented fix is correct despite the TASK.md example being slightly different from the actual API.

---

## Review Summary

**Findings:** 0
**Suggestions:** 1 (P3 docs-only)
**Test Results:** 124/124 pass
**Recommendation:** **APPROVE**

The critical security vulnerability has been fixed correctly. The implementation ensures:
1. Allowance is checked before any transfer via `transferFrom()`
2. Allowance is properly deducted after successful transfer
3. Transfers without sufficient allowance revert with `ERC20InsufficientAllowance`

---

<promise>REVIEW_COMPLETE</promise>
