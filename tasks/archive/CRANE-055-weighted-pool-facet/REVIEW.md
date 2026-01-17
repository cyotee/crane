# Code Review: CRANE-055 (Re-Review)

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-17
**Status:** Complete

---

## Previous Review

The initial review (2026-01-17) found 4 findings that have been addressed:

1. **Finding 1 (Critical): Token sorting breaks weight alignment** - FIXED via `WeightedTokenConfigUtils._sortWithWeights()`
2. **Finding 2 (Medium): Max token count not enforced** - FIXED via `tokensLen > 8` check
3. **Finding 3 (Low): Zero weights not rejected** - FIXED via `ZeroWeight()` validation
4. **Finding 4 (Medium): DFPkg behavior isn't tested** - FIXED via 16 new DFPkg tests

See PROGRESS.md for detailed fix notes.

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Findings

### Finding 1: Token sorting breaks weight alignment
**File:** contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol
**Severity:** Critical
**Description:** Sorting `tokenConfigs` without sorting `normalizedWeights` in lockstep can mis-assign weights to tokens, corrupting pool math.
**Status:** Resolved
**Resolution:** `calcSalt()` and `processArgs()` now sort tokens and weights atomically via `WeightedTokenConfigUtils._sortWithWeights()`. Verified by `test_processArgs_sortsWeightsAlongsideTokens`, `test_processArgs_threeTokenPool_weightsAligned`, and `test_calcSalt_weightsOrderIndependent`.

### Finding 2: Max token count not enforced
**File:** contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol
**Severity:** Medium
**Description:** Balancer pools are bounded (2–8 tokens). Missing a max-length guard allows invalid configurations.
**Status:** Resolved
**Resolution:** `calcSalt()` enforces `2 <= tokensLen <= 8` and reverts with `InvalidTokensLength(8, 2, tokensLen)`. Verified by `test_calcSalt_revertsForSingleToken`, `test_calcSalt_revertsForTooManyTokens`, and `test_calcSalt_acceptsEightTokens`.

### Finding 3: Zero weights not rejected
**File:** contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.sol
**Severity:** Low
**Description:** A zero normalized weight is nonsensical for weighted pool math and should be rejected at initialization.
**Status:** Resolved
**Resolution:** `BalancerV3WeightedPoolRepo._initialize()` now requires `normalizedWeights_.length >= 2` and reverts with `ZeroWeight()` if any weight is 0.

### Finding 4: DFPkg behavior isn’t tested
**File:** test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.t.sol
**Severity:** Medium
**Description:** DFPkg canonicalization (sorting, salt determinism, validation) previously lacked test coverage.
**Status:** Resolved
**Resolution:** Added a dedicated DFPkg spec suite covering sorting/weight alignment, salt determinism/order-independence, and bounds/length validation. Verified locally with `forge test --match-path "test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/*.t.sol"` (47/47).

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Replace `require` string with custom error
**Priority:** Low
**Description:** `WeightedTokenConfigUtils._sortWithWeights()` uses `require(..., "Length mismatch")`. Prefer a custom error for consistency, lower bytecode, and standardized revert semantics across Crane.
**Affected Files:**
- contracts/protocols/dexes/balancer/v3/pool-weighted/WeightedTokenConfigUtils.sol
**User Response:** (pending)
**Notes:** Also consider updating the docstring: `sortedConfigs = tokenConfigs;` does not copy; it sorts in-place on the memory array.

### Suggestion 2: Add explicit negative tests for weight validation
**Priority:** Low
**Description:** Add unit tests asserting reverts for `ZeroWeight()` and `WeightsMustSumToOne()` during initialization, to lock in Finding 3 behavior.
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolTarget.t.sol (or a new repo-focused spec)
**User Response:** (pending)
**Notes:** Not required for correctness given current implementation, but strengthens regression coverage.

---

## Review Summary

**Findings:** 4 (all resolved)
**Suggestions:** 2 (low priority)
**Recommendation:** Approve (fixes verified; targeted tests pass)

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
