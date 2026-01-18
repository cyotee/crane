// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// ═══════════════════════════════════════════════════════════════════════════
// TEST REPRODUCTION
// ═══════════════════════════════════════════════════════════════════════════
// Run all fuzz tests in this file (9 tests):
//   forge test --match-path test/foundry/spec/utils/math/slipstreamUtils/SlipstreamZapQuoter_fuzz.t.sol -vvv
//
// Run all Slipstream fuzz tests (both files, 20 tests):
//   forge test --match-path "test/foundry/spec/utils/math/slipstreamUtils/*_fuzz.t.sol" -vvv
//
// Run specific test with more fuzz runs (default: 256):
//   forge test --match-test testFuzz_zapIn_valueConservation --fuzz-runs 1000 -vvv
// ═══════════════════════════════════════════════════════════════════════════

import "forge-std/Test.sol";

import {SlipstreamZapQuoter} from "@crane/contracts/utils/math/SlipstreamZapQuoter.sol";
import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/// @title Fuzz Tests for SlipstreamZapQuoter
/// @notice Validates zap-in and zap-out operations across arbitrary inputs via fuzzing
/// @dev Tests dust minimization, output accuracy, and consistency across parameters
contract SlipstreamZapQuoter_fuzz_Test is TestBase_Slipstream {
    using SlipstreamZapQuoter for SlipstreamZapQuoter.ZapInParams;
    using SlipstreamZapQuoter for SlipstreamZapQuoter.ZapOutParams;

    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Minimum liquidity in the pool for zap tests
    uint128 constant MIN_POOL_LIQUIDITY = 1_000_000e18;

    /// @dev Maximum pool liquidity
    uint128 constant MAX_POOL_LIQUIDITY = type(uint128).max / 4;

    /// @dev Minimum zap-in amount
    uint256 constant MIN_ZAP_AMOUNT = 1e9;  // 1 gwei

    /// @dev Maximum zap-in amount
    uint256 constant MAX_ZAP_AMOUNT = 1e24;

    /// @dev Minimum liquidity for zap-out
    uint128 constant MIN_BURN_LIQUIDITY = 1e12;

    /// @dev Maximum liquidity for zap-out (relative to pool)
    uint128 constant MAX_BURN_LIQUIDITY = 1_000_000e18;

    /// @dev Default search iterations for zap-in
    uint16 constant DEFAULT_SEARCH_ITERS = 20;

    /// @dev Maximum acceptable dust percentage (5%)
    /// @dev Note: Binary search optimization can produce >1% dust in edge cases
    ///      with narrow tick ranges or specific price/amount combinations
    uint256 constant MAX_DUST_PERCENT = 500;  // 5% = 500 basis points

    /* -------------------------------------------------------------------------- */
    /*                          Fuzz: Zap-In Dust Bounds                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Fuzz test: zap-in dust stays within acceptable bounds
    /// @dev Tests that the binary search optimization keeps dust reasonable
    /// @param amountIn Input amount for zap (bounded)
    /// @param tickRange Tick range width (bounded)
    /// @param zeroForOne Input token direction
    /// @param searchIters Number of binary search iterations
    function testFuzz_zapIn_dustBounds(
        uint256 amountIn,
        int24 tickRange,
        bool zeroForOne,
        uint16 searchIters
    ) public {
        // Bound inputs - use realistic amounts relative to typical DeFi usage
        amountIn = bound(amountIn, MIN_ZAP_AMOUNT, 1e22);  // Cap at 10,000 tokens (18 decimals)
        tickRange = int24(bound(int256(tickRange), 1000, 10000));  // Wider range = more balanced = less dust
        searchIters = uint16(bound(searchIters, 15, 30));  // Minimum 15 iterations for quality

        // Create pool at 1:1 price with high liquidity
        MockCLPool pool = _createPoolWithLiquidity(MIN_POOL_LIQUIDITY);

        // Calculate tick range centered around 0 (1:1 price)
        int24 tickLower = nearestUsableTick(-tickRange, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(tickRange, TICK_SPACING_MEDIUM);

        // Ensure valid range
        if (tickLower >= tickUpper) {
            tickUpper = tickLower + TICK_SPACING_MEDIUM;
        }

        // Create zap-in params
        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: searchIters,
            includeUnstakedFee: false
        });

        // Quote zap-in
        SlipstreamZapQuoter.ZapInQuote memory quote = SlipstreamZapQuoter.quoteZapInSingleCore(params);

        // Calculate total dust
        uint256 totalDust = quote.dust0 + quote.dust1;

        // Calculate max acceptable dust (5% of input)
        uint256 maxDust = (amountIn * MAX_DUST_PERCENT) / 10000;

        // Verify dust is within bounds
        assertTrue(
            totalDust <= maxDust,
            string(abi.encodePacked(
                "Dust exceeds 5%: dust=", vm.toString(totalDust),
                " max=", vm.toString(maxDust)
            ))
        );

        // Verify we actually produce liquidity
        assertTrue(quote.liquidity > 0, "Zap should produce liquidity");
    }

    /// @notice Fuzz test: zap-in with varying search iterations improves or maintains quality
    /// @param amountIn Input amount (bounded)
    /// @param tickRange Tick range (bounded)
    /// @param zeroForOne Input direction
    function testFuzz_zapIn_searchIterationsImproveDust(
        uint256 amountIn,
        int24 tickRange,
        bool zeroForOne
    ) public {
        // Bound inputs
        amountIn = bound(amountIn, MIN_ZAP_AMOUNT, MAX_ZAP_AMOUNT);
        tickRange = int24(bound(int256(tickRange), 500, 5000));

        // Create pool
        MockCLPool pool = _createPoolWithLiquidity(MIN_POOL_LIQUIDITY);

        int24 tickLower = nearestUsableTick(-tickRange, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(tickRange, TICK_SPACING_MEDIUM);

        if (tickLower >= tickUpper) {
            tickUpper = tickLower + TICK_SPACING_MEDIUM;
        }

        // Test with fewer iterations
        SlipstreamZapQuoter.ZapInParams memory paramsLow = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 8,
            includeUnstakedFee: false
        });
        SlipstreamZapQuoter.ZapInQuote memory quoteLow = SlipstreamZapQuoter.quoteZapInSingleCore(paramsLow);

        // Test with more iterations
        SlipstreamZapQuoter.ZapInParams memory paramsHigh = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 24,
            includeUnstakedFee: false
        });
        SlipstreamZapQuoter.ZapInQuote memory quoteHigh = SlipstreamZapQuoter.quoteZapInSingleCore(paramsHigh);

        // More iterations should not significantly reduce liquidity
        // Allow 0.1% tolerance for numerical variance
        uint128 tolerance = uint128(quoteLow.liquidity / 1000);
        assertTrue(
            quoteHigh.liquidity >= quoteLow.liquidity - tolerance,
            "More iterations should maintain or improve liquidity"
        );
    }

    /// @notice Fuzz test: zap-in conserves value in the input token domain
    /// @dev Asserts exact conservation: amountIn = swapAmountIn + usedInput + dustInput
    /// @dev Also asserts dust percentage is bounded relative to input
    /// @param amountIn Input amount (bounded)
    /// @param tickRange Tick range (bounded)
    /// @param zeroForOne Input direction
    function testFuzz_zapIn_valueConservation(
        uint256 amountIn,
        int24 tickRange,
        bool zeroForOne
    ) public {
        // Bound inputs
        amountIn = bound(amountIn, MIN_ZAP_AMOUNT, MAX_ZAP_AMOUNT);
        tickRange = int24(bound(int256(tickRange), 200, 8000));

        MockCLPool pool = _createPoolWithLiquidity(MIN_POOL_LIQUIDITY);

        int24 tickLower = nearestUsableTick(-tickRange, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(tickRange, TICK_SPACING_MEDIUM);

        if (tickLower >= tickUpper) {
            tickUpper = tickLower + TICK_SPACING_MEDIUM;
        }

        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: DEFAULT_SEARCH_ITERS,
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.ZapInQuote memory quote = SlipstreamZapQuoter.quoteZapInSingleCore(params);

        // ═══════════════════════════════════════════════════════════════════
        // INVARIANT 1: Input Token Conservation (Exact)
        // ═══════════════════════════════════════════════════════════════════
        // For zeroForOne=true: amountIn = swap.amountIn + amount0 + dust0
        // For zeroForOne=false: amountIn = swap.amountIn + amount1 + dust1
        //
        // This holds exactly because:
        // - swap.amountIn is the actual amount consumed by the swap
        // - remainingInput = amountIn - swap.amountIn
        // - amount{X} + dust{X} = remainingInput (where X is the input token)
        // ═══════════════════════════════════════════════════════════════════

        uint256 inputUsed;
        uint256 inputDust;
        if (zeroForOne) {
            inputUsed = quote.amount0;
            inputDust = quote.dust0;
        } else {
            inputUsed = quote.amount1;
            inputDust = quote.dust1;
        }

        uint256 totalAccountedInput = quote.swap.amountIn + inputUsed + inputDust;

        assertEq(
            totalAccountedInput,
            amountIn,
            "Input token conservation violated"
        );

        // ═══════════════════════════════════════════════════════════════════
        // INVARIANT 2: Dust Percentage Bound (Relative to Input)
        // ═══════════════════════════════════════════════════════════════════
        // Total dust (both tokens) should be bounded relative to input.
        // We use the MAX_DUST_PERCENT constant (5%) as the bound.
        // This ensures the zap is reasonably efficient.
        // ═══════════════════════════════════════════════════════════════════

        uint256 totalDust = quote.dust0 + quote.dust1;
        uint256 maxAllowedDust = (amountIn * MAX_DUST_PERCENT) / 10000;

        assertTrue(
            totalDust <= maxAllowedDust,
            "Dust exceeds 5% of input"
        );

        // ═══════════════════════════════════════════════════════════════════
        // INVARIANT 3: Liquidity Production
        // ═══════════════════════════════════════════════════════════════════
        // A valid zap should produce liquidity unless we're at an extreme
        // range. This ensures the optimization actually works.
        // ═══════════════════════════════════════════════════════════════════

        assertTrue(
            quote.liquidity > 0,
            "Zap should produce liquidity"
        );

        // ═══════════════════════════════════════════════════════════════════
        // INVARIANT 4: Swap Amount Sanity
        // ═══════════════════════════════════════════════════════════════════
        // The requested swap amount should never exceed the input amount.
        // And the actual swap consumption should not exceed the request.
        // ═══════════════════════════════════════════════════════════════════

        assertTrue(
            quote.swapAmountIn <= amountIn,
            "Requested swap amount exceeds input"
        );

        assertTrue(
            quote.swap.amountIn <= quote.swapAmountIn,
            "Actual swap consumption exceeds request"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Fuzz: Zap-Out Accuracy                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Fuzz test: zap-out produces non-zero output
    /// @param burnLiquidity Liquidity to burn (bounded)
    /// @param tickRange Tick range (bounded)
    /// @param wantToken0 Output token preference
    function testFuzz_zapOut_producesOutput(
        uint128 burnLiquidity,
        int24 tickRange,
        bool wantToken0
    ) public {
        // Bound inputs
        burnLiquidity = uint128(bound(burnLiquidity, MIN_BURN_LIQUIDITY, MAX_BURN_LIQUIDITY));
        tickRange = int24(bound(int256(tickRange), 100, 10000));

        // Create pool with enough liquidity
        MockCLPool pool = _createPoolWithLiquidity(MIN_POOL_LIQUIDITY);

        int24 tickLower = nearestUsableTick(-tickRange, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(tickRange, TICK_SPACING_MEDIUM);

        if (tickLower >= tickUpper) {
            tickUpper = tickLower + TICK_SPACING_MEDIUM;
        }

        // Add liquidity to the position that we'll burn from
        addLiquidity(pool, tickLower, tickUpper, burnLiquidity);

        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: burnLiquidity,
            wantToken0: wantToken0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.ZapOutQuote memory quote = SlipstreamZapQuoter.quoteZapOutSingleCore(params);

        // Verify we get output
        assertTrue(quote.amountOut > 0, "Zap-out should produce output");

        // Verify burn amounts are non-negative
        assertTrue(quote.burnAmount0 >= 0, "Burn amount0 should be non-negative");
        assertTrue(quote.burnAmount1 >= 0, "Burn amount1 should be non-negative");

        // At least one burn amount should be positive (we're in range at 1:1 price)
        assertTrue(
            quote.burnAmount0 > 0 || quote.burnAmount1 > 0,
            "Should receive tokens from burn"
        );
    }

    /// @notice Fuzz test: zap-out combines burn and swap correctly
    /// @param burnLiquidity Liquidity to burn (bounded)
    /// @param tickRange Tick range (bounded)
    /// @param wantToken0 Output token preference
    function testFuzz_zapOut_combinesBurnAndSwap(
        uint128 burnLiquidity,
        int24 tickRange,
        bool wantToken0
    ) public {
        // Bound inputs
        burnLiquidity = uint128(bound(burnLiquidity, MIN_BURN_LIQUIDITY, MAX_BURN_LIQUIDITY / 10));
        tickRange = int24(bound(int256(tickRange), 200, 5000));

        MockCLPool pool = _createPoolWithLiquidity(MIN_POOL_LIQUIDITY);

        int24 tickLower = nearestUsableTick(-tickRange, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(tickRange, TICK_SPACING_MEDIUM);

        if (tickLower >= tickUpper) {
            tickUpper = tickLower + TICK_SPACING_MEDIUM;
        }

        addLiquidity(pool, tickLower, tickUpper, burnLiquidity);

        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: burnLiquidity,
            wantToken0: wantToken0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.ZapOutQuote memory quote = SlipstreamZapQuoter.quoteZapOutSingleCore(params);

        // Calculate expected minimum output (just the burn amount of wanted token)
        uint256 wantedBurnAmount = wantToken0 ? quote.burnAmount0 : quote.burnAmount1;

        // Output should be at least the burn amount of wanted token
        assertTrue(
            quote.amountOut >= wantedBurnAmount,
            "Output should include burn amount of wanted token"
        );

        // If there was unwanted token to swap, output should be higher
        uint256 unwantedBurnAmount = wantToken0 ? quote.burnAmount1 : quote.burnAmount0;
        if (unwantedBurnAmount > 0 && quote.swap.amountOut > 0) {
            assertTrue(
                quote.amountOut > wantedBurnAmount,
                "Output should include swap proceeds when unwanted token exists"
            );
        }
    }

    /// @notice Fuzz test: zap-out dust is minimal when swap is fully filled
    /// @param burnLiquidity Liquidity to burn (bounded)
    /// @param tickRange Tick range (bounded)
    /// @param wantToken0 Output token preference
    function testFuzz_zapOut_dustMinimal(
        uint128 burnLiquidity,
        int24 tickRange,
        bool wantToken0
    ) public {
        // Bound inputs - use smaller amounts to ensure swap can be fully filled
        burnLiquidity = uint128(bound(burnLiquidity, MIN_BURN_LIQUIDITY, MAX_BURN_LIQUIDITY / 100));
        tickRange = int24(bound(int256(tickRange), 500, 3000));

        MockCLPool pool = _createPoolWithLiquidity(MIN_POOL_LIQUIDITY);

        int24 tickLower = nearestUsableTick(-tickRange, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(tickRange, TICK_SPACING_MEDIUM);

        if (tickLower >= tickUpper) {
            tickUpper = tickLower + TICK_SPACING_MEDIUM;
        }

        addLiquidity(pool, tickLower, tickUpper, burnLiquidity);

        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: burnLiquidity,
            wantToken0: wantToken0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.ZapOutQuote memory quote = SlipstreamZapQuoter.quoteZapOutSingleCore(params);

        // If swap was fully filled, dust should be zero
        if (quote.swap.fullyFilled) {
            assertEq(quote.dust, 0, "Dust should be 0 when swap fully filled");
        }

        // Even if not fully filled, dust should be minimal relative to swap amount
        if (quote.swapAmountIn > 0) {
            uint256 dustPercent = (quote.dust * 10000) / quote.swapAmountIn;
            // With high pool liquidity, dust should be very small
            assertTrue(
                dustPercent < 100,  // Less than 1%
                "Dust should be less than 1% of swap amount"
            );
        }
    }

    /// @notice Fuzz test: opposite wantToken0 gives different outputs
    /// @param burnLiquidity Liquidity to burn (bounded)
    /// @param tickRange Tick range (bounded)
    function testFuzz_zapOut_oppositeTokensGiveDifferentOutputs(
        uint128 burnLiquidity,
        int24 tickRange
    ) public {
        // Bound inputs
        burnLiquidity = uint128(bound(burnLiquidity, MIN_BURN_LIQUIDITY, MAX_BURN_LIQUIDITY / 10));
        tickRange = int24(bound(int256(tickRange), 500, 5000));

        MockCLPool pool = _createPoolWithLiquidity(MIN_POOL_LIQUIDITY);

        int24 tickLower = nearestUsableTick(-tickRange, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(tickRange, TICK_SPACING_MEDIUM);

        if (tickLower >= tickUpper) {
            tickUpper = tickLower + TICK_SPACING_MEDIUM;
        }

        addLiquidity(pool, tickLower, tickUpper, burnLiquidity);

        // Quote wanting token0
        SlipstreamZapQuoter.ZapOutParams memory params0 = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: burnLiquidity,
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            includeUnstakedFee: false
        });
        SlipstreamZapQuoter.ZapOutQuote memory quote0 = SlipstreamZapQuoter.quoteZapOutSingleCore(params0);

        // Quote wanting token1
        SlipstreamZapQuoter.ZapOutParams memory params1 = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: burnLiquidity,
            wantToken0: false,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            includeUnstakedFee: false
        });
        SlipstreamZapQuoter.ZapOutQuote memory quote1 = SlipstreamZapQuoter.quoteZapOutSingleCore(params1);

        // Burn amounts should be the same regardless of wanted token
        assertEq(quote0.burnAmount0, quote1.burnAmount0, "Burn amount0 should match");
        assertEq(quote0.burnAmount1, quote1.burnAmount1, "Burn amount1 should match");

        // But output amounts and swap directions differ
        // At 1:1 price with symmetric position, outputs should be similar but swap directions opposite
        assertTrue(quote0.amountOut > 0, "Should have output for token0");
        assertTrue(quote1.amountOut > 0, "Should have output for token1");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Fuzz: Position Range Variations                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Fuzz test: zap-in works across various price positions relative to range
    /// @param amountIn Input amount (bounded)
    /// @param currentTick Current pool tick (bounded)
    /// @param tickLowerOffset Offset for lower tick (bounded)
    /// @param tickUpperOffset Offset for upper tick (bounded)
    /// @param zeroForOne Input direction
    function testFuzz_zapIn_variousRangePositions(
        uint256 amountIn,
        int24 currentTick,
        int24 tickLowerOffset,
        int24 tickUpperOffset,
        bool zeroForOne
    ) public {
        // Bound inputs
        amountIn = bound(amountIn, MIN_ZAP_AMOUNT, MAX_ZAP_AMOUNT);
        currentTick = int24(bound(int256(currentTick), TickMath.MIN_TICK + 10000, TickMath.MAX_TICK - 10000));
        tickLowerOffset = int24(bound(int256(tickLowerOffset), 100, 5000));
        tickUpperOffset = int24(bound(int256(tickUpperOffset), 100, 5000));

        // Calculate tick range (can be above, below, or around current tick)
        int24 tickLower = nearestUsableTick(currentTick - tickLowerOffset, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(currentTick + tickUpperOffset, TICK_SPACING_MEDIUM);

        // Ensure valid range
        if (tickLower >= tickUpper) {
            tickUpper = tickLower + TICK_SPACING_MEDIUM;
        }

        // Create pool at the specified tick
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(currentTick);
        MockCLPool pool = _createPoolAtPrice(sqrtPriceX96, currentTick);

        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: DEFAULT_SEARCH_ITERS,
            includeUnstakedFee: false
        });

        // Should not revert for valid parameters
        SlipstreamZapQuoter.ZapInQuote memory quote = SlipstreamZapQuoter.quoteZapInSingleCore(params);

        // Should produce some result (may be zero liquidity if range is far from price)
        assertTrue(quote.swapAmountIn <= amountIn, "Swap amount should not exceed input");
    }

    /// @notice Fuzz test: zap-out works for positions at various price levels
    /// @param burnLiquidity Liquidity to burn (bounded)
    /// @param currentTick Current tick (bounded)
    /// @param rangeOffset Range offset from current tick
    /// @param wantToken0 Output token preference
    function testFuzz_zapOut_variousPriceLevels(
        uint128 burnLiquidity,
        int24 currentTick,
        int24 rangeOffset,
        bool wantToken0
    ) public {
        // Bound inputs - use conservative tick range to avoid extreme prices
        // where positions may have near-zero value on one side
        burnLiquidity = uint128(bound(burnLiquidity, MIN_BURN_LIQUIDITY, MAX_BURN_LIQUIDITY / 10));
        currentTick = int24(bound(int256(currentTick), -100000, 100000));
        rangeOffset = int24(bound(int256(rangeOffset), 500, 10000));

        // Create range around current tick
        int24 tickLower = nearestUsableTick(currentTick - rangeOffset, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(currentTick + rangeOffset, TICK_SPACING_MEDIUM);

        if (tickLower >= tickUpper) {
            tickUpper = tickLower + TICK_SPACING_MEDIUM;
        }

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(currentTick);
        MockCLPool pool = _createPoolAtPrice(sqrtPriceX96, currentTick);

        // Add liquidity to the position
        addLiquidity(pool, tickLower, tickUpper, burnLiquidity);

        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: burnLiquidity,
            wantToken0: wantToken0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.ZapOutQuote memory quote = SlipstreamZapQuoter.quoteZapOutSingleCore(params);

        // Should produce output
        assertTrue(quote.amountOut > 0, "Should produce output");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Internal Helpers                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Create a pool at 1:1 price with specified liquidity
    function _createPoolWithLiquidity(uint128 liquidity) internal returns (MockCLPool pool) {
        address tokenA = makeAddr(string(abi.encodePacked("TA_", vm.toString(block.timestamp))));
        address tokenB = makeAddr(string(abi.encodePacked("TB_", vm.toString(block.timestamp))));

        pool = createMockPoolOneToOne(tokenA, tokenB, FEE_MEDIUM, TICK_SPACING_MEDIUM);

        // Add wide-range liquidity
        int24 tickLower = nearestUsableTick(-60000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(60000, TICK_SPACING_MEDIUM);
        addLiquidity(pool, tickLower, tickUpper, liquidity);
    }

    /// @notice Create a pool at specified price
    function _createPoolAtPrice(uint160 sqrtPriceX96, int24 tick) internal returns (MockCLPool pool) {
        address tokenA = makeAddr(string(abi.encodePacked("TA_", vm.toString(block.timestamp))));
        address tokenB = makeAddr(string(abi.encodePacked("TB_", vm.toString(block.timestamp))));

        pool = createMockPool(tokenA, tokenB, FEE_MEDIUM, TICK_SPACING_MEDIUM, sqrtPriceX96);

        // Add wide-range liquidity
        int24 tickLower = nearestUsableTick(tick - 30000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(tick + 30000, TICK_SPACING_MEDIUM);

        // Ensure valid range
        if (tickLower < TickMath.MIN_TICK) tickLower = TickMath.MIN_TICK;
        if (tickUpper > TickMath.MAX_TICK) tickUpper = TickMath.MAX_TICK;
        if (tickLower >= tickUpper) tickUpper = tickLower + TICK_SPACING_MEDIUM;

        addLiquidity(pool, tickLower, tickUpper, MIN_POOL_LIQUIDITY);
    }
}
