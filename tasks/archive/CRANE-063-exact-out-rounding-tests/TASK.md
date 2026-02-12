# Task CRANE-063: Add EXACT_OUT Pool-Favorable Rounding Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-14
**Dependencies:** CRANE-053
**Worktree:** `test/exact-out-rounding`
**Origin:** Code review suggestion from CRANE-053 (Suggestion 4)

---

## Description

Add tests specifically asserting pool-favorable rounding behavior for `SwapKind.EXACT_OUT` swaps. For EXACT_OUT, pool-favorable rounding typically requires rounding *up* the required `amountIn` (ceiling) to avoid the pool giving away value.

The current test suite allows invariant decreases via tolerances (e.g., `- 1e9`, or 0.01%), and does not include a targeted check that EXACT_OUT uses pool-favorable rounding.

This task adds:
1. A targeted test searching for counterexamples where floor division under-charges `amountIn`
2. Tightened assertions once correctness is verified
3. Removal of overly permissive tolerances

(Created from code review of CRANE-053)

## Dependencies

- CRANE-053: Create Comprehensive Test Suite for Balancer V3 (parent task)

## User Stories

### US-CRANE-063.1: Add EXACT_OUT rounding edge case tests

As a developer, I want tests that find rounding edge cases for EXACT_OUT swaps so that pool value is never lost.

**Acceptance Criteria:**
- [x] Test searches small input space for rounding edge cases
- [x] Test identifies any cases where floor division under-charges `amountIn`
- [x] Test asserts invariant (k) never decreases after EXACT_OUT swap

### US-CRANE-063.2: Tighten rounding tolerances

As a developer, I want strict pool-favorable rounding assertions so that tolerances don't mask bugs.

**Acceptance Criteria:**
- [x] Remove or tighten "allow small decrease" tolerances
- [x] Invariant assertions use strict >= comparison (no decrease)
- [x] Tests document any legitimate tolerance reasons

### US-CRANE-063.3: Add ceil division for EXACT_OUT (if needed)

As a developer, I want EXACT_OUT to use ceiling division for amountIn if floor division causes value loss.

**Acceptance Criteria:**
- [x] Analyze if current implementation needs fix
- [x] If fix needed, implement ceil division for EXACT_OUT amountIn
- [x] Tests pass with strict assertions

## Files to Create/Modify

**Modified Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol

**Potentially Modified Contract Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol (if fix needed)

## Inventory Check

Before starting, verify:
- [x] CRANE-053 is complete
- [x] BalancerV3RoundingInvariants.t.sol exists
- [x] Current onSwap implementation uses floor division for both swap kinds

## Completion Criteria

- [x] All acceptance criteria met
- [x] All tests pass with strict assertions
- [x] `forge test` passes
- [x] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
