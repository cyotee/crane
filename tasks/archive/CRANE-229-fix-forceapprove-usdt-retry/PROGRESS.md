# Progress Log: CRANE-229

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Code review
**Build status:** Passes (compilation successful, warnings are pre-existing)
**Test status:** All 37 BetterSafeERC20 tests pass

---

## Session Log

### 2026-02-06 - Implementation Complete

**Changes made:**

1. **`contracts/utils/SafeERC20.sol` (line 85)** - Changed `SafeTransferLib.safeApprove()` to `SafeTransferLib.safeApproveWithRetry()` in `forceApprove(IERC20, address, uint256)`. The bool overload delegates to this, so both overloads are fixed.

2. **`test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol` (lines 235-244)** - Updated `test_forceApprove_usdtApprovalToken_overwritesExistingAllowance`:
   - Removed `vm.expectRevert(SafeTransferLib.ApproveFailed.selector)`
   - Removed BUG comment about the library issue
   - Added success assertion: `assertEq(usdtApprovalToken.allowance(...), newAllowance, "Allowance overwritten")`

**Test results:** 37/37 passed, 0 failed, 0 skipped (run with `FOUNDRY_OFFLINE=true` to avoid foundry macOS sandbox crash)

**Acceptance criteria met:**
- [x] `SafeERC20.forceApprove()` calls `SafeTransferLib.safeApproveWithRetry()`
- [x] `test_forceApprove_usdtApprovalToken_overwritesExistingAllowance` expects success (not `ApproveFailed`)
- [x] Test re-asserts the final allowance value is correct after `forceApprove`
- [x] All other BetterSafeERC20 tests still pass
- [x] Both forceApprove overloads work (bool delegates to uint256)
- [x] Build succeeds (no new warnings)

### 2026-02-06 - Task Created

- Task created from code review suggestion
- Origin: CRANE-224 REVIEW.md, Suggestion 1
- Ready for agent assignment via /backlog:launch
