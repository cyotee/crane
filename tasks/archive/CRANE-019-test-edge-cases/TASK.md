# Task CRANE-019: Add Test Edge Cases and Cleanup

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-13
**Dependencies:** CRANE-003
**Worktree:** `fix/test-edge-cases`
**Origin:** Code review suggestion from CRANE-003 (Suggestion 3 - Low Priority)

---

## Description

Evaluate and implement the 2 low-priority recommendations from the CRANE-003 test framework audit:

1. **Handler re-entrancy tests** - Add tests for re-entrant calls in ERC20 handlers
2. **ComparatorRepo cleanup mechanism** - Consider adding cleanup for stored expectations

These are edge cases and hygiene improvements, not critical for current safety, but improve test framework robustness.

## Dependencies

- CRANE-003: Test Framework and IFacet Pattern Audit (parent task - COMPLETE)

## User Stories

### US-CRANE-019.1: Handler Re-entrancy Tests

As a developer, I want ERC20 handlers to test re-entrant scenarios so that I can verify tokens behave correctly under callback conditions.

**Acceptance Criteria:**
- [x] Evaluate whether `TestBase_ERC20.sol` handlers need re-entrancy test coverage
- [x] If needed, add test case for re-entrant `transfer()` or `transferFrom()` calls → **Not needed: ERC20 has no callbacks**
- [x] Document decision if re-entrancy tests are not applicable → **Documented in PROGRESS.md**
- [x] Tests pass

### US-CRANE-019.2: ComparatorRepo Cleanup Mechanism

As a developer, I want a way to clear stored expectations in ComparatorRepo so that tests can run in isolation without stale state.

**Acceptance Criteria:**
- [x] Evaluate whether `Bytes4SetComparatorRepo` needs a cleanup function
- [x] If needed, add `_clear(address subject, bytes4 selector)` function → **Not needed: Foundry isolates tests**
- [x] Document decision if cleanup is not needed (e.g., tests already isolated by fork) → **Documented in PROGRESS.md**
- [x] Tests pass

## Files to Create/Modify

**Modified Files:**
- `contracts/tokens/ERC20/TestBase_ERC20.sol` - Potentially add re-entrancy tests
- `contracts/test/comparators/Bytes4SetComparatorRepo.sol` - Potentially add cleanup function

## Inventory Check

Before starting, verify:
- [x] CRANE-003 is complete
- [x] Affected files exist and compile
- [x] Current tests pass before changes

## Notes

This task may result in documentation-only changes if the features are deemed unnecessary. The primary goal is to evaluate and document the decisions.

## Completion Criteria

- [x] Both user stories evaluated and documented
- [x] Any necessary code changes implemented → **No code changes needed**
- [x] All existing tests still pass
- [x] `forge build` succeeds
- [x] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
