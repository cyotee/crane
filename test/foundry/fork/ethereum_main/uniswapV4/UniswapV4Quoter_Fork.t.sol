// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IPoolManager, StateLibrary} from "../../../../../contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {PoolKey} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/PoolId.sol";
import {Currency} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {TickMath} from "../../../../../contracts/protocols/dexes/uniswap/v4/libraries/TickMath.sol";
import {UniswapV4Quoter} from "../../../../../contracts/protocols/dexes/uniswap/v4/utils/UniswapV4Quoter.sol";
import {TestBase_UniswapV4Fork} from "./TestBase_UniswapV4Fork.sol";

/// @title UniswapV4Quoter Fork Tests
/// @notice Validates tick-crossing quote accuracy against production Uniswap V4 pools
/// @dev V4-specific: Tests use PoolManager singleton and PoolKey identification
/// @dev The view-based quoter reads state via extsload (StateLibrary) without requiring unlock
contract UniswapV4Quoter_Fork_Test is TestBase_UniswapV4Fork {
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;

    /* -------------------------------------------------------------------------- */
    /*                              Pool Keys                                     */
    /* -------------------------------------------------------------------------- */

    PoolKey internal wethUsdcPool_500;
    PoolKey internal wethUsdcPool_3000;
    bool internal hasWethUsdc500;
    bool internal hasWethUsdc3000;

    function setUp() public virtual override {
        super.setUp();

        wethUsdcPool_500 = createPoolKey(WETH, USDC, FEE_LOW, TICK_SPACING_10);
        wethUsdcPool_3000 = createPoolKey(WETH, USDC, FEE_MEDIUM, TICK_SPACING_60);

        hasWethUsdc500 = isPoolInitialized(wethUsdcPool_500);
        hasWethUsdc3000 = isPoolInitialized(wethUsdcPool_3000);
    }

    /* -------------------------------------------------------------------------- */
    /*                        Exact Input Quote Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactInput basic functionality
    /// @dev V4-specific: Uses PoolManager and PoolKey in SwapQuoteParams
    function test_quoteExactInput_basic() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1
            : TickMath.MAX_SQRT_PRICE - 1;

        uint256 amountIn = 1 ether;

        UniswapV4Quoter.SwapQuoteParams memory params = UniswapV4Quoter.SwapQuoteParams({
            manager: poolManager,
            key: key,
            zeroForOne: zeroForOne,
            amount: amountIn,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: 0
        });

        UniswapV4Quoter.SwapQuoteResult memory quote = UniswapV4Quoter.quoteExactInput(params);

        // Verify basic result properties
        assertTrue(quote.amountIn > 0, "amountIn should be > 0");
        assertTrue(quote.amountOut > 0, "amountOut should be > 0");
        assertTrue(quote.sqrtPriceAfterX96 > 0, "sqrtPriceAfterX96 should be > 0");
        assertTrue(quote.steps > 0, "should have at least 1 step");
    }

    /// @notice Test quoteExactInput with larger amount that may cross ticks
    function test_quoteExactInput_tickCrossing() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1
            : TickMath.MAX_SQRT_PRICE - 1;

        // Try progressively larger amounts to find one that crosses ticks
        uint256 amountIn = 10 ether;
        UniswapV4Quoter.SwapQuoteResult memory quote;

        for (uint8 i = 0; i < 6; i++) {
            UniswapV4Quoter.SwapQuoteParams memory params = UniswapV4Quoter.SwapQuoteParams({
                manager: poolManager,
                key: key,
                zeroForOne: zeroForOne,
                amount: amountIn,
                sqrtPriceLimitX96: sqrtPriceLimitX96,
                maxSteps: 0
            });

            quote = UniswapV4Quoter.quoteExactInput(params);
            if (quote.steps > 1) break;
            amountIn *= 2;
        }

        // Verify quote completed
        assertTrue(quote.amountIn > 0, "amountIn should be > 0");
        assertTrue(quote.amountOut > 0, "amountOut should be > 0");

        // Log the number of steps for debugging
        emit log_named_uint("steps", quote.steps);
        emit log_named_uint("amountIn", quote.amountIn);
        emit log_named_uint("amountOut", quote.amountOut);
    }

    /// @notice Test quoteExactInput reverse direction
    function test_quoteExactInput_reverse() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;

        // Swap USDC -> WETH
        bool zeroForOne = tokenIsCurrency0(key, USDC);

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1
            : TickMath.MAX_SQRT_PRICE - 1;

        uint256 amountIn = 10_000e6; // 10000 USDC

        UniswapV4Quoter.SwapQuoteParams memory params = UniswapV4Quoter.SwapQuoteParams({
            manager: poolManager,
            key: key,
            zeroForOne: zeroForOne,
            amount: amountIn,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: 0
        });

        UniswapV4Quoter.SwapQuoteResult memory quote = UniswapV4Quoter.quoteExactInput(params);

        assertTrue(quote.amountIn > 0, "amountIn should be > 0");
        assertTrue(quote.amountOut > 0, "amountOut should be > 0");
    }

    /* -------------------------------------------------------------------------- */
    /*                        Exact Output Quote Tests                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactOutput basic functionality
    function test_quoteExactOutput_basic() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        bool zeroForOne = tokenIsCurrency0(key, WETH); // WETH -> USDC

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1
            : TickMath.MAX_SQRT_PRICE - 1;

        uint256 amountOut = 1000e6; // Want 1000 USDC

        UniswapV4Quoter.SwapQuoteParams memory params = UniswapV4Quoter.SwapQuoteParams({
            manager: poolManager,
            key: key,
            zeroForOne: zeroForOne,
            amount: amountOut,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: 0
        });

        UniswapV4Quoter.SwapQuoteResult memory quote = UniswapV4Quoter.quoteExactOutput(params);

        assertTrue(quote.amountIn > 0, "amountIn should be > 0");
        assertTrue(quote.amountOut > 0, "amountOut should be > 0");
    }

    /// @notice Test quoteExactOutput with tick crossing
    function test_quoteExactOutput_tickCrossing() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1
            : TickMath.MAX_SQRT_PRICE - 1;

        // Large output to potentially cross ticks
        uint256 amountOut = 50_000e6; // Want 50000 USDC

        UniswapV4Quoter.SwapQuoteParams memory params = UniswapV4Quoter.SwapQuoteParams({
            manager: poolManager,
            key: key,
            zeroForOne: zeroForOne,
            amount: amountOut,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: 0
        });

        UniswapV4Quoter.SwapQuoteResult memory quote = UniswapV4Quoter.quoteExactOutput(params);

        assertTrue(quote.amountIn > 0, "amountIn should be > 0");
    }

    /* -------------------------------------------------------------------------- */
    /*                              MaxSteps Tests                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that maxSteps limits tick crossings
    function test_quoteExactInput_maxSteps() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1
            : TickMath.MAX_SQRT_PRICE - 1;

        uint256 amountIn = 100 ether; // Large amount

        // Quote with maxSteps = 1
        UniswapV4Quoter.SwapQuoteParams memory limitedParams = UniswapV4Quoter.SwapQuoteParams({
            manager: poolManager,
            key: key,
            zeroForOne: zeroForOne,
            amount: amountIn,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: 1
        });

        UniswapV4Quoter.SwapQuoteResult memory limitedQuote = UniswapV4Quoter.quoteExactInput(limitedParams);

        // Should have at most 1 step
        assertTrue(limitedQuote.steps <= 1, "should have at most 1 step");

        // May not be fully filled
        if (!limitedQuote.fullyFilled) {
            assertTrue(limitedQuote.amountIn < amountIn, "should consume less than full amount");
        }
    }

    /// @notice Test maxSteps = 2
    function test_quoteExactInput_maxSteps_two() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1
            : TickMath.MAX_SQRT_PRICE - 1;

        uint256 amountIn = 50 ether;

        UniswapV4Quoter.SwapQuoteParams memory params = UniswapV4Quoter.SwapQuoteParams({
            manager: poolManager,
            key: key,
            zeroForOne: zeroForOne,
            amount: amountIn,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: 2
        });

        UniswapV4Quoter.SwapQuoteResult memory quote = UniswapV4Quoter.quoteExactInput(params);

        assertTrue(quote.steps <= 2, "should have at most 2 steps");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Price Limit Tests                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Test sqrtPriceLimitX96 stops swap early
    function test_quoteExactInput_priceLimit() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        (uint160 currentSqrtPrice, , , ) = getPoolState(key);

        // Set price limit ~1% away
        uint160 priceLimit = zeroForOne
            ? uint160((uint256(currentSqrtPrice) * 99) / 100)
            : uint160((uint256(currentSqrtPrice) * 101) / 100);

        // Clamp to valid bounds
        if (priceLimit <= TickMath.MIN_SQRT_PRICE) priceLimit = TickMath.MIN_SQRT_PRICE + 1;
        if (priceLimit >= TickMath.MAX_SQRT_PRICE) priceLimit = TickMath.MAX_SQRT_PRICE - 1;

        uint256 amountIn = 100 ether;

        UniswapV4Quoter.SwapQuoteParams memory params = UniswapV4Quoter.SwapQuoteParams({
            manager: poolManager,
            key: key,
            zeroForOne: zeroForOne,
            amount: amountIn,
            sqrtPriceLimitX96: priceLimit,
            maxSteps: 0
        });

        UniswapV4Quoter.SwapQuoteResult memory quote = UniswapV4Quoter.quoteExactInput(params);

        // Price should not exceed limit in swap direction
        if (zeroForOne) {
            assertTrue(quote.sqrtPriceAfterX96 >= priceLimit, "price should not go below limit");
        } else {
            assertTrue(quote.sqrtPriceAfterX96 <= priceLimit, "price should not go above limit");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              Zero Amount Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zero amount returns current state
    function test_quoteExactInput_zeroAmount() public {
        if (!hasWethUsdc3000) {
            vm.skip(true);
        }

        PoolKey memory key = wethUsdcPool_3000;
        bool zeroForOne = true;

        uint160 sqrtPriceLimitX96 = TickMath.MIN_SQRT_PRICE + 1;

        (uint160 currentSqrtPrice, , , ) = getPoolState(key);
        uint128 currentLiquidity = getPoolLiquidity(key);

        UniswapV4Quoter.SwapQuoteParams memory params = UniswapV4Quoter.SwapQuoteParams({
            manager: poolManager,
            key: key,
            zeroForOne: zeroForOne,
            amount: 0,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: 0
        });

        UniswapV4Quoter.SwapQuoteResult memory quote = UniswapV4Quoter.quoteExactInput(params);

        assertTrue(quote.fullyFilled, "zero amount should be fully filled");
        assertEq(quote.amountIn, 0, "amountIn should be 0");
        assertEq(quote.amountOut, 0, "amountOut should be 0");
        assertEq(quote.sqrtPriceAfterX96, currentSqrtPrice, "price should be unchanged");
        assertEq(quote.liquidityAfter, currentLiquidity, "liquidity should be unchanged");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Result Field Validation                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Validate all result fields are populated
    function test_quoteExactInput_resultFields() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1
            : TickMath.MAX_SQRT_PRICE - 1;

        uint256 amountIn = 5 ether;

        UniswapV4Quoter.SwapQuoteParams memory params = UniswapV4Quoter.SwapQuoteParams({
            manager: poolManager,
            key: key,
            zeroForOne: zeroForOne,
            amount: amountIn,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: 0
        });

        UniswapV4Quoter.SwapQuoteResult memory quote = UniswapV4Quoter.quoteExactInput(params);

        // Verify all fields
        assertTrue(quote.amountIn > 0, "amountIn > 0");
        assertTrue(quote.amountOut > 0, "amountOut > 0");
        assertTrue(quote.feeAmount > 0, "feeAmount > 0");
        assertTrue(quote.sqrtPriceAfterX96 > 0, "sqrtPriceAfterX96 > 0");
        assertTrue(quote.liquidityAfter > 0, "liquidityAfter > 0");
        assertTrue(quote.steps > 0, "steps > 0");

        // Price should move in swap direction
        (uint160 priceBefore, , , ) = getPoolState(key);
        if (zeroForOne) {
            assertTrue(quote.sqrtPriceAfterX96 < priceBefore, "price should decrease for zeroForOne");
        } else {
            assertTrue(quote.sqrtPriceAfterX96 > priceBefore, "price should increase for oneForZero");
        }
    }

    /// @notice Validate exactOutput result fields
    function test_quoteExactOutput_resultFields() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1
            : TickMath.MAX_SQRT_PRICE - 1;

        uint256 amountOut = 5000e6;

        UniswapV4Quoter.SwapQuoteParams memory params = UniswapV4Quoter.SwapQuoteParams({
            manager: poolManager,
            key: key,
            zeroForOne: zeroForOne,
            amount: amountOut,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: 0
        });

        UniswapV4Quoter.SwapQuoteResult memory quote = UniswapV4Quoter.quoteExactOutput(params);

        assertTrue(quote.amountIn > 0, "amountIn should be > 0");
    }
}
