# CRANE-078: Tighten TickMath Revert Expectations

**Status:** Complete
**Priority:** Low
**Origin:** CRANE-032 REVIEW.md Suggestion 1
**Dependencies:** CRANE-032

---

## Summary

Replace bare `vm.expectRevert()` with explicit revert reasons in TickMath tests.

## Background

During CRANE-032 (Add TickMath Bijection Fuzz Tests), the review noted that bare `vm.expectRevert()` calls could mask unrelated reverts. The Uniswap V3 TickMath library uses short revert messages that can be explicitly matched:
- `bytes("T")` for tick out-of-range in `getSqrtRatioAtTick`
- `bytes("R")` for sqrt price out-of-range in `getTickAtSqrtRatio`

## Scope

**Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/libraries/TickMath.t.sol`

## Acceptance Criteria

### US-CRANE-078.1: Tighten Revert Expectations

- [x] Replace `vm.expectRevert()` with `vm.expectRevert(bytes("T"))` for tick out-of-range tests
- [x] Replace `vm.expectRevert()` with `vm.expectRevert(bytes("R"))` for sqrt price out-of-range tests
- [x] Verify the expected revert reasons match actual library behavior
- [x] Tests pass
- [x] Build succeeds

## Verification

```bash
# Build
forge build

# Run TickMath tests
forge test --match-path test/foundry/spec/protocols/dexes/uniswap/v3/libraries/TickMath.t.sol
```

## Notes

- This is a test quality improvement with no functional changes
- If the library uses different revert reasons, update the expectations accordingly
- Check both positive (expected revert) and negative (should not revert) paths still work
