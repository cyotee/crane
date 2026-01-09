// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";

/// @title Test SlipstreamUtils liquidity/amount helpers
/// @notice Validates _quoteAmountsForLiquidity and _quoteLiquidityForAmounts
contract SlipstreamUtils_LiquidityAmounts_Test is TestBase_Slipstream {
    using SlipstreamUtils for *;

    MockCLPool pool;
    address tokenA;
    address tokenB;

    function setUp() public override {
        super.setUp();

        tokenA = makeAddr("TokenA");
        tokenB = makeAddr("TokenB");

        pool = createMockPoolOneToOne(tokenA, tokenB, FEE_MEDIUM, TICK_SPACING_MEDIUM);
    }

    /* -------------------------------------------------------------------------- */
    /*                      quoteAmountsForLiquidity Tests                        */
    /* -------------------------------------------------------------------------- */

    function test_quoteAmountsForLiquidity_priceInRange() public view {
        int24 tickLower = nearestUsableTick(-6000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(6000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, int24 currentTick, , , , ) = pool.slot0();
        assertTrue(currentTick >= tickLower && currentTick < tickUpper, "Price should be in range");

        (uint256 amount0, uint256 amount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            uint128(1000e18)
        );

        assertTrue(amount0 > 0, "amount0 should be > 0 when in range");
        assertTrue(amount1 > 0, "amount1 should be > 0 when in range");
    }

    function test_quoteAmountsForLiquidity_priceBelowRange() public view {
        int24 tickLower = nearestUsableTick(6000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(12000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, int24 currentTick, , , , ) = pool.slot0();
        assertTrue(currentTick < tickLower, "Price should be below range");

        (uint256 amount0, uint256 amount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            uint128(1000e18)
        );

        assertTrue(amount0 > 0, "amount0 should be > 0 when below range");
        assertEq(amount1, 0, "amount1 should be 0 when below range");
    }

    function test_quoteAmountsForLiquidity_priceAboveRange() public view {
        int24 tickLower = nearestUsableTick(-12000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(-6000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, int24 currentTick, , , , ) = pool.slot0();
        assertTrue(currentTick >= tickUpper, "Price should be above range");

        (uint256 amount0, uint256 amount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            uint128(1000e18)
        );

        assertEq(amount0, 0, "amount0 should be 0 when above range");
        assertTrue(amount1 > 0, "amount1 should be > 0 when above range");
    }

    function test_quoteAmountsForLiquidity_tickOverload() public view {
        int24 tickLower = nearestUsableTick(-6000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(6000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, int24 currentTick, , , , ) = pool.slot0();

        (uint256 amount0_sqrtPrice, uint256 amount1_sqrtPrice) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            uint128(1000e18)
        );

        (uint256 amount0_tick, uint256 amount1_tick) = SlipstreamUtils._quoteAmountsForLiquidity(
            currentTick,
            tickLower,
            tickUpper,
            uint128(1000e18)
        );

        assertEq(amount0_sqrtPrice, amount0_tick, "amount0 mismatch");
        assertEq(amount1_sqrtPrice, amount1_tick, "amount1 mismatch");
    }

    function test_quoteAmountsForLiquidity_zeroLiquidity() public view {
        int24 tickLower = nearestUsableTick(-6000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(6000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();

        (uint256 amount0, uint256 amount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            0
        );

        assertEq(amount0, 0, "amount0 should be 0 for zero liquidity");
        assertEq(amount1, 0, "amount1 should be 0 for zero liquidity");
    }

    /* -------------------------------------------------------------------------- */
    /*                      quoteLiquidityForAmounts Tests                        */
    /* -------------------------------------------------------------------------- */

    function test_quoteLiquidityForAmounts_priceInRange() public view {
        int24 tickLower = nearestUsableTick(-6000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(6000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();

        uint128 liquidity = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            1000e18,
            1000e18
        );

        assertTrue(liquidity > 0, "liquidity should be > 0");
    }

    function test_quoteLiquidityForAmounts_priceBelowRange_onlyToken0Matters() public view {
        int24 tickLower = nearestUsableTick(6000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(12000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();

        uint128 liquidity = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            1000e18,
            1000e18
        );

        uint128 liquidityFromZeroOnly = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            1000e18,
            0
        );

        assertEq(liquidity, liquidityFromZeroOnly, "liquidity should only depend on token0");
    }

    function test_quoteLiquidityForAmounts_priceAboveRange_onlyToken1Matters() public view {
        int24 tickLower = nearestUsableTick(-12000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(-6000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();

        uint128 liquidity = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            1000e18,
            1000e18
        );

        uint128 liquidityFromOneOnly = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            0,
            1000e18
        );

        assertEq(liquidity, liquidityFromOneOnly, "liquidity should only depend on token1");
    }

    function test_quoteLiquidityForAmounts_tickOverload() public view {
        int24 tickLower = nearestUsableTick(-6000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(6000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, int24 currentTick, , , , ) = pool.slot0();

        uint128 liquidity_sqrtPrice = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            1000e18,
            1000e18
        );

        uint128 liquidity_tick = SlipstreamUtils._quoteLiquidityForAmounts(
            currentTick,
            tickLower,
            tickUpper,
            1000e18,
            1000e18
        );

        assertEq(liquidity_sqrtPrice, liquidity_tick, "liquidity mismatch");
    }

    function test_quoteLiquidityForAmounts_zeroAmounts() public view {
        int24 tickLower = nearestUsableTick(-6000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(6000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();

        uint128 liquidity = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            0,
            0
        );

        assertEq(liquidity, 0, "liquidity should be 0 for zero amounts");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Round-Trip Consistency Tests                       */
    /* -------------------------------------------------------------------------- */

    function test_roundTrip_amountsToLiquidityToAmounts() public view {
        int24 tickLower = nearestUsableTick(-6000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(6000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();

        uint256 inputAmount0 = 1000e18;
        uint256 inputAmount1 = 1000e18;

        uint128 liquidity = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            inputAmount0,
            inputAmount1
        );

        (uint256 outputAmount0, uint256 outputAmount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        assertTrue(outputAmount0 <= inputAmount0, "output amount0 should be <= input");
        assertTrue(outputAmount1 <= inputAmount1, "output amount1 should be <= input");

        bool amount0IsLimiting = outputAmount0 >= inputAmount0 * 99 / 100;
        bool amount1IsLimiting = outputAmount1 >= inputAmount1 * 99 / 100;
        assertTrue(amount0IsLimiting || amount1IsLimiting, "one amount should be ~100% of input");
    }

    function test_roundTrip_liquidityToAmountsToLiquidity() public view {
        int24 tickLower = nearestUsableTick(-6000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(6000, TICK_SPACING_MEDIUM);

        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();

        uint128 inputLiquidity = uint128(1000e18);

        (uint256 amount0, uint256 amount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            inputLiquidity
        );

        uint128 outputLiquidity = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        assertApproxEqAbs(outputLiquidity, inputLiquidity, 10, "liquidity should round-trip");
    }
}
