# Progress Log: CRANE-057

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Ready for code review
**Build status:** ✅ Passing
**Test status:** ✅ 54/54 tests passing

---

## Session Log

### 2026-01-17 - Implementation Complete

**Changes Made:**

1. **Added new error to `IDiamondLoupe.sol`** (line 22):
   ```solidity
   /// @notice Thrown when attempting to remove a selector that belongs to a different facet
   error SelectorFacetMismatch(bytes4 functionSelector, address expectedFacet, address actualFacet);
   ```

2. **Updated `_removeFacet()` in `ERC2535Repo.sol`** (lines 130-152):
   - Added validation that each selector being removed actually maps to the specified `facetCut.facetAddress`
   - If a selector belongs to a different facet, reverts with `SelectorFacetMismatch(selector, expectedFacet, actualFacet)`
   - This prevents owner errors from corrupting the diamond's loupe bookkeeping

3. **Added negative test to `DiamondCut.t.sol`**:
   - `test_diamondCut_removeFacet_revertsOnSelectorFacetMismatch()` - Tests that attempting to remove a selector belonging to a different facet reverts with the correct error and preserves state

**Test Results:**
- All 54 ERC2535 tests pass
- New test specifically validates the mismatch scenario
- No regressions in existing tests

**Files Modified:**
- `contracts/interfaces/IDiamondLoupe.sol` - Added `SelectorFacetMismatch` error
- `contracts/introspection/ERC2535/ERC2535Repo.sol` - Added ownership validation in `_removeFacet()`
- `test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol` - Added negative test

---

### 2026-01-14 - Task Created

- Task created from code review suggestion (Suggestion 2)
- Origin: CRANE-014 REVIEW.md
- Priority: High
- Ready for agent assignment via /backlog:launch
