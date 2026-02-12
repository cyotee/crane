# Task CRANE-197: Stabilize ReClaMM Deterministic Address Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-01
**Dependencies:** CRANE-149
**Worktree:** `fix/reclamm-deterministic-address-test`
**Origin:** Code review suggestion from CRANE-149

---

## Description

Change `testDeploymentAddress()` to validate deterministic behavior without hard-coding a single expected address.

The test currently asserts a fixed address for `getDeploymentAddress(ONE_BYTES32)`. This is environment-sensitive (factory address, init code hashing, etc.) and is failing in worktrees.

Assert a property instead of a fixed address (e.g., consistency between predicted address and actual deployed pool) or gate the assertion behind an environment that pins the deployer/factory.

This makes CI/worktree differences less brittle.

(Created from code review of CRANE-149)

## Dependencies

- CRANE-149: Fork ReClaMM Pool to Local Contracts (parent task)

## User Stories

### US-CRANE-197.1: Property-Based Address Test

As a developer, I want the deterministic address test to validate behavior rather than a fixed address so that tests pass in any environment.

**Acceptance Criteria:**
- [ ] Test validates deterministic property (prediction matches actual)
- [ ] Hard-coded address assertion removed
- [ ] Test passes in worktrees and CI
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/reclamm/ReClammPoolFactory.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-149 is complete
- [ ] Test file exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
