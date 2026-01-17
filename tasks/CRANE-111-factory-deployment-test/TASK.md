# Task CRANE-111: Add Factory Integration Deployment Test for DFPkg

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-054
**Worktree:** `test/factory-deployment-test`
**Origin:** Code review suggestion from CRANE-054

---

## Description

Add an integration-style deployment test that uses the canonical factory bootstrap (`InitDevService.initEnv(...)`) to deploy the DFPkg + proxy via `DiamondPackageCallBackFactory`, and then asserts initialization results (e.g., vault-aware storage set, token configs sorted/recorded, etc.).

This would turn "selector collision detection" into a true "deployment regression" test.

(Created from code review of CRANE-054)

## Dependencies

- CRANE-054: Add DFPkg Deployment Test for Selector Collision (parent task)

## User Stories

### US-CRANE-111.1: Full Diamond deployment path test

As a developer, I want a test that deploys via the real factory path so that initialization and postDeploy behavior is validated.

**Acceptance Criteria:**
- [ ] Test uses `InitDevService.initEnv()` for canonical bootstrap
- [ ] Test deploys DFPkg via `DiamondPackageCallBackFactory.deploy()`
- [ ] Test asserts vault-aware storage is set correctly
- [ ] Test asserts token configs are sorted/recorded
- [ ] Existing tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-054 is complete
- [ ] InitDevService and DiamondPackageCallBackFactory exist
- [ ] Real facets test provides patterns to follow

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
