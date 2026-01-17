# Task CRANE-105: Document K-on-Burn Behavior Clarification

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-049
**Worktree:** `docs/k-burn-clarification`
**Origin:** Code review suggestion from CRANE-049

---

## Description

Document that the original acceptance criterion "K never decreases after burns" is incorrect. K decreasing on burn is expected AMM behavior since burning LP tokens removes liquidity from the pool.

(Created from code review of CRANE-049)

## Dependencies

- CRANE-049: Add K Invariant Preservation Tests (parent task - complete)

## User Stories

### US-CRANE-105.1: K Invariant Documentation

As a developer, I want clear documentation on K invariant behavior so that future implementers understand the correct invariants for each operation.

**Acceptance Criteria:**
- [ ] Add NatSpec comments to CamelotV2_invariant.t.sol explaining K behavior
- [ ] Document per-operation K invariants:
  - Swaps: K_new >= K_old (fees accumulate)
  - Mints: K_new > K_old (reserves increase)
  - Burns: K_new < K_old proportionally (expected)
- [ ] Reference the correction in test file header
- [ ] Build passes

## Technical Details

**Documentation locations:**
1. Test file header comment explaining K invariants
2. Per-test NatSpec explaining what each test verifies
3. Handler contract documenting operation-specific behavior

**Example documentation:**
```solidity
/**
 * @title Camelot V2 K Invariant Tests
 * @notice Verifies constant product (K) preservation across AMM operations
 *
 * K INVARIANT RULES:
 * - Swaps:  K_new >= K_old (fees cause K to increase)
 * - Mints:  K_new > K_old  (adding liquidity increases reserves)
 * - Burns:  K_new < K_old  (removing liquidity decreases reserves)
 *
 * NOTE: The original task spec stated "K never decreases after burns" which is
 * incorrect. K decreasing on burn is expected behavior since burning LP tokens
 * removes liquidity proportionally from both reserves.
 */
```

**Test Suite:** Documentation only

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_invariant.t.sol`
- `test/foundry/spec/protocols/dexes/camelot/v2/handlers/CamelotV2Handler.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-049 is complete
- [ ] CamelotV2_invariant.t.sol exists
- [ ] CamelotV2Handler.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
