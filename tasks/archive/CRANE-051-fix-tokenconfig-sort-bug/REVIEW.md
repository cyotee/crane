# Code Review: CRANE-051

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-15
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Findings

### Finding 1: Struct swap bug is fixed
**File:** contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol
**Severity:** High (would be data corruption), **Resolved in implementation**
**Description:** `_sort()` now swaps the entire `TokenConfig` struct via a temp variable, preserving the alignment of `tokenType`, `rateProvider`, and `paysYieldFees` with the correct token address.
**Status:** Resolved
**Resolution:** Verified implementation performs full-struct swaps and the accompanying tests assert field alignment preservation.

### Finding 2: Minor lint/consistency nits
**File:** contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol
**Severity:** Low
**Description:** `IERC20` is imported but not referenced directly in this file (it may only be referenced transitively via `TokenConfig`). This can contribute to compiler warnings.
**Status:** Open
**Resolution:** Suggestion captured below.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Remove unused import / reduce warnings
**Priority:** Low
**Description:** If `IERC20` is not required in scope for compilation, remove the unused import in `TokenConfigUtils.sol` to reduce warnings and keep the file minimal.
**Affected Files:**
- contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol
**User Response:** (pending)
**Notes:** If the import is actually necessary due to how the compiler resolves transitive types for `TokenConfig`, keep it and ignore this suggestion.

### Suggestion 2: Add fuzz for field alignment mapping
**Priority:** Medium
**Description:** Add a fuzz test that assigns distinct per-token metadata (e.g., `rateProvider = address(uint160(token) ^ 0x1234)`) and asserts that after sorting, each `token` still maps to its original metadata. Current fuzz tests verify ordering/length, but not alignment under arbitrary inputs.
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/utils/TokenConfigUtils.t.sol
**User Response:** (pending)
**Notes:** This would directly guard against regressions of the original “swap only token address” bug class.

---

## Review Summary

**Findings:** 2 (1 resolved, 1 low-severity nit)
**Suggestions:** 2
**Recommendation:** Approve (fix is correct and tests are strong)

Notes:
- Verified locally by running:
	- `forge test --root /Users/cyotee/Development/github-cyotee/indexedex/lib/daosys/lib/crane-wt/fix/tokenconfig-sort-bug --match-path test/foundry/spec/protocols/dexes/balancer/v3/utils/TokenConfigUtils.t.sol --color never | cat`
	- Result: 19 passed; 0 failed; 0 skipped

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
