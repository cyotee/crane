# Task CRANE-253: Remove Empty Helper Libraries from Integration Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-111
**Worktree:** `fix/CRANE-253-remove-empty-helper-libraries`
**Origin:** Code review suggestion from CRANE-111

---

## Description

Remove the empty `PoolRoleAccountsHelper` and `LiquidityManagementHelper` libraries and their corresponding `using` directives from the ConstantProduct DFPkg integration test. These libraries have no functions and serve no purpose — they appear to be remnants from earlier development and add visual clutter.

(Created from code review of CRANE-111)

## Dependencies

- CRANE-111: Add Factory Integration Deployment Test for DFPkg (parent task, complete)

## User Stories

### US-CRANE-253.1: Remove dead code from integration test

As a developer, I want empty helper libraries removed so that the test file is cleaner and doesn't mislead readers into thinking those libraries provide functionality.

**Acceptance Criteria:**
- [ ] `PoolRoleAccountsHelper` library declaration removed
- [ ] `LiquidityManagementHelper` library declaration removed
- [ ] Both `using` directives removed from `MockBalancerV3Vault`
- [ ] No other code references these libraries
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol (lines 172-173, 260-261)

## Inventory Check

Before starting, verify:
- [ ] CRANE-111 is complete
- [ ] Integration test file exists
- [ ] Libraries are indeed empty (no functions)

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
