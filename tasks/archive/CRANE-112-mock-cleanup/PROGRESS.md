# Progress Log: CRANE-112

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Ready for code review
**Build status:** ✅ Passes
**Test status:** ✅ 12/12 pass (including 2 new regression tests)

---

## Session Log

### 2026-02-08 - Implementation Complete

**Problem:** In `_deployPkgWithRealFacets()`, the `standardSwapFeePercentageBoundsFacet` and
`unbalancedLiquidityInvariantRatioBoundsFacet` PkgInit fields were populated with the `MockPoolInfoFacet`
(the pool-info mock). These fields are accepted by `PkgInit` but completely ignored by the DFPkg
constructor — they are never stored as immutables and never referenced in `facetCuts()`. Reusing the
pool-info mock for unrelated fields could become misleading if those fields are ever wired in.

**Solution (hybrid approach):**

1. **Created dedicated mocks:**
   - `MockSwapFeeBoundsFacet` — implements `IFacet`, returns `ISwapFeePercentageBounds` selectors
   - `MockInvariantRatioBoundsFacet` — implements `IFacet`, returns `IUnbalancedLiquidityInvariantRatioBounds` selectors

2. **Updated `_deployPkgWithRealFacets()`** to use dedicated mocks instead of reusing `poolInfoFacet`

3. **Added 2 regression tests:**
   - `test_swapFeeBoundsFacet_notInFacetCuts()` — asserts address NOT in any `FacetCut`
   - `test_invariantRatioBoundsFacet_notInFacetCuts()` — asserts address NOT in any `FacetCut`

**Files modified:**
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol`

**Verification:**
- `forge build` — passes (lint warnings only)
- `forge test` on this file — 12/12 pass (10 existing + 2 new)

### 2026-01-17 - Task Created

- Task created from code review suggestion (Suggestion 3)
- Origin: CRANE-054 REVIEW.md
- Priority: Low
- Ready for agent assignment via /backlog:launch
