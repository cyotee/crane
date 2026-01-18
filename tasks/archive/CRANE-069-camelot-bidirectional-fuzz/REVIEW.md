# Code Review: CRANE-069

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-18
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Checklist

### Deliverables Present
- [x] Bidirectional fuzz test strengthened
- [x] Output validated against expected quotes
- [x] Each direction tested with known reserves

### Quality Checks
- [x] Fuzz tests comprehensive
- [x] No regressions introduced

### Build Verification
- [x] `forge build` passes
- [x] `forge test` passes

---

## Review Findings

### Acceptance criteria coverage

- The bidirectional fuzz test is split into two phases using `vm.snapshotState()` / `vm.revertToState()`, ensuring each direction is validated under the same initial reserve state.
- Each direction asserts output correctness against `ConstProdUtils._saleQuote(...)` with the correct directional fee.
- Fee selection is validated per direction via `CamelotV2Service._sortReservesStruct(...)`.

### Verification

- `forge build`: ok
- `forge test --match-path test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_asymmetricFees.t.sol -vvv`: 12/12 passing; fuzz runs observed for `testFuzz_asymmetricFees_bothDirections`.

### Notes

- The `assertEq` between `_swap` output and `_saleQuote` is intentionally strict. It’s good for catching math regressions, but it may become sensitive if the swap path and quote helper diverge in rounding behavior in the future.

---

## Suggestions

Actionable items for follow-up tasks:

1. If `vm.revertToState` returns a boolean in this Foundry version, consider asserting it (e.g., `assertTrue(vm.revertToState(snapshotId));`) to make snapshot failures explicit.
2. Consider re-reading reserves after `vm.revertToState(snapshotId)` (or asserting equality with the pre-snapshot reserves) to make the “known reserves” invariant explicit.
3. Consider clarifying fee units near the fuzz bounds (the `100 /* 0.1% */` comment is easy to misread without the implicit denominator).

---

## Review Summary

CRANE-069 meets requirements: bidirectional fuzz now validates both directions independently against expected quotes under a known initial reserve state (via snapshot/restore). Focused Foundry tests and build pass.

---

<promise>REVIEW_COMPLETE</promise>
