# Progress Log: CRANE-117

## Current Checkpoint

**Last checkpoint:** Task complete
**Next step:** Ready for code review
**Build status:** Passing
**Test status:** All 61 ERC2535 tests passing (32 DiamondCut + 5 ProxyRoutingRegression + 24 others)

---

## Session Log

### 2026-02-08 - Task Complete

**Analysis: Core issue already resolved by prior tasks**

The original CRANE-117 concern was that `_removeFacet()` "unconditionally deletes
`facetFunctionSelectors[facetCut.facetAddress]` and removes `facetCut.facetAddress`
from `facetAddresses`" during partial removal. This code was already fixed by:

- **CRANE-058**: Implemented per-selector removal with conditional facet cleanup
  (`ERC2535Repo.sol:150-153` — only removes from `facetAddresses` when selector
  set is empty)
- **CRANE-057**: Added `SelectorFacetMismatch` validation (lines 144-147)
- **CRANE-115**: Fixed `currentFacet` resolution pattern (line 150 uses resolved
  `currentFacet` instead of `facetCut.facetAddress`)

**Gap identified: No holistic loupe consistency assertion**

Existing CRANE-058 tests checked individual loupe views but did not verify that all
four ERC-2535 loupe views (`facets()`, `facetAddresses()`, `facetFunctionSelectors()`,
`facetAddress()`) agree with each other after partial removal.

**Tests added (3 new tests + 1 helper):**

All in `test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol`:

1. `_assertLoupeConsistency(string context)` - Helper that validates the diamond
   invariant: all four loupe views must be mutually consistent (same facet set,
   matching selector lists, correct reverse lookups, no empty facets)

2. `test_diamondCut_partialRemoval_loupeConsistency` - Verifies all loupe views
   agree after removing a subset of a facet's selectors

3. `test_diamondCut_fullLifecycle_loupeConsistency` - Exercises the complete
   add-partial-remove-full-remove lifecycle with consistency checks at each step

4. `test_diamondCut_partialRemoveThenReplace_loupeConsistency` - Verifies loupe
   consistency when partial removal is followed by a replace operation

**Test Results:**
- 32/32 DiamondCut tests passing
- 5/5 ProxyRoutingRegression tests passing
- 61/61 total ERC2535 tests passing
- Build clean (zero compilation errors)

**Acceptance Criteria:**
- [x] Validate facet's selector set is empty before removing from `facetAddresses`
      (Already implemented by CRANE-058 at ERC2535Repo.sol:151-153)
- [x] Loupe views remain consistent after any valid removal operation
      (New tests verify this holistically)
- [x] Add test coverage for partial removal edge cases
      (3 new loupe consistency tests added)
- [x] Tests pass (61/61)
- [x] Build succeeds (zero errors)

### 2026-02-08 - Task Launched

- Task launched via /pm:launch
- Agent worktree created
- Ready to begin implementation

### 2026-01-17 - Task Created

- Task created from code review suggestion
- Origin: CRANE-057 REVIEW.md (Suggestion 1)
- Ready for agent assignment via /backlog:launch
