// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/// @title Test SlipstreamUtils._quoteExactOutputSingle
/// @notice Validates exact output swap quotes for Slipstream pools
contract SlipstreamUtils_quoteExactOutput_Test is TestBase_Slipstream {
    using SlipstreamUtils for *;

    MockCLPool pool;
    address tokenA;
    address tokenB;

    uint256 constant INITIAL_LIQUIDITY = 1_000_000e18;
    uint256 constant TEST_AMOUNT_OUT = 1e18;

    function setUp() public override {
        super.setUp();

        tokenA = makeAddr("TokenA");
        tokenB = makeAddr("TokenB");

        pool = createMockPoolOneToOne(tokenA, tokenB, FEE_MEDIUM, TICK_SPACING_MEDIUM);

        int24 tickLower = nearestUsableTick(-60000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(60000, TICK_SPACING_MEDIUM);
        addLiquidity(pool, tickLower, tickUpper, uint128(INITIAL_LIQUIDITY));
    }

    /* -------------------------------------------------------------------------- */
    /*                          Quote vs Mock Swap Tests                          */
    /* -------------------------------------------------------------------------- */

    function test_quoteExactOutput_zeroForOne_matchesMockSwap() public {
        uint256 amountOut = TEST_AMOUNT_OUT;

        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        uint160 sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        (int256 amount0, int256 amount1) = pool.swap(
            address(this),
            true,
            -int256(amountOut),
            sqrtPriceLimitX96,
            ""
        );

        uint256 actualIn = uint256(amount0);
        uint256 actualOut = uint256(-amount1);

        assertApproxEqAbs(actualOut, amountOut, 1, "Mock did not fill requested output");
        assertApproxEqAbs(quotedIn, actualIn, 1, "Quote mismatch for zeroForOne");

        // tick overload parity
        uint256 quotedWithTick = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            tick,
            liquidity,
            FEE_MEDIUM,
            true
        );
        assertEq(quotedIn, quotedWithTick, "Tick overload mismatch");
    }

    function test_quoteExactOutput_oneForZero_matchesMockSwap() public {
        uint256 amountOut = TEST_AMOUNT_OUT;

        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            false
        );

        uint160 sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
        (int256 amount0, int256 amount1) = pool.swap(
            address(this),
            false,
            -int256(amountOut),
            sqrtPriceLimitX96,
            ""
        );

        uint256 actualIn = uint256(amount1);
        uint256 actualOut = uint256(-amount0);

        assertApproxEqAbs(actualOut, amountOut, 1, "Mock did not fill requested output");
        assertApproxEqAbs(quotedIn, actualIn, 1, "Quote mismatch for oneForZero");

        uint256 quotedWithTick = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            tick,
            liquidity,
            FEE_MEDIUM,
            false
        );
        assertEq(quotedIn, quotedWithTick, "Tick overload mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Fee Tier Tests                                  */
    /* -------------------------------------------------------------------------- */

    function test_quoteExactOutput_higherFeeRequiresMoreInput() public pure {
        uint256 amountOut = TEST_AMOUNT_OUT;

        uint256 quoteLow = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            uint160(1) << 96,
            uint128(INITIAL_LIQUIDITY),
            FEE_LOW,
            true
        );

        uint256 quoteHigh = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            uint160(1) << 96,
            uint128(INITIAL_LIQUIDITY),
            FEE_HIGH,
            true
        );

        assertLt(quoteLow, quoteHigh, "Higher fee should require more input");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Edge Cases                                    */
    /* -------------------------------------------------------------------------- */

    function test_quoteExactOutput_zeroAmount() public view {
        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            0,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        assertEq(quotedIn, 0, "Zero output should require zero input");
    }
}
