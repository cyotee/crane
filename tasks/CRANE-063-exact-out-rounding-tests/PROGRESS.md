# Progress Log: CRANE-063

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Ready for code review
**Build status:** Passing
**Test status:** All 36 tests pass (was 29, added 7 new tests)

---

## Session Log

### 2026-01-17 - Implementation Complete

#### Summary

Implemented targeted EXACT_OUT rounding edge case tests and tightened all tolerance-based assertions to use strict invariant preservation checks.

#### Changes Made

**File Modified:** `test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol`

1. **Tightened Tolerances (US-CRANE-063.2)**
   - Line 277-282: Removed `- 1e9` tolerance, now uses strict `>=` assertion for EXACT_IN invariant
   - Line 310-318: Removed `- 1e9` tolerance, now uses strict `>=` assertion for EXACT_OUT invariant
   - Line 352-362: Renamed `testFuzz_swap_invariantPreserved` → `testFuzz_swap_invariantPreserved_exactIn`, removed 0.01% tolerance, now uses strict `>=` assertion
   - Line 578-580: Removed `- 1` tolerance from `testFuzz_productNeverDecreases`, now uses strict `>=` assertion

2. **Added New Tests (US-CRANE-063.1 and US-CRANE-063.3)**
   - `test_exactOut_smallInputSpace_noUndercharge()` - Iterates 10,000 combinations (100x100) searching for rounding edge cases
   - `test_exactOut_ceilRounding_addsOneWhenRemainder()` - Verifies divUpRaw adds 1 when remainder exists
   - `test_exactOut_noCeilPenalty_whenExactlyDivisible()` - Verifies no penalty when evenly divisible
   - `testFuzz_swap_invariantPreserved_exactOut()` - Fuzz test with strict assertion for EXACT_OUT invariant
   - `test_exactOut_extremeImbalance_invariantPreserved()` - Tests 1000:1 pool ratio edge case
   - `test_exactOut_minimumAmounts_invariantPreserved()` - Tests minimum meaningful amounts
   - `testFuzz_exactOut_chargesEnoughForKPreservation()` - Fuzz property: k must never decrease

#### Implementation Analysis (US-CRANE-063.3)

**No implementation fix needed.** The `BalancerV3ConstantProductPoolTarget.onSwap()` already uses `FixedPoint.divUpRaw()` for EXACT_OUT (line 114-115), which correctly implements ceiling division. This was verified by:
1. Reading the `divUpRaw` implementation from Balancer's FixedPoint library
2. Adding tests that verify ceil behavior (adds 1 when remainder, equals floor when exact)
3. All 36 tests pass with strict assertions

#### Test Results

```
Ran 36 tests for BalancerV3RoundingInvariants.t.sol
[PASS] All tests pass including 7 new CRANE-063 tests
Suite result: ok. 36 passed; 0 failed; 0 skipped
```

All 196 Balancer V3 tests pass (full suite).

#### Acceptance Criteria Status

**US-CRANE-063.1: Add EXACT_OUT rounding edge case tests**
- [x] Test searches small input space for rounding edge cases (`test_exactOut_smallInputSpace_noUndercharge`)
- [x] Test identifies any cases where floor division under-charges `amountIn` (none found - implementation is correct)
- [x] Test asserts invariant (k) never decreases after EXACT_OUT swap (`testFuzz_swap_invariantPreserved_exactOut`)

**US-CRANE-063.2: Tighten rounding tolerances**
- [x] Remove or tighten "allow small decrease" tolerances (all removed)
- [x] Invariant assertions use strict >= comparison (no decrease)
- [x] Tests document any legitimate tolerance reasons (none needed - pool-favorable rounding guarantees property)

**US-CRANE-063.3: Add ceil division for EXACT_OUT (if needed)**
- [x] Analyze if current implementation needs fix (no - already uses `divUpRaw`)
- [x] If fix needed, implement ceil division for EXACT_OUT amountIn (N/A)
- [x] Tests pass with strict assertions (yes, all 36 pass)

---

### 2026-01-14 - Task Created

- Task created from code review suggestion (Suggestion 4)
- Origin: CRANE-053 REVIEW.md
- Priority: Medium (P2)
- Ready for agent assignment via /backlog:launch
