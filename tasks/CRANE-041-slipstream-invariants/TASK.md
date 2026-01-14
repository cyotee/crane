# Task CRANE-041: Add Slipstream Invariant Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-011
**Worktree:** `test/slipstream-invariants`
**Origin:** Code review suggestion from CRANE-011

---

## Description

Add invariant tests for Slipstream quote operations: reversibility (quoteExactInput roundtrips with quoteExactOutput), monotonicity (larger input yields larger output), and fee bounds (fees bounded by fee tier).

(Created from code review of CRANE-011)

## Dependencies

- CRANE-011: Slipstream Utilities Review (parent task - complete)

## User Stories

### US-CRANE-041.1: Quote Reversibility Invariant

As a developer, I want invariant tests verifying quote reversibility so that roundtrip accuracy is guaranteed.

**Acceptance Criteria:**
- [ ] Test `quoteExactInput(quoteExactOutput(x)) ≈ x` within tolerance
- [ ] Test `quoteExactOutput(quoteExactInput(x)) ≈ x` within tolerance
- [ ] Document acceptable tolerance (accounting for fees and rounding)

### US-CRANE-041.2: Monotonicity Invariant

As a developer, I want invariant tests verifying monotonicity so that larger inputs always yield larger outputs.

**Acceptance Criteria:**
- [ ] Test that `amountIn1 > amountIn2` implies `amountOut1 >= amountOut2`
- [ ] Test monotonicity across fee tiers
- [ ] Test monotonicity across liquidity levels

### US-CRANE-041.3: Fee Bounds Invariant

As a developer, I want invariant tests verifying fee bounds so that fees are properly bounded.

**Acceptance Criteria:**
- [ ] Test `feeAmount <= amountIn * fee / 1e6`
- [ ] Test fee never exceeds input
- [ ] Test fee calculation accuracy

## Technical Details

**Invariant Test Pattern (Foundry):**
```solidity
contract SlipstreamInvariantTest is StdInvariant {
    function invariant_quoteReversibility() public {
        uint256 amountIn = 1e18;
        uint256 amountOut = quote.quoteExactInputSingle(...);
        uint256 roundtrip = quote.quoteExactOutputSingle(amountOut, ...);
        assertApproxEqRel(roundtrip, amountIn, 0.01e18); // 1% tolerance
    }
}
```

## Files to Create/Modify

**New Files:**
- `test/foundry/protocols/dexes/aerodrome/slipstream/SlipstreamUtils_invariants.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamUtils.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamQuoter.sol`

## Inventory Check

Before starting, verify:
- [ ] Foundry invariant testing setup
- [ ] Quote functions accessible for invariant testing
- [ ] Handler contract pattern understood

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Invariant tests pass with default runs
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
