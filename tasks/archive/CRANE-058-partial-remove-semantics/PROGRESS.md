# Progress Log: CRANE-058

## Current Checkpoint

**Last checkpoint:** Task complete
**Next step:** Ready for code review
**Build status:** ✅ Passing
**Test status:** ✅ All 72 ERC2535 tests passing

---

## Session Log

### 2026-01-17 - Task Complete

**Design Decision: Option B - Support Partial Remove**

Implemented partial remove semantics for `_removeFacet()`:
- Selectors are removed individually from `facetFunctionSelectors[facetAddress]`
- Facet is only removed from `facetAddresses` when its selector set becomes empty
- This provides maximum flexibility for diamond upgrades

**Implementation Summary:**

The implementation in `ERC2535Repo.sol:130-148` supports partial removal:
1. Each selector in the removal list is individually removed from the selector-to-facet mapping (line 139)
2. Each selector is removed from the facet's selector set (line 141)
3. The facet is only removed from `facetAddresses` when the selector set is empty (lines 144-147)

**Tests Added/Verified:**

All tests in `test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol`:
- `test_diamondCut_removeFacet_partialRemove_keepsFacetInSet` - Verifies facet stays in set after partial removal
- `test_diamondCut_removeFacet_fullRemove_removesFacetFromSet` - Verifies facet is removed after full removal
- `test_diamondCut_removeFacet_incrementalRemove_cleansUpAtEnd` - Verifies incremental removal works correctly
- `test_diamondCut_removeFacet_partialRemove_updatesSelectorsCorrectly` - Verifies selector tracking is correct

**Test Results:**
- 72 tests passing across all ERC2535 test suites
- All 28 DiamondCut tests passing
- All 5 ProxyRoutingRegression tests passing

**Acceptance Criteria:**
- [x] Design decision documented (Option B - partial remove)
- [x] Implementation matches chosen design
- [x] Tests cover both full and attempted partial removal
- [x] Error messages are clear if partial removal is rejected (FunctionNotPresent)
- [x] Tests pass
- [x] Build succeeds

### 2026-01-14 - Task Created

- Task created from code review suggestion (Suggestion 3)
- Origin: CRANE-014 REVIEW.md
- Priority: Medium
- Ready for agent assignment via /backlog:launch
