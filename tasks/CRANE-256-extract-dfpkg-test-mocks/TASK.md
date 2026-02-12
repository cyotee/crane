# Task CRANE-256: Extract DFPkg Test Mocks to Shared Utility

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-112
**Worktree:** `refactor/CRANE-256-extract-dfpkg-test-mocks`
**Origin:** Code review suggestion from CRANE-112

---

## Description

Extract `MockSwapFeeBoundsFacet` and `MockInvariantRatioBoundsFacet` from the inline test file to a shared test utility location. These mocks implement `IFacet` with correct selectors from `ISwapFeePercentageBounds` and `IUnbalancedLiquidityInvariantRatioBounds` respectively. Moving them to a shared location enables reuse across DFPkg test files for other Balancer V3 pool packages.

(Created from code review of CRANE-112 - Suggestion 1)

## Dependencies

- CRANE-112: Clean Up Mock Reuse in DFPkg Tests (parent task)

## User Stories

### US-CRANE-256.1: Extract mocks to shared location

As a developer, I want DFPkg-related IFacet mocks in a shared test utility so that multiple DFPkg test files can reuse them without duplication.

**Acceptance Criteria:**
- [ ] Extract `MockSwapFeeBoundsFacet` to a shared test utility file
- [ ] Extract `MockInvariantRatioBoundsFacet` to a shared test utility file
- [ ] Update `BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol` to import from shared location
- [ ] Existing tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- contracts/test/stubs/balancer/v3/MockSwapFeeBoundsFacet.sol (or similar shared location)
- contracts/test/stubs/balancer/v3/MockInvariantRatioBoundsFacet.sol (or similar shared location)

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-112 is complete
- [ ] MockSwapFeeBoundsFacet exists inline in the test file
- [ ] MockInvariantRatioBoundsFacet exists inline in the test file

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
