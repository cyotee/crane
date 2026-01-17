# Task CRANE-117: Guard Against Partial Facet Removal Bookkeeping Corruption

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-057
**Worktree:** `fix/partial-removal-guardrails`
**Origin:** Code review suggestion from CRANE-057

---

## Description

`_removeFacet()` unconditionally deletes `facetFunctionSelectors[facetCut.facetAddress]` and removes `facetCut.facetAddress` from `facetAddresses`. That's correct when the cut removes *all* selectors for that facet, but if a caller accidentally passes only a subset, the remaining selectors can still map to the facet while loupe bookkeeping is wiped.

If partial removal is not supported by design, consider adding explicit validation:
- Verify the facet's selector set is empty after removals before removing from `facetAddresses`, OR
- Require the cut to include all selectors for that facet

(Created from code review of CRANE-057)

## Dependencies

- CRANE-057: Fix Remove Selector Ownership Validation (parent task)

## Related Tasks

- CRANE-058: Implement Partial Remove Semantics (may have addressed some of this)
- CRANE-115: Enforce Correct Facet Address During Remove
- CRANE-116: Add Negative Test for Facet/Selector Mismatch During Remove

## User Stories

### US-CRANE-117.1: Prevent Loupe Bookkeeping Corruption on Partial Removal

As a diamond proxy developer, I want `_removeFacet()` to maintain consistent loupe bookkeeping so that partial selector removal doesn't leave orphaned selector-to-facet mappings when `facetAddresses` is wiped.

**Acceptance Criteria:**
- [ ] Validate facet's selector set is empty before removing from `facetAddresses`
- [ ] OR verify all selectors for a facet are included in the remove cut
- [ ] Loupe views remain consistent after any valid removal operation
- [ ] Add test coverage for partial removal edge cases
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/introspection/ERC2535/ERC2535Repo.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-057 is complete
- [ ] contracts/introspection/ERC2535/ERC2535Repo.sol exists
- [ ] Review CRANE-058 implementation for overlap

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Loupe view consistency maintained in all edge cases
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
