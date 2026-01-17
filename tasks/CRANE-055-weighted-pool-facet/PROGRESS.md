# Progress Log: CRANE-055

## Current Checkpoint

**Last checkpoint:** Review fixes complete
**Next step:** Re-review requested
**Build status:** Passing
**Test status:** 47/47 weighted pool tests, 1908/1908 total tests passing

---

## Session Log

### 2026-01-17 - Review Fixes Complete

**Review Findings Addressed:**

1. **Finding 1 (Critical): Token sorting breaks weight alignment** - FIXED
   - Created `WeightedTokenConfigUtils.sol` with `_sortWithWeights()` function
   - Updated `calcSalt()` and `processArgs()` in DFPkg to use atomic pair sorting
   - Weights now reorder alongside tokenConfigs when sorted by address

2. **Finding 2 (Medium): Max token count not enforced** - FIXED
   - Added `tokensLen > 8` check in `calcSalt()`
   - Now reverts with `InvalidTokensLength(8, 2, tokensLen)` for > 8 tokens

3. **Finding 3 (Low): Weight initialization doesn't reject zero weights** - FIXED
   - Added `ZeroWeight()` error and validation in `BalancerV3WeightedPoolRepo._initialize()`
   - Changed minimum length check from `== 0` to `< 2` to match pool usage

4. **Finding 4 (Medium): DFPkg behavior isn't tested** - FIXED
   - Created `BalancerV3WeightedPoolDFPkg.t.sol` with 16 new tests
   - Key tests: `test_processArgs_sortsWeightsAlongsideTokens`, `test_calcSalt_weightsOrderIndependent`
   - Tests verify token/weight alignment after sorting with unsorted inputs

**Files Created/Modified:**

1. **New Files:**
   - `contracts/protocols/dexes/balancer/v3/pool-weighted/WeightedTokenConfigUtils.sol` - Pair-sort utility
   - `test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.t.sol` - 16 DFPkg tests

2. **Modified Files:**
   - `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol`:
     - Import and use `WeightedTokenConfigUtils`
     - `calcSalt()`: Added max token check, use `_sortWithWeights()`
     - `processArgs()`: Use `_sortWithWeights()`, changed to `pure`
   - `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.sol`:
     - Added `ZeroWeight()` error
     - `_initialize()`: Changed min length to 2, added zero weight validation

**Test Summary:**
- WeightedPoolTarget tests: 17 passing
- WeightedPoolFacet_IFacet tests: 14 passing
- WeightedPoolDFPkg tests: 16 passing (NEW)
- Total weighted pool tests: 47 passing
- Full suite: 1908 tests passing


### 2026-01-16 - Implementation Complete

**Files Created:**

1. **Contracts:**
   - `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.sol` - Storage library for normalized weights
   - `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolTarget.sol` - Implementation with WeightedMath
   - `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolFacet.sol` - Facet with IFacet interface
   - `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol` - Diamond Factory package
   - `contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolTargetStub.sol` - Test stub

2. **Interfaces:**
   - `contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3WeightedPool.sol` - Minimal weighted pool interface

3. **Tests:**
   - `test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolTarget.t.sol` - 17 tests
   - `test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolFacet_IFacet.t.sol` - 14 tests

**Implementation Details:**

- Target implements `IBalancerV3Pool` and `IBalancerV3WeightedPool` interfaces
- Uses Balancer's `WeightedMath` library for all invariant and swap calculations
- Weights stored in `BalancerV3WeightedPoolRepo` using Diamond storage pattern
- Supports configurable weights (e.g., 80/20, 60/40, etc.)
- DFPkg follows same pattern as `BalancerV3ConstantProductPoolDFPkg`

**Test Coverage:**

- `computeInvariant` - Tests for balanced pools, rounding, edge cases
- `computeBalance` - Tests for invariant ratio handling
- `onSwap` - Tests for EXACT_IN, EXACT_OUT, both directions
- `getNormalizedWeights` - Tests for weight retrieval
- Fuzz tests for various balance and amount combinations
- IFacet compliance tests for facet metadata

### 2026-01-14 - Task Created

- Task created from code review suggestion (Suggestion 4)
- Origin: CRANE-013 REVIEW.md
- Priority: Low
- Ready for agent assignment via /backlog:launch

---

## Completion Checklist

- [x] All acceptance criteria met
- [x] Facet and target match patterns from constant product pool
- [x] `forge build` succeeds
- [x] `forge test` passes (31/31 tests)
- [x] PROGRESS.md has final summary
