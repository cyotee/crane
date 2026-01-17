# Progress Log: CRANE-056

## Current Checkpoint

**Last checkpoint:** Task complete
**Next step:** Ready for review
**Build status:** Passing
**Test status:** Passing (5 new tests, all 1881 tests pass)

---

## Session Log

### 2026-01-17 - Implementation Complete

**Completed:**

1. **Verified inventory prerequisites:**
   - CRANE-014 is complete (archived)
   - `MinimalDiamondCallBackProxy` exists at `contracts/proxies/MinimalDiamondCallBackProxy.sol`
   - `Proxy.NoTargetFor` error defined at `contracts/proxies/Proxy.sol:19`

2. **Created proxy routing regression test:**
   - New file: `test/foundry/spec/introspection/ERC2535/ProxyRoutingRegression.t.sol`
   - Uses actual Diamond proxy deployed via `DiamondPackageCallBackFactory` (not `DiamondCutTargetStub`)
   - Exercises full proxy routing path through `MinimalDiamondCallBackProxy.fallback()`

3. **Test coverage:**
   - `test_proxy_removedSelector_revertsWithNoTargetFor()` - Core regression test: add facet, verify it works, remove selector, verify `Proxy.NoTargetFor` revert
   - `test_proxy_multipleRemovedSelectors_allRevertWithNoTargetFor()` - Tests multiple selectors
   - `test_proxy_partialRemoval_removedRevertsOtherWorks()` - Tests partial removal (one selector removed, other still works)
   - `test_proxy_neverRegisteredSelector_revertsWithNoTargetFor()` - Tests never-registered selector
   - `testFuzz_proxy_removedSelector_revertsWithNoTargetFor(bytes4)` - Fuzz test with any selector

4. **Build and test results:**
   - `forge build` - Passes with only lint warnings
   - `forge test` - 1881 tests passed, 0 failed, 8 skipped

**Files Created:**
- `test/foundry/spec/introspection/ERC2535/ProxyRoutingRegression.t.sol`

**Key Implementation Details:**
- Test uses `InitDevService.initEnv()` to set up factory infrastructure
- Deploys `DiamondCutFacetDFPkg` to create a Diamond proxy with `diamondCut` capability
- Adds `MockFacet` via `diamondCut`, then removes it
- Verifies both `facetAddress(selector) == address(0)` AND actual proxy revert with `Proxy.NoTargetFor`

---

### 2026-01-14 - Task Created

- Task created from code review suggestion (Suggestion 1)
- Origin: CRANE-014 REVIEW.md
- Priority: Medium
- Ready for agent assignment via /backlog:launch
