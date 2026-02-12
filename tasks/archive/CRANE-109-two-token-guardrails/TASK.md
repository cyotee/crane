# Task CRANE-109: Add 2-Token Pool Guardrails to Balancer V3 Pool

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-052
**Worktree:** `fix/two-token-guardrails`
**Origin:** Code review suggestion from CRANE-052

---

## Description

The Balancer V3 Constant Product Pool implementation assumes 2-token pools (`computeBalance()` hardcodes the "other token index"). `computeInvariant()` comments "expects exactly 2 tokens" but does not enforce it.

Add a require/assert or tighten docs to avoid misuse when callers might pass non-2-token balances.

(Created from code review of CRANE-052)

## Dependencies

- CRANE-052: Add FixedPoint Rounding to Balancer V3 Swaps (parent task)

## User Stories

### US-CRANE-109.1: Enforce 2-token pool constraint

As a developer, I want explicit guardrails on the 2-token assumption so that misuse with different token counts fails fast with a clear error.

**Acceptance Criteria:**
- [ ] `computeInvariant()` validates balances.length == 2
- [ ] `computeBalance()` validates token index bounds
- [ ] Clear error messages for constraint violations
- [ ] Add test for 3+ token array rejection
- [ ] Existing 1-token edge case test still passes (or is updated appropriately)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol

**Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol (add guardrail tests)

## Inventory Check

Before starting, verify:
- [ ] CRANE-052 is complete
- [ ] Current implementation lacks explicit 2-token validation
- [ ] Tests include a 1-token edge case for `computeInvariant()`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
