# Task CRANE-245: Add Burn Proportional Tests to Stable Pool Contract

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** CRANE-104
**Worktree:** `test/CRANE-245-stable-pool-burn-proportional-tests`
**Origin:** Code review suggestion from CRANE-104

---

## Description

The `CamelotV2_invariant_stable` contract does not include any burn proportional invariant tests or unit tests. Only the volatile pool contract (`CamelotV2_invariant`) has the new burn proportional coverage. The handler already tracks burn state for both pool types (since the same handler is used), so adding the invariant functions to the stable contract is straightforward.

Note: The stable pool K formula is `K = x^3*y + y^3*x`, so the reserve-based K proportionality check may not hold in the same quadratic form as for volatile pools. The reserve ratio and LP balance checks would still apply.

(Created from code review of CRANE-104)

## Dependencies

- CRANE-104: Add Burn Proportional Invariant Check (parent task - complete)

## User Stories

### US-CRANE-245.1: Stable Pool Burn Invariant Coverage

As a developer, I want burn proportional invariant tests for stable pools so that burn correctness is verified for both pool types.

**Acceptance Criteria:**
- [ ] Add `invariant_burn_proportional_K` to stable pool contract (adapting formula for stable K)
- [ ] Add `invariant_burn_reserve_ratio_constant` to stable pool contract
- [ ] Add `invariant_burn_lp_balance_exact` to stable pool contract
- [ ] Add corresponding unit tests for stable pool burns
- [ ] Verify stable pool K formula `x^3*y + y^3*x` proportionality behavior
- [ ] Tests pass
- [ ] Build succeeds

## Technical Details

**Stable Pool K Formula:**
```solidity
// Volatile: K = x * y (quadratic proportionality on burn)
// Stable:   K = x^3*y + y^3*x (different proportionality)
```

The reserve ratio and LP balance checks should be identical. The K proportionality check needs adaptation for the stable pool formula.

**Test Suite:** Unit + Invariant

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_invariant.t.sol` (stable contract section)

## Inventory Check

Before starting, verify:
- [ ] CRANE-104 is complete
- [ ] CamelotV2_invariant.t.sol exists with stable pool contract
- [ ] CamelotV2Handler.sol already tracks burn state

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
