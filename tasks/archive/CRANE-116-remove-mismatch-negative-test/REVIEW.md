# Code Review: CRANE-116

**Reviewer:** Claude Opus 4.6
**Review Started:** 2026-02-08
**Status:** Complete

---

## Clarifying Questions

No clarifying questions needed. The task requirements are clear from TASK.md and the existing CRANE-057 test establishes the pattern.

---

## Review Findings

### Finding 1: Minor indentation inconsistency on CRANE-057 test
**File:** test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol
**Line:** 522
**Severity:** Cosmetic (pre-existing)
**Description:** The `@notice CRANE-057` test at line 522 has inconsistent indentation - the NatSpec comment begins at column 0 (`/// @notice CRANE-057:`) while all other NatSpec comments in the file are indented with 4 spaces. This pre-dates the CRANE-116 changes. The new CRANE-116 tests correctly follow the 4-space indentation pattern used by the rest of the file.
**Status:** Resolved (not a regression, pre-existing cosmetic issue)
**Resolution:** Not part of this task's scope. Could be addressed in a separate cleanup.

### Finding 2: New tests correctly verify all three dimensions of state preservation
**File:** test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol
**Lines:** 588-716
**Severity:** Informational (positive finding)
**Description:** The reverse-direction test (`_reverseDirection`) at line 588 verifies state preservation at three levels: (1) `facetAddress()` returns correct owner for both facets' selectors, (2) `facetFunctionSelectors()` returns correct counts for both facets. The multi-selector test at line 662 additionally verifies `mockFunctionB` was not partially removed (validating atomic revert). This is thorough.
**Status:** Resolved (no issue)

### Finding 3: Error parameter ordering matches implementation
**File:** test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol
**Lines:** 631-637, 689-695
**Severity:** Informational (positive finding)
**Description:** The `SelectorFacetMismatch` error parameter order in both new tests correctly matches the implementation at `ERC2535Repo.sol:146`: `(selector, facetCut.facetAddress, currentFacet)`. The inline comments correctly label `expected` (caller's claim) vs `actual` (real owner). This is consistent with the CRANE-057 test pattern at lines 564-570.
**Status:** Resolved (no issue)

---

## Suggestions

### Suggestion 1: Consider adding a mixed-mismatch test
**Priority:** Low
**Description:** A future test could combine correctly-owned and mismatched selectors in a single Remove FacetCut to verify the implementation reverts on the first mismatch without processing correct selectors beforehand. E.g., if facetA owns [mockFunctionA, mockFunctionB] and facetC owns [mockFunctionC], attempt a remove with `facetAddress=A` and `selectors=[mockFunctionA, mockFunctionC]`. This would test that `mockFunctionA` is NOT removed despite being correct, because the batch reverts atomically when it reaches `mockFunctionC`.
**Affected Files:**
- test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-263. This is a nice-to-have edge case test. The current tests already prove atomicity because the EVM's revert mechanism guarantees no state changes on revert. The existing `_multipleSelectors` test covers the atomic revert with ALL selectors mismatching. This suggestion would cover the "partial match within a single cut" case.

---

## Acceptance Criteria Verification

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Test registers two distinct facets with different selectors | PASS | Both new tests register mockFacetA (2 selectors) and mockFacetC (1 selector) via `addCuts` at lines 592-604 and 665-677 |
| Test attempts a remove cut with mismatched facet address | PASS | Test 1 (line 624): `facetAddress=mockFacetA` with `mockFunctionC.selector`. Test 2 (line 682): `facetAddress=mockFacetC` with `mockFacetA.facetFuncs()` |
| Test asserts expected behavior (revert or consistent state) | PASS | Both tests use `vm.expectRevert` with exact `SelectorFacetMismatch` error encoding AND verify post-revert state preservation |
| Test documents intended API semantics via clear assertions | PASS | NatSpec `@notice CRANE-116` annotations, descriptive inline comments explaining "reverse direction" and "wrong facet", clear assertion messages |
| Tests pass | PASS | 31/31 tests pass including 2 new (verified via `forge test`) |
| Build succeeds | PASS | Compilation succeeded (no errors) |

---

## Review Summary

**Findings:** 3 (1 pre-existing cosmetic, 2 positive/informational)
**Suggestions:** 1 (low priority)
**Recommendation:** APPROVE

The implementation is clean, thorough, and well-documented. The two new tests provide meaningful coverage by testing:
1. The **reverse direction** of the mismatch (facetAddress=A, selector owned by C) which complements the existing CRANE-057 test (facetAddress=C, selector owned by A)
2. The **multi-selector mismatch** case, confirming atomic revert on the first mismatched selector when all selectors in the batch belong to the wrong facet

Both tests correctly encode the `SelectorFacetMismatch` error parameters and thoroughly verify state preservation after the expected revert. No bugs, security issues, or regressions were found. No infrastructure changes were needed - the tests appropriately reuse existing MockFacet, MockFacetC, and DiamondCutTargetStub contracts.

---

**Review complete.**
