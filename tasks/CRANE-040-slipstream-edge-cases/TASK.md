# Task CRANE-040: Add Slipstream Edge Case Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-011
**Worktree:** `test/slipstream-edge-cases`
**Origin:** Code review suggestion from CRANE-011

---

## Description

Add tests for edge cases identified in the Slipstream review: MIN_TICK/MAX_TICK positions, zero liquidity swaps, extreme liquidity values, and tick spacing variations.

(Created from code review of CRANE-011)

## Dependencies

- CRANE-011: Slipstream Utilities Review (parent task - complete)

## User Stories

### US-CRANE-040.1: Edge Tick Value Tests

As a developer, I want tests for edge tick values so that boundary conditions are verified.

**Acceptance Criteria:**
- [ ] Test positions at MIN_TICK
- [ ] Test positions at MAX_TICK
- [ ] Test positions spanning MIN_TICK to MAX_TICK
- [ ] Verify graceful handling at boundaries

### US-CRANE-040.2: Extreme Value Tests

As a developer, I want tests for extreme liquidity and amount values so that overflow safety is verified.

**Acceptance Criteria:**
- [ ] Test with uint128.max liquidity
- [ ] Test zero liquidity swaps (graceful failure)
- [ ] Test with very small amounts (1 wei)
- [ ] Test with very large amounts (1e30+)

### US-CRANE-040.3: Tick Spacing Variation Tests

As a developer, I want tests across all standard tick spacings so that compatibility is verified.

**Acceptance Criteria:**
- [ ] Test with tick spacing 1
- [ ] Test with tick spacing 10
- [ ] Test with tick spacing 50
- [ ] Test with tick spacing 100
- [ ] Test with tick spacing 200

### US-CRANE-040.4: Price Limit Exactness Tests

As a developer, I want tests verifying swaps stop exactly at price limits.

**Acceptance Criteria:**
- [ ] Test swap stops at sqrtPriceLimitX96
- [ ] Verify no overshoot

## Files to Create/Modify

**New Files:**
- `test/foundry/protocols/dexes/aerodrome/slipstream/SlipstreamUtils_edgeCases.t.sol`

**Reference Files:**
- `test/foundry/protocols/dexes/aerodrome/slipstream/SlipstreamUtils_quoteExactInput.t.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamUtils.sol`

## Inventory Check

Before starting, verify:
- [ ] TickMath constants (MIN_TICK, MAX_TICK) accessible
- [ ] MockCLPool supports edge configurations
- [ ] Standard tick spacings documented

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
