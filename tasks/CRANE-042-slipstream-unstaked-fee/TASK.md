# Task CRANE-042: Add Unstaked Fee Handling

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-011
**Worktree:** `feature/slipstream-unstaked-fee`
**Origin:** Code review suggestion from CRANE-011

---

## Description

Add `unstakedFee` parameter to Slipstream quote functions for accurate unstaked LP quotes. Currently quotes don't account for the `unstakedFee()` that Slipstream charges on unstaked liquidity positions, which may cause quote underestimation for non-staked positions.

(Created from code review of CRANE-011)

## Dependencies

- CRANE-011: Slipstream Utilities Review (parent task - complete)

## User Stories

### US-CRANE-042.1: Add Unstaked Fee Support to Quotes

As a developer, I want quote functions to optionally include unstaked fees so that quotes for unstaked positions are accurate.

**Acceptance Criteria:**
- [ ] `_quoteExactInputSingle()` accepts optional unstaked fee parameter
- [ ] `_quoteExactOutputSingle()` accepts optional unstaked fee parameter
- [ ] Default behavior (no unstaked fee) is unchanged for backwards compatibility
- [ ] Documentation explains when to use unstaked fee parameter
- [ ] Tests verify unstaked fee handling

## Technical Details

**Slipstream Unstaked Fee:**
- Pools charge an additional fee on swaps executed against unstaked liquidity
- Accessed via `pool.unstakedFee()` - returns additional fee in 1e6 denominator
- Total fee for unstaked = `pool.fee() + pool.unstakedFee()`

**Implementation Approach:**
```solidity
function _quoteExactInputSingle(
    ICLPool pool,
    bool zeroForOne,
    uint256 amountIn,
    uint160 sqrtPriceLimitX96,
    bool includeUnstakedFee  // NEW: optional parameter
) internal view returns (uint256 amountOut) {
    uint24 fee = pool.fee();
    if (includeUnstakedFee) {
        fee += uint24(pool.unstakedFee());
    }
    // ... existing logic with adjusted fee
}
```

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamUtils.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamQuoter.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamZapQuoter.sol`

**New/Modified Tests:**
- `test/foundry/protocols/dexes/aerodrome/slipstream/SlipstreamUtils_unstakedFee.t.sol`

## Inventory Check

Before starting, verify:
- [ ] `ICLPool.unstakedFee()` interface exists
- [ ] Understand when unstaked fee applies
- [ ] Identify all quote functions needing update

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Backwards compatible (existing calls still work)
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
