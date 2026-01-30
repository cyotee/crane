# Task CRANE-178: Integration Tests for Weighted Pool Package

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-143
**Worktree:** `test/pool-weighted-integration`
**Origin:** Code review suggestion from CRANE-143

---

## Description

Create comprehensive integration tests for WeightedPool and LBPool with actual Diamond Vault deployment. The current tests verify individual components but don't test the full integration flow with the Diamond Vault.

(Created from code review of CRANE-143)

## Dependencies

- CRANE-143: Refactor Balancer V3 Weighted Pool Package (parent task)
- CRANE-141: Refactor Balancer V3 Vault as Diamond Facets

## User Stories

### US-CRANE-178.1: WeightedPool Integration Tests

As a developer, I want integration tests for WeightedPool so that I can verify it works correctly with Diamond Vault.

**Acceptance Criteria:**
- [ ] Create integration test that deploys Diamond Vault
- [ ] Register WeightedPool via DFPkg
- [ ] Test swap operations through the vault
- [ ] Test invariant calculations through the vault
- [ ] Tests pass

### US-CRANE-178.2: LBPool Integration Tests

As a developer, I want integration tests for LBPool so that I can verify time-based weight transitions work end-to-end.

**Acceptance Criteria:**
- [ ] Create integration test that deploys Diamond Vault
- [ ] Register LBPool via DFPkg
- [ ] Test swaps at different time points
- [ ] Verify weight interpolation through vault
- [ ] Test seedless LBP configuration
- [ ] Tests pass

## Files to Create/Modify

**New Files:**
- `test/foundry/integration/protocols/dexes/balancer/v3/pool-weighted/WeightedPoolIntegration.t.sol`
- `test/foundry/integration/protocols/dexes/balancer/v3/pool-weighted/LBPoolIntegration.t.sol`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
