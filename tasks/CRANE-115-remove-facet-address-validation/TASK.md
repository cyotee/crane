# Task CRANE-115: Enforce Correct Facet Address During Remove

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-058
**Worktree:** `fix/remove-facet-address-validation`
**Origin:** Code review suggestion from CRANE-058

---

## Description

Update `_removeFacet()` to mirror `_replaceFacet()`'s pattern for maintaining selector-set invariants:

1. Resolve `currentFacet = layout.facetAddress[selector]` *before* clearing it
2. Remove the selector from `layout.facetFunctionSelectors[currentFacet]`
3. Remove `currentFacet` from `facetAddresses` only when its selector set becomes empty
4. Emit `DiamondFunctionRemoved(selector, currentFacet)` (or revert on mismatch if `facetCut.facetAddress` should be authoritative)

This prevents ERC-2535 loupe view inconsistencies even if `facetCut.facetAddress` is incorrect.

(Created from code review of CRANE-058)

## Dependencies

- CRANE-058: Implement Partial Remove Semantics (parent task)

## Problem Statement

Currently `_removeFacet()` clears `layout.facetAddress[selector]` and then removes the selector from `layout.facetFunctionSelectors[facetCut.facetAddress]`. Because `Bytes4SetRepo._remove` is idempotent (no revert when missing), if a caller supplies selectors owned by a *different* facet than `facetCut.facetAddress`, the selector-to-facet mapping will be cleared but the selector will remain in the *real* facet's selector set.

This can leave loupe views inconsistent:
- `facetAddress(selector)` returns `address(0)` (removed)
- but `facetFunctionSelectors(realFacet)` and `facets()` still report the selector as present

## User Stories

### US-CRANE-115.1: Correct Facet Resolution During Remove

As a diamond proxy developer, I want `_removeFacet()` to always maintain internal selector-set invariants so that loupe views remain consistent regardless of caller input.

**Acceptance Criteria:**
- [ ] `_removeFacet()` resolves the actual owning facet before clearing mappings
- [ ] Selectors are removed from the correct facet's selector set
- [ ] Facet addresses are removed from `facetAddresses` when their selector set becomes empty
- [ ] Events reflect the actual facet, not the (potentially incorrect) `facetCut.facetAddress`
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/introspection/ERC2535/ERC2535Repo.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-058 is complete
- [ ] contracts/introspection/ERC2535/ERC2535Repo.sol exists
- [ ] Understand `_replaceFacet()` pattern for reference

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Loupe view consistency maintained in all edge cases
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
