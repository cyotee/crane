# Review: CRANE-049 — K Invariant Preservation Tests

## Status: Awaiting Review

## Implementation Summary

This task implements K invariant preservation tests for Camelot V2 AMM pools. The implementation verifies that the constant product formula K is properly maintained across swap, mint, and burn operations.

### Key Design Decisions

1. **Operation-Specific K Invariants**: The original assumption that "K never decreases" applies to all operations was incorrect. The correct invariants are:
   - **Swaps**: K_new >= K_old (fees accumulate)
   - **Mints**: K_new > K_old (reserves increase)
   - **Burns**: K_new < K_old proportionally (expected behavior)

2. **Handler Pattern**: Following the established `TestBase_ERC20.sol` pattern with a handler that normalizes fuzz inputs and tracks expected state.

### Files Changed

**New Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/handlers/CamelotV2Handler.sol`
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_invariant.t.sol`

**Modified Files:**
- `contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol` - Added 3 interface methods:
  - `precisionMultiplier0()`
  - `precisionMultiplier1()`
  - `setStableSwap(bool, uint112, uint112)`

### Test Results

```
Ran 2 test suites in 3.47s: 15 tests passed, 0 failed, 0 skipped

CamelotV2_invariant (10 tests):
- invariant_K_never_decreases_after_swap ✅
- invariant_K_never_decreases_after_mint ✅
- invariant_K_positive_when_reserves_positive ✅
- invariant_reserves_nonzero ✅
- test_K_increases_after_swap ✅
- test_K_increases_after_mint ✅
- test_K_stable_after_burn ✅
- test_K_accumulates_fees_over_swaps ✅
- test_random_operations_preserve_K ✅
- testPair ✅

CamelotV2_invariant_stable (5 tests):
- invariant_stable_K_never_decreases_after_swap ✅
- invariant_stable_K_never_decreases_after_mint ✅
- invariant_stable_mode_enabled ✅
- test_stable_pool_uses_stable_K_formula ✅
- testPair ✅
```

## Review Checklist

### Deliverables Present
- [x] Invariant test file exists
- [x] Handler contract exists
- [x] K never decreases across swap operations
- [x] K never decreases across mint operations
- [x] K decreases proportionally for burns (expected AMM behavior)

### Quality Checks
- [ ] Tests are comprehensive
- [ ] No regressions introduced
- [ ] Follows codebase patterns

### Build Verification
- [x] `forge build` passes
- [x] `forge test` passes (all 15 tests)

## Review Notes

**Reviewer:** GitHub Copilot
**Date:** 2026-01-17

### Feedback

- ✅ Core approach is correct: swap/mint invariants are enforced via `lastOpType` gating in the handler, which matches the “K monotonicity only applies to swaps (and effectively mints)” clarification.
- ✅ Stable-pool K computation is consistent with the Solidly-style invariant: $x^3y + y^3x = xy(x^2 + y^2)$, using `precisionMultiplier0/1` to normalize decimals.
- ✅ Interface updates to `ICamelotPair` are justified by stable-K computation and stable-mode setup, and match the existing stub implementation.

#### Issues Found (Fixed)

- Fixed a setup ordering bug where LP tokens were transferred to `address(handler)` before the handler was deployed (so LP effectively went to `address(0)`), making `removeLiquidity` a no-op and masking burn-related behavior.
- After fixing LP transfer ordering, the unit test `test_random_operations_preserve_K()` started failing because it asserted global `K_end >= K_start` across a sequence that included a burn. Burns are expected to reduce K proportionally, so the test was corrected to not include `removeLiquidity()` in that specific global monotonicity assertion.

#### Suggested Follow-ups (Optional)

- Consider adding an explicit burn-specific check (e.g., proportional invariants tied to LP supply) if we want stronger coverage for "burn correctness" beyond "reserves remain positive".
  - **Converted to task:** CRANE-104
- The task acceptance criteria line "K never decreases after burns" should remain documented as clarified/incorrect, since K decreasing on burn is expected.
  - **Converted to task:** CRANE-105

### Decision

- [x] Approved
- [ ] Changes Requested
- [ ] Blocked
