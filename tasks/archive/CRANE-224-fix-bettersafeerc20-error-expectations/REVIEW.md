# Code Review: CRANE-224

**Reviewer:** Claude (Code Review Agent)
**Review Started:** 2026-02-06
**Status:** Complete

---

## Clarifying Questions

No clarifying questions needed. The task requirements, error propagation chain, and implementation are all clearly documented.

---

## Review Findings

### Finding 1: All 5 error expectations correctly updated
**File:** `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol`
**Severity:** N/A (Correct)
**Description:** Each of the 5 test fixes was traced through the full delegation chain:

| Test | Old Expectation | New Expectation | Delegation Chain | Correct? |
|------|----------------|-----------------|------------------|----------|
| `test_safeTransfer_revertingToken_reverts` | `"Transfer not allowed"` | `SafeTransferLib.TransferFailed.selector` | Harness -> BetterSafeERC20.safeTransfer -> SafeERC20.safeTransfer -> SafeTransferLib.safeTransfer (assembly catches revert, emits TransferFailed) | Yes |
| `test_safeTransfer_falseReturningToken_whenFalse_reverts` | `SafeERC20.SafeERC20FailedOperation(address)` | `SafeTransferLib.TransferFailed.selector` | Harness -> BetterSafeERC20.safeTransfer -> SafeERC20.safeTransfer -> SafeTransferLib.safeTransfer (assembly sees return value != 1, emits TransferFailed) | Yes |
| `test_safeTransfer_insufficientBalance_reverts` | `"Insufficient balance"` | `SafeTransferLib.TransferFailed.selector` | Harness -> BetterSafeERC20.safeTransfer -> SafeERC20.safeTransfer -> SafeTransferLib.safeTransfer (assembly catches revert, emits TransferFailed) | Yes |
| `test_safeTransferFrom_insufficientAllowance_reverts` | `"Insufficient allowance"` | `SafeTransferLib.TransferFromFailed.selector` | Harness -> BetterSafeERC20.safeTransferFrom -> SafeERC20.safeTransferFrom -> SafeTransferLib.safeTransferFrom (assembly catches revert, emits TransferFromFailed) | Yes |
| `test_forceApprove_usdtApprovalToken_overwritesExistingAllowance` | Expected success | `SafeTransferLib.ApproveFailed.selector` | Harness -> BetterSafeERC20.forceApprove -> SafeERC20.forceApprove -> SafeTransferLib.safeApprove (assembly catches revert, emits ApproveFailed) | Yes |

**Status:** Resolved - All mappings verified correct.

### Finding 2: SafeTransferLib import is appropriately scoped
**File:** `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol:15`
**Severity:** N/A (Correct)
**Description:** The new import `{SafeTransferLib} from "@crane/contracts/tokens/ERC20/utils/SafeTransferLib.sol"` is the correct source (Crane's local Solady copy, not an external submodule). Only error selectors are referenced from it, which is appropriate.
**Status:** Resolved

### Finding 3: forceApprove USDT bug correctly documented
**File:** `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol:240-244`
**Severity:** Info
**Description:** The test for `forceApprove_usdtApprovalToken` was changed from expecting success to expecting `ApproveFailed.selector`. The inline comment correctly documents this as a library bug:

The chain is: `BetterSafeERC20.forceApprove()` -> `SafeERC20.forceApprove()` -> `SafeTransferLib.safeApprove()`. The issue is that `SafeERC20.forceApprove()` at line 85 calls `SafeTransferLib.safeApprove()` instead of `SafeTransferLib.safeApproveWithRetry()`. The `safeApproveWithRetry()` function (SafeTransferLib.sol:411-438) includes the zero-first retry logic that USDT-like tokens require.

This is the right approach: document the bug in the test, assert the actual (buggy) behavior, and defer the library fix to a follow-up task.
**Status:** Resolved

### Finding 4: Existing safeApprove test correctly left unchanged
**File:** `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol:261-264`
**Severity:** N/A (Correct)
**Description:** `test_safeApprove_falseReturningToken_whenFalse_reverts` still expects `SafeERC20.SafeERC20FailedOperation(address)`. This is correct because `BetterSafeERC20.safeApprove()` (line 133-137) uses its own `callOptionalReturn()` which has high-level Solidity error handling — it does NOT delegate through SafeTransferLib. The `callOptionalReturn()` function checks the return value and reverts with `SafeERC20.SafeERC20FailedOperation(address)` at line 162. The agent correctly identified this different code path and left the test unchanged.
**Status:** Resolved

### Finding 5: No regressions in untouched tests
**File:** N/A
**Severity:** N/A
**Description:** PROGRESS.md reports 37 tests pass, 0 fail. The diff only modifies error expectations in the 5 targeted tests. No other test logic or assertions were changed.
**Status:** Resolved

---

## Suggestions

### Suggestion 1: Fix SafeERC20.forceApprove() to use safeApproveWithRetry()
**Priority:** High
**Description:** `SafeERC20.forceApprove()` at line 85 of `contracts/utils/SafeERC20.sol` calls `SafeTransferLib.safeApprove()` instead of `SafeTransferLib.safeApproveWithRetry()`. This breaks USDT-like tokens that require zero-first approval. This is already documented in MEMORY.md and in the test comment.
**Affected Files:**
- `contracts/utils/SafeERC20.sol` (line 85)
**User Response:** Accepted
**Notes:** Converted to task CRANE-229. When fixed, `test_forceApprove_usdtApprovalToken_overwritesExistingAllowance` should be updated to expect success and re-add the final `assertEq` for the updated allowance value.

---

## Review Summary

**Findings:** 5 (all Resolved/Correct)
**Suggestions:** 1 (follow-up task for forceApprove bug)
**Recommendation:** **Approve** - All changes are correct and well-documented. The 5 error expectations accurately reflect the actual error propagation through the BetterSafeERC20 -> SafeERC20 -> SafeTransferLib delegation chain. The forceApprove USDT bug is properly documented as known-broken behavior with a clear path to resolution.

---

**Review complete.** `<promise>PHASE_DONE</promise>`
