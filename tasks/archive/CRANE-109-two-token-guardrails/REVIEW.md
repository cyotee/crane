# Code Review: CRANE-109

**Reviewer:** Claude (Opus 4.6)
**Review Started:** 2026-02-08
**Status:** Complete

---

## Clarifying Questions

No clarifying questions needed. The task requirements are clear and well-scoped.

---

## Acceptance Criteria Verification

### AC-1: `computeInvariant()` validates balances.length == 2
- **Status:** PASS
- **Location:** `BalancerV3ConstantProductPoolTarget.sol:56-58`
- **Verification:** Guard is placed as the first statement in the function, before any computation. Reverts with `BalancerV3Pool_RequiresTwoTokens(length)`.

### AC-2: `computeBalance()` validates token index bounds
- **Status:** PASS
- **Location:** `BalancerV3ConstantProductPoolTarget.sol:84-89`
- **Verification:** Two guards present: (1) length == 2 check, (2) tokenInIndex <= 1 check. Order is correct - length is checked first for better error specificity.

### AC-3: Clear error messages for constraint violations
- **Status:** PASS
- **Location:** `IBalancerV3Pool.sol:20-28`
- **Verification:** Two descriptive custom errors with NatSpec:
  - `BalancerV3Pool_RequiresTwoTokens(uint256 length)` - selector 0x832fa110 (verified with `cast sig`)
  - `BalancerV3Pool_TokenIndexOutOfBounds(uint256 index)` - selector 0x63da7284 (verified with `cast sig`)
  - Both include the offending value as a parameter for debugging.

### AC-4: Add test for 3+ token array rejection
- **Status:** PASS
- **Location:** `BalancerV3RoundingInvariants.t.sol:1054-1074` (3-token + 4-token for computeInvariant), `1109-1116` (3-token for computeBalance)
- **Verification:** Tests cover 0, 1, 3, and 4-token arrays for `computeInvariant`, and 0, 1, 3-token arrays for `computeBalance`. Fuzz test covers any non-2 length.

### AC-5: Existing 1-token edge case test still passes (or is updated appropriately)
- **Status:** PASS
- **Location:** `BalancerV3ConstantProductPoolTarget.t.sol:87-94`
- **Verification:** Test renamed from `test_computeInvariant_singleToken_returnsScaledValue` to `test_computeInvariant_singleToken_reverts`. Now correctly expects `BalancerV3Pool_RequiresTwoTokens` revert. This is the appropriate behavioral change.

### AC-6: Tests pass
- **Status:** PASS
- **Verification:** `forge test` output: 128 tests passed, 0 failed, 0 skipped across 6 test suites.

### AC-7: Build succeeds
- **Status:** PASS
- **Verification:** `forge build` succeeds. Warnings only (unchecked low-level calls in unrelated files, AST source warning for unrelated file).

---

## Review Findings

### Finding 1: Missing include-tags on new errors (NatSpec convention)
**File:** `contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol`
**Severity:** Low (documentation/style)
**Description:** The AGENTS.md specifies that documented symbols should be wrapped with AsciiDoc include-tags (`// tag::SymbolName[]` / `// end::SymbolName[]`). The two new errors lack these tags.
**Status:** Resolved - Acceptable for this task scope
**Resolution:** This is a documentation convention. The errors are fully documented with NatSpec, `@custom:signature`, and `@custom:selector`. Include-tags can be added in a docs-focused pass if the codebase requires AsciiDoc extraction for these errors.

### Finding 2: `onSwap` does not validate 2-token assumption
**File:** `BalancerV3ConstantProductPoolTarget.sol:103-125`
**Severity:** Informational
**Description:** The `onSwap` function uses `params.balancesScaled18[params.indexIn]` and `params.balancesScaled18[params.indexOut]` without validating that the balances array has exactly 2 entries or that indices are in bounds. This is consistent with the task scope (which only targets `computeInvariant` and `computeBalance`), and `onSwap` receives its params from the Balancer V3 Vault which enforces pool token counts upstream. Noting for completeness.
**Status:** Resolved - Out of scope / enforced upstream
**Resolution:** No action needed for CRANE-109. The Vault is the caller and validates pool structure.

### Finding 3: Test quality - good fuzz coverage
**File:** `BalancerV3RoundingInvariants.t.sol:1156-1177`
**Severity:** Positive finding
**Description:** The implementation includes two fuzz tests that cover the guardrails comprehensively: `testFuzz_computeInvariant_revert_wrongLength` (any length 0-10 except 2) and `testFuzz_computeBalance_revert_badIndex` (any index >= 2 up to uint256 max). This is thorough testing practice.
**Status:** N/A (positive observation)

---

## Suggestions

### Suggestion 1: Consider adding `onSwap` guardrails in a follow-up
**Priority:** Low
**Description:** For defense-in-depth, `onSwap` could validate `params.balancesScaled18.length == 2` and `params.indexIn <= 1 && params.indexOut <= 1`. This is not critical since the Balancer Vault enforces pool structure, but would make the contract self-contained.
**Affected Files:**
- `contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-248. This would add ~150 gas per swap call. May not be worth the tradeoff given Vault enforcement.

---

## Review Summary

**Findings:** 3 (1 low/style, 1 informational/out-of-scope, 1 positive)
**Suggestions:** 1 (low priority)
**Recommendation:** **APPROVE** - All acceptance criteria are met. The implementation is clean, well-guarded, and thoroughly tested with both unit and fuzz tests. Error definitions follow Crane conventions (interface placement, NatSpec + selectors). The test changes to the existing 1-token test case are appropriate.

---

**Review complete.**
