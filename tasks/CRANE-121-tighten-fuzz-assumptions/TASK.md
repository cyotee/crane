# Task CRANE-121: Tighten Fuzz Assumptions for Realism

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-062
**Worktree:** `feature/tighten-fuzz-assumptions`
**Origin:** Code review suggestion from CRANE-062 (Suggestion 1)

---

## Description

Add a conditional assumption to fuzz tests: if `TokenType.WITH_RATE`, then require `rateProvider != address(0)`. This keeps fuzz inputs closer to real pool configurations while preserving the alignment/order-independence goal.

Currently, fuzz tests may generate "degenerate" cases with `WITH_RATE` tokens that have zero-address rate providers, which wouldn't be valid in production.

(Created from code review of CRANE-062)

## Dependencies

- CRANE-062: Add Heterogeneous TokenConfig Order-Independence Tests (parent task)

## User Stories

### US-CRANE-121.1: Add realistic rate provider assumptions

As a developer, I want fuzz tests to use realistic token configurations so that test coverage matches production scenarios.

**Acceptance Criteria:**
- [ ] Fuzz tests assume `rateProvider != address(0)` when `tokenType == WITH_RATE`
- [ ] Tests still cover alignment and order-independence
- [ ] Tests pass with tightened assumptions

## Files to Create/Modify

**Modified Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-062 is complete
- [ ] Heterogeneous fuzz tests exist

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
