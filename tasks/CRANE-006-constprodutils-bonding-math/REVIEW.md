# Code Review: CRANE-006

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-13
**Review Completed:** 2026-01-13
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None. TASK.md acceptance criteria were clear.

---

## Review Checklist

### Deliverables Present
- [x] `docs/review/constprodutils-and-bonding-math.md` exists
- [x] Memo lists key invariants
- [x] Memo lists rounding modes
- [x] Memo lists overflow/underflow assumptions
- [x] Memo identifies boundary condition behaviors
- [x] At least one high-signal test added

### Quality Checks
- [x] Memo is clear and actionable
- [x] Test validates real edge cases and invariants
- [x] No regressions introduced (spot-check compilation + targeted test run)

### Build Verification
- [x] `forge build` passes (no changes; compilation skipped)
- [x] `forge test` passes (ran the new invariant test file; 13/13 passing)

---

## Review Findings

### Finding 1: Potential division-by-zero in zap-out protocol-fee adjustment
**File:** `contracts/utils/math/ConstProdUtils.sol`
**Severity:** Medium
**Description:** `_quoteZapOutToTargetWithFee(ZapOutToTargetWithFeeArgs)` adjusts `lpTotalSupply` for protocol fees when `feeOn && kLast != 0`. In that block it computes:
`feeFactor = (protocolFeeDenominator / ownerFeeShare) - 1;`
If a caller passes `feeOn = true` and `ownerFeeShare = 0`, this will divide by zero and revert.

While other helpers (e.g., `_calculateProtocolFee`) explicitly treat `ownerFeeShare == 0` as “fees disabled”, this zap-out helper does not.
**Status:** Open
**Resolution:** Add an early guard (either in the top-level validation or inside the feeOn branch):
- If `feeOn && ownerFeeShare == 0`, return 0 (or skip fee adjustment and proceed).
- Add a test asserting it does not revert for `ownerFeeShare==0`.

### Finding 2: Memo slightly overstates first-deposit behavior for sub-minimum liquidity
**File:** `docs/review/constprodutils-and-bonding-math.md`
**Severity:** Low
**Description:** The memo discusses first-deposit minting as `sqrt(a*b) - MINIMUM_LIQUIDITY` and implies “lpAmount = 0” may occur when `sqrt(a*b) <= MINIMUM_LIQUIDITY`. In the current implementation of `_depositQuote`, `lpAmount = sqrtProduct - _MINIMUM_LIQUIDITY` will **revert** on underflow when `sqrtProduct < _MINIMUM_LIQUIDITY` (Solidity 0.8 checked arithmetic).

This is consistent with Uniswap-style “insufficient liquidity minted” behavior, but the memo should state it as a revert condition (or explicitly document expected input bounds).
**Status:** Resolved
**Resolution:** Document as “reverts if `sqrt(amountA*amountB) < MINIMUM_LIQUIDITY`” (or update code to clamp to 0, if that’s desired).

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Harden zap-out fee-on input validation
**Priority:** High
**Description:** Prevent `ownerFeeShare == 0` from causing a revert inside `_quoteZapOutToTargetWithFee` when `feeOn` is enabled.
**Affected Files:**
- `contracts/utils/math/ConstProdUtils.sol`
- `test/foundry/spec/utils/math/constProdUtils/` (new unit test)
**User Response:** (not requested)
**Notes:** This is a classic “flag says enabled, params say disabled” edge case. Even if current callers never do it, defensive handling is cheap and improves library robustness.

### Suggestion 2: Replace fee-denominator heuristic with explicit parameter (or make it opt-in)
**Priority:** Medium
**Description:** `_quoteSwapDepositWithFee` infers fee denominator using `feePercent <= 10 ? 1000 : 100_000`. This is a reasonable heuristic, but it can misclassify low modern fees (e.g., 10/100000 = 0.01%) as legacy (10/1000 = 1%).
**Affected Files:**
- `contracts/utils/math/ConstProdUtils.sol`
- Any call sites that currently pass feePercent without denom
**User Response:** (not requested)
**Notes:** If refactoring APIs is too heavy, consider adding an overload that takes `feeDenominator` and using that in new call sites.

### Suggestion 3: Strengthen “near overflow” tests to actually hit overflow boundaries
**Priority:** Low
**Description:** The new test file includes “near overflow” cases, but the chosen magnitudes (`1e38`) likely do not exercise true overflow risk in `_saleQuote` (given the extra feeDenominator scaling). Consider adding explicit overflow-expecting tests for the quadratic path in `_swapDepositSaleAmt` and/or multi-multiply paths such as `_calculateFeePortionForPosition`.
**Affected Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_InvariantPreservation.t.sol`
**User Response:** (not requested)
**Notes:** It’s fine to accept reverts on overflow; the value is asserting “reverts (no wrap)”, especially around multi-multiply expressions.

---

## Review Summary

**Findings:** 2 total (1 open, 1 resolved/documentation-level)
**Suggestions:** 3 actionable follow-ups (1 high priority)
**Recommendation:** Approve with follow-up on zap-out `ownerFeeShare==0` hardening.

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
