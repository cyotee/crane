# Code Review: CRANE-066

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-18
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Checklist

### Deliverables Present
- [x] Value conservation assertions strengthened
- [x] Tests remain tolerant of fee mechanics
- [x] No brittle cross-domain accounting

### Quality Checks
- [x] Fuzz tests comprehensive
- [x] No regressions introduced

### Build Verification
- [x] `forge build` passes (via `forge test` compile step)
- [x] `forge test` passes (targeted suite)

---

## Review Findings

### ✅ Acceptance criteria coverage

- The updated `testFuzz_zapIn_valueConservation` adds an exact, input-token-domain accounting invariant:
	- `amountIn == quote.swap.amountIn + quote.amount{input} + quote.dust{input}`
	- This is consistent with `SlipstreamZapQuoter._evaluateSwapAmount`, which defines `remainingInput = p.amountIn - q.swap.amountIn` and later sets `q.amount{X}` to `used{X}` with `q.dust{X} = preUsed{X} - used{X}`.
- Swap sanity checks are strengthened appropriately:
	- Requested swap (`quote.swapAmountIn`) is bounded by input.
	- Actual swap consumption (`quote.swap.amountIn`) is bounded by request (handles partial fill / step limits).

### ✅ Fee mechanics tolerance

- The invariant uses `quote.swap.amountIn` (actual consumed) rather than `quote.swapAmountIn` (requested), so it remains valid even when the swap quote is not fully filled.
- Swap fees are inherently included in `quote.swap.amountIn` (the amount actually spent from input), so the equality remains exact.

### ⚠️ Minor robustness / clarity notes (non-blocking)

- The dust bound in this test uses `quote.dust0 + quote.dust1 <= amountIn * MAX_DUST_PERCENT / 10000`. This is “cross-domain” in principle (token0 + token1 vs tokenIn). It’s fine under the current test setup (pool initialized around 1:1, symmetric range), but could become misleading if the test is later generalized to non-1:1 prices.
- `quote.liquidity > 0` is reasonable with the current bounds, but if bounds are relaxed later it may become a fuzz flake for tiny `amountIn` or extremely narrow/odd ranges.

---

## Suggestions

Actionable items for follow-up tasks:


- Consider bounding dust only in the input token domain (e.g., `inputDust <= amountIn * MAX_DUST_PERCENT / 10000`) to avoid any future cross-domain interpretation.
- If this test is later expanded to arbitrary pool prices, consider converting the non-input-token dust into input-token value using `sqrtPriceX96` before comparing against `amountIn`.
- If fuzz flakes ever show up around `quote.liquidity > 0`, make the assertion conditional on a clearly-defined “non-degenerate” region (or add an `assume` that excludes the degenerate region).

---

## Review Summary

CRANE-066 meets the acceptance criteria: it strengthens zap-in value conservation with an exact invariant in the input token domain (robust to fees/partial fill) and retains/extends dust and sanity checks. Targeted Foundry suite `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamZapQuoter_fuzz.t.sol` passes.

---

<promise>REVIEW_COMPLETE</promise>
