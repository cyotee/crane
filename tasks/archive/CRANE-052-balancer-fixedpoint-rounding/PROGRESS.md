# Progress Log: CRANE-052

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Ready for code review
**Build status:** PASS (with warnings only)
**Test status:** PASS (79 tests)

---

## Session Log

### 2026-01-16 - Implementation Complete

#### Changes Made

**Modified files:**
1. `contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol`
   - Added `FixedPoint.divUpRaw()` to `computeBalance()` (line 85) for pool-favorable rounding
   - Added `FixedPoint.divUpRaw()` to `onSwap()` EXACT_OUT case (lines 114-115) for pool-favorable rounding
   - EXACT_IN case unchanged (uses raw `/` which rounds DOWN - correct for paying out tokens)

2. `test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol`
   - Added 6 new tests for EXACT_OUT rounding UP verification
   - Added 2 new tests for computeBalance rounding UP verification
   - Tests verify rounding protects the pool invariant

3. `test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.t.sol`
   - Updated `test_onSwap_exactOut_returnsCorrectInput()` to use `assertGe` instead of `assertEq` to account for round-up behavior

#### Rounding Convention Applied

Following Balancer V3 conventions:
- **Round DOWN** when paying out tokens to users (they receive less)
- **Round UP** when charging tokens from users (they pay more)

This protects the pool from rounding exploits and ensures the invariant never decreases.

#### Implementation Details

1. **`computeBalance()`**: Used `FixedPoint.divUpRaw()` because the numerator (`newInvariant * newInvariant`) is already 36 decimals and the result should be 18 decimals. Raw division avoids double-scaling.

2. **`onSwap()` EXACT_OUT**: Used `FixedPoint.divUpRaw()` because the numerator (`poolBalanceTokenIn * amountTokenOut`) is 36 decimals and the result should be 18 decimals.

3. **`onSwap()` EXACT_IN**: Kept raw `/` division which rounds DOWN - correct for calculating how much the user receives.

#### Test Results

```
Ran 4 test suites: 79 tests passed, 0 failed, 0 skipped
- BalancerV3ConstantProductPoolFacet_IFacet.t.sol: 11 passed
- BalancerV3ConstantProductPoolTarget.t.sol: 19 passed
- BalancerV3ConstantProductPoolDFPkg.t.sol: 20 passed
- BalancerV3RoundingInvariants.t.sol: 29 passed
```

Key fuzz tests verifying rounding correctness:
- `testFuzz_onSwap_exactOut_roundsUp` - Verifies EXACT_OUT always returns >= raw division
- `testFuzz_onSwap_exactOut_invariantIncreases` - Verifies invariant increases after EXACT_OUT swap
- `testFuzz_computeBalance_roundsUp` - Verifies computeBalance always returns >= raw division
- `testFuzz_roundTrip_losesValue` - Verifies round-trip swaps lose value (no arbitrage)
- `testFuzz_productNeverDecreases` - Verifies x*y product never decreases

#### Acceptance Criteria Status

- [x] `onSwap()` uses `mulDown`/`divUp` appropriately (lines 94-115)
- [x] `computeBalance()` uses `divUp()` for pool-favorable rounding (line 85)
- [x] Rounding follows Balancer V3 conventions (round up when charging users, round down when paying out)
- [x] Tests verify correct rounding behavior
- [x] Tests pass
- [x] Build succeeds

---

### 2026-01-14 - Task Created

- Task created from code review suggestion (Suggestion 2)
- Origin: CRANE-013 REVIEW.md
- Priority: Medium
- Ready for agent assignment via /backlog:launch
