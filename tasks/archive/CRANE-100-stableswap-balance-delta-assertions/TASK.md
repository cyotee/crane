# Task CRANE-100: Assert Stable-Swap Behavior Using Balance Deltas

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-045
**Worktree:** `test/stableswap-balance-deltas`
**Origin:** Code review suggestion from CRANE-045

---

## Description

Switch stable swap tests from asserting on `CamelotV2Service._swap()` return values to measuring actual received output via token balance deltas. The `_swap()` return value uses constant-product math internally, while the actual swap execution uses stable-swap math when `stableSwap=true`.

This makes the tests robust to future changes in return semantics and ensures they test the real executed path.

(Created from code review of CRANE-045)

## Dependencies

- CRANE-045: Add Camelot V2 Stable Swap Pool Tests (parent task - complete)

## User Stories

### US-CRANE-100.1: Balance Delta Assertions

As a developer, I want stable swap tests to assert on actual token balance changes so that tests verify the real execution path rather than internal return values.

**Acceptance Criteria:**
- [x] Identify all tests that assert on `_swap()` return value
- [x] Refactor to measure balance deltas (before/after swap)
- [x] Optionally compare to `pair.getAmountOut()` for expected values
- [x] Tests for Newton-Raphson convergence now assert real executed path
- [x] Tests pass
- [x] Build succeeds

## Technical Details

**Tests to refactor:**
- `test_getY_convergence_smallAmount`
- `test_getY_convergence_largeAmount`
- `test_getY_convergence_unbalancedReserves`
- `test_swapOutput_bidirectional`
- `test_stableSwap_nearReserveLimit`
- `test_stableSwap_multipleSequentialSwaps`

**Pattern:**
```solidity
// Before
uint256 out = CamelotV2Service._swap(...);
assertGt(out, 0);

// After
uint256 balBefore = tokenOut.balanceOf(recipient);
CamelotV2Service._swap(...);
uint256 balAfter = tokenOut.balanceOf(recipient);
uint256 received = balAfter - balBefore;
assertGt(received, 0);
```

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_stableSwap.t.sol

## Inventory Check

Before starting, verify:
- [ ] CamelotV2_stableSwap.t.sol exists
- [ ] Identified tests use `_swap()` return value assertions

## Completion Criteria

- [x] All acceptance criteria met
- [x] `forge build` passes
- [x] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
