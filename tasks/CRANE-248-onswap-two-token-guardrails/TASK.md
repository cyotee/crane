# Task CRANE-248: Add onSwap 2-Token Guardrails to Balancer V3 Pool

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-109
**Worktree:** `fix/CRANE-248-onswap-two-token-guardrails`
**Origin:** Code review suggestion from CRANE-109

---

## Description

For defense-in-depth, add input validation to `onSwap` in `BalancerV3ConstantProductPoolTarget` to validate `params.balancesScaled18.length == 2` and `params.indexIn <= 1 && params.indexOut <= 1`. This is not critical since the Balancer Vault enforces pool structure upstream, but would make the contract self-contained and consistent with the guardrails already added by CRANE-109 to `computeInvariant` and `computeBalance`.

Note: This adds ~150 gas per swap call. The tradeoff is acceptable for defense-in-depth.

(Created from code review of CRANE-109)

## Dependencies

- CRANE-109: Add 2-Token Pool Guardrails to Balancer V3 Pool (parent task)

## User Stories

### US-CRANE-248.1: Defense-in-depth onSwap validation

As a developer, I want `onSwap` to validate its array length and index bounds so that the contract is self-contained and does not rely solely on upstream Vault enforcement.

**Acceptance Criteria:**
- [ ] `onSwap` validates `params.balancesScaled18.length == 2`, reverting with `BalancerV3Pool_RequiresTwoTokens`
- [ ] `onSwap` validates `params.indexIn <= 1` and `params.indexOut <= 1`, reverting with `BalancerV3Pool_TokenIndexOutOfBounds`
- [ ] Tests added for 3+ token array rejection in `onSwap`
- [ ] Tests added for out-of-bounds index rejection in `onSwap`
- [ ] Existing tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol

**Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol (or new test file)

## Inventory Check

Before starting, verify:
- [ ] CRANE-109 is complete
- [ ] `BalancerV3ConstantProductPoolTarget.sol` exists with existing guardrails from CRANE-109
- [ ] Custom errors `BalancerV3Pool_RequiresTwoTokens` and `BalancerV3Pool_TokenIndexOutOfBounds` exist in `IBalancerV3Pool.sol`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
