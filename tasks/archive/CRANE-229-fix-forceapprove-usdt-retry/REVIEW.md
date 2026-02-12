# Code Review: CRANE-229

**Reviewer:** Claude (Code Review Agent)
**Review Started:** 2026-02-06
**Status:** Complete

---

## Clarifying Questions

No clarifying questions needed - the task is well-defined with clear acceptance criteria.

---

## Review Findings

### Finding 1: Fix is correct and minimal
**File:** `contracts/utils/SafeERC20.sol:85`
**Severity:** N/A (positive finding)
**Description:** The one-line change from `SafeTransferLib.safeApprove()` to `SafeTransferLib.safeApproveWithRetry()` is the correct fix. The `safeApproveWithRetry` function (SafeTransferLib.sol:411-438) contains the zero-first retry logic needed for USDT-like tokens. The function signature is identical except for the retry behavior, so this is a drop-in replacement with no API change.
**Status:** Resolved

### Finding 2: Both overloads are covered
**File:** `contracts/utils/SafeERC20.sol:93-95`
**Severity:** N/A (positive finding)
**Description:** The bool overload `forceApprove(IERC20, address, bool)` delegates to the uint256 overload at line 94, so fixing the uint256 overload at line 85 automatically fixes both. No additional changes needed.
**Status:** Resolved

### Finding 3: Full delegation chain verified
**Files:** `BetterSafeERC20.sol:69-71`, `SafeERC20.sol:84-86`, `SafeTransferLib.sol:411-438`
**Severity:** N/A (verification)
**Description:** Traced the complete call chain:
1. `BetterSafeERC20Harness.forceApprove()` -> `BetterSafeERC20.forceApprove()` (line 69)
2. `BetterSafeERC20.forceApprove()` -> `SafeERC20.forceApprove()` via `using SafeERC20 for IERC20` (line 35)
3. `SafeERC20.forceApprove()` -> `SafeTransferLib.safeApproveWithRetry()` (line 85, the fix)
4. `safeApproveWithRetry()` performs: try approve -> if fail -> approve(0) -> approve(value)
**Status:** Resolved

### Finding 4: Test correctly validates the fix
**File:** `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol:235-244`
**Severity:** N/A (positive finding)
**Description:** The test `test_forceApprove_usdtApprovalToken_overwritesExistingAllowance` properly:
1. Sets initial non-zero allowance (100 ether)
2. Asserts it was set correctly
3. Overwrites with new non-zero allowance (200 ether) - this is the case that previously failed
4. Asserts the new allowance is correct
The `vm.expectRevert` and BUG comment were correctly removed. The `MockERC20USDTApproval` mock correctly enforces `require(allowance == 0 || amount == 0)`, validating that `safeApproveWithRetry` actually performs the zero-first pattern.
**Status:** Resolved

### Finding 5: No missing test coverage
**File:** `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol`
**Severity:** Info
**Description:** The `safeIncreaseAllowance` and `safeDecreaseAllowance` functions also call `forceApprove` internally (SafeERC20.sol:53, 71), meaning they also benefit from this fix. However, the existing tests for these functions only use `standardToken` and `nonReturningToken`, not `usdtApprovalToken`. This means the zero-first retry path isn't tested through those entry points. This is acceptable for this task scope since `safeIncreaseAllowance` with USDT is an indirect path, but could be a follow-up improvement.
**Status:** Resolved (out of scope for this task)

---

## Suggestions

### Suggestion 1: Add USDT tests for safeIncreaseAllowance/safeDecreaseAllowance
**Priority:** Low
**Description:** `safeIncreaseAllowance` and `safeDecreaseAllowance` both call `forceApprove` internally, which means they now also handle USDT-like tokens correctly. Adding tests that exercise these paths with `MockERC20USDTApproval` would improve coverage and document this behavior.
**Affected Files:**
- `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-231

---

## Acceptance Criteria Checklist

- [x] `SafeERC20.forceApprove()` calls `SafeTransferLib.safeApproveWithRetry()` (verified at SafeERC20.sol:85)
- [x] `test_forceApprove_usdtApprovalToken_overwritesExistingAllowance` expects success (not `ApproveFailed`)
- [x] Test re-asserts the final allowance value is correct after `forceApprove` (line 243)
- [x] All other BetterSafeERC20 tests still pass (37/37 pass)
- [x] No regression in other tests (only 2 files changed, both in SafeERC20 scope)
- [x] Both forceApprove overloads work (bool delegates to uint256 at SafeERC20.sol:94)
- [x] Build succeeds with no new warnings

## Review Summary

**Findings:** 5 (all resolved/positive)
**Suggestions:** 1 (low priority, out of scope)
**Recommendation:** **APPROVE** - The change is correct, minimal, well-tested, and addresses the exact bug described in the task. The one-line fix properly routes `forceApprove` through Solady's `safeApproveWithRetry` which includes the zero-first retry logic required by USDT-like tokens. All 37 BetterSafeERC20 tests pass.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
