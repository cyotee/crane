# Progress Log: CRANE-020

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Ready for review
**Build status:** ✅ Passes
**Test status:** ✅ All 124 ERC20 tests pass

---

## Session Log

### 2026-01-14 - Implementation Complete

**Summary:**
- Fixed critical ERC20 `transferFrom` allowance bypass vulnerability
- Added 3 new tests for allowance enforcement
- All existing tests pass

**Changes Made:**

1. **`contracts/tokens/ERC20/ERC20Target.sol:38`**
   - Changed `ERC20Repo._transfer(owner, recipient, amount)` to `ERC20Repo._transferFrom(owner, recipient, amount)`
   - This ensures `_spendAllowance()` is called before transfer, enforcing allowance checks

2. **`test/foundry/spec/tokens/ERC20/ERC20Target_EdgeCases.t.sol`**
   - Added `test_transferFrom_withoutAllowance_reverts()` - verifies unauthorized transfer reverts with `ERC20InsufficientAllowance`
   - Added `test_transferFrom_exceedsAllowance_reverts()` - verifies transfer exceeding allowance reverts
   - Added `test_transferFrom_decreasesAllowance()` - verifies allowance is properly deducted after transfer
   - Updated `test_transferFrom_withAllowance_succeeds()` - added assertion that allowance is zero after full spend

**Verification:**
- `forge build` - ✅ Compiles successfully (with existing warnings unrelated to this fix)
- `forge test --match-path "test/foundry/spec/tokens/ERC20/*"` - ✅ 124 tests pass
  - New tests pass: `test_transferFrom_withoutAllowance_reverts`, `test_transferFrom_exceedsAllowance_reverts`, `test_transferFrom_decreasesAllowance`
  - Invariant tests pass: `invariant_allowances_consistent`, `invariant_totalSupply_equals_sumBalances`, `invariant_nonnegative`

---

### 2026-01-13 - Task Created

- Task created from code review suggestion
- Origin: CRANE-005 REVIEW.md - Suggestion 1 (P0 Critical)
- Ready for agent assignment via /backlog:launch
