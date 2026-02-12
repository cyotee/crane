# Code Review: CRANE-035

**Reviewer:** Claude Sonnet 4
**Review Started:** 2026-01-16
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

(None.)

---

## Acceptance Criteria Verification

- [x] NatSpec `@notice` on `UniswapV4Quoter.sol` main functions noting dynamic fee limitation
	- Verified: `quoteExactInput()` / `quoteExactOutput()` include dynamic-fee warning in `@notice`.
	- Verified: library-level NatSpec includes `IMPORTANT` warning in single `@notice` block.
- [x] NatSpec `@dev` explaining that FEE_DYNAMIC flag means hooks can modify fees
	- Verified: `FEE_DYNAMIC flag = 0x800000` and `beforeSwap()` hook behavior described in library-level `@dev`.
- [x] Similar documentation on `UniswapV4ZapQuoter.sol`
	- Verified: library-level warning + dynamic-fee warning on `quoteZapInSingleCore()` and `quoteZapOutSingleCore()`.
- [x] Build succeeds
	- Verified: `forge build` succeeds (compilation skipped; warnings only).

---

## Review Findings

### Finding 1: Function-level `@notice` does not mention dynamic fee caveat
**File:** contracts/protocols/dexes/uniswap/v4/utils/UniswapV4Quoter.sol
**Severity:** Low
**Description:** The acceptance criteria calls for a `@notice` on main functions noting the dynamic-fee limitation. The current warning on `quoteExactInput()` / `quoteExactOutput()` is present, but is expressed via `@dev` (and the library-level `@notice`), not in function-level `@notice`.
**Status:** Resolved
**Resolution:** Added dynamic-fee caveat to function-level `@notice` on both `quoteExactInput()` and `quoteExactOutput()`.

### Finding 2: Duplicate `@notice` tags at library scope may not render consistently
**File:** contracts/protocols/dexes/uniswap/v4/utils/UniswapV4Quoter.sol
**Severity:** Low
**Description:** The library header uses two consecutive `@notice` tags. Some tooling concatenates, some may only surface the first; the "IMPORTANT" warning is critical enough that it's safer to keep a single `@notice` block.
**Status:** Resolved
**Resolution:** Collapsed duplicate `@notice` tags into single multi-line `@notice` block in both files.

---

## Suggestions

All suggestions have been addressed in this session:

### Suggestion 1: Surface dynamic-fee caveat in function `@notice`
**Priority:** Low
**Description:** Add/adjust NatSpec so `quoteExactInput()` / `quoteExactOutput()` have the dynamic-fee warning in `@notice` (not only `@dev`).
**Affected Files:**
- contracts/protocols/dexes/uniswap/v4/utils/UniswapV4Quoter.sol
**User Response:** Implemented
**Notes:** This is documentation-only and did not affect tests.

### Suggestion 2: Collapse duplicate library `@notice` into one
**Priority:** Low
**Description:** Replace multiple `@notice` tags with a single `@notice` block containing both the general description and the dynamic-fee warning.
**Affected Files:**
- contracts/protocols/dexes/uniswap/v4/utils/UniswapV4Quoter.sol
- contracts/protocols/dexes/uniswap/v4/utils/UniswapV4ZapQuoter.sol
**User Response:** Implemented
**Notes:** Helps doc-generation consistency.

---

## Review Summary

**Findings:** 2 (both Low, both Resolved)
**Suggestions:** 2 (both Implemented)
**Recommendation:** Approved - all acceptance criteria met, review findings addressed.

---

**Review complete:** `<promise>REVIEW_COMPLETE</promise>`
