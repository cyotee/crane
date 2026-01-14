# Task CRANE-049: Add K Invariant Preservation Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-012
**Worktree:** `test/camelot-k-invariant`
**Origin:** Code review suggestion from CRANE-012

---

## Description

Add invariant fuzz tests verifying K (constant product) never decreases across all operations. This is a fundamental AMM property that ensures no value extraction.

(Created from code review of CRANE-012)

## Dependencies

- CRANE-012: Camelot V2 Utilities Review (parent task - complete)

## User Stories

### US-CRANE-049.1: K Invariant Fuzz Tests

As a developer, I want invariant tests proving K never decreases so that AMM security is verified.

**Acceptance Criteria:**
- [ ] Invariant test: K never decreases after swaps
- [ ] Invariant test: K never decreases after mints
- [ ] Invariant test: K never decreases after burns
- [ ] Test K accumulates fees (K_new >= K_old)
- [ ] Fuzz across random operation sequences
- [ ] Tests pass

## Technical Details

**Invariant Pattern:**
```solidity
function invariant_K_never_decreases() public {
    uint256 kBefore = pair.kLast();
    // Execute random operation
    uint256 kAfter = pair.kLast();
    assertGe(kAfter, kBefore);
}
```

**Key Formula:**
- Non-stable: `K = reserve0 * reserve1`
- Stable: `K = x^3*y + y^3*x` (where x, y are normalized reserves)

**Test Suite:** Invariant Fuzz

## Files to Create/Modify

**New Files:**
- `test/foundry/protocols/dexes/camelot/v2/CamelotV2_invariant.t.sol`
- `test/foundry/protocols/dexes/camelot/v2/handlers/CamelotV2Handler.sol`

**Reference Files:**
- `contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol`

## Inventory Check

Before starting, verify:
- [ ] Foundry invariant testing setup
- [ ] Handler contract pattern for state mutations
- [ ] `kLast()` accessible on pair

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Invariant tests pass with default runs
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
