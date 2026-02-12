# Code Review: CRANE-056

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-17
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None.
- Note: Crane’s current `ERC2535Repo._processFacetCut` ignores cuts with `facetAddress == address(0)`, so this test correctly uses `facetAddress: address(mockFacet)` for `FacetCutAction.Remove` (even though EIP-2535 commonly uses `address(0)` for remove).

---

## Review Findings

- No blocking findings. The implementation meets the CRANE-056 acceptance criteria and exercises the proxy routing path via a real proxy deployed through `DiamondPackageCallBackFactory`.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Deploy `MockFacet` via `ICreate3Factory.deployFacet`
**Priority:** Low
**Description:** In `setUp()`, `MockFacet` is currently deployed with `new MockFacet()`. Consider deploying it via `create3Factory.deployFacet(type(MockFacet).creationCode, abi.encode(type(MockFacet).name)._hash())` for consistency with the deterministic deployment patterns used throughout Crane.
**Affected Files:**
- test/foundry/spec/introspection/ERC2535/ProxyRoutingRegression.t.sol
**User Response:** (not requested)
**Notes:** This is a style/convention alignment suggestion; current test behavior is correct.

### Suggestion 2: Bubble revert data in fuzz call helper
**Priority:** Low
**Description:** The fuzz test currently uses `diamond.call(abi.encodeWithSelector(selector))` under `vm.expectRevert(...)`. This passes today, but could be clearer/less tool-dependent if wrapped in a helper that reverts with the returned revert data when `success == false`.
**Affected Files:**
- test/foundry/spec/introspection/ERC2535/ProxyRoutingRegression.t.sol
**User Response:** (not requested)
**Notes:** Not required for correctness; current approach passes in Foundry as written.

---

## Review Summary

**Findings:** 0 blocking
**Suggestions:** 2 (both Low priority)
**Recommendation:** Approve

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
