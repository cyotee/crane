# Task CRANE-252: Add ConstantProduct DFPkg 3+ Token Count Revert Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-111
**Worktree:** `test/CRANE-252-constprod-token-count-revert-test`
**Origin:** Code review suggestion from CRANE-111

---

## Description

Add a test showing that `BalancerV3ConstantProductPoolDFPkg.calcSalt()` reverts when given 3+ token configs at the factory integration level. The `calcSalt` function enforces exactly 2 tokens (`tokenConfigs.length != 2` check at line 236), which is correct for constant-product (x*y=k) math. This constraint is specific to the ConstantProduct DFPkg — other Balancer pool types (weighted, stable, gyro) support multi-token configurations.

A unit test (`test_calcSalt_revertsForWrongTokenCount`) may already exist. This task adds an integration-level test confirming the factory stack also handles this correctly end-to-end.

(Created from code review of CRANE-111)

## Dependencies

- CRANE-111: Add Factory Integration Deployment Test for DFPkg (parent task, complete)

## User Stories

### US-CRANE-252.1: 3+ token rejection is tested at integration level

As a developer, I want an integration test that confirms the factory stack rejects 3+ token configs for ConstantProduct pools so that the 2-token constraint is validated end-to-end, not just at the unit level.

**Acceptance Criteria:**
- [ ] Test passes 3 token configs through `DiamondPackageCallBackFactory.deploy()`
- [ ] Test expects `InvalidTokensLength` revert from `calcSalt`
- [ ] Test confirms this is a ConstantProduct-specific constraint (not Balancer-wide)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-111 is complete
- [ ] Integration test file exists
- [ ] Check if unit-level test already exists and reference it in NatSpec

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
