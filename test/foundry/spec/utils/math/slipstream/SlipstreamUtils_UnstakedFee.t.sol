// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/// @title SlipstreamUtils Unstaked Fee Tests
/// @notice Unit tests for the unstaked fee functionality in SlipstreamUtils
/// @dev Tests verify that unstaked fee overloads correctly add the additional fee
contract SlipstreamUtils_UnstakedFee_Test is Test {
    using SlipstreamUtils for uint256;

    /* -------------------------------------------------------------------------- */
    /*                              Test Constants                                */
    /* -------------------------------------------------------------------------- */

    // Standard fee tiers (in pips: 1 pip = 0.0001%)
    uint24 internal constant FEE_LOW = 100;       // 0.01%
    uint24 internal constant FEE_MEDIUM = 500;    // 0.05%
    uint24 internal constant FEE_HIGH = 3000;     // 0.3%

    // Typical unstaked fees
    uint24 internal constant UNSTAKED_FEE_NONE = 0;
    uint24 internal constant UNSTAKED_FEE_LOW = 50;   // 0.005%
    uint24 internal constant UNSTAKED_FEE_MEDIUM = 100; // 0.01%
    uint24 internal constant UNSTAKED_FEE_HIGH = 500;  // 0.05%

    // Reasonable test values
    uint256 internal constant AMOUNT_IN = 1000e18;
    uint256 internal constant AMOUNT_OUT = 100e18;
    uint128 internal constant LIQUIDITY = 1e24;
    int24 internal constant TICK = 0; // Price ratio ~1:1

    /* -------------------------------------------------------------------------- */
    /*                    quoteExactInputSingle Unstaked Fee Tests                */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that unstaked fee of 0 gives same result as base function
    function test_quoteExactInputSingle_unstakedFeeZero_matchesBase() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        // Quote with base function
        uint256 baseQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            true // zeroForOne
        );

        // Quote with unstaked fee function (0 unstaked fee)
        uint256 unstakedQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_NONE,
            true
        );

        assertEq(baseQuote, unstakedQuote, "Zero unstaked fee should match base");
    }

    /// @notice Test that unstaked fee reduces output amount
    function test_quoteExactInputSingle_unstakedFee_reducesOutput() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        // Quote without unstaked fee
        uint256 noUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_NONE,
            true
        );

        // Quote with unstaked fee
        uint256 withUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_MEDIUM,
            true
        );

        assertTrue(
            withUnstakedFeeQuote < noUnstakedFeeQuote,
            "Unstaked fee should reduce output"
        );
    }

    /// @notice Test that combined fee equals fee + unstakedFee
    function test_quoteExactInputSingle_unstakedFee_equalsManualCombine() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        // Quote using the unstaked fee overload
        uint256 unstakedQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_MEDIUM,
            true
        );

        // Quote using base function with manually combined fee
        uint24 combinedFee = FEE_MEDIUM + UNSTAKED_FEE_MEDIUM;
        uint256 manualQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            combinedFee,
            true
        );

        assertEq(unstakedQuote, manualQuote, "Unstaked overload should equal manually combined fee");
    }

    /// @notice Test tick overload with unstaked fee
    function test_quoteExactInputSingle_tickOverload_unstakedFee() public pure {
        // Quote using tick overload without unstaked fee
        uint256 noUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            TICK,
            LIQUIDITY,
            FEE_MEDIUM,
            true
        );

        // Quote using tick overload with unstaked fee
        uint256 withUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            TICK,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_MEDIUM,
            true
        );

        assertTrue(
            withUnstakedFeeQuote < noUnstakedFeeQuote,
            "Tick overload: unstaked fee should reduce output"
        );
    }

    /// @notice Test zeroForOne = false direction with unstaked fee
    function test_quoteExactInputSingle_unstakedFee_reverseDirection() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        // Quote without unstaked fee (reverse direction)
        uint256 noUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_NONE,
            false // token1 -> token0
        );

        // Quote with unstaked fee (reverse direction)
        uint256 withUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_MEDIUM,
            false
        );

        assertTrue(
            withUnstakedFeeQuote < noUnstakedFeeQuote,
            "Reverse direction: unstaked fee should reduce output"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                   quoteExactOutputSingle Unstaked Fee Tests                */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that unstaked fee of 0 gives same result as base function for exact output
    function test_quoteExactOutputSingle_unstakedFeeZero_matchesBase() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        // Quote with base function
        uint256 baseQuote = SlipstreamUtils._quoteExactOutputSingle(
            AMOUNT_OUT,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            true
        );

        // Quote with unstaked fee function (0 unstaked fee)
        uint256 unstakedQuote = SlipstreamUtils._quoteExactOutputSingle(
            AMOUNT_OUT,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_NONE,
            true
        );

        assertEq(baseQuote, unstakedQuote, "Zero unstaked fee should match base");
    }

    /// @notice Test that unstaked fee increases required input for exact output
    function test_quoteExactOutputSingle_unstakedFee_increasesInput() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        // Quote without unstaked fee
        uint256 noUnstakedFeeQuote = SlipstreamUtils._quoteExactOutputSingle(
            AMOUNT_OUT,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_NONE,
            true
        );

        // Quote with unstaked fee
        uint256 withUnstakedFeeQuote = SlipstreamUtils._quoteExactOutputSingle(
            AMOUNT_OUT,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_MEDIUM,
            true
        );

        assertTrue(
            withUnstakedFeeQuote > noUnstakedFeeQuote,
            "Unstaked fee should increase required input"
        );
    }

    /// @notice Test that combined fee equals fee + unstakedFee for exact output
    function test_quoteExactOutputSingle_unstakedFee_equalsManualCombine() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        // Quote using the unstaked fee overload
        uint256 unstakedQuote = SlipstreamUtils._quoteExactOutputSingle(
            AMOUNT_OUT,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_MEDIUM,
            true
        );

        // Quote using base function with manually combined fee
        uint24 combinedFee = FEE_MEDIUM + UNSTAKED_FEE_MEDIUM;
        uint256 manualQuote = SlipstreamUtils._quoteExactOutputSingle(
            AMOUNT_OUT,
            sqrtPriceX96,
            LIQUIDITY,
            combinedFee,
            true
        );

        assertEq(unstakedQuote, manualQuote, "Unstaked overload should equal manually combined fee");
    }

    /// @notice Test tick overload with unstaked fee for exact output
    function test_quoteExactOutputSingle_tickOverload_unstakedFee() public pure {
        // Quote using tick overload without unstaked fee
        uint256 noUnstakedFeeQuote = SlipstreamUtils._quoteExactOutputSingle(
            AMOUNT_OUT,
            TICK,
            LIQUIDITY,
            FEE_MEDIUM,
            true
        );

        // Quote using tick overload with unstaked fee
        uint256 withUnstakedFeeQuote = SlipstreamUtils._quoteExactOutputSingle(
            AMOUNT_OUT,
            TICK,
            LIQUIDITY,
            FEE_MEDIUM,
            UNSTAKED_FEE_MEDIUM,
            true
        );

        assertTrue(
            withUnstakedFeeQuote > noUnstakedFeeQuote,
            "Tick overload: unstaked fee should increase required input"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                        Fuzz Tests for Unstaked Fee                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Fuzz test: unstaked fee always reduces exact input output
    function testFuzz_quoteExactInputSingle_unstakedFee_alwaysReducesOutput(
        uint256 amountIn,
        uint24 fee,
        uint24 unstakedFee
    ) public pure {
        // Bound inputs to reasonable ranges
        amountIn = bound(amountIn, 1e6, 1e30);
        fee = uint24(bound(fee, 1, 10000)); // Max 1%
        unstakedFee = uint24(bound(unstakedFee, 1, 5000)); // Max 0.5%

        // Ensure combined fee doesn't exceed reasonable bounds
        vm.assume(uint256(fee) + uint256(unstakedFee) <= 100000); // Max 10%

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        uint256 noUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            LIQUIDITY,
            fee,
            0,
            true
        );

        uint256 withUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            LIQUIDITY,
            fee,
            unstakedFee,
            true
        );

        assertTrue(
            withUnstakedFeeQuote <= noUnstakedFeeQuote,
            "Unstaked fee should never increase output"
        );
    }

    /// @notice Fuzz test: unstaked fee always increases exact output input requirement
    function testFuzz_quoteExactOutputSingle_unstakedFee_alwaysIncreasesInput(
        uint256 amountOut,
        uint24 fee,
        uint24 unstakedFee
    ) public pure {
        // Bound inputs to reasonable ranges
        amountOut = bound(amountOut, 1e6, 1e24); // Smaller max to avoid overflow
        fee = uint24(bound(fee, 1, 10000));
        unstakedFee = uint24(bound(unstakedFee, 1, 5000));

        vm.assume(uint256(fee) + uint256(unstakedFee) <= 100000);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        uint256 noUnstakedFeeQuote = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            LIQUIDITY,
            fee,
            0,
            true
        );

        uint256 withUnstakedFeeQuote = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            LIQUIDITY,
            fee,
            unstakedFee,
            true
        );

        assertTrue(
            withUnstakedFeeQuote >= noUnstakedFeeQuote,
            "Unstaked fee should never decrease required input"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                     Combined Fee Guard Revert Tests                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that exact input reverts when combined fee equals 1e6
    function test_quoteExactInputSingle_revert_combinedFeeEqualsDenominator() public {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        // feePips + unstakedFeePips == 1e6 should revert
        uint24 feePips = 500_000;
        uint24 unstakedFeePips = 500_000;

        vm.expectRevert("SL:INVALID_FEE");
        SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            feePips,
            unstakedFeePips,
            true
        );
    }

    /// @notice Test that exact input reverts when combined fee exceeds 1e6
    function test_quoteExactInputSingle_revert_combinedFeeExceedsDenominator() public {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        // feePips + unstakedFeePips > 1e6 should revert
        uint24 feePips = 999_000;
        uint24 unstakedFeePips = 2_000;

        vm.expectRevert("SL:INVALID_FEE");
        SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            feePips,
            unstakedFeePips,
            true
        );
    }

    /// @notice Test that exact output reverts when combined fee equals 1e6
    function test_quoteExactOutputSingle_revert_combinedFeeEqualsDenominator() public {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        uint24 feePips = 500_000;
        uint24 unstakedFeePips = 500_000;

        vm.expectRevert("SL:INVALID_FEE");
        SlipstreamUtils._quoteExactOutputSingle(
            AMOUNT_OUT,
            sqrtPriceX96,
            LIQUIDITY,
            feePips,
            unstakedFeePips,
            true
        );
    }

    /// @notice Test that exact output reverts when combined fee exceeds 1e6
    function test_quoteExactOutputSingle_revert_combinedFeeExceedsDenominator() public {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        uint24 feePips = 999_000;
        uint24 unstakedFeePips = 2_000;

        vm.expectRevert("SL:INVALID_FEE");
        SlipstreamUtils._quoteExactOutputSingle(
            AMOUNT_OUT,
            sqrtPriceX96,
            LIQUIDITY,
            feePips,
            unstakedFeePips,
            true
        );
    }

    /// @notice Test that combined fee just below 1e6 still works
    function test_quoteExactInputSingle_combinedFeeJustBelowDenominator() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        // feePips + unstakedFeePips == 999_999 should NOT revert
        uint24 feePips = 500_000;
        uint24 unstakedFeePips = 499_999;

        uint256 result = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            feePips,
            unstakedFeePips,
            true
        );

        // With ~99.9999% fee, output should be near zero but valid
        assertTrue(result >= 0, "Should not revert for totalFee < 1e6");
    }

    /// @notice Fuzz test: combined fee >= 1e6 always reverts for exact input
    function testFuzz_quoteExactInputSingle_revert_invalidCombinedFee(
        uint24 feePips,
        uint24 unstakedFeePips
    ) public {
        // Ensure combined fee >= 1e6
        feePips = uint24(bound(feePips, 1, 999_999));
        unstakedFeePips = uint24(bound(unstakedFeePips, uint256(1e6) - feePips, type(uint24).max - feePips));

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        vm.expectRevert("SL:INVALID_FEE");
        SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            feePips,
            unstakedFeePips,
            true
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Various Fee Tier Tests                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Test with low fee tier
    function test_quoteExactInputSingle_lowFeeTier_withUnstakedFee() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        uint256 noUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_LOW, // 0.01%
            UNSTAKED_FEE_NONE,
            true
        );

        uint256 withUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_LOW,
            UNSTAKED_FEE_LOW, // +0.005%
            true
        );

        // With very low fees, unstaked fee should still reduce output
        assertTrue(
            withUnstakedFeeQuote < noUnstakedFeeQuote,
            "Low fee tier: unstaked fee should reduce output"
        );
    }

    /// @notice Test with high fee tier
    function test_quoteExactInputSingle_highFeeTier_withUnstakedFee() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TICK);

        uint256 noUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_HIGH, // 0.3%
            UNSTAKED_FEE_NONE,
            true
        );

        uint256 withUnstakedFeeQuote = SlipstreamUtils._quoteExactInputSingle(
            AMOUNT_IN,
            sqrtPriceX96,
            LIQUIDITY,
            FEE_HIGH,
            UNSTAKED_FEE_HIGH, // +0.05%
            true
        );

        assertTrue(
            withUnstakedFeeQuote < noUnstakedFeeQuote,
            "High fee tier: unstaked fee should reduce output"
        );
    }
}
