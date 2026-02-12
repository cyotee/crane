# Task CRANE-263: Add Mixed-Mismatch Remove FacetCut Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-116
**Worktree:** `test/CRANE-263-mixed-mismatch-remove-test`
**Origin:** Code review suggestion from CRANE-116

---

## Description

Add a negative test that combines correctly-owned and mismatched selectors in a single Remove FacetCut to verify atomic revert behavior. Register facetA with [mockFunctionA, mockFunctionB] and facetC with [mockFunctionC], then attempt a remove with `facetAddress=A` and `selectors=[mockFunctionA, mockFunctionC]`. This tests that `mockFunctionA` is NOT removed despite being correctly owned, because the batch reverts atomically when it reaches the mismatched `mockFunctionC`.

While the existing `_multipleSelectors` test covers the case where ALL selectors are mismatched, this test covers the "partial match within a single cut" edge case.

(Created from code review of CRANE-116)

## Dependencies

- CRANE-116: Add Negative Test for Facet/Selector Mismatch During Remove (parent task)

## User Stories

### US-CRANE-263.1: Mixed-Mismatch Atomic Revert Test

As a diamond proxy developer, I want a test that verifies atomic revert when a Remove FacetCut contains a mix of correctly-owned and mismatched selectors so that partial removal cannot corrupt state.

**Acceptance Criteria:**
- [ ] Test registers two facets: facetA (2+ selectors) and facetC (1+ selectors)
- [ ] Test attempts a remove with facetAddress=A and selectors including both A-owned and C-owned selectors
- [ ] Test asserts revert with SelectorFacetMismatch on the first mismatched selector
- [ ] Test verifies NO selectors were removed (atomic revert - even the correctly-matched ones stay)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-116 is complete
- [ ] test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol exists
- [ ] Understand existing CRANE-116 test patterns in the file

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
