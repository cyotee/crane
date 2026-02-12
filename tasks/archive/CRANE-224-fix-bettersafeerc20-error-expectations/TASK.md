# Task CRANE-224: Fix BetterSafeERC20 Test Error Expectations (5 tests)

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-05
**Dependencies:** None
**Worktree:** `fix/bettersafeerc20-error-expectations`

---

## Description

5 tests in BetterSafeERC20.t.sol fail because the tests expect OpenZeppelin-style error messages (string reverts like "Insufficient balance", parametric errors like `SafeERC20FailedOperation(address)`) but the Crane implementation wraps Solady's SafeTransferLib which throws simplified custom errors (`TransferFailed()`, `TransferFromFailed()`, `ApproveFailed()`). The tests need to be updated to expect the actual Crane/Solady error signatures.

## Dependencies

- None

## User Stories

### US-CRANE-224.1: Align Test Expectations with SafeTransferLib Errors

As a developer, I want the BetterSafeERC20 tests to correctly assert the error types thrown by Solady's SafeTransferLib so that the test suite validates actual library behavior.

**Acceptance Criteria:**
- [x] All 5 BetterSafeERC20 test failures are resolved
- [x] Tests correctly expect `TransferFailed()`, `TransferFromFailed()`, or `ApproveFailed()` as appropriate
- [x] The forceApprove USDT test either passes or is correctly documented if it's a logic bug

## Technical Details

### Root Cause

BetterSafeERC20 delegates to Solady's SafeTransferLib, which uses assembly-optimized code that:
- Catches ALL token call failures (reverts, false returns)
- Wraps them in generic custom errors: `TransferFailed()`, `TransferFromFailed()`, `ApproveFailed()`
- Does NOT preserve original revert strings from tokens

### Affected Tests (5 total)

**test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol:**

1. `test_forceApprove_usdtApprovalToken_overwritesExistingAllowance`
   - **Expected:** Success (USDT-like approval should work via forceApprove)
   - **Actual:** `ApproveFailed()`
   - **Fix:** Investigate whether `forceApprove()` correctly delegates to `safeApproveWithRetry()`. If not, fix the library. If it does, update the test.

2. `test_safeTransferFrom_insufficientAllowance_reverts`
   - **Expected:** String "Insufficient allowance"
   - **Actual:** `TransferFromFailed()`
   - **Fix:** `vm.expectRevert(SafeTransferLib.TransferFromFailed.selector)`

3. `test_safeTransfer_falseReturningToken_whenFalse_reverts`
   - **Expected:** `SafeERC20FailedOperation(address)`
   - **Actual:** `TransferFailed()`
   - **Fix:** `vm.expectRevert(SafeTransferLib.TransferFailed.selector)`

4. `test_safeTransfer_insufficientBalance_reverts`
   - **Expected:** String "Insufficient balance"
   - **Actual:** `TransferFailed()`
   - **Fix:** `vm.expectRevert(SafeTransferLib.TransferFailed.selector)`

5. `test_safeTransfer_revertingToken_reverts`
   - **Expected:** String "Transfer not allowed"
   - **Actual:** `TransferFailed()`
   - **Fix:** `vm.expectRevert(SafeTransferLib.TransferFailed.selector)`

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol` - Update all 5 test error expectations

**Files to Read (for context):**
- `contracts/tokens/ERC20/utils/BetterSafeERC20.sol` - The wrapper library
- `contracts/utils/SafeTransferLib.sol` - The underlying Solady-based implementation

## Inventory Check

Before starting, verify:
- [ ] `SafeTransferLib.sol` defines `error TransferFailed()`, `error TransferFromFailed()`, `error ApproveFailed()`
- [ ] `BetterSafeERC20.sol` delegates to SafeTransferLib functions
- [ ] The forceApprove USDT case: check if `safeApproveWithRetry` is called or if there's a missing code path

## Completion Criteria

- [x] All 5 BetterSafeERC20 tests pass
- [x] No regression in other tests
- [x] If forceApprove is a library bug (not just a test bug), file a follow-up task

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
