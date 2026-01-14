# Task CRANE-055: Implement Balancer V3 Weighted Pool Facet/Target

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-013
**Worktree:** `feature/weighted-pool-facet`
**Origin:** Code review suggestion from CRANE-013

---

## Description

Implement facet and target wrappers for the existing BalancerV38020WeightedPoolMath library. The math library is comprehensive but has no corresponding facet/target implementation to expose it through the diamond pattern.

(Created from code review of CRANE-013)

## Dependencies

- CRANE-013: Balancer V3 Utilities Review (parent task)

## User Stories

### US-CRANE-055.1: Create weighted pool facet

As a developer, I want a weighted pool facet so that I can use 80/20 weighted pool math through the diamond pattern.

**Acceptance Criteria:**
- [ ] Create BalancerV3WeightedPoolFacet exposing math library functions
- [ ] Facet implements IFacet interface
- [ ] Facet properly registers ERC165 interfaces
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-055.2: Create weighted pool target

As a developer, I want a weighted pool target so that I can integrate weighted pool swaps with external protocols.

**Acceptance Criteria:**
- [ ] Create BalancerV3WeightedPoolTarget implementing IBalancerPool
- [ ] Target properly delegates to math library
- [ ] Target handles Balancer V3 vault callbacks
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolFacet.sol
- contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolTarget.sol
- contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol

**New Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolFacet.t.sol
- test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolTarget.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-013 is complete
- [ ] contracts/protocols/dexes/balancer/v3/pool-constProd/ exists as reference
- [ ] BalancerV38020WeightedPoolMath library exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Facet and target match patterns from constant product pool
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
