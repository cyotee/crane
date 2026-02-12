// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {UniswapV3Utils} from "@crane/contracts/utils/math/UniswapV3Utils.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {FixedPoint96} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/FixedPoint96.sol";

/// @title Test UniswapV3Utils edge cases and boundary conditions
contract UniswapV3Utils_EdgeCases_Test is Test {
    using UniswapV3Utils for *;

    /* -------------------------------------------------------------------------- */
    /*                        getSqrtPriceFromReserves Tests                      */
    /* -------------------------------------------------------------------------- */

    /// @notice Test converting 1:1 reserves to sqrt price
    function test_getSqrtPriceFromReserves_oneToOne() public {
        uint256 reserve0 = 1_000_000e18;
        uint256 reserve1 = 1_000_000e18;

        uint160 sqrtPriceX96 = UniswapV3Utils._getSqrtPriceFromReserves(reserve0, reserve1);

        // 1:1 price means sqrt(1) * 2^96 = 2^96
        uint160 expected = uint160(uint256(1) << 96);

        // Allow small rounding error from sqrt calculation
        assertApproxEqAbs(sqrtPriceX96, expected, 1, "1:1 price incorrect");
    }

    /// @notice Test converting 1:4 reserves (price = 4)
    function test_getSqrtPriceFromReserves_oneToFour() public {
        uint256 reserve0 = 1_000_000e18;
        uint256 reserve1 = 4_000_000e18;

        uint160 sqrtPriceX96 = UniswapV3Utils._getSqrtPriceFromReserves(reserve0, reserve1);

        // Price = 4, so sqrtPrice = 2
        // sqrtPriceX96 = 2 * 2^96
        uint160 expected = uint160(uint256(2) << 96);

        assertApproxEqAbs(sqrtPriceX96, expected, 100, "1:4 price incorrect");
    }

    /// @notice Test with very small reserves
    function test_getSqrtPriceFromReserves_smallReserves() public {
        uint256 reserve0 = 1e6;   // 0.000001 tokens (6 decimals)
        uint256 reserve1 = 1e6;

        uint160 sqrtPriceX96 = UniswapV3Utils._getSqrtPriceFromReserves(reserve0, reserve1);

        // Should still be ~2^96 for 1:1 price
        uint160 expected = uint160(uint256(1) << 96);
        assertApproxEqAbs(sqrtPriceX96, expected, 1, "Small reserves 1:1 incorrect");
    }

    /// @notice Test with large reserves
    function test_getSqrtPriceFromReserves_largeReserves() public {
        uint256 reserve0 = 1_000_000_000e18;  // 1 billion tokens
        uint256 reserve1 = 1_000_000_000e18;

        uint160 sqrtPriceX96 = UniswapV3Utils._getSqrtPriceFromReserves(reserve0, reserve1);

        uint160 expected = uint160(uint256(1) << 96);
        assertApproxEqAbs(sqrtPriceX96, expected, 1, "Large reserves 1:1 incorrect");
    }

    /// @notice Test reverts with zero reserve0
    /// @dev Internal library calls can't use vm.expectRevert, so we use try/catch via external call
    function test_getSqrtPriceFromReserves_revertsOnZeroReserve0() public {
        // Test via low-level call to catch the revert
        (bool success,) = address(this).call(
            abi.encodeWithSignature("callGetSqrtPriceFromReserves(uint256,uint256)", 0, 1_000_000e18)
        );
        assertFalse(success, "Should revert on zero reserve0");
    }

    /// @dev External helper to make the internal library call catchable
    function callGetSqrtPriceFromReserves(uint256 r0, uint256 r1) external pure returns (uint160) {
        return UniswapV3Utils._getSqrtPriceFromReserves(r0, r1);
    }

    /// @notice Test with zero reserve1 (valid - price is 0)
    function test_getSqrtPriceFromReserves_zeroReserve1() public {
        uint256 reserve0 = 1_000_000e18;
        uint256 reserve1 = 0;

        uint160 sqrtPriceX96 = UniswapV3Utils._getSqrtPriceFromReserves(reserve0, reserve1);

        // Price = 0, so sqrtPrice = 0
        assertEq(sqrtPriceX96, 0, "Zero reserve1 should give zero price");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Amount Delta Helper Tests                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Test _getAmount0Delta helper
    function test_getAmount0Delta() public {
        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(-1000);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(1000);
        uint128 liquidity = 1_000_000e18;

        // Test rounding down (receiving tokens)
        uint256 amount0Down = UniswapV3Utils._getAmount0Delta(
            sqrtPriceAX96,
            sqrtPriceBX96,
            liquidity,
            false
        );

        // Test rounding up (paying tokens)
        uint256 amount0Up = UniswapV3Utils._getAmount0Delta(
            sqrtPriceAX96,
            sqrtPriceBX96,
            liquidity,
            true
        );

        // Rounding up should be >= rounding down
        assertTrue(amount0Up >= amount0Down, "Round up should be >= round down");

        // Both should be non-zero for this range
        assertTrue(amount0Down > 0, "Amount0 should be > 0");
    }

    /// @notice Test _getAmount1Delta helper
    function test_getAmount1Delta() public {
        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(-1000);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(1000);
        uint128 liquidity = 1_000_000e18;

        // Test rounding down
        uint256 amount1Down = UniswapV3Utils._getAmount1Delta(
            sqrtPriceAX96,
            sqrtPriceBX96,
            liquidity,
            false
        );

        // Test rounding up
        uint256 amount1Up = UniswapV3Utils._getAmount1Delta(
            sqrtPriceAX96,
            sqrtPriceBX96,
            liquidity,
            true
        );

        // Rounding up should be >= rounding down
        assertTrue(amount1Up >= amount1Down, "Round up should be >= round down");

        // Both should be non-zero
        assertTrue(amount1Down > 0, "Amount1 should be > 0");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Boundary Tick Tests                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote at minimum tick
    function test_quoteExactInput_atMinTick() public {
        uint160 sqrtPriceX96 = TickMath.MIN_SQRT_RATIO + 1;
        uint128 liquidity = 1_000_000e18;
        uint256 amountIn = 1_000e18;

        // Should not revert
        uint256 amountOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            3000,
            false  // Swap token1 -> token0 (price will increase from min)
        );

        // Output should be positive
        assertTrue(amountOut > 0, "Output at min tick should be > 0");
    }

    /// @notice Test quote at maximum tick
    function test_quoteExactInput_atMaxTick() public {
        uint160 sqrtPriceX96 = TickMath.MAX_SQRT_RATIO - 1;
        uint128 liquidity = 1_000_000e18;
        uint256 amountIn = 1_000e18;

        // Should not revert
        uint256 amountOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            3000,
            true  // Swap token0 -> token1 (price will decrease from max)
        );

        // Output should be positive
        assertTrue(amountOut > 0, "Output at max tick should be > 0");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Zero Liquidity Tests                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote with zero liquidity returns zero output
    /// @dev With zero liquidity, no swap can occur so output should be zero
    function test_quoteExactInput_zeroLiquidity() public {
        uint160 sqrtPriceX96 = uint160(uint256(1) << 96);  // 1:1 price
        uint128 liquidity = 0;
        uint256 amountIn = 1_000e18;

        // With zero liquidity, no tokens can be swapped - output should be zero
        uint256 amountOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            3000,
            true
        );

        // Zero liquidity means no swap is possible
        assertEq(amountOut, 0, "Zero liquidity should give zero output");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Fee Percentage Tests                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that higher fees result in less output
    function test_quoteExactInput_higherFeeMeansLessOutput() public {
        uint160 sqrtPriceX96 = uint160(uint256(1) << 96);
        uint128 liquidity = 1_000_000e18;
        uint256 amountIn = 1_000e18;

        // Quote with low fee (0.05%)
        uint256 outputLowFee = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            500,  // 0.05%
            true
        );

        // Quote with medium fee (0.3%)
        uint256 outputMediumFee = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            3000,  // 0.3%
            true
        );

        // Quote with high fee (1%)
        uint256 outputHighFee = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            10000,  // 1%
            true
        );

        // Higher fee should result in less output
        assertTrue(outputLowFee > outputMediumFee, "Low fee should give more output than medium");
        assertTrue(outputMediumFee > outputHighFee, "Medium fee should give more output than high");
    }

    /// @notice Test that higher fees require more input for same output
    function test_quoteExactOutput_higherFeeMeansMoreInput() public {
        uint160 sqrtPriceX96 = uint160(uint256(1) << 96);
        uint128 liquidity = 1_000_000e18;
        uint256 amountOut = 1_000e18;

        // Quote with low fee
        uint256 inputLowFee = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            500,
            true
        );

        // Quote with medium fee
        uint256 inputMediumFee = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            3000,
            true
        );

        // Quote with high fee
        uint256 inputHighFee = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            10000,
            true
        );

        // Higher fee should require more input
        assertTrue(inputLowFee < inputMediumFee, "Low fee should require less input than medium");
        assertTrue(inputMediumFee < inputHighFee, "Medium fee should require less input than high");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Price Impact Tests                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that larger swaps have more price impact
    function test_quoteExactInput_largerSwapMoreImpact() public {
        uint160 sqrtPriceX96 = uint160(uint256(1) << 96);
        uint128 liquidity = 1_000_000e18;

        // Small swap
        uint256 smallAmount = 1_000e18;
        uint256 smallOutput = UniswapV3Utils._quoteExactInputSingle(
            smallAmount,
            sqrtPriceX96,
            liquidity,
            3000,
            true
        );

        // Large swap (10x)
        uint256 largeAmount = 10_000e18;
        uint256 largeOutput = UniswapV3Utils._quoteExactInputSingle(
            largeAmount,
            sqrtPriceX96,
            liquidity,
            3000,
            true
        );

        // Due to price impact, 10x input should give less than 10x output
        assertTrue(largeOutput < smallOutput * 10, "Large swap should have more price impact");

        // But should still give more than 1x output
        assertTrue(largeOutput > smallOutput, "Large swap should give more output");
    }
}
