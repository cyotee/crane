# Task CRANE-038: Add Slipstream Fuzz Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-011
**Worktree:** `test/slipstream-fuzz-tests`
**Origin:** Code review suggestion from CRANE-011

---

## Description

Add fuzz tests for Slipstream quote correctness verification. The review identified this as a critical gap - there are no fuzz tests validating that quotes match actual swap execution across arbitrary parameters.

(Created from code review of CRANE-011)

## Dependencies

- CRANE-011: Slipstream Utilities Review (parent task - complete)

## User Stories

### US-CRANE-038.1: Fuzz Test Quote Correctness

As a developer, I want fuzz tests that verify Slipstream quotes match actual swap execution so that quote accuracy is proven across arbitrary inputs.

**Acceptance Criteria:**
- [ ] Fuzz test for `_quoteExactInputSingle()` with arbitrary (amountIn, tick, liquidity, zeroForOne)
- [ ] Fuzz test for `_quoteExactOutputSingle()` with arbitrary parameters
- [ ] Fuzz test verifying `quoteExactInput(quoteExactOutput(x)) ≈ x` roundtrip
- [ ] All fuzz tests use proper bounds (see recommended structure below)
- [ ] Tests pass

### US-CRANE-038.2: Fuzz Test Zap Operations

As a developer, I want fuzz tests for zap operations so that dust minimization is verified across ranges.

**Acceptance Criteria:**
- [ ] Fuzz test for zap-in dust bounds
- [ ] Fuzz test for zap-out accuracy
- [ ] Tests pass

## Technical Details

**Recommended Fuzz Test Structure:**
```solidity
function testFuzz_quoteExactInput_matchesSwap(
    uint256 amountIn,
    int24 tick,
    uint128 liquidity,
    bool zeroForOne
) public {
    amountIn = bound(amountIn, 1, 1e30);
    tick = int24(bound(int256(tick), TickMath.MIN_TICK, TickMath.MAX_TICK));
    liquidity = uint128(bound(liquidity, 1e6, type(uint128).max / 2));

    // Quote
    uint256 quoted = SlipstreamUtils._quoteExactInputSingle(...);

    // Actual swap
    MockCLPool pool = createPool(tick, liquidity);
    (,int256 amount1) = pool.swap(...);

    // Verify
    assertApproxEqAbs(quoted, uint256(-amount1), 1);
}
```

## Files to Create/Modify

**New Files:**
- `test/foundry/protocols/dexes/aerodrome/slipstream/SlipstreamUtils_fuzz.t.sol`
- `test/foundry/protocols/dexes/aerodrome/slipstream/SlipstreamZapQuoter_fuzz.t.sol`

**Reference Files:**
- `test/foundry/protocols/dexes/aerodrome/slipstream/SlipstreamUtils_quoteExactInput.t.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamUtils.sol`
- `test/foundry/protocols/dexes/aerodrome/slipstream/mocks/MockCLPool.sol`

## Inventory Check

Before starting, verify:
- [ ] Existing Slipstream tests in `test/foundry/protocols/dexes/aerodrome/slipstream/`
- [ ] MockCLPool available for swap simulation
- [ ] TestBase_Slipstream helpers available

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Fuzz tests run with default foundry fuzz runs (256+)
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
