# Task CRANE-108: Use Math.mulDiv for Overflow Protection in Balancer V3 Pool

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-052
**Worktree:** `fix/muldiv-overflow-protection`
**Origin:** Code review suggestion from CRANE-052

---

## Description

Both `computeBalance()` and `onSwap()` in the Balancer V3 Constant Product Pool form a product (`a * b`) before dividing. For extremely large balances, `a * b` can overflow and revert even when the final quotient would fit.

Using OpenZeppelin's 512-bit `Math.mulDiv` with explicit rounding (ceil for pool-favorable EXACT_OUT / computeBalance) would make the math more robust.

(Created from code review of CRANE-052)

## Dependencies

- CRANE-052: Add FixedPoint Rounding to Balancer V3 Swaps (parent task)

## User Stories

### US-CRANE-108.1: Prevent overflow in product intermediates

As a developer, I want the pool math to use 512-bit intermediate multiplication so that extremely large balances don't cause overflow reverts.

**Acceptance Criteria:**
- [ ] `computeBalance()` uses `Math.mulDiv(..., Rounding.Ceil)` for pool-favorable rounding
- [ ] `onSwap()` EXACT_OUT uses `Math.mulDiv(..., Rounding.Ceil)` for pool-favorable rounding
- [ ] `onSwap()` EXACT_IN uses `Math.mulDiv(..., Rounding.Floor)` or equivalent
- [ ] Add test with large balances that would overflow with raw multiplication
- [ ] Existing tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol

**Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol (add large balance test)

## Inventory Check

Before starting, verify:
- [ ] CRANE-052 is complete
- [ ] OpenZeppelin's Math library is available
- [ ] Current implementation uses raw `a * b / c` pattern

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
