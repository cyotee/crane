# Task CRANE-251: Add Negative Test for Duplicate Token Configs

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-111
**Worktree:** `test/CRANE-251-duplicate-token-config-negative-test`
**Origin:** Code review suggestion from CRANE-111

---

## Description

Add a negative test verifying behavior when both token configs use the same token address (e.g., `TokenConfig(tokenA) + TokenConfig(tokenA)`). Depending on the DFPkg's `calcSalt` and `processArgs` behavior, this could either revert or produce an unexpected state (identical salt allowing overwrite of an existing pool deployment). A test documenting this edge case strengthens the suite.

(Created from code review of CRANE-111)

## Dependencies

- CRANE-111: Add Factory Integration Deployment Test for DFPkg (parent task, complete)

## User Stories

### US-CRANE-251.1: Duplicate token config behavior is documented via test

As a developer, I want a test that attempts to deploy a ConstantProduct pool with two identical token addresses so that the expected behavior (revert or degenerate state) is explicitly documented.

**Acceptance Criteria:**
- [ ] Test passes duplicate token configs to `BalancerV3ConstantProductPoolDFPkg`
- [ ] Test documents whether this reverts or produces unexpected state
- [ ] If it does not revert, test documents the salt collision risk
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-111 is complete
- [ ] Integration test file exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
