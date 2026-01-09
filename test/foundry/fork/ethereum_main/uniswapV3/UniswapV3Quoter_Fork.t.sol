// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {UniswapV3Quoter} from "@crane/contracts/utils/math/UniswapV3Quoter.sol";
import {TestBase_UniswapV3Fork} from "./TestBase_UniswapV3Fork.sol";

/// @title UniswapV3Quoter Fork Tests
/// @notice Validates tick-crossing quote accuracy against production Uniswap V3 pools
/// @dev Tests the view-based quoter that can simulate multi-tick swaps
contract UniswapV3Quoter_Fork_Test is TestBase_UniswapV3Fork {
    using UniswapV3Quoter for UniswapV3Quoter.SwapQuoteParams;

    /* -------------------------------------------------------------------------- */
    /*                        Exact Input Tick-Crossing Tests                     */
    /* -------------------------------------------------------------------------- */

    /// @notice Test large WETH/USDC swap that crosses multiple ticks
    function test_quoteExactInput_WETH_USDC_3000_tickCrossing() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        // Large swap: 10 ETH should cross ticks
        uint256 amountIn = 10 ether;

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true, // WETH -> USDC
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0 // Unlimited steps
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactInput(params);

        // Execute actual swap
        uint256 actualOut = swapExactInput(pool, true, amountIn, address(this));

        // Verify quote accuracy
        assertTrue(quote.fullyFilled, "quote should fully fill");
        assertEq(quote.amountIn, amountIn, "amountIn should match requested");
        assertQuoteAccuracy(quote.amountOut, actualOut, "tick-crossing exactIn quote mismatch");

        // Verify we actually crossed ticks
        assertTrue(quote.steps > 1, "should have crossed multiple ticks");
    }

    /// @notice Test large USDC -> WETH swap (reverse direction)
    function test_quoteExactInput_WETH_USDC_3000_tickCrossing_reverse() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        // Large swap: 10000 USDC should cross ticks
        uint256 amountIn = 10_000e6;

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: false, // USDC -> WETH
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MAX_SQRT_RATIO - 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactInput(params);
        uint256 actualOut = swapExactInput(pool, false, amountIn, address(this));

        assertTrue(quote.fullyFilled, "quote should fully fill");
        assertQuoteAccuracy(quote.amountOut, actualOut, "reverse tick-crossing quote mismatch");
    }

    /// @notice Test tick-crossing on WETH/USDC 0.05% pool (tighter tick spacing)
    function test_quoteExactInput_WETH_USDC_500_tickCrossing() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_500);

        // Medium swap on 0.05% pool
        uint256 amountIn = 5 ether;

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactInput(params);
        uint256 actualOut = swapExactInput(pool, true, amountIn, address(this));

        assertTrue(quote.fullyFilled, "quote should fully fill");
        assertQuoteAccuracy(quote.amountOut, actualOut, "0.05% pool tick-crossing quote mismatch");
    }

    /// @notice Test tick-crossing on WETH/USDC 1% pool (wider tick spacing)
    function test_quoteExactInput_WETH_USDC_10000_tickCrossing() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_10000);

        // Swap on 1% pool (fewer ticks)
        uint256 amountIn = 2 ether;

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactInput(params);
        uint256 actualOut = swapExactInput(pool, true, amountIn, address(this));

        assertTrue(quote.fullyFilled, "quote should fully fill");
        assertQuoteAccuracy(quote.amountOut, actualOut, "1% pool tick-crossing quote mismatch");
    }

    /// @notice Test on stablecoin pool (USDC/USDT)
    function test_quoteExactInput_USDC_USDT_500_tickCrossing() public {
        IUniswapV3Pool pool = getPool(USDC_USDT_500);

        // Large stablecoin swap
        uint256 amountIn = 100_000e6; // 100k USDC

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactInput(params);
        uint256 actualOut = swapExactInput(pool, true, amountIn, address(this));

        assertTrue(quote.fullyFilled, "quote should fully fill");
        assertQuoteAccuracy(quote.amountOut, actualOut, "stablecoin tick-crossing quote mismatch");
    }

    /// @notice Test on WBTC/WETH pool
    function test_quoteExactInput_WBTC_WETH_3000_tickCrossing() public {
        IUniswapV3Pool pool = getPool(WBTC_WETH_3000);

        // 0.1 WBTC swap
        uint256 amountIn = 0.1e8;

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true, // WBTC -> WETH
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactInput(params);
        uint256 actualOut = swapExactInput(pool, true, amountIn, address(this));

        assertTrue(quote.fullyFilled, "quote should fully fill");
        assertQuoteAccuracy(quote.amountOut, actualOut, "WBTC/WETH tick-crossing quote mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                       Exact Output Tick-Crossing Tests                     */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactOutput with tick crossing
    function test_quoteExactOutput_WETH_USDC_3000_tickCrossing() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        // Want 10000 USDC (may cross ticks)
        uint256 amountOut = 10_000e6;

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountOut,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactOutput(params);
        uint256 actualIn = swapExactOutput(pool, true, amountOut, address(this));

        assertTrue(quote.fullyFilled, "quote should fully fill");
        assertQuoteAccuracy(quote.amountIn, actualIn, "exactOutput tick-crossing quote mismatch");
    }

    /// @notice Test quoteExactOutput reverse direction
    /// @dev On mainnet WETH_USDC_3000: USDC is token0, WETH is token1
    ///      So oneForZero (false) means WETH -> USDC (we want USDC output)
    function test_quoteExactOutput_WETH_USDC_3000_tickCrossing_reverse() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        // Want 5000 USDC (USDC is token0)
        // oneForZero = WETH -> USDC
        uint256 amountOut = 5000e6;

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: false, // WETH -> USDC (token1 -> token0)
            amount: amountOut,
            sqrtPriceLimitX96: TickMath.MAX_SQRT_RATIO - 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactOutput(params);
        uint256 actualIn = swapExactOutput(pool, false, amountOut, address(this));

        assertTrue(quote.fullyFilled, "quote should fully fill");
        assertQuoteAccuracy(quote.amountIn, actualIn, "reverse exactOutput quote mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                              MaxSteps Tests                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that maxSteps limits the number of tick crossings
    function test_quoteExactInput_maxSteps_limits() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        // Large swap that would normally cross many ticks
        uint256 amountIn = 50 ether;

        // First, get unlimited quote
        UniswapV3Quoter.SwapQuoteParams memory unlimitedParams = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory unlimitedQuote = UniswapV3Quoter.quoteExactInput(unlimitedParams);

        // Now with maxSteps = 1
        UniswapV3Quoter.SwapQuoteParams memory limitedParams = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 1
        });

        UniswapV3Quoter.SwapQuoteResult memory limitedQuote = UniswapV3Quoter.quoteExactInput(limitedParams);

        // Limited quote should not fully fill
        assertFalse(limitedQuote.fullyFilled, "limited quote should not fully fill");
        assertEq(limitedQuote.steps, 1, "should only have 1 step");
        assertTrue(limitedQuote.amountIn < amountIn, "should have consumed less input");
        assertTrue(limitedQuote.amountOut < unlimitedQuote.amountOut, "should have less output");
    }

    /// @notice Test maxSteps = 2 vs unlimited
    function test_quoteExactInput_maxSteps_partial() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        uint256 amountIn = 20 ether;

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 2
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactInput(params);

        assertTrue(quote.steps <= 2, "should have at most 2 steps");
        assertTrue(quote.amountIn <= amountIn, "amountIn should be <= requested");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Price Limit Tests                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that sqrtPriceLimitX96 stops the swap early
    function test_quoteExactInput_priceLimit() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 currentSqrtPrice, , ) = getPoolState(pool);

        // Set a price limit that's 1% away from current
        // For zeroForOne, price decreases, so limit is lower
        uint160 priceLimit = uint160((uint256(currentSqrtPrice) * 99) / 100);

        uint256 amountIn = 50 ether; // Large swap

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: priceLimit,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactInput(params);

        // The swap should stop at or before the price limit
        assertTrue(quote.sqrtPriceAfterX96 >= priceLimit, "price should not exceed limit");

        // If not fully filled, we hit the price limit
        if (!quote.fullyFilled) {
            assertApproxEqRel(quote.sqrtPriceAfterX96, priceLimit, 0.001e18, "should be near price limit");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                         Zero Amount Edge Case                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zero amount returns current state
    function test_quoteExactInput_zeroAmount() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 currentSqrtPrice, int24 currentTick, uint128 currentLiquidity) = getPoolState(pool);

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: 0,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactInput(params);

        assertTrue(quote.fullyFilled, "zero amount should be fully filled");
        assertEq(quote.amountIn, 0, "amountIn should be 0");
        assertEq(quote.amountOut, 0, "amountOut should be 0");
        assertEq(quote.sqrtPriceAfterX96, currentSqrtPrice, "price should be unchanged");
        assertEq(quote.liquidityAfter, currentLiquidity, "liquidity should be unchanged");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Result Field Validation                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Validate all result fields are populated correctly
    function test_quoteExactInput_resultFields() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        uint256 amountIn = 5 ether;

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactInput(params);

        // Verify all result fields
        assertTrue(quote.amountIn > 0, "amountIn should be > 0");
        assertTrue(quote.amountOut > 0, "amountOut should be > 0");
        assertTrue(quote.feeAmount > 0, "feeAmount should be > 0");
        assertTrue(quote.sqrtPriceAfterX96 > 0, "sqrtPriceAfterX96 should be > 0");
        assertTrue(quote.liquidityAfter > 0, "liquidityAfter should be > 0");
        assertTrue(quote.steps > 0, "steps should be > 0");

        // For zeroForOne, price should decrease
        (uint160 priceBefore, , ) = getPoolState(pool);
        assertTrue(quote.sqrtPriceAfterX96 < priceBefore, "price should decrease for zeroForOne");
    }

    /// @notice Validate result fields for exactOutput
    function test_quoteExactOutput_resultFields() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        uint256 amountOut = 5000e6;

        UniswapV3Quoter.SwapQuoteParams memory params = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountOut,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory quote = UniswapV3Quoter.quoteExactOutput(params);

        assertTrue(quote.fullyFilled, "should fully fill");
        assertTrue(quote.amountIn > 0, "amountIn should be > 0");
        assertEq(quote.amountOut, amountOut, "amountOut should match requested");
    }
}
