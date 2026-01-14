# Progress Log: CRANE-014

## Current Checkpoint

**Last checkpoint:** Task Complete
**Next step:** Ready for review
**Build status:** ✅ Passing
**Test status:** ✅ 1324 tests passing (8 skipped pre-existing)

---

## Session Log

### 2026-01-13 - Implementation Complete

**Summary:**
Fixed two critical correctness bugs in ERC2535Repo.sol and added comprehensive tests.

**Bug 1 - `_removeFacet()` (line 139):**
- **Before:** `layout.facetAddress[selector] = facetCut.facetAddress;`
- **After:** `layout.facetAddress[selector] = address(0);`
- **Impact:** Removed selectors now correctly return `address(0)` from `facetAddress()`, making them unroutable via the proxy (Proxy.sol reverts with `NoTargetFor` when target is not a contract)

**Bug 2 - `_replaceFacet()` (line 121):**
- **Before:** `layout.facetAddresses._remove(facetCut.facetAddress);` (removed new facet)
- **After:** `layout.facetAddresses._remove(currentFacet);` (removes old facet)
- **Impact:** Old facets are now correctly removed from `facetAddresses` set when they become empty after replace

**Files Modified:**
- `contracts/introspection/ERC2535/ERC2535Repo.sol` - Both bug fixes

**Tests Added (6 new tests in DiamondCut.t.sol):**
1. `test_diamondCut_removeFacet_selectorReturnsZeroAddress` - Verifies removed selectors return address(0)
2. `test_diamondCut_removeFacet_allSelectorsReturnZero` - Verifies all selectors in batch return address(0)
3. `test_diamondCut_replaceFacet_removesOldFacetFromSet` - Verifies old facet removed when empty
4. `test_diamondCut_replaceFacet_updatesFacetFunctionSelectors` - Verifies selector sets updated correctly
5. `test_diamondCut_replaceFacet_keepsOldFacetWhenNotEmpty` - Verifies partial replace keeps old facet

**Verification:**
- `forge build` - Successful (warnings are pre-existing)
- `forge test` - All 1324 tests pass, 8 skipped (pre-existing)
- `forge test --match-path "test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol"` - All 24 tests pass

### 2026-01-13 - Task Launched

- Task launched via /backlog:launch
- Agent worktree created
- Ready to begin implementation

### 2026-01-12 - Task Created

- Task created from code review suggestion (Suggestion 1)
- Origin: CRANE-002 REVIEW.md
- Priority: Critical
- Ready for agent assignment via /backlog:launch

---

## Acceptance Criteria Checklist

### US-CRANE-014.1: Fix selector removal routing
- [x] `_removeFacet()` sets `layout.facetAddress[selector] = address(0)`
- [x] Removed selectors return `address(0)` from `_facetAddress()`
- [x] `MinimalDiamondCallBackProxy._getTarget()` reverts for removed selectors (via Proxy.sol `NoTargetFor`)
- [x] Unit test verifies selector becomes unroutable after removal
- [x] Tests pass
- [x] Build succeeds

### US-CRANE-014.2: Fix replace facet bookkeeping
- [x] `_replaceFacet()` removes the old facet address when it becomes empty (not the new one)
- [x] Old facet's selector set is deleted when empty
- [x] Unit test verifies facet address set consistency after replace
- [x] Tests pass
- [x] Build succeeds

### US-CRANE-014.3: Add comprehensive remove/replace tests
- [x] Test: remove selector makes it unroutable
- [x] Test: remove updates facet address set correctly
- [x] Test: replace updates facet address set correctly (old facet removed, new facet present)
- [x] Test: replace with empty old facet removes old facet from set
- [x] Tests pass
- [x] Build succeeds

## Completion Criteria
- [x] All acceptance criteria met
- [x] Unit tests added that would have caught both bugs
- [x] `forge test` passes
- [x] `forge build` succeeds
