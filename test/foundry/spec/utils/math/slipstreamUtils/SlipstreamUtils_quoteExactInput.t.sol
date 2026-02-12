// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/// @title Test SlipstreamUtils._quoteExactInputSingle
/// @notice Validates exact input swap quotes for Slipstream pools
contract SlipstreamUtils_quoteExactInput_Test is TestBase_Slipstream {
    using SlipstreamUtils for *;

    MockCLPool pool;
    address tokenA;
    address tokenB;

    uint256 constant INITIAL_LIQUIDITY = 1_000_000e18;
    uint256 constant TEST_AMOUNT = 1e18;

    function setUp() public override {
        super.setUp();

        // Create test token addresses
        tokenA = makeAddr("TokenA");
        tokenB = makeAddr("TokenB");

        // Create mock pool with 0.3% fee at 1:1 price
        pool = createMockPoolOneToOne(tokenA, tokenB, FEE_MEDIUM, TICK_SPACING_MEDIUM);

        // Add liquidity in wide range around current tick
        int24 tickLower = nearestUsableTick(-60000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(60000, TICK_SPACING_MEDIUM);
        addLiquidity(pool, tickLower, tickUpper, uint128(INITIAL_LIQUIDITY));
    }

    /* -------------------------------------------------------------------------- */
    /*                          Quote vs Mock Swap Tests                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Test exact input quote matches mock swap (token0 -> token1)
    function test_quoteExactInput_zeroForOne_matchesMockSwap() public {
        uint256 amountIn = TEST_AMOUNT;

        // Get current pool state
        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Get quote from SlipstreamUtils
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true  // token0 -> token1
        );

        // Execute mock swap
        uint160 sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        (, int256 amount1) = pool.swap(
            address(this),
            true,
            int256(amountIn),
            sqrtPriceLimitX96,
            ""
        );

        uint256 actualOut = uint256(-amount1);

        // Quote should match actual within rounding tolerance
        assertApproxEqAbs(quotedOut, actualOut, 1, "Quote mismatch for zeroForOne");
    }

    /// @notice Test exact input quote matches mock swap (token1 -> token0)
    function test_quoteExactInput_oneForZero_matchesMockSwap() public {
        uint256 amountIn = TEST_AMOUNT;

        // Get current pool state
        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Get quote from SlipstreamUtils
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            false  // token1 -> token0
        );

        // Execute mock swap
        uint160 sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
        (int256 amount0, ) = pool.swap(
            address(this),
            false,
            int256(amountIn),
            sqrtPriceLimitX96,
            ""
        );

        uint256 actualOut = uint256(-amount0);

        // Quote should match actual within rounding tolerance
        assertApproxEqAbs(quotedOut, actualOut, 1, "Quote mismatch for oneForZero");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Tick Overload Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test tick overload produces same result as sqrtPrice version
    function test_quoteExactInput_tickOverload_matchesSqrtPriceVersion() public {
        uint256 amountIn = TEST_AMOUNT;

        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Quote using sqrtPriceX96
        uint256 quotedWithSqrtPrice = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        // Quote using tick
        uint256 quotedWithTick = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            tick,
            liquidity,
            FEE_MEDIUM,
            true
        );

        // Should be equal (tick is derived from same sqrtPrice)
        assertEq(quotedWithSqrtPrice, quotedWithTick, "Tick overload mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Fee Tier Tests                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote with low fee tier
    function test_quoteExactInput_lowFeeTier() public {
        uint256 amountIn = TEST_AMOUNT;
        uint24 fee = FEE_LOW;
        int24 tickSpacing = getTickSpacing(fee);

        MockCLPool testPool = createMockPoolOneToOne(
            makeAddr("TokenA_low"),
            makeAddr("TokenB_low"),
            fee,
            tickSpacing
        );

        addLiquidity(
            testPool,
            nearestUsableTick(-60000, tickSpacing),
            nearestUsableTick(60000, tickSpacing),
            uint128(INITIAL_LIQUIDITY)
        );

        (uint160 sqrtPriceX96, , , , , ) = testPool.slot0();
        uint128 liq = testPool.liquidity();

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn, sqrtPriceX96, liq, fee, true
        );

        assertTrue(quotedOut > 0, "Quote should be positive");
    }

    /// @notice Test quote with high fee tier
    function test_quoteExactInput_highFeeTier() public {
        uint256 amountIn = TEST_AMOUNT;
        uint24 fee = FEE_HIGH;
        int24 tickSpacing = getTickSpacing(fee);

        MockCLPool testPool = createMockPoolOneToOne(
            makeAddr("TokenA_high"),
            makeAddr("TokenB_high"),
            fee,
            tickSpacing
        );

        addLiquidity(
            testPool,
            nearestUsableTick(-60000, tickSpacing),
            nearestUsableTick(60000, tickSpacing),
            uint128(INITIAL_LIQUIDITY)
        );

        (uint160 sqrtPriceX96, , , , , ) = testPool.slot0();
        uint128 liq = testPool.liquidity();

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn, sqrtPriceX96, liq, fee, true
        );

        assertTrue(quotedOut > 0, "Quote should be positive");
    }

    /// @notice Test higher fees give less output
    function test_quoteExactInput_higherFeeGivesLessOutput() public {
        uint256 amountIn = TEST_AMOUNT;

        // Quote with low fee
        uint256 quoteLow = SlipstreamUtils._quoteExactInputSingle(
            amountIn, uint160(1) << 96, uint128(INITIAL_LIQUIDITY), FEE_LOW, true
        );

        // Quote with high fee
        uint256 quoteHigh = SlipstreamUtils._quoteExactInputSingle(
            amountIn, uint160(1) << 96, uint128(INITIAL_LIQUIDITY), FEE_HIGH, true
        );

        assertGt(quoteLow, quoteHigh, "Higher fee should give less output");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Edge Cases                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote with dust amount (1 wei)
    function test_quoteExactInput_dustAmount() public {
        uint256 amountIn = 1;  // 1 wei

        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        // For such a small amount, output might be 0 due to fees
        assertTrue(quotedOut <= amountIn, "Output should not exceed input for 1 wei");
    }

    /// @notice Test quote with zero amount returns zero
    function test_quoteExactInput_zeroAmount() public {
        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            0,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        assertEq(quotedOut, 0, "Zero input should give zero output");
    }

    /// @notice Test quote correctness at various liquidity levels
    function test_quoteExactInput_variousLiquidityLevels() public {
        uint256 amountIn = TEST_AMOUNT;
        uint128[3] memory liquidityLevels = [uint128(1_000e18), uint128(1_000_000e18), uint128(1_000_000_000e18)];

        for (uint256 i = 0; i < liquidityLevels.length; i++) {
            MockCLPool testPool = createMockPoolOneToOne(
                makeAddr(string(abi.encodePacked("TokenA_liq_", vm.toString(i)))),
                makeAddr(string(abi.encodePacked("TokenB_liq_", vm.toString(i)))),
                FEE_MEDIUM,
                TICK_SPACING_MEDIUM
            );

            addLiquidity(
                testPool,
                nearestUsableTick(-60000, TICK_SPACING_MEDIUM),
                nearestUsableTick(60000, TICK_SPACING_MEDIUM),
                liquidityLevels[i]
            );

            (uint160 sqrtPriceX96, , , , , ) = testPool.slot0();

            uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
                amountIn,
                sqrtPriceX96,
                liquidityLevels[i],
                FEE_MEDIUM,
                true
            );

            assertTrue(quotedOut > 0, "Quote should be positive");
            assertTrue(quotedOut < amountIn, "Output should be less than input due to fees");
        }
    }
}
