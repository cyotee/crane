# Task CRANE-112: Clean Up Mock Reuse in DFPkg Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-054
**Worktree:** `fix/mock-cleanup`
**Origin:** Code review suggestion from CRANE-054

---

## Description

In `_deployPkgWithRealFacets()`, the `standardSwapFeePercentageBoundsFacet` and `unbalancedLiquidityInvariantRatioBoundsFacet` are populated with the pool-info mock. If/when those fields begin affecting `facetCuts()`, the test could become misleading.

Prefer dedicated mocks or explicit assertions that those fields are currently unused.

(Created from code review of CRANE-054)

## Dependencies

- CRANE-054: Add DFPkg Deployment Test for Selector Collision (parent task)

## User Stories

### US-CRANE-112.1: Cleaner mock usage in tests

As a developer, I want mock usage to be explicit and not reused for unrelated fields so that tests remain clear when requirements change.

**Acceptance Criteria:**
- [ ] Create dedicated mocks or stubs for `standardSwapFeePercentageBoundsFacet`
- [ ] Create dedicated mocks or stubs for `unbalancedLiquidityInvariantRatioBoundsFacet`
- [ ] Or add explicit assertion/comment that these fields are currently unused by facetCuts()
- [ ] Existing tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-054 is complete
- [ ] MockPoolInfoFacet is being reused for multiple init fields

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
