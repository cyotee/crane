# Progress: CRANE-008 — Uniswap V3 Utilities

## Status: Complete

## Work Log

### Session 1
**Date:** 2026-01-13
**Agent:** Claude Opus 4.5

**Completed:**
- [x] Review `contracts/protocols/dexes/uniswap/v3/` (vendored Uniswap V3 core)
- [x] Review `contracts/protocols/dexes/uniswap/v3/libraries/` (TickMath, SqrtPriceMath, SwapMath, FullMath, Tick, TickBitmap, Oracle, Position, LiquidityMath)
- [x] Review `UniswapV3Pool.sol` and `UniswapV3Factory.sol`
- [x] Identify Crane-specific utilities
- [x] Review test coverage (7 test files, 62 tests)
- [x] Document review findings

**Blockers:** None

## Checklist

### Inventory Check
- [x] Uniswap V3 utilities reviewed
- [x] Tick math utilities identified (TickMath.sol)
- [x] sqrtPriceX96 handling reviewed (SqrtPriceMath.sol)

### Deliverables
- [x] Review memo complete (below)
- [x] `forge build` passes
- [x] `forge test` passes (62 tests passed, 0 failed)

---

# Review Memo

## Executive Summary

Crane's Uniswap V3 integration consists of:
1. **Vendored Uniswap V3 Core Libraries** - Battle-tested math libraries from Uniswap
2. **Crane-Specific Quoter Utilities** - Custom quoting libraries for swap and zap operations
3. **Test Infrastructure** - TestBase and comprehensive unit tests

The implementation correctly wraps Uniswap V3's concentrated liquidity math while providing additional utilities for single-tick quoting, multi-tick quoting with tick crossing, and zap operations (single-sided liquidity provision).

---

## Key Invariants

### TickMath Invariants

| Invariant | Description |
|-----------|-------------|
| **Tick Bounds** | `MIN_TICK = -887272`, `MAX_TICK = 887272` |
| **Price Bounds** | `MIN_SQRT_RATIO = 4295128739`, `MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342` |
| **Bijection** | `getTickAtSqrtRatio(getSqrtRatioAtTick(tick)) == tick` (within rounding) |
| **Monotonicity** | Higher tick always means higher sqrtPriceX96 |

### SqrtPriceMath Invariants

| Invariant | Description |
|-----------|-------------|
| **Rounding Direction** | `getNextSqrtPriceFromAmount0RoundingUp` always rounds up; `getNextSqrtPriceFromAmount1RoundingDown` always rounds down |
| **Conservation** | Adding token0 decreases price; adding token1 increases price |
| **Amount Delta Signs** | Positive liquidity delta = amounts owed to pool; negative = amounts owed to user |

### SwapMath Invariants

| Invariant | Description |
|-----------|-------------|
| **Fee Handling** | Fee is deducted from input amount before computing swap step |
| **Fee Denominator** | Fees expressed in pips (1e6 = 100%) |
| **Output Cap** | For exact output, amountOut never exceeds amountRemaining |

### Liquidity Invariants

| Invariant | Description |
|-----------|-------------|
| **Range Position** | Below range: only token0 required; Above range: only token1 required; In range: both required |
| **Max Liquidity Per Tick** | `type(uint128).max / numTicks` prevents overflow |

---

## Concentrated Liquidity Handling

### sqrtPriceX96 Representation

The price is stored as a Q64.96 fixed-point square root:

```
sqrtPriceX96 = sqrt(price) * 2^96
price = token1 / token0 (reserve ratio)
```

**Key Implementation Details:**

1. **`TickMath.getSqrtRatioAtTick(tick)`**
   - Uses binary decomposition with pre-computed magic numbers
   - Computes `sqrt(1.0001^tick) * 2^96`
   - Rounds up when converting from Q128.128 to Q64.96 for consistency

2. **`TickMath.getTickAtSqrtRatio(sqrtPriceX96)`**
   - Binary search algorithm using assembly for gas efficiency
   - Computes `log_1.0001(sqrtPriceX96^2 / 2^192)`
   - Returns floor tick for given price

### Tick Math and Tick Spacing

**Standard Fee Tiers and Tick Spacings:**

| Fee Tier | Fee (bps) | Tick Spacing | Price Increment |
|----------|-----------|--------------|-----------------|
| LOW | 5 (0.05%) | 10 | ~0.1% per tick |
| MEDIUM | 30 (0.3%) | 60 | ~0.6% per tick |
| HIGH | 100 (1%) | 200 | ~2% per tick |

**Tick Boundary Handling:**
- Ticks must be multiples of tick spacing
- `TickBitmap` stores initialization state packed into uint256 words
- `nextInitializedTickWithinOneWord` searches for next active tick

---

## Crane-Specific Utilities

### UniswapV3Utils (`contracts/utils/math/UniswapV3Utils.sol`)

**Purpose:** Single-tick swap quoting without on-chain pool interaction.

**Functions:**
- `_quoteExactInputSingle(amountIn, sqrtPriceX96, liquidity, feePips, zeroForOne)` - Quote output for exact input
- `_quoteExactOutputSingle(amountOut, sqrtPriceX96, liquidity, feePips, zeroForOne)` - Quote input for exact output
- `_quoteAmountsForLiquidity(sqrtPriceX96, tickLower, tickUpper, liquidity)` - Token amounts for position
- `_quoteLiquidityForAmounts(sqrtPriceX96, tickLower, tickUpper, amount0, amount1)` - Max mintable liquidity

**Limitations:**
- Assumes swap stays within current tick (no tick crossing)
- For large swaps, use `UniswapV3Quoter` instead

### UniswapV3Quoter (`contracts/utils/math/UniswapV3Quoter.sol`)

**Purpose:** View-based multi-tick swap quoting that handles tick crossings.

**Key Features:**
- Mirrors `UniswapV3Pool.swap` logic in view function
- Reads tick bitmap and tick liquidity from pool
- Supports `maxSteps` parameter for gas-bounded quoting
- Returns detailed `SwapQuoteResult` including:
  - `amountIn`, `amountOut`, `feeAmount`
  - `sqrtPriceAfterX96`, `tickAfter`, `liquidityAfter`
  - `fullyFilled` flag and step count

### UniswapV3ZapQuoter (`contracts/utils/math/UniswapV3ZapQuoter.sol`)

**Purpose:** Single-sided liquidity provision (zap) quoting.

**Zap-In Flow:**
1. Binary search for optimal swap amount
2. Swap portion of input token to get both tokens
3. Calculate maximum mintable liquidity
4. Report dust (leftover tokens)

**Zap-Out Flow:**
1. Calculate burn amounts for liquidity
2. Swap unwanted token to wanted token
3. Report total output

**Configuration:**
- `searchIters`: Binary search iterations (default: 20)
- `maxSwapSteps`: Limit tick crossings in swap quote
- `sqrtPriceLimitX96`: Price slippage protection

---

## Test Coverage Analysis

### Existing Test Files

| File | Coverage Area |
|------|---------------|
| `UniswapV3Utils_quoteExactInput.t.sol` | Single-tick exact input quotes vs actual swaps |
| `UniswapV3Utils_quoteExactOutput.t.sol` | Single-tick exact output quotes |
| `UniswapV3Utils_LiquidityAmounts.t.sol` | Position amount calculations |
| `UniswapV3Utils_EdgeCases.t.sol` | Boundary conditions and edge cases |
| `UniswapV3Quoter_tickCrossing.t.sol` | Multi-tick quote accuracy |
| `UniswapV3ZapQuoter_ZapIn.t.sol` | Zap-in optimization |
| `UniswapV3ZapQuoter_ZapOut.t.sol` | Zap-out calculations |

### Test Patterns Used

1. **Quote vs Actual Swap Comparison** - Validates quotes match real execution
2. **Round-Trip Consistency** - amounts -> liquidity -> amounts
3. **Tick Overload Equivalence** - tick vs sqrtPriceX96 versions match
4. **Fee Tier Variation** - Tests across 0.05%, 0.3%, 1% fees
5. **Edge Cases** - Zero amounts, dust amounts, boundary ticks

---

## Missing Tests and Recommendations

### Missing Unit Tests

| Area | Recommendation | Priority |
|------|----------------|----------|
| **Oracle (TWAP)** | Test `observe()` and `snapshotCumulativesInside()` | Medium |
| **Flash Loans** | Test `flash()` callback and fee calculation | Medium |
| **Protocol Fees** | Test `setFeeProtocol()` and `collectProtocol()` | Low |
| **Extreme Ticks** | Test at MIN_TICK and MAX_TICK boundaries | Medium |

### Recommended Fuzz Tests

```solidity
// Fuzz test for TickMath bijection
function testFuzz_tickMath_bijection(int24 tick) public {
    vm.assume(tick >= TickMath.MIN_TICK && tick <= TickMath.MAX_TICK);
    uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(tick);
    int24 recoveredTick = TickMath.getTickAtSqrtRatio(sqrtPrice);
    assertEq(recoveredTick, tick);
}

// Fuzz test for quote vs actual swap
function testFuzz_quoteMatchesSwap(uint128 amountIn, bool zeroForOne) public {
    vm.assume(amountIn > 1000 && amountIn < 1e24);
    // ... setup and compare
}

// Fuzz test for liquidity round-trip
function testFuzz_liquidityRoundTrip(uint128 liquidity, int24 tickLower, int24 tickUpper) public {
    // Bound inputs appropriately
    // Test amounts -> liquidity -> amounts
}
```

### Recommended Invariant Tests

```solidity
// Handler for invariant testing
contract UniswapV3Handler is Test {
    // Track expected state
    uint256 totalLiquidity;
    mapping(bytes32 => uint128) positionLiquidity;

    function mint(...) external {
        // Update expected state
        // Call pool.mint()
    }
}

// Invariant: total liquidity equals sum of positions
function invariant_liquidityConsistency() public {
    // Verify actual matches expected
}
```

---

## Security Considerations

### Handled Correctly

1. **Reentrancy** - `lock` modifier on state-changing functions
2. **Overflow Protection** - Solidity 0.8+ with explicit `unchecked` blocks where safe
3. **Price Manipulation** - sqrtPriceLimitX96 enforced in swaps
4. **Tick Bounds** - MIN_TICK/MAX_TICK validated

### Edge Cases to Monitor

1. **Zero Liquidity** - Pool reverts on swap with zero liquidity
2. **Tick Spacing Violations** - Only ticks divisible by tickSpacing are valid
3. **Price at Boundary** - getTickAtSqrtRatio requires `sqrtPriceX96 < MAX_SQRT_RATIO`

---

## Recommendations

### Immediate

1. **Add Oracle Tests** - Test TWAP functionality if used by downstream consumers
2. **Add Extreme Value Tests** - Boundary ticks and maximum amounts

### Future Improvements

1. **Gas Benchmarks** - Add gas snapshot tests for quoting functions
2. **Integration Tests** - Test with real pool deployments on fork
3. **Documentation** - Add NatSpec to Crane-specific utilities with examples

---

## Files Reviewed

### Core Contracts

| File | LOC | Status |
|------|-----|--------|
| `libraries/TickMath.sol` | 205 | Vendored from Uniswap |
| `libraries/SqrtPriceMath.sol` | 227 | Vendored from Uniswap |
| `libraries/SwapMath.sol` | 98 | Vendored from Uniswap |
| `libraries/FullMath.sol` | 137 | Vendored from Uniswap |
| `libraries/Tick.sol` | 195 | Vendored from Uniswap |
| `libraries/TickBitmap.sol` | 78 | Vendored from Uniswap |
| `libraries/Oracle.sol` | 335 | Vendored from Uniswap |
| `libraries/Position.sol` | 93 | Vendored from Uniswap |
| `UniswapV3Pool.sol` | 869 | Vendored from Uniswap |
| `UniswapV3Factory.sol` | - | Vendored from Uniswap |

### Crane Utilities

| File | LOC | Status |
|------|-----|--------|
| `utils/math/UniswapV3Utils.sol` | 390 | Reviewed |
| `utils/math/UniswapV3Quoter.sol` | 219 | Reviewed |
| `utils/math/UniswapV3ZapQuoter.sol` | 489 | Reviewed |
| `test/bases/TestBase_UniswapV3.sol` | 283 | Reviewed |

### Test Files

| File | Tests | Status |
|------|-------|--------|
| `UniswapV3Utils_quoteExactInput.t.sol` | 7 | Reviewed |
| `UniswapV3Utils_quoteExactOutput.t.sol` | - | Reviewed |
| `UniswapV3Utils_LiquidityAmounts.t.sol` | 14 | Reviewed |
| `UniswapV3Utils_EdgeCases.t.sol` | 19 | Reviewed |
| `UniswapV3Quoter_tickCrossing.t.sol` | 2 | Reviewed |
| `UniswapV3ZapQuoter_ZapIn.t.sol` | 11 | Reviewed |
| `UniswapV3ZapQuoter_ZapOut.t.sol` | 9 | Reviewed |

---

## Conclusion

Crane's Uniswap V3 utilities are well-implemented with:
- Correct delegation to battle-tested Uniswap math libraries
- Comprehensive single-tick and multi-tick quoting
- Innovative zap functionality with binary search optimization
- Good test coverage with quote vs actual swap validation

**Primary gaps:**
- Missing Oracle/TWAP tests
- No fuzz tests for math functions
- No invariant tests for state consistency

**Recommendation:** The utilities are safe for production use. Add fuzz/invariant tests before expanding to additional downstream consumers.
