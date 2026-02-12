# Task CRANE-229: Fix SafeERC20.forceApprove() to Use safeApproveWithRetry()

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-06
**Dependencies:** CRANE-224
**Worktree:** `fix/forceapprove-usdt-retry`
**Origin:** Code review suggestion from CRANE-224

---

## Description

`SafeERC20.forceApprove()` calls `SafeTransferLib.safeApprove()` instead of `SafeTransferLib.safeApproveWithRetry()`. This breaks USDT-like tokens that require the allowance to be set to zero before setting a non-zero value. The `safeApproveWithRetry()` function (SafeTransferLib.sol lines 411-438) includes the zero-first retry logic that these tokens require, but `forceApprove()` doesn't use it.

(Created from code review of CRANE-224)

## Dependencies

- CRANE-224: Fix BetterSafeERC20 Test Error Expectations (parent task - Complete)

## User Stories

### US-CRANE-229.1: Fix forceApprove for USDT-like Tokens

As a developer, I want `SafeERC20.forceApprove()` to correctly handle USDT-like tokens that require zero-first approval so that the library works with all common ERC20 implementations.

**Acceptance Criteria:**
- [ ] `SafeERC20.forceApprove()` calls `SafeTransferLib.safeApproveWithRetry()` instead of `SafeTransferLib.safeApprove()`
- [ ] `test_forceApprove_usdtApprovalToken_overwritesExistingAllowance` expects success (not `ApproveFailed`)
- [ ] The test re-asserts the final allowance value is correct after `forceApprove`
- [ ] All other BetterSafeERC20 tests still pass
- [ ] No regression in other tests

### US-CRANE-229.2: Verify Both forceApprove Overloads

As a developer, I want both `forceApprove(IERC20, address, uint256)` and `forceApprove(IERC20, address, bool)` to work with USDT-like tokens since the bool overload delegates to the uint256 overload.

**Acceptance Criteria:**
- [ ] Both forceApprove overloads work correctly with USDT-like mock tokens
- [ ] The bool overload correctly delegates to the fixed uint256 overload

## Technical Details

### Root Cause

In `contracts/utils/SafeERC20.sol` at line 85:
```solidity
function forceApprove(IERC20 token, address spender, uint256 value) internal {
    SafeTransferLib.safeApprove(address(token), spender, value);  // BUG
}
```

### Fix

Change to use `safeApproveWithRetry`:
```solidity
function forceApprove(IERC20 token, address spender, uint256 value) internal {
    SafeTransferLib.safeApproveWithRetry(address(token), spender, value);
}
```

### Test Fix

In `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol`, the test `test_forceApprove_usdtApprovalToken_overwritesExistingAllowance` currently expects `ApproveFailed`. After the library fix, it should:
1. Remove the `vm.expectRevert(SafeTransferLib.ApproveFailed.selector)` line
2. Restore the success assertion: `assertEq(token.allowance(address(harness), spender), newAllowance)`
3. Remove the comment about the library bug

### Delegation Chain

`BetterSafeERC20.forceApprove()` -> `SafeERC20.forceApprove()` -> `SafeTransferLib.safeApproveWithRetry()` (after fix)

The `safeApproveWithRetry()` function:
1. First tries `safeApprove(token, spender, value)`
2. If that fails, retries with `safeApprove(token, spender, 0)` then `safeApprove(token, spender, value)`
3. This handles USDT's requirement that allowance must be zero before being changed

## Files to Create/Modify

**Modified Files:**
- `contracts/utils/SafeERC20.sol` (line 85) - Change `safeApprove` to `safeApproveWithRetry`
- `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol` - Update forceApprove USDT test to expect success

## Inventory Check

Before starting, verify:
- [ ] `SafeTransferLib.safeApproveWithRetry(address, address, uint256)` exists and includes zero-first retry logic
- [ ] `SafeERC20.forceApprove` still calls `safeApprove` (not already fixed)
- [ ] The USDT mock token in tests requires zero-first approval pattern

## Completion Criteria

- [ ] `SafeERC20.forceApprove()` uses `safeApproveWithRetry()`
- [ ] USDT forceApprove test expects success and validates allowance
- [ ] All BetterSafeERC20 tests pass
- [ ] All other tests unaffected
- [ ] Build succeeds with no new warnings

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
