# Task CRANE-104: Add Burn Proportional Invariant Check

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-049
**Worktree:** `test/burn-proportional-invariant`
**Origin:** Code review suggestion from CRANE-049

---

## Description

Add an explicit burn-specific check that verifies proportional invariants tied to LP supply. This provides stronger coverage for "burn correctness" beyond the existing "reserves remain positive" assertion.

(Created from code review of CRANE-049)

## Dependencies

- CRANE-049: Add K Invariant Preservation Tests (parent task - complete)

## User Stories

### US-CRANE-104.1: Burn Proportional Invariant Tests

As a developer, I want tests that verify burns reduce reserves proportionally to LP tokens burned so that burn correctness is fully verified.

**Acceptance Criteria:**
- [ ] Test that burn reduces K proportionally to LP share burned
- [ ] Test that reserve0/reserve1 ratio remains constant after burn
- [ ] Test that LP supply reduces by exact burn amount
- [ ] Verify proportionality: `(K_after / K_before) == ((lpSupply - burned) / lpSupply)^2`
- [ ] Tests pass

## Technical Details

**Proportional Burn Invariant:**
```solidity
// Before burn
uint256 kBefore = reserve0 * reserve1;
uint256 lpSupplyBefore = pair.totalSupply();

// After burn of `burnAmount`
uint256 kAfter = reserve0New * reserve1New;
uint256 lpSupplyAfter = pair.totalSupply();

// Invariant: K scales with square of LP proportion
// (since K = r0 * r1, and both r0 and r1 scale linearly)
uint256 expectedKRatio = (lpSupplyAfter ** 2) / (lpSupplyBefore ** 2);
assertApproxEqRel(kAfter, kBefore * expectedKRatio, 1e15); // 0.1% tolerance
```

**Test Suite:** Unit

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_invariant.t.sol`

**Reference Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/handlers/CamelotV2Handler.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-049 is complete
- [ ] CamelotV2_invariant.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
