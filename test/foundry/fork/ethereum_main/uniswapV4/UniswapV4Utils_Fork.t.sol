// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {PoolKey} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/PoolId.sol";
import {Currency} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {TickMath} from "../../../../../contracts/protocols/dexes/uniswap/v4/libraries/TickMath.sol";
import {UniswapV4Utils} from "../../../../../contracts/protocols/dexes/uniswap/v4/utils/UniswapV4Utils.sol";
import {TestBase_UniswapV4Fork} from "./TestBase_UniswapV4Fork.sol";

/// @title UniswapV4Utils Fork Tests
/// @notice Validates single-tick quote functions against production Uniswap V4 pools on Ethereum mainnet
/// @dev V4-specific: Tests use PoolKey and read state via StateLibrary
/// @dev Since V4 swaps require unlock callbacks, we validate quotes against pool state
///      rather than executing actual swaps
contract UniswapV4Utils_Fork_Test is TestBase_UniswapV4Fork {
    using UniswapV4Utils for uint256;
    using PoolIdLibrary for PoolKey;

    /* -------------------------------------------------------------------------- */
    /*                              Pool Keys                                     */
    /* -------------------------------------------------------------------------- */

    /// @dev Well-known pool keys - we'll discover these in setUp or skip if not found
    PoolKey internal wethUsdcPool_500;
    PoolKey internal wethUsdcPool_3000;
    bool internal hasWethUsdc500;
    bool internal hasWethUsdc3000;

    function setUp() public virtual override {
        super.setUp();

        // Try to find WETH/USDC pools with common configurations
        // V4 pools may use different fee/tickSpacing combinations
        wethUsdcPool_500 = createPoolKey(WETH, USDC, FEE_LOW, TICK_SPACING_10);
        wethUsdcPool_3000 = createPoolKey(WETH, USDC, FEE_MEDIUM, TICK_SPACING_60);

        hasWethUsdc500 = isPoolInitialized(wethUsdcPool_500);
        hasWethUsdc3000 = isPoolInitialized(wethUsdcPool_3000);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Single-Tick Quote Tests                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactInputSingle returns reasonable output
    /// @dev V4-specific: Uses pool state from StateLibrary
    function test_quoteExactInputSingle_basic() public {
        // Skip if no pool found
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        uint24 fee = hasWethUsdc3000 ? FEE_MEDIUM : FEE_LOW;

        (uint160 sqrtPriceX96, , , uint24 lpFee) = getPoolState(key);
        uint128 liquidity = getPoolLiquidity(key);

        // Small swap amount to stay within single tick
        uint256 amountIn = 0.001 ether; // 0.001 WETH worth
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        uint256 quotedOut = UniswapV4Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            lpFee,
            zeroForOne
        );

        // Basic sanity checks
        assertTrue(quotedOut > 0, "output should be > 0");
        assertTrue(quotedOut < amountIn * 10000, "output should be reasonable"); // Not more than 10000x input
    }

    /// @notice Test quoteExactInputSingle with tick overload
    function test_quoteExactInputSingle_withTick() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        uint24 fee = hasWethUsdc3000 ? FEE_MEDIUM : FEE_LOW;

        (, int24 tick, , uint24 lpFee) = getPoolState(key);
        uint128 liquidity = getPoolLiquidity(key);

        uint256 amountIn = 100e6; // 100 USDC
        bool zeroForOne = tokenIsCurrency0(key, USDC);

        uint256 quotedOut = UniswapV4Utils._quoteExactInputSingle(
            amountIn,
            tick,
            liquidity,
            lpFee,
            zeroForOne
        );

        assertTrue(quotedOut > 0, "output should be > 0");
    }

    /// @notice Test quoteExactOutputSingle basic functionality
    function test_quoteExactOutputSingle_basic() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;

        (uint160 sqrtPriceX96, , , uint24 lpFee) = getPoolState(key);
        uint128 liquidity = getPoolLiquidity(key);

        uint256 amountOut = 0.0001 ether; // Want 0.0001 WETH
        bool zeroForOne = tokenIsCurrency0(key, USDC); // USDC -> WETH

        uint256 quotedIn = UniswapV4Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            lpFee,
            zeroForOne
        );

        assertTrue(quotedIn > 0, "input should be > 0");
        assertTrue(quotedIn > amountOut / 10000, "input should be reasonable"); // At least some value
    }

    /// @notice Test quoteExactOutputSingle with tick overload
    function test_quoteExactOutputSingle_withTick() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;

        (, int24 tick, , uint24 lpFee) = getPoolState(key);
        uint128 liquidity = getPoolLiquidity(key);

        uint256 amountOut = 10e6; // Want 10 USDC
        bool zeroForOne = tokenIsCurrency0(key, WETH); // WETH -> USDC

        uint256 quotedIn = UniswapV4Utils._quoteExactOutputSingle(
            amountOut,
            tick,
            liquidity,
            lpFee,
            zeroForOne
        );

        assertTrue(quotedIn > 0, "input should be > 0");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Direction Tests                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Test both swap directions give different results
    function test_quoteExactInputSingle_bothDirections() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;

        (uint160 sqrtPriceX96, , , uint24 lpFee) = getPoolState(key);
        uint128 liquidity = getPoolLiquidity(key);

        uint256 amountIn = 1 ether;

        // Quote zeroForOne
        uint256 outZeroForOne = UniswapV4Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            lpFee,
            true
        );

        // Quote oneForZero
        uint256 outOneForZero = UniswapV4Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            lpFee,
            false
        );

        // Both should produce output, but different amounts
        assertTrue(outZeroForOne > 0, "zeroForOne output should be > 0");
        assertTrue(outOneForZero > 0, "oneForZero output should be > 0");
        assertTrue(outZeroForOne != outOneForZero, "outputs should differ by direction");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Liquidity Amount Tests                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteAmountsForLiquidity
    function test_quoteAmountsForLiquidity() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (uint160 sqrtPriceX96, int24 tick, , ) = getPoolState(key);

        // Create a position around current tick
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        uint128 liquidity = 1e15; // Some liquidity amount

        (uint256 amount0, uint256 amount1) = UniswapV4Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        // At least one amount should be > 0 if price is in range
        uint160 sqrtPriceLower = TickMath.getSqrtPriceAtTick(tickLower);
        uint160 sqrtPriceUpper = TickMath.getSqrtPriceAtTick(tickUpper);

        if (sqrtPriceX96 >= sqrtPriceLower && sqrtPriceX96 <= sqrtPriceUpper) {
            // Price in range - both amounts should be > 0
            assertTrue(amount0 > 0 || amount1 > 0, "at least one amount should be > 0 in range");
        }
    }

    /// @notice Test quoteLiquidityForAmounts
    function test_quoteLiquidityForAmounts() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (uint160 sqrtPriceX96, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        uint256 amount0 = 0.1 ether;  // Some currency0
        uint256 amount1 = 100e6;       // Some currency1 (assuming USDC decimals)

        uint128 liquidity = UniswapV4Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        assertTrue(liquidity > 0, "liquidity should be > 0");

        // Verify round-trip: amounts for this liquidity should be <= provided
        (uint256 required0, uint256 required1) = UniswapV4Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        assertTrue(required0 <= amount0 + 1, "required0 should be <= provided + rounding");
        assertTrue(required1 <= amount1 + 1, "required1 should be <= provided + rounding");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Price Delta Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test getAmount0Delta
    function test_getAmount0Delta() public {
        (uint160 sqrtPriceX96, , , ) = getPoolState(wethUsdcPool_3000);
        if (sqrtPriceX96 == 0) {
            vm.skip(true);
        }

        // Create a price range
        uint160 sqrtPriceLower = uint160((uint256(sqrtPriceX96) * 99) / 100);
        uint160 sqrtPriceUpper = sqrtPriceX96;

        uint128 liquidity = 1e18;

        uint256 amount0 = UniswapV4Utils._getAmount0Delta(
            sqrtPriceLower,
            sqrtPriceUpper,
            liquidity,
            true // roundUp
        );

        assertTrue(amount0 > 0, "amount0 should be > 0");

        // Round down should give <= round up
        uint256 amount0Down = UniswapV4Utils._getAmount0Delta(
            sqrtPriceLower,
            sqrtPriceUpper,
            liquidity,
            false // roundUp
        );

        assertTrue(amount0Down <= amount0, "round down should be <= round up");
    }

    /// @notice Test getAmount1Delta
    function test_getAmount1Delta() public {
        (uint160 sqrtPriceX96, , , ) = getPoolState(wethUsdcPool_3000);
        if (sqrtPriceX96 == 0) {
            vm.skip(true);
        }

        uint160 sqrtPriceLower = sqrtPriceX96;
        uint160 sqrtPriceUpper = uint160((uint256(sqrtPriceX96) * 101) / 100);

        uint128 liquidity = 1e18;

        uint256 amount1 = UniswapV4Utils._getAmount1Delta(
            sqrtPriceLower,
            sqrtPriceUpper,
            liquidity,
            true // roundUp
        );

        assertTrue(amount1 > 0, "amount1 should be > 0");

        uint256 amount1Down = UniswapV4Utils._getAmount1Delta(
            sqrtPriceLower,
            sqrtPriceUpper,
            liquidity,
            false // roundUp
        );

        assertTrue(amount1Down <= amount1, "round down should be <= round up");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Edge Cases                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zero amount returns zero
    function test_quoteExactInputSingle_zeroAmount() public {
        if (!hasWethUsdc3000) {
            vm.skip(true);
        }

        (uint160 sqrtPriceX96, , , uint24 lpFee) = getPoolState(wethUsdcPool_3000);
        uint128 liquidity = getPoolLiquidity(wethUsdcPool_3000);

        uint256 quotedOut = UniswapV4Utils._quoteExactInputSingle(
            0, // zero amount
            sqrtPriceX96,
            liquidity,
            lpFee,
            true
        );

        assertEq(quotedOut, 0, "zero input should give zero output");
    }

    /// @notice Test zero liquidity reverts or returns zero
    function test_quoteExactInputSingle_zeroLiquidity() public {
        if (!hasWethUsdc3000) {
            vm.skip(true);
        }

        (uint160 sqrtPriceX96, , , uint24 lpFee) = getPoolState(wethUsdcPool_3000);

        // With zero liquidity, the quote should return 0 output
        uint256 quotedOut = UniswapV4Utils._quoteExactInputSingle(
            1 ether,
            sqrtPriceX96,
            0, // zero liquidity
            lpFee,
            true
        );

        assertEq(quotedOut, 0, "zero liquidity should give zero output");
    }

    /* -------------------------------------------------------------------------- */
    /*                          getSqrtPriceFromReserves Test                     */
    /* -------------------------------------------------------------------------- */

    /// @notice Test getSqrtPriceFromReserves calculation
    function test_getSqrtPriceFromReserves() public pure {
        // Test with known values
        // If reserve0 = 1e18 and reserve1 = 1e18, price should be 1:1
        // sqrtPrice = sqrt(reserve1/reserve0) * 2^96

        uint256 reserve0 = 1e18;
        uint256 reserve1 = 1e18;

        uint160 sqrtPrice = UniswapV4Utils._getSqrtPriceFromReserves(reserve0, reserve1);

        // sqrt(1) * 2^96 = 2^96
        uint256 expected = 1 << 96;
        assertApproxEqRel(sqrtPrice, expected, 0.01e18, "sqrtPrice should be ~2^96 for equal reserves");

        // Test with different ratios
        uint256 reserve0_2 = 1e18;
        uint256 reserve1_2 = 4e18; // 4:1 ratio

        uint160 sqrtPrice2 = UniswapV4Utils._getSqrtPriceFromReserves(reserve0_2, reserve1_2);

        // sqrt(4) * 2^96 = 2 * 2^96
        uint256 expected2 = 2 * (1 << 96);
        assertApproxEqRel(sqrtPrice2, expected2, 0.01e18, "sqrtPrice should be ~2*2^96 for 4:1 ratio");
    }
}
