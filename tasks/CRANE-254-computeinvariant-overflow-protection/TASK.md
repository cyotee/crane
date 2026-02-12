# Task CRANE-254: Protect computeInvariant Overflow Boundary with mulDiv

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-108
**Worktree:** `fix/CRANE-254-computeinvariant-overflow-protection`
**Origin:** Code review suggestion from CRANE-108

---

## Description

The `computeInvariant` function in `BalancerV3ConstantProductPoolTarget` uses `FixedPoint.mulDown`/`mulUp` for the product accumulation loop. These functions overflow for balances above ~3.4e38 (since `mulDown` does `a * b / 1e18` with raw `*`). CRANE-108 replaced the `a*b/c` patterns in `onSwap` and `computeBalance` with `Math.mulDiv`, but `computeInvariant` still has the old FixedPoint-based computation, creating a practical ceiling on the overflow protection.

Replace the FixedPoint loop in `computeInvariant` with `Math.mulDiv`-based computation to match the overflow protection level already achieved in `onSwap` and `computeBalance`.

(Created from code review of CRANE-108)

## Dependencies

- CRANE-108: Use Math.mulDiv for Overflow Protection in Balancer V3 Pool (parent task, complete)

## User Stories

### US-CRANE-254.1: computeInvariant handles ultra-large balances without overflow

As a developer, I want `computeInvariant` to use `Math.mulDiv` for its internal multiplication so that pools with ultra-large balances (above ~3.4e38) don't overflow during invariant computation.

**Acceptance Criteria:**
- [ ] `computeInvariant` uses `Math.mulDiv` instead of `FixedPoint.mulDown`/`mulUp` for product accumulation
- [ ] Rounding direction is preserved (mulDown for invariant floor, mulUp for invariant ceiling)
- [ ] Add test with balances above 3.4e38 that would overflow with old implementation
- [ ] Existing tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol (computeInvariant function, ~lines 59-61)

**Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol (add overflow test)

## Inventory Check

Before starting, verify:
- [ ] CRANE-108 is complete
- [ ] BalancerV3ConstantProductPoolTarget.sol exists with computeInvariant using FixedPoint
- [ ] Math.mulDiv is available and working (proven by CRANE-108)

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
