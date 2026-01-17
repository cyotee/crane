# Task CRANE-054: Add DFPkg Deployment Test for Selector Collision Detection

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-013
**Worktree:** `test/dfpkg-deployment`
**Origin:** Code review suggestion from CRANE-013

---

## Description

Add a Foundry spec that deploys `BalancerV3ConstantProductPoolDFPkg` and asserts `diamondConfig().facetCuts` contains no duplicate selectors. The package composes multiple facets that may have overlapping selectors (ERC20/ERC20Metadata).

Note: `DefaultPoolInfoFacet` is in `old/` directory (deprecated). The DFPkg's `PkgInit.defaultPoolInfoFacet` reference may need updating.

(Created from code review of CRANE-013)

## Dependencies

- CRANE-013: Balancer V3 Utilities Review (parent task)

## User Stories

### US-CRANE-054.1: Detect selector collisions at deployment

As a deployer, I want deployment tests that catch selector collisions so that misconfigured packages fail fast.

**Acceptance Criteria:**
- [x] Test deploys BalancerV3ConstantProductPoolDFPkg
- [x] Test asserts no duplicate selectors in facetCuts
- [x] Test verifies pool metadata after deployment
- [x] Test verifies vault registration flow
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**New Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol

**Potentially Modified Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol (if selector collision found)

## Inventory Check

Before starting, verify:
- [x] CRANE-013 is complete
- [x] contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol exists
- [x] Check if DefaultPoolInfoFacet reference needs updating (in old/ directory) - Note: Using MockPoolInfoFacet for testing

## Completion Criteria

- [x] All acceptance criteria met
- [x] Deployment test catches any selector collisions
- [x] `forge test` passes
- [x] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
