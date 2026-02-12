# Code Review: CRANE-117

**Reviewer:** Claude Opus 4.6
**Review Started:** 2026-02-08
**Status:** Complete

---

## Clarifying Questions

None needed. The task scope and prior work (CRANE-057/058/115) are well-documented in PROGRESS.md.

---

## Review Findings

### Finding 1: _assertLoupeConsistency only checks selector list lengths, not contents
**File:** test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol:1003-1008
**Severity:** Low (Informational)
**Description:** The helper compares `facets()[i].functionSelectors.length` against `facetFunctionSelectors(addr).length` but doesn't verify the actual selector values match between the two views. Since both views derive from the same underlying `Bytes4Set` via `_asArray()`, they are identical by construction, so this is not a real bug — but the assertion could be more thorough if the implementation ever changes.
**Status:** Resolved (by-design — both views call the same `_asArray()` on the same set, making value comparison redundant)

### Finding 2: No modification to production code
**File:** contracts/introspection/ERC2535/ERC2535Repo.sol
**Severity:** None (Observation)
**Description:** TASK.md listed `ERC2535Repo.sol` under "Files to Create/Modify", but no changes were made to it. PROGRESS.md correctly explains this: the core fix was already implemented by CRANE-058 (per-selector removal with conditional cleanup at lines 150-153). This task added test coverage only, which is the right decision.
**Status:** Resolved (correct approach — no code change needed)

### Finding 3: Tests correctly exercise the critical path
**File:** test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol:1028-1194
**Severity:** None (Positive)
**Description:** The three CRANE-117 tests cover the key scenarios that could expose loupe inconsistency:
1. `test_diamondCut_partialRemoval_loupeConsistency` — single-selector partial remove
2. `test_diamondCut_fullLifecycle_loupeConsistency` — add → partial remove → full remove with a second facet present
3. `test_diamondCut_partialRemoveThenReplace_loupeConsistency` — partial remove + replace interaction

These cover the gap identified in PROGRESS.md where earlier CRANE-058 tests checked individual views but not cross-view consistency.
**Status:** Resolved (good coverage)

---

## Suggestions

### Suggestion 1: Consider reusing _assertLoupeConsistency in existing tests
**Priority:** Low
**Description:** The `_assertLoupeConsistency` helper is a general-purpose diamond invariant check. It could be promoted to a shared test utility (e.g., a `Behavior_IDiamondLoupe.sol` library) and called in all diamond-related tests, not just the CRANE-117 tests. This would provide ongoing regression protection for the loupe invariant across all future diamond operations.
**Affected Files:**
- test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol
- contracts/introspection/ERC2535/ (new Behavior library)
**User Response:** (pending)
**Notes:** Not blocking. The helper works well where it is. Promoting it would be a refactor for improved reusability.

### Suggestion 2: Add a reverse-direction check in _assertLoupeConsistency
**Priority:** Low
**Description:** While the current check is mathematically sufficient (|A|=|B| and A⊆B implies A=B), explicitly verifying that every `facetAddresses()` entry also appears in `facets()` would make the invariant more self-documenting and resilient to future implementation changes.
**Affected Files:**
- test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol
**User Response:** (pending)
**Notes:** Not blocking. The length check makes this redundant, but explicit bidirectional checking improves readability.

---

## Acceptance Criteria Verification

- [x] **Validate facet's selector set is empty before removing from facetAddresses** — Already implemented by CRANE-058 at `ERC2535Repo.sol:151-153`. Verified by reading the code.
- [x] **Loupe views remain consistent after any valid removal operation** — New `_assertLoupeConsistency` helper validates all four loupe views agree. Exercised in 3 test scenarios.
- [x] **Add test coverage for partial removal edge cases** — 3 new tests + 1 helper added covering partial remove, full lifecycle, and partial-remove-then-replace.
- [x] **Tests pass** — 32/32 DiamondCut tests passing. Verified by running `forge test`.
- [x] **Build succeeds** — Zero compilation errors. Verified.

---

## Review Summary

**Findings:** 3 findings — 1 informational (selector content check is length-only), 1 observation (no prod code change, which is correct), 1 positive (good test coverage)
**Suggestions:** 2 low-priority suggestions for future improvement (promote helper to shared library; add reverse-direction check)
**Recommendation:** **APPROVE** — Task is complete. The implementation correctly identified that CRANE-058 had already resolved the core issue and added the missing holistic loupe consistency tests as the value-add. All acceptance criteria are met, all tests pass, no production code was modified (correctly so).

---
