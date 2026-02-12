# Code Review: CRANE-104

**Reviewer:** Claude (Code Review Agent)
**Review Started:** 2026-02-07
**Status:** Complete

---

## Clarifying Questions

None needed. Requirements are clear from TASK.md.

---

## Acceptance Criteria Verification

### AC-1: Test that burn reduces K proportionally to LP share burned
**Status:** PASS
**Evidence:** `test_burn_K_proportional_to_LP_share()` (line 251) verifies K_after * r0_before^2 ~= K_before * r0_after^2 using scaled cross-multiplication. `invariant_burn_proportional_K()` (line 224) verifies this across all fuzz runs via `handler.burnProportionalKHeld()`. `test_sequential_burns_proportional()` (line 314) confirms it holds across 3 consecutive burns.

### AC-2: Test that reserve0/reserve1 ratio remains constant after burn
**Status:** PASS
**Evidence:** `test_burn_reserve_ratio_constant()` (line 273) cross-multiplies r0_before * r1_after vs r1_before * r0_after with 0.1% tolerance. `invariant_burn_reserve_ratio_constant()` (line 233) verifies this across all fuzz runs.

### AC-3: Test that LP supply reduces by exact burn amount
**Status:** PASS
**Evidence:** `test_burn_lp_balance_exact()` (line 295) verifies the handler's LP balance decreases by exactly the computed burn amount. Correctly uses handler balance instead of totalSupply (which is affected by `_mintFee()`). `invariant_burn_lp_balance_exact()` (line 241) verifies this across all fuzz runs.

### AC-4: Verify proportionality formula
**Status:** PASS (with notation variance)
**Note:** TASK.md specified `(K_after / K_before) == ((lpSupply - burned) / lpSupply)^2`. Implementation uses the mathematically equivalent reserve-based formulation: `K_after * r0_before^2 ~= K_before * r0_after^2`. This is actually *better* because the original formula has a flaw: `totalSupply` changes by more than `burned` due to `_mintFee()` protocol fee minting during burn. The reserve-based approach avoids this entirely.

### AC-5: Tests pass
**Status:** PASS
**Evidence:** `forge test` results: 22/22 passing (17 in CamelotV2_invariant + 5 in CamelotV2_invariant_stable). Build clean (warnings only).

---

## Review Findings

### Finding 1: Violation flags are never reset between operations
**File:** `handlers/CamelotV2Handler.sol:51-53`
**Severity:** Low (correctness concern, but mitigated)
**Description:** The boolean violation flags (`burnProportionalViolation`, `burnRatioViolation`, `burnLpBalanceViolation`) are set to `true` on violation but never reset to `false`. This means once any burn operation violates an invariant, the flag stays `true` for all subsequent invariant checks. In the current design this is actually the *intended* behavior — the invariant tests check that no burn *ever* violated the property. However, the burn tracking state variables (`burnKBefore`, `burnReserve0Before`, etc.) ARE overwritten on each burn. This means the recorded state only reflects the *last* burn operation, while the violation flags accumulate across all burns. This asymmetry is safe (a single violation permanently fails the invariant) but could be confusing for debugging — if a violation occurred on burn N, the recorded state would show burn N+M's data, not the violating burn.
**Status:** Resolved (acceptable design)
**Resolution:** The never-reset pattern is intentional for invariant testing: if any burn violates the invariant, the entire test should fail. For debugging purposes, one would re-run with `-vvv` traces. No change needed.

### Finding 2: NatSpec comment regression in contract-level docs
**File:** `CamelotV2_invariant.t.sol:16-17`, `handlers/CamelotV2Handler.sol:13`
**Severity:** Informational
**Description:** The previous CRANE-049 implementation had detailed contract-level NatSpec documenting K invariant behavior by operation type (swaps increase K, mints increase K, burns decrease K proportionally). The CRANE-104 changes replaced these with simplified one-line comments like "Tests that K = reserve0 * reserve1 never decreases across swap/mint/burn operations" — which is actually *incorrect* (K does decrease on burns, as the prior comment correctly noted). The new comment on `CamelotV2_invariant` (line 17) implies K never decreases across *all* operations including burns, but the test `test_K_stable_after_burn` (line 166) only checks reserves remain positive, not that K didn't decrease. Similarly, `test_random_operations_preserve_K` (line 201) doesn't include burns, but its NatSpec says "random operation sequence" without clarifying burns are excluded.
**Status:** Open
**Resolution:** The contract-level NatSpec should be restored to clearly document that K decreases on burns are expected. The simplified comment is misleading.

### Finding 3: `test_K_stable_after_burn` name is misleading
**File:** `CamelotV2_invariant.t.sol:166`
**Severity:** Informational
**Description:** The function was renamed from `test_K_decreases_after_burn` (which accurately described the behavior) to `test_K_stable_after_burn`. The test body doesn't actually assert K stability — it only asserts reserves are positive. The name implies K should remain stable/unchanged after burn, which contradicts the actual AMM behavior where K *decreases* proportionally on burn.
**Status:** Open
**Resolution:** Consider renaming back to `test_K_decreases_after_burn` or `test_reserves_positive_after_burn` to accurately reflect what the test verifies.

### Finding 4: Reserve ratio tolerance uses absolute difference (handler) vs relative difference (unit tests)
**File:** `handlers/CamelotV2Handler.sol:310-315` vs `CamelotV2_invariant.t.sol:288`
**Severity:** Low
**Description:** The handler's `_checkBurnProportionalInvariants()` uses absolute tolerance `crossA / 1000` for the reserve ratio check (Check 2), while the unit test `test_burn_reserve_ratio_constant()` uses `assertApproxEqRel(crossA, crossB, 1e15)` which is a relative tolerance. These should be equivalent (both ~0.1%), but they're computed differently. The handler's absolute tolerance is derived from `crossA` only, which means the tolerance is asymmetric (it's based on one side of the comparison). If `crossB` is much larger than `crossA`, the tolerance may be too tight. This is unlikely in practice since reserves change proportionally, but it's a subtle inconsistency.
**Status:** Resolved (negligible impact)
**Resolution:** Both approaches compute approximately 0.1% tolerance. The asymmetry is negligible because reserves change by the same proportion during burns. No change needed.

### Finding 5: Proportionality check comment claims linear but verifies quadratic
**File:** `handlers/CamelotV2Handler.sol:319-323`
**Severity:** Informational
**Description:** The comment says "Equivalently: K_after * r0_before ~= K_before * r0_after (linear proportionality per reserve)" but the actual check uses `K_after * r0_before^2 ~= K_before * r0_after^2` (quadratic). The comment's "linear" form is incorrect — it should be K_after * sqrt(K_before) proportional, not the simpler form stated. The code itself is correct; only the intermediate comment line is wrong.
**Status:** Open
**Resolution:** Fix the misleading comment. The correct derivation is: if r0_after/r0_before = r1_after/r1_before = f, then K_after/K_before = f^2, so K_after * r0_before^2 = K_before * r0_after^2.

---

## Suggestions

### Suggestion 1: Add burn proportional tests to stable pool contract
**Priority:** Low
**Description:** The `CamelotV2_invariant_stable` contract does not include any burn proportional invariant tests or unit tests. Only the volatile pool contract (`CamelotV2_invariant`) has the new burn proportional coverage. The handler already tracks burn state for both pool types (since the same handler is used), so adding the 3 invariant functions to the stable contract would be straightforward.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_invariant.t.sol` (stable contract section)
**User Response:** Accepted
**Notes:** Converted to task CRANE-245

### Suggestion 2: Add debugging info to violation tracking
**Priority:** Low
**Description:** When a violation flag is set, there's no way to determine *which* burn operation caused it or what the actual values were (since state is overwritten on each burn). Consider adding a violation counter or storing the first-violating burn's data in separate variables to aid debugging.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/handlers/CamelotV2Handler.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-246

### Suggestion 3: Fix misleading NatSpec comments
**Priority:** Medium
**Description:** Several NatSpec comments were simplified in ways that make them less accurate. The contract-level doc on `CamelotV2_invariant` implies K never decreases on burns (incorrect). `test_K_stable_after_burn` implies K is stable after burn (it isn't — it decreases proportionally). The handler comment on Check 3 claims linear proportionality but verifies quadratic. These should be corrected to avoid confusion for future developers.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_invariant.t.sol`
- `test/foundry/spec/protocols/dexes/camelot/v2/handlers/CamelotV2Handler.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-247

---

## Review Summary

**Findings:** 5 (0 Critical, 0 High, 2 Low, 3 Informational)
**Suggestions:** 3 (1 Medium, 2 Low)
**Recommendation:** APPROVE with minor suggestions

The implementation is solid. All 5 acceptance criteria are met. The key design decisions (using handler LP balance instead of totalSupply, using reserve-based proportionality instead of LP-supply-based) correctly handle the `_mintFee()` complication in Camelot V2. The overflow prevention strategy (scaling down by 1e9/1e3) is appropriate for the value ranges involved. Tests cover single burns, sequential burns, and fuzz invariant testing.

The main items for follow-up are:
1. **NatSpec accuracy** — several comments were simplified to the point of being misleading
2. **Stable pool coverage** — burn proportional invariants only exist for volatile pools
3. **Debugging ergonomics** — violation tracking could preserve more context

None of these block merge.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
