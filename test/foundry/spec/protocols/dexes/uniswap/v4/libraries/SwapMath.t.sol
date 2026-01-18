// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SwapMath} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/SwapMath.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/TickMath.sol";
import {SqrtPriceMath} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.sol";

/**
 * @title SwapMath_V4_Test
 * @notice Unit tests for Uniswap V4 SwapMath library pure math functions.
 * @dev Tests computeSwapStep and getSqrtPriceTarget with known inputs/outputs.
 *
 * Key properties tested:
 * 1. getSqrtPriceTarget returns correct target based on direction
 * 2. computeSwapStep handles exact input swaps correctly
 * 3. computeSwapStep handles exact output swaps correctly
 * 4. Fee calculations are correct
 * 5. Edge cases: zero amounts, max fees, boundary prices
 */
contract SwapMath_V4_Test is Test {

    /* -------------------------------------------------------------------------- */
    /*                            Constants                                       */
    /* -------------------------------------------------------------------------- */

    uint256 internal constant MAX_SWAP_FEE = 1e6;
    uint160 internal constant MIN_SQRT_PRICE = 4295128739;
    uint160 internal constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342;

    // Common test values
    uint160 internal constant SQRT_PRICE_1_1 = 79228162514264337593543950336; // 2^96, 1:1 price
    uint128 internal constant LIQUIDITY_1E18 = 1e18;

    /* -------------------------------------------------------------------------- */
    /*                       getSqrtPriceTarget Tests                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests getSqrtPriceTarget for zeroForOne = true (selling token0)
     * @dev When zeroForOne is true, price decreases, so target = max(next, limit)
     */
    function test_getSqrtPriceTarget_zeroForOne_nextGreater() public pure {
        uint160 sqrtPriceNextX96 = 100e18;
        uint160 sqrtPriceLimitX96 = 50e18;

        uint160 target = SwapMath.getSqrtPriceTarget(true, sqrtPriceNextX96, sqrtPriceLimitX96);

        // When zeroForOne, we want max(next, limit) because price is decreasing
        assertEq(target, sqrtPriceNextX96, "Should return next when next > limit for zeroForOne");
    }

    /**
     * @notice Tests getSqrtPriceTarget for zeroForOne = true when limit is greater
     */
    function test_getSqrtPriceTarget_zeroForOne_limitGreater() public pure {
        uint160 sqrtPriceNextX96 = 50e18;
        uint160 sqrtPriceLimitX96 = 100e18;

        uint160 target = SwapMath.getSqrtPriceTarget(true, sqrtPriceNextX96, sqrtPriceLimitX96);

        // When zeroForOne and limit > next, return limit (we can't go lower than limit)
        assertEq(target, sqrtPriceLimitX96, "Should return limit when limit > next for zeroForOne");
    }

    /**
     * @notice Tests getSqrtPriceTarget for zeroForOne = false (selling token1)
     * @dev When zeroForOne is false, price increases, so target = min(next, limit)
     */
    function test_getSqrtPriceTarget_oneForZero_nextLess() public pure {
        uint160 sqrtPriceNextX96 = 50e18;
        uint160 sqrtPriceLimitX96 = 100e18;

        uint160 target = SwapMath.getSqrtPriceTarget(false, sqrtPriceNextX96, sqrtPriceLimitX96);

        // When oneForZero, we want min(next, limit) because price is increasing
        assertEq(target, sqrtPriceNextX96, "Should return next when next < limit for oneForZero");
    }

    /**
     * @notice Tests getSqrtPriceTarget for zeroForOne = false when limit is less
     */
    function test_getSqrtPriceTarget_oneForZero_limitLess() public pure {
        uint160 sqrtPriceNextX96 = 100e18;
        uint160 sqrtPriceLimitX96 = 50e18;

        uint160 target = SwapMath.getSqrtPriceTarget(false, sqrtPriceNextX96, sqrtPriceLimitX96);

        // When oneForZero and limit < next, return limit (we can't go higher than limit)
        assertEq(target, sqrtPriceLimitX96, "Should return limit when limit < next for oneForZero");
    }

    /**
     * @notice Tests getSqrtPriceTarget when next equals limit
     */
    function test_getSqrtPriceTarget_equal() public pure {
        uint160 sqrtPrice = 79228162514264337593543950336; // 2^96

        uint160 targetZeroForOne = SwapMath.getSqrtPriceTarget(true, sqrtPrice, sqrtPrice);
        uint160 targetOneForZero = SwapMath.getSqrtPriceTarget(false, sqrtPrice, sqrtPrice);

        assertEq(targetZeroForOne, sqrtPrice, "Equal prices should return same for zeroForOne");
        assertEq(targetOneForZero, sqrtPrice, "Equal prices should return same for oneForZero");
    }

    /* -------------------------------------------------------------------------- */
    /*                   computeSwapStep - Exact Input Tests                      */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests computeSwapStep with exact input, reaching target price
     * @dev amountRemaining < 0 indicates exact input swap
     */
    function test_computeSwapStep_exactIn_reachTarget_zeroForOne() public pure {
        uint160 sqrtPriceCurrent = SQRT_PRICE_1_1;
        uint160 sqrtPriceTarget = TickMath.getSqrtPriceAtTick(-100); // Lower price
        uint128 liquidity = LIQUIDITY_1E18;
        int256 amountRemaining = -1e18; // Exact input of 1e18
        uint24 feePips = 3000; // 0.3%

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        // Verify outputs are reasonable
        assertLe(sqrtPriceNext, sqrtPriceCurrent, "Price should decrease for zeroForOne");
        assertGe(sqrtPriceNext, sqrtPriceTarget, "Price should not go below target");
        assertGt(amountIn, 0, "amountIn should be positive");
        assertGt(amountOut, 0, "amountOut should be positive");

        // Fee should be a portion of input
        assertLe(feeAmount + amountIn, uint256(-amountRemaining), "Fee + input should not exceed amountRemaining");
    }

    /**
     * @notice Tests computeSwapStep with exact input, not reaching target
     * @dev When input is exhausted before reaching target
     */
    function test_computeSwapStep_exactIn_exhaustInput() public pure {
        uint160 sqrtPriceCurrent = SQRT_PRICE_1_1;
        uint160 sqrtPriceTarget = TickMath.getSqrtPriceAtTick(-10000); // Very low target
        uint128 liquidity = LIQUIDITY_1E18;
        int256 amountRemaining = -1e15; // Small exact input
        uint24 feePips = 3000; // 0.3%

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        // Should not reach target due to small input
        assertGt(sqrtPriceNext, sqrtPriceTarget, "Should not reach target with small input");

        // All of amountRemaining should be consumed (minus fee)
        assertEq(amountIn + feeAmount, uint256(-amountRemaining), "All input should be consumed");
    }

    /**
     * @notice Tests computeSwapStep with exact input, oneForZero direction
     */
    function test_computeSwapStep_exactIn_oneForZero() public pure {
        uint160 sqrtPriceCurrent = SQRT_PRICE_1_1;
        uint160 sqrtPriceTarget = TickMath.getSqrtPriceAtTick(100); // Higher price
        uint128 liquidity = LIQUIDITY_1E18;
        int256 amountRemaining = -1e18; // Exact input of 1e18
        uint24 feePips = 3000; // 0.3%

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        // Verify outputs are reasonable for oneForZero
        assertGe(sqrtPriceNext, sqrtPriceCurrent, "Price should increase for oneForZero");
        assertLe(sqrtPriceNext, sqrtPriceTarget, "Price should not exceed target");
        assertGt(amountIn, 0, "amountIn should be positive");
        assertGt(amountOut, 0, "amountOut should be positive");
    }

    /* -------------------------------------------------------------------------- */
    /*                   computeSwapStep - Exact Output Tests                     */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests computeSwapStep with exact output, reaching target
     * @dev amountRemaining > 0 indicates exact output swap
     */
    function test_computeSwapStep_exactOut_reachTarget() public pure {
        uint160 sqrtPriceCurrent = SQRT_PRICE_1_1;
        uint160 sqrtPriceTarget = TickMath.getSqrtPriceAtTick(-100);
        uint128 liquidity = LIQUIDITY_1E18;
        int256 amountRemaining = 1e18; // Exact output of 1e18
        uint24 feePips = 3000; // 0.3%

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        // Verify outputs
        assertGe(sqrtPriceNext, sqrtPriceTarget, "Price should not go below target");
        assertGt(amountIn, 0, "amountIn should be positive for exact output");
        assertLe(amountOut, uint256(amountRemaining), "amountOut should not exceed requested");
        assertGt(feeAmount, 0, "feeAmount should be positive");
    }

    /**
     * @notice Tests computeSwapStep with exact output, capped by output amount
     */
    function test_computeSwapStep_exactOut_cappedByOutput() public pure {
        uint160 sqrtPriceCurrent = SQRT_PRICE_1_1;
        uint160 sqrtPriceTarget = TickMath.getSqrtPriceAtTick(-10000); // Very low target
        uint128 liquidity = LIQUIDITY_1E18;
        int256 amountRemaining = 1e12; // Small exact output
        uint24 feePips = 3000;

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        // Output should equal requested since we have plenty of range
        assertEq(amountOut, uint256(amountRemaining), "Output should equal requested amount");
        assertGt(sqrtPriceNext, sqrtPriceTarget, "Should not reach target with small output request");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Fee Calculation Tests                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests fee calculation with zero fee
     */
    function test_computeSwapStep_zeroFee() public pure {
        uint160 sqrtPriceCurrent = SQRT_PRICE_1_1;
        uint160 sqrtPriceTarget = TickMath.getSqrtPriceAtTick(-100);
        uint128 liquidity = LIQUIDITY_1E18;
        int256 amountRemaining = -1e18;
        uint24 feePips = 0; // No fee

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        assertEq(feeAmount, 0, "Fee should be zero with zero feePips");
        assertGt(amountIn, 0, "amountIn should still be positive");
        assertGt(amountOut, 0, "amountOut should still be positive");
    }

    /**
     * @notice Tests fee calculation with maximum fee (100%)
     * @dev With 100% fee, amountRemainingLessFee = 0, but we only reach target if amountIn to reach target is also 0.
     *      Since prices differ, amountIn > 0, so 0 >= amountIn is false, meaning we exhaust input (which is 0)
     *      and call getNextSqrtPriceFromInput with amountIn=0, returning current price.
     */
    function test_computeSwapStep_maxFee() public pure {
        uint160 sqrtPriceCurrent = SQRT_PRICE_1_1;
        uint160 sqrtPriceTarget = TickMath.getSqrtPriceAtTick(-100);
        uint128 liquidity = LIQUIDITY_1E18;
        int256 amountRemaining = -1e18;
        uint24 feePips = uint24(MAX_SWAP_FEE); // 100% fee

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        // With 100% fee:
        // - amountRemainingLessFee = mulDiv(1e18, 0, 1e6) = 0
        // - amountIn (to target) = getAmount0Delta(...) > 0 since prices differ
        // - 0 >= amountIn is FALSE, so we go to else branch (exhaust remaining)
        // - amountIn = amountRemainingLessFee = 0
        // - sqrtPriceNext = getNextSqrtPriceFromInput(current, liq, 0, true) = current (no movement)
        // - feeAmount = -amountRemaining - amountIn = 1e18 - 0 = 1e18 (entire input is fee)
        assertEq(sqrtPriceNext, sqrtPriceCurrent, "Price should not move with 100% fee");
        assertEq(amountIn, 0, "amountIn should be zero (all goes to fee)");
        assertEq(amountOut, 0, "amountOut should be zero (no swap occurs)");
        assertEq(feeAmount, uint256(-amountRemaining), "Entire input should be fee with 100% fee");
    }

    /**
     * @notice Tests that fee is correctly proportional to input when NOT reaching target
     * @dev Fee + amountIn = totalInput only when we exhaust input (don't reach target)
     */
    function test_computeSwapStep_feeProportionality() public pure {
        uint160 sqrtPriceCurrent = SQRT_PRICE_1_1;
        // Use a very far target and small liquidity to ensure we exhaust input
        uint160 sqrtPriceTarget = TickMath.getSqrtPriceAtTick(-100000);
        uint128 liquidity = 1e15; // Small liquidity to ensure we don't reach target
        int256 amountRemaining = -1e18;
        uint24 feePips = 3000; // 0.3%

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            ,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        // Only when we don't reach target (exhaust input), fee + input = total
        if (sqrtPriceNext != sqrtPriceTarget) {
            // When input is exhausted, amountIn + feeAmount should equal total input
            uint256 totalInput = uint256(-amountRemaining);
            assertEq(amountIn + feeAmount, totalInput, "Fee + input should equal total when exhausting input");
        }

        // Fee should be approximately correct relative to amountIn
        // Expected fee = amountIn * feePips / (MAX_SWAP_FEE - feePips)
        if (amountIn > 0) {
            uint256 expectedFeeApprox = amountIn * feePips / (MAX_SWAP_FEE - feePips);
            // Allow up to 1% relative difference due to rounding
            assertApproxEqRel(feeAmount, expectedFeeApprox, 0.01e18, "Fee should be approximately correct");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                           Edge Cases                                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests computeSwapStep with zero amount remaining
     * @dev amountRemaining = 0 is treated as exact output mode (since 0 >= 0 is true)
     *      When amountRemaining = 0 for exact output, uint256(0) >= amountOut is only true if amountOut = 0
     */
    function test_computeSwapStep_zeroAmount() public pure {
        uint160 sqrtPriceCurrent = SQRT_PRICE_1_1;
        uint160 sqrtPriceTarget = TickMath.getSqrtPriceAtTick(-100);
        uint128 liquidity = LIQUIDITY_1E18;
        int256 amountRemaining = 0; // Zero amount

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, 3000);

        // amountRemaining = 0, exactIn = false (since 0 is not < 0)
        // So this is exact output mode with 0 requested output
        // Since amountOut from target > 0, we don't reach target (0 < amountOut)
        // amountOut gets capped to 0, and sqrtPriceNext is calculated from 0 output
        // getNextSqrtPriceFromOutput with 0 amount returns the same price
        assertEq(sqrtPriceNext, sqrtPriceCurrent, "Zero exact output should not move price");
        assertEq(amountIn, 0, "amountIn should be zero");
        assertEq(amountOut, 0, "amountOut should be zero");
        assertEq(feeAmount, 0, "feeAmount should be zero");
    }

    /**
     * @notice Tests computeSwapStep when current equals target (no movement)
     */
    function test_computeSwapStep_noMovement() public pure {
        uint160 sqrtPrice = SQRT_PRICE_1_1;
        uint128 liquidity = LIQUIDITY_1E18;
        int256 amountRemaining = -1e18;

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPrice, sqrtPrice, liquidity, amountRemaining, 3000);

        // No price movement expected
        assertEq(sqrtPriceNext, sqrtPrice, "Price should not change when current equals target");
        assertEq(amountIn, 0, "amountIn should be zero");
        assertEq(amountOut, 0, "amountOut should be zero");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Golden Vector Tests                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Golden vector test: exactIn oneForZero capped at price target
     * @dev Derived from Uniswap V4 reference: test_computeSwapStep_exactAmountIn_oneForZero_thatGetsCappedAtPriceTargetIn
     *
     * Scenario: Selling token1 for token0 (oneForZero) with exact input of 1 ether.
     * The swap reaches the price target (101:100 ratio) before exhausting input.
     *
     * Inputs:
     * - sqrtPriceCurrent: 79228162514264337593543950336 (1:1 price, 2^96)
     * - sqrtPriceTarget: 79623317895830914510639640423 (101:100 price)
     * - liquidity: 2 ether
     * - amountRemaining: -1 ether (exact input)
     * - feePips: 600 (0.06%)
     *
     * Expected outputs (from Uniswap V4 tests):
     * - sqrtPriceNext: 79623317895830914510639640423 (reaches target)
     * - amountIn: 9975124224178055
     * - amountOut: 9925619580021728
     * - feeAmount: 5988667735148
     */
    function test_goldenVector_exactIn_oneForZero_cappedAtTarget() public pure {
        uint160 sqrtPriceCurrent = 79228162514264337593543950336;
        uint160 sqrtPriceTarget = 79623317895830914510639640423;
        uint128 liquidity = 2 ether;
        int256 amountRemaining = -1 ether;
        uint24 feePips = 600;

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        assertEq(sqrtPriceNext, sqrtPriceTarget, "Golden: sqrtPriceNext should reach target");
        assertEq(amountIn, 9975124224178055, "Golden: amountIn mismatch");
        assertEq(amountOut, 9925619580021728, "Golden: amountOut mismatch");
        assertEq(feeAmount, 5988667735148, "Golden: feeAmount mismatch");
    }

    /**
     * @notice Golden vector test: exactIn oneForZero fully spent (exhausts input before target)
     * @dev Derived from Uniswap V4 reference: test_computeSwapStep_exactAmountIn_oneForZero_thatIsFullySpentIn
     *
     * Scenario: Selling token1 for token0 (oneForZero) with exact input of 1 ether.
     * The target price is far away (1000:100 = 10x) so input is exhausted before reaching target.
     *
     * Inputs:
     * - sqrtPriceCurrent: 79228162514264337593543950336 (1:1 price)
     * - sqrtPriceTarget: 250541448375047931186413801569 (1000:100 = 10x price)
     * - liquidity: 2 ether
     * - amountRemaining: -1 ether (exact input)
     * - feePips: 600 (0.06%)
     *
     * Expected outputs (from Uniswap V4 tests):
     * - amountIn: 999400000000000000
     * - amountOut: 666399946655997866
     * - feeAmount: 600000000000000
     */
    function test_goldenVector_exactIn_oneForZero_fullySpent() public pure {
        uint160 sqrtPriceCurrent = 79228162514264337593543950336;
        uint160 sqrtPriceTarget = 250541448375047931186413801569;
        uint128 liquidity = 2 ether;
        int256 amountRemaining = -1 ether;
        uint24 feePips = 600;

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        // Input is exhausted, so sqrtPriceNext does not reach target
        assertGt(sqrtPriceTarget, sqrtPriceNext, "Golden: should not reach target (input exhausted)");
        assertEq(amountIn, 999400000000000000, "Golden: amountIn mismatch");
        assertEq(amountOut, 666399946655997866, "Golden: amountOut mismatch");
        assertEq(feeAmount, 600000000000000, "Golden: feeAmount mismatch");
        // Verify conservation: fee + amountIn = total input (when input exhausted)
        assertEq(amountIn + feeAmount, uint256(-amountRemaining), "Golden: input conservation");
    }

    /**
     * @notice Golden vector test: exactOut oneForZero capped at target
     * @dev Derived from Uniswap V4 reference: test_computeSwapStep_exactAmountOut_oneForZero_thatGetsCappedAtPriceTargetIn
     *
     * Scenario: Exact output of 1 ether, but capped at price target.
     * Uses same parameters as exactIn capped test for comparison.
     *
     * Inputs:
     * - sqrtPriceCurrent: 79228162514264337593543950336 (1:1 price)
     * - sqrtPriceTarget: 79623317895830914510639640423 (101:100 price)
     * - liquidity: 2 ether
     * - amountRemaining: 1 ether (exact output requested)
     * - feePips: 600 (0.06%)
     *
     * Expected outputs (from Uniswap V4 tests):
     * - amountIn: 9975124224178055
     * - amountOut: 9925619580021728
     * - feeAmount: 5988667735148
     */
    function test_goldenVector_exactOut_oneForZero_cappedAtTarget() public pure {
        uint160 sqrtPriceCurrent = 79228162514264337593543950336;
        uint160 sqrtPriceTarget = 79623317895830914510639640423;
        uint128 liquidity = 2 ether;
        int256 amountRemaining = 1 ether;
        uint24 feePips = 600;

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        assertEq(sqrtPriceNext, sqrtPriceTarget, "Golden: sqrtPriceNext should reach target");
        assertEq(amountIn, 9975124224178055, "Golden: amountIn mismatch");
        assertEq(amountOut, 9925619580021728, "Golden: amountOut mismatch");
        assertEq(feeAmount, 5988667735148, "Golden: feeAmount mismatch");
    }

    /**
     * @notice Golden vector test: exactOut oneForZero fully received
     * @dev Derived from Uniswap V4 reference: test_computeSwapStep_exactAmountOut_oneForZero_thatIsFullyReceivedIn
     *
     * Scenario: Exact output of 1 ether is fully satisfied because target is far away.
     *
     * Inputs:
     * - sqrtPriceCurrent: 79228162514264337593543950336 (1:1 price)
     * - sqrtPriceTarget: 792281625142643375935439503360 (10000:100 = 100x price)
     * - liquidity: 2 ether
     * - amountRemaining: 1 ether (exact output)
     * - feePips: 600 (0.06%)
     *
     * Expected outputs (from Uniswap V4 tests):
     * - amountIn: 2000000000000000000
     * - amountOut: 1 ether
     * - feeAmount: 1200720432259356
     */
    function test_goldenVector_exactOut_oneForZero_fullyReceived() public pure {
        uint160 sqrtPriceCurrent = 79228162514264337593543950336;
        uint160 sqrtPriceTarget = 792281625142643375935439503360;
        uint128 liquidity = 2 ether;
        int256 amountRemaining = 1 ether;
        uint24 feePips = 600;

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        // Did not reach target since output was satisfied first
        assertLt(sqrtPriceNext, sqrtPriceTarget, "Golden: should not reach target (output satisfied)");
        assertEq(amountIn, 2000000000000000000, "Golden: amountIn mismatch");
        assertEq(amountOut, 1 ether, "Golden: amountOut mismatch");
        assertEq(feeAmount, 1200720432259356, "Golden: feeAmount mismatch");
    }

    /**
     * @notice Golden vector test: amountOut capped at desired amount (edge case)
     * @dev Derived from Uniswap V4 reference: test_computeSwapStep_amountOut_isCappedAtTheDesiredAmountOut
     *
     * Scenario: Edge case where computed output would be 2 but requested is 1.
     * Tests proper capping of output amount.
     *
     * Inputs:
     * - sqrtPriceCurrent: 417332158212080721273783715441582
     * - sqrtPriceTarget: 1452870262520218020823638996
     * - liquidity: 159344665391607089467575320103
     * - amountRemaining: 1 (exact output)
     * - feePips: 1
     *
     * Expected outputs (from Uniswap V4 tests):
     * - sqrtPriceNext: 417332158212080721273783715441581
     * - amountIn: 1
     * - amountOut: 1 (capped from 2)
     * - feeAmount: 1
     */
    function test_goldenVector_exactOut_cappedAtDesiredAmount() public pure {
        uint160 sqrtPriceCurrent = 417332158212080721273783715441582;
        uint160 sqrtPriceTarget = 1452870262520218020823638996;
        uint128 liquidity = 159344665391607089467575320103;
        int256 amountRemaining = 1;
        uint24 feePips = 1;

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        assertEq(sqrtPriceNext, 417332158212080721273783715441581, "Golden: sqrtPriceNext mismatch");
        assertEq(amountIn, 1, "Golden: amountIn mismatch");
        assertEq(amountOut, 1, "Golden: amountOut mismatch (should be capped)");
        assertEq(feeAmount, 1, "Golden: feeAmount mismatch");
    }

    /**
     * @notice Golden vector test: zeroForOne (selling token0) reaching target price
     * @dev Derived from Uniswap V4 reference: test_computeSwapStep_oneForZero_handlesIntermediateInsufficientLiquidityInExactOutputCase
     *
     * Note: This test uses a zeroForOne direction by having current > target.
     * Uses low liquidity to test edge case handling.
     *
     * Inputs:
     * - sqrtPriceCurrent: 20282409603651670423947251286016
     * - sqrtPriceTarget: (sqrtPriceCurrent * 9) / 10 = 18254168643286503381552526157414
     * - liquidity: 1024
     * - amountRemaining: 263000 (exact output)
     * - feePips: 3000 (0.3%)
     *
     * Expected outputs (from Uniswap V4 tests):
     * - sqrtPriceNext: target price
     * - amountIn: 1
     * - amountOut: 26214
     * - feeAmount: 1
     */
    function test_goldenVector_zeroForOne_lowLiquidity_reachTarget() public pure {
        uint160 sqrtPriceCurrent = 20282409603651670423947251286016;
        uint160 sqrtPriceTarget = (sqrtPriceCurrent * 9) / 10;
        uint128 liquidity = 1024;
        int256 amountRemaining = 263000;
        uint24 feePips = 3000;

        (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(sqrtPriceCurrent, sqrtPriceTarget, liquidity, amountRemaining, feePips);

        assertEq(sqrtPriceNext, sqrtPriceTarget, "Golden: sqrtPriceNext should reach target");
        assertEq(amountIn, 1, "Golden: amountIn mismatch");
        assertEq(amountOut, 26214, "Golden: amountOut mismatch");
        assertEq(feeAmount, 1, "Golden: feeAmount mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Invariant Tests                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: verifies price movement direction matches swap direction
     * @dev Uses conservative bounds to avoid overflow in underlying math
     */
    function testFuzz_computeSwapStep_priceDirectionConsistency(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        uint256 amountSeed,
        uint24 feePips
    ) public pure {
        // Use more conservative bounds to avoid overflow
        // sqrtPrice around 2^96 (1:1 price) is safest
        uint160 midPrice = SQRT_PRICE_1_1;
        sqrtPriceCurrent = uint160(bound(sqrtPriceCurrent, midPrice / 100, midPrice * 100));
        sqrtPriceTarget = uint160(bound(sqrtPriceTarget, midPrice / 100, midPrice * 100));

        // Keep liquidity reasonable to avoid overflow
        liquidity = uint128(bound(liquidity, 1e12, 1e24));

        // Exclude max fee to avoid division issues
        feePips = uint24(bound(feePips, 0, 500000)); // Max 50% fee for safety

        // Avoid same price (no movement case)
        if (sqrtPriceCurrent == sqrtPriceTarget) {
            sqrtPriceTarget = sqrtPriceCurrent > MIN_SQRT_PRICE
                ? sqrtPriceCurrent - 1
                : sqrtPriceCurrent + 1;
        }

        // Use exact input with reasonable amounts
        uint256 amount = bound(amountSeed, 1e12, 1e24);
        int256 amountRemaining = -int256(amount);

        bool zeroForOne = sqrtPriceCurrent >= sqrtPriceTarget;

        (uint160 sqrtPriceNext,,,) = SwapMath.computeSwapStep(
            sqrtPriceCurrent,
            sqrtPriceTarget,
            liquidity,
            amountRemaining,
            feePips
        );

        // Price should move in the correct direction
        if (zeroForOne) {
            assertLe(sqrtPriceNext, sqrtPriceCurrent, "zeroForOne: price should decrease or stay same");
            assertGe(sqrtPriceNext, sqrtPriceTarget, "zeroForOne: price should not go below target");
        } else {
            assertGe(sqrtPriceNext, sqrtPriceCurrent, "oneForZero: price should increase or stay same");
            assertLe(sqrtPriceNext, sqrtPriceTarget, "oneForZero: price should not exceed target");
        }
    }

    /**
     * @notice Fuzz test: verifies fee + amountIn <= |amountRemaining| for exact input
     */
    function testFuzz_computeSwapStep_exactIn_inputConservation(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        uint256 inputAmount,
        uint24 feePips
    ) public pure {
        // Bound inputs
        sqrtPriceCurrent = uint160(bound(sqrtPriceCurrent, MIN_SQRT_PRICE + 1, MAX_SQRT_PRICE - 1));
        sqrtPriceTarget = uint160(bound(sqrtPriceTarget, MIN_SQRT_PRICE, MAX_SQRT_PRICE - 1));
        liquidity = uint128(bound(liquidity, 1e6, type(uint128).max / 2));
        inputAmount = bound(inputAmount, 1, 1e30);
        feePips = uint24(bound(feePips, 0, MAX_SWAP_FEE));

        // Ensure different prices
        if (sqrtPriceCurrent == sqrtPriceTarget) {
            sqrtPriceTarget = sqrtPriceCurrent > MIN_SQRT_PRICE
                ? sqrtPriceCurrent - 1
                : sqrtPriceCurrent + 1;
        }

        int256 amountRemaining = -int256(inputAmount);

        (
            ,
            uint256 amountIn,
            ,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(
            sqrtPriceCurrent,
            sqrtPriceTarget,
            liquidity,
            amountRemaining,
            feePips
        );

        // Fee + input should never exceed the provided amount
        assertLe(amountIn + feeAmount, inputAmount, "Fee + input should not exceed provided amount");
    }
}
