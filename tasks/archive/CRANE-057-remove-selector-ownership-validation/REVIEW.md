# Code Review: CRANE-057

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-17
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Findings

### Finding 1: Task inventory misses one modified file
**File:** tasks/CRANE-057-remove-selector-ownership-validation/TASK.md
**Severity:** Low
**Description:** Implementation added a new error in `contracts/interfaces/IDiamondLoupe.sol`, but `TASK.md` only lists `ERC2535Repo.sol` + `DiamondCut.t.sol` as modified.
**Status:** Open
**Resolution:** Update the “Files to Create/Modify” section to include `contracts/interfaces/IDiamondLoupe.sol`.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Consider guarding against partial facet removal bookkeeping corruption
**Priority:** Medium
**Description:** `_removeFacet()` unconditionally deletes `facetFunctionSelectors[facetCut.facetAddress]` and removes `facetCut.facetAddress` from `facetAddresses`. That’s correct when the cut removes *all* selectors for that facet, but if a caller accidentally passes only a subset, the remaining selectors can still map to the facet while loupe bookkeeping is wiped. If partial removal is not supported by design, consider adding an explicit validation (e.g., verify the facet’s selector set is empty after removals before removing from `facetAddresses`, or require the cut to include all selectors).
**Affected Files:**
- contracts/introspection/ERC2535/ERC2535Repo.sol
**User Response:** (pending)
**Notes:** This is adjacent to CRANE-057’s risk model and may already be addressed by other work (e.g., partial remove semantics workstreams).

---

## Review Summary

**Findings:** 1 (Low)
**Suggestions:** 1 (Medium)
**Recommendation:** Approve (ship CRANE-057 as implemented). The selector ownership validation and the negative test cover the stated corruption risk.

**Verified:**
- Build: `forge build` (pass)
- Tests: `forge test --match-path test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol` (pass)
- Tests: `forge test` full suite (1929 passing)

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
