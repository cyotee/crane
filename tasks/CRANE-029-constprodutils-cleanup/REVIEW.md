# Code Review: CRANE-029

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-15
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

1. Do internal library functions require `@custom:signature` / `@custom:selector` tags?
	- Answer: No. These tags are meaningful for public/external ABI-entrypoints; internal functions do not have selectors.
	- Status: Resolved (file contains only `internal` functions).

---

## Acceptance Criteria Verification

### US-CRANE-029.1: Remove Dead Code

- [x] Remove commented-out code block (lines 848-1312 or equivalent)
- [x] Remove debug console imports if present
- [x] No functional changes to the contract
- [x] Tests pass
- [x] Build succeeds

### US-CRANE-029.2: Add NatSpec Documentation Tags

- [x] All public/external functions have `@custom:signature` tag
- [x] All public/external functions have `@custom:selector` tag
- [x] Tags follow Crane NatSpec standard (see CLAUDE.md)
- [x] Build succeeds

Notes:
- `contracts/utils/math/ConstProdUtils.sol` is a `library` containing only `internal` functions. Therefore the tag requirements are satisfied vacuously.
- NatSpec was improved for `_computeZapOut(..., ZapOutToTargetWithFeeArgs memory args)` to correctly document `args` as a parameter.

---

## Review Findings

### Finding 1: No behavioral diff detected
**File:** `contracts/utils/math/ConstProdUtils.sol`
**Severity:** Informational
**Description:** The diff consists of removing unused debug imports and commented-out debug/dead code plus a NatSpec parameter documentation fix. No executable code changes were observed.
**Status:** Resolved
**Resolution:** Verified via `git diff` and by running targeted Foundry tests.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Remove remaining commented-out “parameter” stubs
**Priority:** Low
**Description:** There are a few small commented-out fragments that read like previously-planned params (e.g., `// uint256 bufferPct` in `_quoteZapOutToTargetWithFee`). Consider removing them entirely or reintroducing as a real parameter if still intended.
**Affected Files:**
- `contracts/utils/math/ConstProdUtils.sol`
**Notes:** Not required for CRANE-029 acceptance, but helps keep the file consistently “dead-code free”.

---

## Review Summary

**Findings:** 0 open (1 informational resolved)
**Suggestions:** 1 low-priority cleanup suggestion
**Recommendation:** Approve

Validation performed:
- `forge build` (passes; only pre-existing warnings)
- `forge test --match-path "test/foundry/spec/utils/math/constProdUtils/*.t.sol"` (350 passing)

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`

<promise>REVIEW_COMPLETE</promise>
