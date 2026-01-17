# Task CRANE-052: Add FixedPoint Rounding to Balancer V3 Swap Calculations

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-013
**Worktree:** `fix/balancer-fixedpoint-rounding`
**Origin:** Code review suggestion from CRANE-013

---

## Description

Add proper FixedPoint rounding (`mulDown`/`divUp`) to onSwap() and computeBalance() functions in the Balancer V3 constant product pool. Current implementation uses raw integer division which may favor users over the pool in edge cases with small amounts.

(Created from code review of CRANE-013)

## Dependencies

- CRANE-013: Balancer V3 Utilities Review (parent task)

## User Stories

### US-CRANE-052.1: Add pool-favorable rounding to swap calculations

As a pool operator, I want swap calculations to use proper rounding so that the pool is protected from rounding exploits.

**Acceptance Criteria:**
- [ ] `onSwap()` uses `mulDown`/`divUp` appropriately (lines 94-113)
- [ ] `computeBalance()` uses `divUp()` for pool-favorable rounding (line 84)
- [ ] Rounding follows Balancer V3 conventions (round up when charging users, round down when paying out)
- [ ] Tests verify correct rounding behavior
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol

**New/Modified Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-013 is complete
- [ ] contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol exists
- [ ] FixedPoint library is available for import

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Unit tests added for rounding edge cases
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
