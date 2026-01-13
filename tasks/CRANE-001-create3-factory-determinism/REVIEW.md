# Code Review: CRANE-001

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-12
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None.

---

## Review Findings

### Finding 1: Memo “gaps” section is now slightly stale
**File:** docs/review/create3-and-determinism.md
**Severity:** Low
**Description:** The memo lists “Salt collision with different initCode” as missing coverage, but this worktree now includes determinism/idempotency coverage via `test_create3_differentInitCode_sameSalt_returnsOriginal()` and `test_deployFacet_differentInitCode_sameSalt_returnsOriginalAndDoesNotReRegister()`.
**Status:** Open
**Resolution:** Update the memo’s coverage/gaps table to reflect the added tests (and keep “Cross-chain address prediction” as the remaining missing area if still desired).

### Finding 2: `create3WithArgs` is not idempotent and this distinction is easy to miss
**File:** contracts/factories/create3/Create3Factory.sol; contracts/utils/Creation.sol; contracts/utils/Bytecode.sol
**Severity:** Medium
**Description:** `Create3Factory.create3()` pre-checks the predicted CREATE3 address and returns the existing contract if already deployed, providing idempotent behavior for re-runnable scripts. However, `Create3Factory.create3WithArgs()` delegates directly to `Creation.create3WithArgs()` which ultimately calls `Bytecode.create3()` and will revert with `TargetAlreadyExists()` when the salt is already occupied.

This is a determinism-footgun: callers can reasonably assume `*WithArgs` has the same “replay-safe” semantics as `create3()`, but today it does not.
**Status:** Open
**Resolution:** Document the semantic difference prominently and/or add the same `predictedTarget.isContract()` guard to `create3WithArgs()` (and its `deployFacetWithArgs`/`deployPackageWithArgs` callers) depending on the intended API contract.

### Finding 3: Minor NatSpec / naming inconsistencies reduce clarity
**File:** contracts/factories/create3/Create3Factory.sol
**Severity:** Low
**Description:** The top-level NatSpec header appears copy/pasted (“Create2CallBackFactory”, typos), and `create3()` returns the final deployed target address (not the proxy), but names the return value `proxy`.
**Status:** Open
**Resolution:** Fix the NatSpec header and consider renaming the return variable to `deployment`/`target` to align with actual behavior.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Update the determinism memo coverage table
**Priority:** P2
**Description:** Adjust docs to reflect the new determinism/idempotency tests; keep the remaining gaps list accurate.
**Affected Files:**
- docs/review/create3-and-determinism.md
**User Response:** (pending)
**Notes:** The tests are in `test/foundry/spec/factories/create3/Create3Factory.t.sol`.

### Suggestion 2: Decide and codify `create3WithArgs` replay semantics
**Priority:** P1
**Description:** Either make `create3WithArgs` idempotent (match `create3`) or explicitly document that it reverts if the salt is already used; add tests for the chosen behavior.
**Affected Files:**
- contracts/factories/create3/Create3Factory.sol
- test/foundry/spec/factories/create3/Create3Factory.t.sol
- docs/review/create3-and-determinism.md (optional doc note)
**User Response:** (pending)
**Notes:** This is the most likely “surprising behavior” for downstream script authors.

### Suggestion 3: Optional “cross-chain determinism” test
**Priority:** P3
**Description:** Add a unit test that asserts the CREATE3 predicted address equals `_create3AddressFromOf(factory, salt)` and is stable for the same inputs. (This doesn’t truly test multiple chains, but it locks in the formula/implementation.)
**Affected Files:**
- test/foundry/spec/factories/create3/Create3Factory.t.sol (or Creation/Bytecode spec)
**User Response:** (pending)
**Notes:** This is mainly a regression guard against formula changes.

---

## Review Summary

**Findings:** 3 (1 medium, 2 low)
**Suggestions:** 3
**Recommendation:** Accept, with follow-ups recommended (especially clarifying/aligning `create3WithArgs` replay semantics).

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
