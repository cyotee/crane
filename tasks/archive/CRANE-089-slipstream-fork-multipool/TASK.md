# Task CRANE-089: Add Additional High-Liquidity Pool to Fork Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-15
**Dependencies:** CRANE-039
**Worktree:** `test/slipstream-fork-multipool`
**Origin:** Code review suggestion from CRANE-039

---

## Description

Add at least one additional high-liquidity Slipstream pool (e.g., AERO/USDC) to the fork tests. This reduces the chance of pair-specific assumptions slipping in.

If address stability at the fork block is uncertain, add a lightweight "pool exists" check and `vm.skip(true)` for that test only.

(Created from code review of CRANE-039)

## Dependencies

- CRANE-039: Add Slipstream Fork Tests (Complete - parent task)

## User Stories

### US-CRANE-089.1: Add Second Pool to Fork Tests

As a developer, I want fork tests against multiple Slipstream pools so that pair-specific assumptions are caught.

**Acceptance Criteria:**
- [x] Add AERO/USDC or another high-liquidity Slipstream pool (cbBTC/WETH 0.05% CL pool)
- [x] Add pool existence check with vm.skip if pool doesn't exist at fork block
- [x] Quote accuracy tests for the new pool (4 tests: exactIn/exactOut for both directions)
- [x] Tests pass on fork (all 24 tests pass)
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/fork/base_main/slipstream/TestBase_SlipstreamFork.sol
- test/foundry/fork/base_main/slipstream/SlipstreamUtils_Fork.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-039 is complete
- [x] Fork test files exist

## Completion Criteria

- [x] All acceptance criteria met
- [x] `forge build` succeeds
- [x] Fork tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
