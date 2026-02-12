# Code Review: CRANE-112

**Reviewer:** Claude (Code Review Agent)
**Review Started:** 2026-02-08
**Status:** Complete

---

## Checklist: Acceptance Criteria

- [x] Create dedicated mocks for `standardSwapFeePercentageBoundsFacet` — `MockSwapFeeBoundsFacet` created (lines 482-508)
- [x] Create dedicated mocks for `unbalancedLiquidityInvariantRatioBoundsFacet` — `MockInvariantRatioBoundsFacet` created (lines 517-543)
- [x] Add explicit assertion that these fields are currently unused by `facetCuts()` — two regression tests added (lines 385-411)
- [x] Existing tests still pass — 12/12 pass (10 original + 2 new)
- [x] Build succeeds — confirmed, lint warnings only

---

## Verification Summary

### Source Cross-Reference

Verified against `BalancerV3ConstantProductPoolDFPkg.sol`:

| PkgInit Field | Stored as Immutable? | In facetCuts()? | Mock Used |
|---|---|---|---|
| `balancerV3VaultAwareFacet` | Yes | Yes | Real facet |
| `betterBalancerV3PoolTokenFacet` | Yes | Yes | Real facet |
| `defaultPoolInfoFacet` | Yes | Yes | MockPoolInfoFacet |
| `standardSwapFeePercentageBoundsFacet` | **No** | **No** | MockSwapFeeBoundsFacet |
| `unbalancedLiquidityInvariantRatioBoundsFacet` | **No** | **No** | MockInvariantRatioBoundsFacet |
| `balancerV3AuthenticationFacet` | Yes | Yes | Real facet |
| `balancerV3ConstProdPoolFacet` | Yes | Yes | Real facet |

The constructor ignores both fields entirely — they are accepted in the struct but never assigned to immutables. The `facetCuts()` method references only the 5 stored immutables. This confirms the mocks and regression tests are correctly placed.

### Test Results

```
12/12 pass
- test_authFacet_selectors (PASS)
- test_constProdFacet_selectors (PASS)
- test_diamondConfig_realFacets (PASS)
- test_facetCuts_listAllSelectors_realFacets (PASS)
- test_facetCuts_noSelectorCollisions_realFacets (PASS)
- test_facetCuts_selectorCount_realFacets (PASS)
- test_facetInterfaces_realFacets (PASS)
- test_invariantRatioBoundsFacet_notInFacetCuts (PASS)
- test_packageMetadata_realFacets (PASS)
- test_poolTokenFacet_selectors (PASS)
- test_swapFeeBoundsFacet_notInFacetCuts (PASS)
- test_vaultAwareFacet_selectors (PASS)
```

---

## Review Findings

### Finding 1: Mock interface fidelity is correct
**File:** BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol:482-543
**Severity:** Info (positive)
**Description:** Both new mocks correctly implement `IFacet` and return the actual selectors from their respective interfaces (`ISwapFeePercentageBounds` with 2 selectors, `IUnbalancedLiquidityInvariantRatioBounds` with 2 selectors). If these fields are ever wired into `facetCuts()`, the mocks will provide the correct selectors rather than the unrelated `IPoolInfo` selectors that were previously reused.
**Status:** Resolved (no action needed)

### Finding 2: Regression tests use correct assertion pattern
**File:** BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol:385-411
**Severity:** Info (positive)
**Description:** The two `notInFacetCuts` tests iterate all `FacetCut` entries and assert that the mock addresses do NOT appear. This is the right approach — it will break immediately if the constructor ever starts storing these fields, serving as a clear regression tripwire.
**Status:** Resolved (no action needed)

### Finding 3: Minor code duplication in mock `facetMetadata()`
**File:** BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol:498-507, 533-542
**Severity:** Low
**Description:** Each mock duplicates its interface/selector arrays across `facetInterfaces()`, `facetFuncs()`, and `facetMetadata()`. This is consistent with the existing `MockPoolInfoFacet` pattern (lines 460-472) so it's not a deviation. However, `facetMetadata()` could delegate to `facetInterfaces()` and `facetFuncs()` to avoid the duplication. This is a very minor style preference and not a required change.
**Status:** Resolved (consistent with existing pattern, no change needed)

---

## Suggestions

### Suggestion 1: Consider extracting mocks to shared test utilities
**Priority:** Low (future cleanup)
**Description:** If additional DFPkg tests need these same mocks, they could be extracted to `contracts/protocols/dexes/balancer/v3/pool-constProd/test/` or a similar shared location. For now, keeping them in the test file is fine since they're only used in one place.
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-256

---

## Review Summary

**Findings:** 3 (all informational/positive, 0 issues)
**Suggestions:** 1 (low priority, deferred)
**Recommendation:** **Approve** — All acceptance criteria are met. The implementation is clean: dedicated mocks return correct interface selectors, regression tests form effective tripwires, all 12 tests pass, and the code is consistent with existing patterns in the file.

---

**Review complete:** `<promise>PHASE_DONE</promise>`
