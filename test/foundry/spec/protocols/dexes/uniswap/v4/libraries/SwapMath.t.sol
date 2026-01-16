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
