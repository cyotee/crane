# Code Review: CRANE-037

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-15
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None.

---

## Acceptance Criteria Verification

### US-CRANE-037.1: Volatile Pool Library
- ✅ `AerodromServiceVolatile.sol` exists and contains volatile-only functions:
	- `_swapVolatile`, `_swapDepositVolatile`, `_withdrawSwapVolatile`, `_quoteSwapDepositSaleAmtVolatile`
- ✅ All router/factory interactions explicitly use `stable: false`.
- ✅ Quoting uses `ConstProdUtils._swapDepositSaleAmt(...)` and Aerodrome fee denom `10000`.
- ✅ Tests pass: `forge test --match-path test/foundry/spec/protocols/dexes/aerodrome/v1/services/*.t.sol`.

### US-CRANE-037.2: Stable Pool Library
- ✅ `AerodromServiceStable.sol` exists and contains stable-only functions:
	- `_swapStable`, `_swapDepositStable`, `_withdrawSwapStable`, `_quoteSwapDepositSaleAmtStable`
- ✅ All router/factory interactions explicitly use `stable: true`.
- ✅ Quoting implements the stable invariant math matching `Pool.sol` (`x³y + xy³ = k`) via Newton-Raphson.
- ✅ New tests exist and pass (`AerodromServiceStable.t.sol`).

### US-CRANE-037.3: Deprecate Original Library
- ✅ `AerodromService.sol` includes a clear NatSpec deprecation notice and migration hints.
- ⚠️ The legacy test file `AerodromService.t.sol` still exercises the deprecated library directly.
	- This is fine if the intent is explicit backwards-compat coverage.
	- If the intent was “migrate tests away from deprecated APIs”, this should be updated (see Finding 1).

---

## Review Findings

### Finding 1: Legacy tests still target deprecated API
**File:** test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromService.t.sol
**Severity:** Low
**Description:** TASK.md says old tests should be updated to use `AerodromServiceVolatile`, but the legacy suite continues to call `AerodromService._swap` / `AerodromService._swapDepositVolatile` / `AerodromService._withdrawSwapVolatile`.
**Status:** Open
**Resolution:** Either (a) update this file to test the new volatile library, or (b) keep it but rename/add a header comment making it explicitly “deprecated/back-compat coverage”.

### Finding 2: “stable vs volatile slippage” test does not assert the claim
**File:** test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.t.sol
**Severity:** Low
**Description:** `test_stableVsVolatile_stableHasLowerSlippage()` currently only asserts that both swaps produce output. It does not assert that the stable pool has lower slippage / higher output.
**Status:** Open
**Resolution:** Add an assertion such as `assertGt(stableOut, volatileOut, ...)` (the stub `PoolFactory` defaults to stable fee 5 bps vs volatile fee 30 bps, so this should be deterministic under the current test setup).

### Finding 3: Potential overflow in stable swap-deposit binary search comparison
**File:** contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol
**Severity:** Low
**Description:** `_binarySearchOptimalSwapStable()` compares `remainingIn * newReserveOut` vs `swapOut * newReserveIn`. In extreme reserve/amount ranges, these multiplications can overflow.
**Status:** Open
**Resolution:** Consider using `Math.mulDiv` for both sides (or a division-based compare with explicit rounding rules) to make the quote robust for high-decimal / high-supply assets.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Clarify/back-compat intent for deprecated library tests
**Priority:** Medium
**Description:** Decide whether `AerodromService.t.sol` is meant to (a) keep verifying backwards compatibility, or (b) be migrated to `AerodromServiceVolatile` as the new canonical API. Update naming/comments accordingly.
**Affected Files:**
- test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromService.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-083

### Suggestion 2: Strengthen stable-vs-volatile comparison assertion
**Priority:** Low
**Description:** Make the "lower slippage" comparison a real assertion (`stableOut > volatileOut` or similar), or rename the test to match what it actually checks.
**Affected Files:**
- test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-084

### Suggestion 3: Consider a gas/complexity note for stable swap-deposit quoting
**Priority:** Low
**Description:** `_swapDepositStable` uses a 20-iteration binary search, each calling Newton-Raphson up to 255 iterations in the worst case. Consider documenting expected convergence/gas, or adding early-exit heuristics if this will be used heavily on-chain.
**Affected Files:**
- contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-085

---

## Review Summary

**Findings:** 3 (all Low severity)
**Suggestions:** 3
**Recommendation:** Approve with minor follow-ups (mainly test intent/clarity and one robustness improvement).

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`

<promise>REVIEW_COMPLETE</promise>
