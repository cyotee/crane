# Code Review: CRANE-096

**Reviewer:** Claude Opus 4.6
**Review Started:** 2026-02-07
**Status:** Complete

---

## Clarifying Questions

None needed. Task scope and acceptance criteria are clear from TASK.md.

---

## Acceptance Criteria Verification

### AC-1: Add test with `includeUnstakedFee=true` for SlipstreamQuoter
**Status:** PASS
**Evidence:** 4 new tests in `SlipstreamQuoter_tickCrossing.t.sol` (lines 329-460):
- `test_quoteExactInput_unstakedFee_reducesOutput` - exact-in with fee
- `test_quoteExactOutput_unstakedFee_increasesInput` - exact-out with fee
- `test_quoteExactInput_unstakedFee_oneForZero` - oneForZero direction
- `test_quoteExactInput_unstakedFee_tickCrossing` - multi-tick crossing

### AC-2: Add test with `includeUnstakedFee=true` for SlipstreamZapQuoter (ZapIn)
**Status:** PASS
**Evidence:** 3 new tests in `SlipstreamZapQuoter_ZapIn.t.sol` (lines 315-426):
- `test_zapIn_unstakedFee_token0_reducesSwapOutput` - token0 direction
- `test_zapIn_unstakedFee_token1_reducesSwapOutput` - token1 direction
- `test_zapIn_unstakedFee_swapAmountsDiffer` - swap amount divergence

### AC-3: Add test with `includeUnstakedFee=true` for SlipstreamZapQuoter (ZapOut)
**Status:** PASS
**Evidence:** 3 new tests in `SlipstreamZapQuoter_ZapOut.t.sol` (lines 342-451):
- `test_zapOut_unstakedFee_toToken0_reducesOutput` - token0 output
- `test_zapOut_unstakedFee_toToken1_reducesOutput` - token1 output
- `test_zapOut_unstakedFee_swapOutputReduced` - swap sub-quote validation

### AC-4: Tests assert quotes change in expected direction
**Status:** PASS
**Evidence:** Every test follows baseline-vs-fee comparison pattern:
- Quoter exact-in: `feeResult.amountOut < baseResult.amountOut` (line 358)
- Quoter exact-out: `feeResult.amountIn > baseResult.amountIn` (line 392)
- ZapIn: `feeQuote.liquidity <= baseQuote.liquidity` (lines 350, 386)
- ZapOut: `feeQuote.amountOut < baseQuote.amountOut` (lines 376, 412)

### AC-5: MockCLPool exposes configurable `unstakedFee()`
**Status:** PASS
**Evidence:** In `TestBase_Slipstream.sol`:
- `_unstakedFee` state variable (line 174)
- `unstakedFee()` changed from `pure` to `view` (line 260-262)
- `setUnstakedFee(uint24)` test helper (lines 536-538)

### AC-6: `forge build` passes
**Status:** PASS (verified 2026-02-07)

### AC-7: `forge test` passes
**Status:** PASS (192/192 tests pass, verified 2026-02-07)

---

## Review Findings

### Finding 1: ZapIn liquidity assertion uses `<=` instead of strict `<`
**File:** `SlipstreamZapQuoter_ZapIn.t.sol` lines 350, 386
**Severity:** Low (test quality)
**Description:** The ZapIn unstaked fee tests use `feeQuote.liquidity <= baseQuote.liquidity` (non-strict inequality), while the equivalent ZapOut tests use strict `<`. The non-strict version allows the fee to have zero effect, which would mean the test passes even if the feature is broken. However, this is a deliberate design choice because the binary search in `quoteZapInSingleCore` optimizes the swap amount to maximize liquidity, and with sufficient search iterations the optimizer might partially compensate for the fee impact, making the liquidity values very close or equal.
**Status:** Resolved (acceptable design choice)
**Resolution:** The `<=` is intentional because the binary search optimizer in ZapIn can adjust swap amounts to partially offset fee impact. The strict `<` in the `test_zapIn_unstakedFee_swapAmountsDiffer` test (line 421-425) provides the strict check that the swap amounts actually differ, ensuring the feature is exercised.

### Finding 2: Tick-crossing test correctly uses ~10% overshoot
**File:** `SlipstreamQuoter_tickCrossing.t.sol` lines 425-460
**Severity:** Info (positive)
**Description:** The `test_quoteExactInput_unstakedFee_tickCrossing` test uses `amountInToCross + (amountInToCross / 10)` to push ~10% past the tick boundary. This avoids the "liquidity exhaustion" trap where both baseline and fee quotes consume all available liquidity and produce identical outputs. The test also validates `baseResult.steps > 1` to confirm ticks were actually crossed.
**Status:** Resolved (good implementation)
**Resolution:** Correctly follows the documented pattern for tick-crossing tests.

### Finding 3: Tests correctly mutate pool state before comparisons
**File:** All three test files
**Severity:** Info (positive)
**Description:** Each test calls `pool.setUnstakedFee(unstakedFee)` before both baseline and fee quotes. Since the quoter only reads `pool.unstakedFee()` when `includeUnstakedFee=true`, the baseline quote (with `includeUnstakedFee=false`) correctly ignores the set fee value. The tests are non-`view` (they mutate mock state), which is correct.
**Status:** Resolved (correct pattern)

### Finding 4: ZapOut tests verify burn amounts are fee-invariant
**File:** `SlipstreamZapQuoter_ZapOut.t.sol` lines 377-378
**Severity:** Info (positive)
**Description:** The `test_zapOut_unstakedFee_toToken0_reducesOutput` test asserts that `burnAmount0` and `burnAmount1` are unchanged between baseline and fee quotes. This is a valuable correctness check: the unstaked fee should only affect the swap portion of a zap-out, not the liquidity burn calculation.
**Status:** Resolved (good test design)

---

## Suggestions

### Suggestion 1: Consider adding a quantitative fee bound assertion
**Priority:** Low
**Description:** The current tests verify directional correctness (output decreases with fee) but don't validate the magnitude. A test could assert that the output reduction is approximately proportional to the unstaked fee. For example, with a 500 pip (0.05%) unstaked fee on a 3000 pip (0.3%) base fee, the output should decrease by roughly `500/1_000_000` of the swap amount. This would catch off-by-one errors in fee arithmetic that directional tests would miss.
**Affected Files:**
- `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamQuoter_tickCrossing.t.sol`
**User Response:** (pending)
**Notes:** The invariant test suite (`invariant_quoteReversibility`) already exercises fee math broadly via fuzzing, so this is a nice-to-have rather than a gap.

### Suggestion 2: Test with maximum unstaked fee value
**Priority:** Low
**Description:** The tests use unstaked fees of 500 (0.05%) and 1000 (0.1%). Consider adding an edge case test with the maximum meaningful unstaked fee (e.g., 100_000 = 10%) to verify the quoter handles extreme fee scenarios without overflow or unexpected behavior.
**Affected Files:**
- `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamQuoter_tickCrossing.t.sol`
**User Response:** (pending)
**Notes:** Low priority since the `SwapMath.computeSwapStep` function from Uniswap V3 already handles fee parameters of any valid `uint24` value.

---

## Review Summary

**Findings:** 4 (0 bugs, 1 low-severity test quality note, 3 positive observations)
**Suggestions:** 2 (both low priority)
**Recommendation:** **APPROVE** - All acceptance criteria are met. The implementation is clean, well-structured, and correctly validates the `includeUnstakedFee` feature across all three quoter entry points (SlipstreamQuoter, ZapIn, ZapOut). The MockCLPool change is minimal and backwards-compatible. All 192 tests pass.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
