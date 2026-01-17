# Code Review: CRANE-058

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-17
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None. TASK.md acceptance criteria are unambiguous.

---

## Review Findings

### Finding 1: `_removeFacet` can desync selector sets if `facetAddress` is incorrect
**File:** contracts/introspection/ERC2535/ERC2535Repo.sol
**Severity:** High (correctness / invariant integrity)
**Description:**
`_removeFacet()` clears `layout.facetAddress[selector]` and then removes the selector from `layout.facetFunctionSelectors[facetCut.facetAddress]`.

Because `Bytes4SetRepo._remove` is idempotent (no revert when missing), if a caller supplies selectors that are actually owned by a *different* facet than `facetCut.facetAddress`, the selector-to-facet mapping will be cleared but the selector will remain in the *real* facet’s selector set.

This can leave ERC-2535 loupe views inconsistent:
- `facetAddress(selector)` returns `address(0)` (removed)
- but `facetFunctionSelectors(realFacet)` and `facets()` may still report the selector as present.

It also emits `DiamondFunctionRemoved(selector, facetCut.facetAddress)` even when the selector was not actually removed from that facet.

**Expected/Preferred Behavior:**
Either:
1) Validate `layout.facetAddress[selector] == facetCut.facetAddress` and revert on mismatch, OR
2) Ignore `facetCut.facetAddress` for selector-set maintenance and instead remove from the resolved `currentFacet` (as `_replaceFacet()` already does).

**Status:** Open
**Resolution:** Not addressed in this change set; recommend follow-up fix + negative test.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Enforce / derive correct facet during `Remove`
**Priority:** High
**Description:**
Update `_removeFacet()` to mirror `_replaceFacet()`’s pattern:
- Resolve `currentFacet = layout.facetAddress[selector]` *before* clearing it
- Remove the selector from `layout.facetFunctionSelectors[currentFacet]`
- Remove `currentFacet` from `facetAddresses` only when its selector set becomes empty
- Emit `DiamondFunctionRemoved(selector, currentFacet)` (or revert on mismatch if you want `facetCut.facetAddress` to be authoritative)

This prevents loupe inconsistencies even if `facetCut.facetAddress` is incorrect.
**Affected Files:**
- contracts/introspection/ERC2535/ERC2535Repo.sol
**User Response:** (pending)
**Notes:** This is a correctness hardening; only-owner access reduces exploitability but not invariant risk.

### Suggestion 2: Add a negative test for facet/selector mismatch during remove
**Priority:** Medium
**Description:**
Add a test that registers two facets, then attempts a remove cut where `facetAddress` is facet A but selectors belong to facet B. Assert either:
- it reverts (preferred), OR
- state remains consistent (selector removed from the correct facet set, and events reflect reality).
**Affected Files:**
- test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol
**User Response:** (pending)
**Notes:** This locks in the intended API semantics for `Remove` and prevents future regressions.

---

## Review Summary

**Findings:** 1 open (high severity correctness hardening)
**Suggestions:** 2 (1 high priority fix + 1 test)
**Recommendation:** Conditional approval.

This PR meets CRANE-058’s stated acceptance criteria for “Option B partial remove semantics” and adds meaningful coverage.
However, `_removeFacet()` currently relies on the caller providing a correct `facetCut.facetAddress`, and does not maintain internal selector-set invariants if that assumption is violated.

**Verification:**
- `forge test --match-path test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol` (28/28 passing)
- `forge test --match-path 'test/foundry/spec/introspection/ERC2535/*.t.sol'` (57/57 passing)

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
