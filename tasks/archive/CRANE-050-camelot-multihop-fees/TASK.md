# Task CRANE-050: Add Multi-Hop Swap with Directional Fees Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-13
**Dependencies:** CRANE-012
**Worktree:** `test/camelot-multihop-fees`
**Origin:** Code review suggestion from CRANE-012

---

## Description

Add tests for router multi-hop path handling with different fee configurations per hop. Each hop may have different directional fees, affecting cumulative output.

(Created from code review of CRANE-012)

## Dependencies

- CRANE-012: Camelot V2 Utilities Review (parent task - complete)

## User Stories

### US-CRANE-050.1: Multi-Hop Directional Fee Tests

As a developer, I want tests for multi-hop swaps with varying directional fees so that path accuracy is verified.

**Acceptance Criteria:**
- [x] Test path with different fee configurations per hop
- [x] Test accumulated fee impact on final output
- [x] Test path: A->B (0.3%) -> B->C (0.5%) -> C->D (0.1%)
- [x] Verify cumulative quote matches actual swap
- [x] Tests pass

## Technical Details

**Multi-hop with directional fees:**
- Each pair in the path may have different token0Fee and token1Fee
- The fee applied depends on which token is being sold at each hop
- Cumulative fees compound through the path

**Test Scenario:**
```
Path: WETH -> USDC -> ARB -> GMX
Hop 1: WETH/USDC pool (token0Fee=0.3%, token1Fee=0.5%) - selling WETH (use 0.3%)
Hop 2: USDC/ARB pool (token0Fee=0.2%, token1Fee=0.4%) - selling USDC (depends on sort)
Hop 3: ARB/GMX pool (token0Fee=0.1%, token1Fee=0.3%) - selling ARB (depends on sort)
```

**Test Suite:** Integration

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_multihop.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/camelot/v2/stubs/CamelotRouter.sol`
- `contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol`

## Inventory Check

Before starting, verify:
- [x] Router multi-hop functions exist
- [x] Can deploy multiple pairs with different fee configs

## Completion Criteria

- [x] All acceptance criteria met
- [x] `forge build` passes
- [x] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
