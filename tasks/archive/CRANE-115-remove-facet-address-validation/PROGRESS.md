# Progress Log: CRANE-115

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Code review
**Build status:** PASS
**Test status:** PASS (4890/4890, 6 pre-existing fork test failures unrelated to this change)

---

## Session Log

### 2026-02-07 - Implementation Complete

**Changes made to `contracts/introspection/ERC2535/ERC2535Repo.sol`:**

Refactored `_removeFacet()` to mirror `_replaceFacet()`'s pattern for maintaining selector-set invariants:

1. **Renamed `actualFacet` to `currentFacet`** - Consistent with `_replaceFacet()` naming convention
2. **All operations use resolved `currentFacet`** - Selector set removal, facet address cleanup, and event emission now use the resolved address from `layout.facetAddress[selector]` instead of `facetCut.facetAddress`
3. **Moved facet address cleanup inside the loop** - Per-selector check `layout.facetFunctionSelectors[currentFacet]._length() == 0` inside the loop (same pattern as `_replaceFacet()`)
4. **Event uses `currentFacet`** - `DiamondFunctionRemoved` emitted with resolved address

**Acceptance criteria status:**
- [x] `_removeFacet()` resolves the actual owning facet before clearing mappings
- [x] Selectors are removed from the correct facet's selector set
- [x] Facet addresses are removed from `facetAddresses` when their selector set becomes empty
- [x] Events reflect the actual facet, not the (potentially incorrect) `facetCut.facetAddress`
- [x] Tests pass (73/73 ERC2535 tests, 4890/4890 total)
- [x] Build succeeds

### 2026-01-17 - Task Created

- Task created from code review suggestion
- Origin: CRANE-058 REVIEW.md (Suggestion 1)
- Ready for agent assignment via /backlog:launch
