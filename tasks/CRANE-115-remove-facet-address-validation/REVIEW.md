# Code Review: CRANE-115

**Reviewer:** Claude Opus 4.6
**Review Started:** 2026-02-07
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None - the TASK.md acceptance criteria and PROGRESS.md implementation notes were sufficiently clear.

---

## Review Findings

### Finding 1: Rename from `actualFacet` to `currentFacet` is correct and consistent
**File:** contracts/introspection/ERC2535/ERC2535Repo.sol:140
**Severity:** Info (positive)
**Description:** The variable rename from `actualFacet` to `currentFacet` aligns with the naming convention used in `_replaceFacet()` (line 118) and `_facets()` (line 166). This improves readability and consistency across the library.
**Status:** Resolved (no action needed)
**Resolution:** Good change.

### Finding 2: All selector-set operations now use resolved `currentFacet`
**File:** contracts/introspection/ERC2535/ERC2535Repo.sol:150
**Severity:** Info (positive)
**Description:** The old code used `facetCut.facetAddress` for `_remove()` and event emission. The new code uses `currentFacet` (resolved from `layout.facetAddress[selector]`). While the `SelectorFacetMismatch` guard at line 145 ensures `currentFacet == facetCut.facetAddress`, using the resolved value is structurally safer - it would remain correct even if the guard were removed in a future refactor.
**Status:** Resolved (no action needed)
**Resolution:** Correct application of "resolve then operate" pattern.

### Finding 3: Facet address cleanup moved inside the loop
**File:** contracts/introspection/ERC2535/ERC2535Repo.sol:151-153
**Severity:** Low (gas observation, not a bug)
**Description:** The old code checked `layout.facetFunctionSelectors[facetCut.facetAddress]._length() == 0` once after the loop. The new code checks per-iteration inside the loop. Given the `SelectorFacetMismatch` guard ensures all selectors belong to the same facet, the check can only ever be true on the last iteration. This costs slightly more gas (an extra `_length()` call per iteration). However, this exactly mirrors the `_replaceFacet()` pattern at lines 120-122, which is the stated design goal.
**Status:** Resolved (acceptable trade-off)
**Resolution:** Structural consistency > marginal gas savings. The in-loop pattern also correctly handles a hypothetical future where selectors from multiple facets could be processed in a single FacetCut.

### Finding 4: Event emission uses resolved `currentFacet`
**File:** contracts/introspection/ERC2535/ERC2535Repo.sol:154
**Severity:** Info (positive)
**Description:** `DiamondFunctionRemoved(selector, currentFacet)` now emits the resolved address. Again, with the mismatch guard this is equivalent, but it's the correct pattern for event accuracy.
**Status:** Resolved (no action needed)
**Resolution:** Events should always reflect ground-truth state.

### Finding 5: No new tests added, but existing coverage is comprehensive
**File:** test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol
**Severity:** Info
**Description:** No new tests were added for CRANE-115 specifically, but the existing test suite (29 tests including the CRANE-057 mismatch test and CRANE-058 partial/full removal tests) thoroughly exercises all code paths. The refactor is purely structural - it doesn't change observable behavior when the mismatch guard is present.
**Status:** Resolved (no action needed)
**Resolution:** Test coverage is adequate for a refactoring change.

### Finding 6: No bugs found
**File:** contracts/introspection/ERC2535/ERC2535Repo.sol:130-156
**Severity:** Info
**Description:** Reviewed all operations in `_removeFacet()` for correctness:
- `currentFacet` is resolved before `facetAddress[selector]` is zeroed (line 140 before 148) ✓
- `SelectorFacetMismatch` guard prevents cross-facet corruption ✓
- `_remove(selector)` targets the correct facet's selector set ✓
- `facetAddresses._remove(currentFacet)` only fires when selector set is empty ✓
- Event reflects the actual facet ✓
- `FunctionNotPresent` revert for already-removed selectors ✓
**Status:** Resolved
**Resolution:** No bugs found.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: (none)
No actionable suggestions. The implementation is clean, minimal, and correctly scoped.

---

## Review Summary

**Findings:** 6 (0 bugs, 1 low-severity gas observation, 5 informational/positive)
**Suggestions:** 0
**Recommendation:** APPROVE

The change is a well-scoped structural refactoring that makes `_removeFacet()` mirror `_replaceFacet()`'s "resolve then operate" pattern. All acceptance criteria are met:

- [x] `_removeFacet()` resolves the actual owning facet before clearing mappings
- [x] Selectors are removed from the correct facet's selector set
- [x] Facet addresses are removed from `facetAddresses` when their selector set becomes empty
- [x] Events reflect the actual facet, not the (potentially incorrect) `facetCut.facetAddress`
- [x] Tests pass (29/29 DiamondCut tests, 4890/4890 total with 6 pre-existing fork failures)
- [x] Build succeeds

The diff is minimal (net -2 lines), there are no behavioral changes for correct callers, and the code is now structurally safe against future guard removal.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
