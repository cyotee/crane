// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SwapMath} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/SwapMath.sol";
import {SqrtPriceMath} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.sol";

/**
 * @title SwapMath_V4_Fuzz_Test
 * @notice Fuzz tests for Uniswap V4 SwapMath library to discover edge cases via randomized inputs.
 * @dev Tests invariants of computeSwapStep and getSqrtPriceTarget.
 *
 * Key invariants tested:
 * 1. For exact input swaps: amountIn + feeAmount <= abs(amountRemaining)
 * 2. For exact output swaps: amountOut <= abs(amountRemaining)
 * 3. sqrtPriceNext is bounded between current price and target price
 * 4. Fee calculations are always non-negative
 * 5. getSqrtPriceTarget returns correct min/max based on direction
 */
contract SwapMath_V4_Fuzz_Test is Test {

    /* -------------------------------------------------------------------------- */
    /*                            Constants                                       */
    /* -------------------------------------------------------------------------- */

    /// @dev Maximum swap fee is 100% (1e6 hundredths of a bip)
    uint256 internal constant MAX_SWAP_FEE = 1e6;

    /// @dev Minimum sqrt price from TickMath
    uint160 internal constant MIN_SQRT_PRICE = 4295128739;

    /// @dev Maximum sqrt price from TickMath
    uint160 internal constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342;

    /* -------------------------------------------------------------------------- */
    /*                    getSqrtPriceTarget Fuzz Tests                           */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: getSqrtPriceTarget returns the correct target based on direction
     * @dev When zeroForOne, returns max(next, limit); when oneForZero, returns min(next, limit)
     * @param zeroForOne Direction of the swap
     * @param sqrtPriceNextX96 The sqrt price for the next initialized tick
     * @param sqrtPriceLimitX96 The sqrt price limit for the swap
     */
    function testFuzz_getSqrtPriceTarget_correctSelection(
        bool zeroForOne,
        uint160 sqrtPriceNextX96,
        uint160 sqrtPriceLimitX96
    ) public pure {
        uint160 result = SwapMath.getSqrtPriceTarget(zeroForOne, sqrtPriceNextX96, sqrtPriceLimitX96);

        // Compute expected result using reference logic
        uint160 expected;
        if (zeroForOne) {
            // zeroForOne: price decreases, so we want max(next, limit)
            expected = sqrtPriceNextX96 < sqrtPriceLimitX96 ? sqrtPriceLimitX96 : sqrtPriceNextX96;
        } else {
            // oneForZero: price increases, so we want min(next, limit)
            expected = sqrtPriceNextX96 > sqrtPriceLimitX96 ? sqrtPriceLimitX96 : sqrtPriceNextX96;
        }

        assertEq(result, expected, "getSqrtPriceTarget returned incorrect value");
    }

    /* -------------------------------------------------------------------------- */
    /*                computeSwapStep Comprehensive Fuzz Test                     */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Comprehensive fuzz test for computeSwapStep covering all invariants
     * @dev Tests all acceptance criteria in a single fuzz test for efficiency
     * @param sqrtPriceRaw Current sqrt price (raw input, will be bounded)
     * @param sqrtPriceTargetRaw Target sqrt price (raw input, will be bounded)
     * @param liquidity Pool liquidity
     * @param amountRemaining Remaining amount to swap (negative for exact in, positive for exact out)
     * @param feePips Fee in hundredths of a bip
     */
    function testFuzz_computeSwapStep_allInvariants(
        uint160 sqrtPriceRaw,
        uint160 sqrtPriceTargetRaw,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    ) public pure {
        // Bound inputs to valid ranges
        vm.assume(sqrtPriceRaw > 0);
        vm.assume(sqrtPriceTargetRaw > 0);

        // Fee constraints differ based on swap type
        // For exact output (amountRemaining >= 0), fee must be < 100%
        // For exact input (amountRemaining < 0), fee can be up to 100%
        if (amountRemaining >= 0) {
            vm.assume(feePips < MAX_SWAP_FEE);
        } else {
            vm.assume(feePips <= MAX_SWAP_FEE);
        }

        // Execute the swap step
        (uint160 sqrtPriceNext, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(sqrtPriceRaw, sqrtPriceTargetRaw, liquidity, amountRemaining, feePips);

        // INVARIANT 1: Fee is always non-negative (implicit in uint256, but verify no overflow)
        assertLe(amountIn, type(uint256).max - feeAmount, "amountIn + feeAmount would overflow");

        // INVARIANT 2 & 3: Amount conservation based on swap type
        unchecked {
            if (amountRemaining >= 0) {
                // Exact output: amountOut <= abs(amountRemaining)
                assertLe(amountOut, uint256(amountRemaining), "exactOut: amountOut exceeds amountRemaining");
            } else {
                // Exact input: amountIn + feeAmount <= abs(amountRemaining)
                assertLe(amountIn + feeAmount, uint256(-amountRemaining), "exactIn: amountIn + fee exceeds abs(amountRemaining)");
            }
        }

        // INVARIANT 4: When current equals target, no swap occurs
        if (sqrtPriceRaw == sqrtPriceTargetRaw) {
            assertEq(amountIn, 0, "No swap should occur when prices equal (amountIn)");
            assertEq(amountOut, 0, "No swap should occur when prices equal (amountOut)");
            assertEq(feeAmount, 0, "No swap should occur when prices equal (feeAmount)");
            assertEq(sqrtPriceNext, sqrtPriceTargetRaw, "Price should not change when current equals target");
        }

        // INVARIANT 5: If target not reached, entire amount must be consumed
        if (sqrtPriceNext != sqrtPriceTargetRaw) {
            uint256 absAmtRemaining;
            if (amountRemaining == type(int256).min) {
                absAmtRemaining = uint256(type(int256).max) + 1;
            } else if (amountRemaining < 0) {
                absAmtRemaining = uint256(-amountRemaining);
            } else {
                absAmtRemaining = uint256(amountRemaining);
            }

            if (amountRemaining > 0) {
                // Exact output: output should equal the full requested amount
                assertEq(amountOut, absAmtRemaining, "If target not reached, exact output should be fully consumed");
            } else {
                // Exact input: input + fee should equal the full input amount
                assertEq(amountIn + feeAmount, absAmtRemaining, "If target not reached, exact input should be fully consumed");
            }
        }

        // INVARIANT 6: sqrtPriceNext is bounded between current and target prices
        if (sqrtPriceTargetRaw <= sqrtPriceRaw) {
            // zeroForOne: price decreases
            assertLe(sqrtPriceNext, sqrtPriceRaw, "zeroForOne: next price should be <= current");
            assertGe(sqrtPriceNext, sqrtPriceTargetRaw, "zeroForOne: next price should be >= target");
        } else {
            // oneForZero: price increases
            assertGe(sqrtPriceNext, sqrtPriceRaw, "oneForZero: next price should be >= current");
            assertLe(sqrtPriceNext, sqrtPriceTargetRaw, "oneForZero: next price should be <= target");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                    Exact Input Specific Fuzz Tests                         */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: exactIn invariant - amountIn + feeAmount <= abs(amountRemaining)
     * @dev Specifically tests the exact input invariant with focused input ranges
     * @param sqrtPriceCurrent Current sqrt price
     * @param sqrtPriceTarget Target sqrt price
     * @param liquidity Pool liquidity
     * @param inputAmount Amount of input tokens (will be negated for amountRemaining)
     * @param feePips Fee in hundredths of a bip
     */
    function testFuzz_computeSwapStep_exactIn_inputConservation(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        uint256 inputAmount,
        uint24 feePips
    ) public pure {
        // Bound inputs to reasonable ranges
        sqrtPriceCurrent = uint160(bound(sqrtPriceCurrent, MIN_SQRT_PRICE, MAX_SQRT_PRICE));
        sqrtPriceTarget = uint160(bound(sqrtPriceTarget, MIN_SQRT_PRICE, MAX_SQRT_PRICE));
        liquidity = uint128(bound(liquidity, 1, type(uint128).max));
        inputAmount = bound(inputAmount, 1, type(uint128).max); // Reasonable input range
        feePips = uint24(bound(feePips, 0, MAX_SWAP_FEE));

        // Ensure different prices to avoid trivial case
        if (sqrtPriceCurrent == sqrtPriceTarget) {
            if (sqrtPriceTarget < MAX_SQRT_PRICE) {
                sqrtPriceTarget++;
            } else {
                sqrtPriceCurrent--;
            }
        }

        // Exact input uses negative amountRemaining
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

        // Core invariant: amountIn + feeAmount <= abs(amountRemaining)
        assertLe(
            amountIn + feeAmount,
            inputAmount,
            "exactIn: amountIn + feeAmount exceeds input amount"
        );

        // Fee should be non-negative (guaranteed by uint256 but verify no underflow scenarios)
        assertTrue(feeAmount >= 0, "feeAmount should be non-negative");
    }

    /* -------------------------------------------------------------------------- */
    /*                   Exact Output Specific Fuzz Tests                         */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: exactOut invariant - amountOut <= amountRemaining
     * @dev Specifically tests the exact output invariant with focused input ranges
     * @param sqrtPriceCurrent Current sqrt price
     * @param sqrtPriceTarget Target sqrt price
     * @param liquidity Pool liquidity
     * @param outputAmount Amount of output tokens requested
     * @param feePips Fee in hundredths of a bip (must be < 100% for exact out)
     */
    function testFuzz_computeSwapStep_exactOut_outputConservation(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        uint256 outputAmount,
        uint24 feePips
    ) public pure {
        // Bound inputs to reasonable ranges
        sqrtPriceCurrent = uint160(bound(sqrtPriceCurrent, MIN_SQRT_PRICE, MAX_SQRT_PRICE));
        sqrtPriceTarget = uint160(bound(sqrtPriceTarget, MIN_SQRT_PRICE, MAX_SQRT_PRICE));
        liquidity = uint128(bound(liquidity, 1, type(uint128).max));
        outputAmount = bound(outputAmount, 1, type(uint128).max);
        // Exact output requires fee < 100%
        feePips = uint24(bound(feePips, 0, MAX_SWAP_FEE - 1));

        // Ensure different prices to avoid trivial case
        if (sqrtPriceCurrent == sqrtPriceTarget) {
            if (sqrtPriceTarget < MAX_SQRT_PRICE) {
                sqrtPriceTarget++;
            } else {
                sqrtPriceCurrent--;
            }
        }

        // Exact output uses positive amountRemaining
        int256 amountRemaining = int256(outputAmount);

        (
            ,
            ,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(
            sqrtPriceCurrent,
            sqrtPriceTarget,
            liquidity,
            amountRemaining,
            feePips
        );

        // Core invariant: amountOut <= amountRemaining
        assertLe(
            amountOut,
            outputAmount,
            "exactOut: amountOut exceeds requested output"
        );

        // Fee should be non-negative
        assertTrue(feeAmount >= 0, "feeAmount should be non-negative");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Price Bounds Fuzz Tests                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: sqrtPriceNext is bounded by current and target prices
     * @dev Tests that the resulting price never exceeds the boundaries
     * @param sqrtPriceCurrent Current sqrt price
     * @param sqrtPriceTarget Target sqrt price
     * @param liquidity Pool liquidity
     * @param amountRemaining Amount remaining (negative = exact in, positive = exact out)
     * @param feePips Fee in hundredths of a bip
     */
    function testFuzz_computeSwapStep_priceBounds(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    ) public pure {
        // Bound inputs
        sqrtPriceCurrent = uint160(bound(sqrtPriceCurrent, MIN_SQRT_PRICE, MAX_SQRT_PRICE));
        sqrtPriceTarget = uint160(bound(sqrtPriceTarget, MIN_SQRT_PRICE, MAX_SQRT_PRICE));
        liquidity = uint128(bound(liquidity, 1, type(uint128).max));

        // Handle fee constraints based on swap direction
        if (amountRemaining >= 0) {
            feePips = uint24(bound(feePips, 0, MAX_SWAP_FEE - 1));
        } else {
            feePips = uint24(bound(feePips, 0, MAX_SWAP_FEE));
        }

        (uint160 sqrtPriceNext,,,) = SwapMath.computeSwapStep(
            sqrtPriceCurrent,
            sqrtPriceTarget,
            liquidity,
            amountRemaining,
            feePips
        );

        bool zeroForOne = sqrtPriceCurrent >= sqrtPriceTarget;

        if (zeroForOne) {
            // Price is decreasing: sqrtPriceTarget <= sqrtPriceNext <= sqrtPriceCurrent
            assertLe(sqrtPriceNext, sqrtPriceCurrent, "zeroForOne: next price exceeds current");
            assertGe(sqrtPriceNext, sqrtPriceTarget, "zeroForOne: next price below target");
        } else {
            // Price is increasing: sqrtPriceCurrent <= sqrtPriceNext <= sqrtPriceTarget
            assertGe(sqrtPriceNext, sqrtPriceCurrent, "oneForZero: next price below current");
            assertLe(sqrtPriceNext, sqrtPriceTarget, "oneForZero: next price exceeds target");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                       Fee Calculation Fuzz Tests                           */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: Fee calculations are always non-negative
     * @dev Verifies feeAmount is never negative (uint256 guarantees this, but we verify no underflow)
     * @param sqrtPriceCurrent Current sqrt price
     * @param sqrtPriceTarget Target sqrt price
     * @param liquidity Pool liquidity
     * @param amountRemaining Amount remaining
     * @param feePips Fee in hundredths of a bip
     */
    function testFuzz_computeSwapStep_feeNonNegative(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    ) public pure {
        // Bound inputs
        vm.assume(sqrtPriceCurrent > 0);
        vm.assume(sqrtPriceTarget > 0);

        // Handle fee constraints based on swap direction
        if (amountRemaining >= 0) {
            vm.assume(feePips < MAX_SWAP_FEE);
        } else {
            vm.assume(feePips <= MAX_SWAP_FEE);
        }

        (
            ,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        ) = SwapMath.computeSwapStep(
            sqrtPriceCurrent,
            sqrtPriceTarget,
            liquidity,
            amountRemaining,
            feePips
        );

        // Fee is non-negative (uint256 ensures this)
        assertTrue(feeAmount >= 0, "feeAmount should be non-negative");

        // If fee rate is 0, fee amount should be 0
        if (feePips == 0) {
            assertEq(feeAmount, 0, "feeAmount should be 0 when feePips is 0");
        }

        // Note: Even when amountIn=0 and amountOut=0, feeAmount may be non-zero due to rounding
        // in edge cases with very small liquidity and amounts. This is expected behavior.
    }

    /* -------------------------------------------------------------------------- */
    /*                   sqrtPriceLimit Bound Fuzz Tests                          */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: sqrtPriceNextX96 never crosses sqrtPriceLimitX96
     * @dev This test validates the swap loop composition by:
     *      1. Generating (sqrtPriceCurrentX96, sqrtPriceNextTickX96, sqrtPriceLimitX96)
     *      2. Deriving sqrtPriceTargetX96 via getSqrtPriceTarget
     *      3. Asserting sqrtPriceNextX96 never crosses sqrtPriceLimitX96
     *
     *      The existing tests bound sqrtPriceNextX96 vs the *target*, which is correct
     *      for computeSwapStep in isolation. This test validates the intended call
     *      composition used by pool swap loops where the limit is the user-specified
     *      price boundary.
     *
     * @param sqrtPriceCurrentX96 Current sqrt price (will be bounded)
     * @param sqrtPriceNextTickX96 Sqrt price at the next initialized tick (will be bounded)
     * @param sqrtPriceLimitX96 User-specified sqrt price limit (will be bounded)
     * @param liquidity Pool liquidity
     * @param amountRemaining Amount remaining (negative = exact in, positive = exact out)
     * @param feePips Fee in hundredths of a bip
     */
    function testFuzz_computeSwapStep_sqrtPriceLimitNeverCrossed(
        uint160 sqrtPriceCurrentX96,
        uint160 sqrtPriceNextTickX96,
        uint160 sqrtPriceLimitX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    ) public pure {
        // Bound all prices to valid Uniswap V4 range
        sqrtPriceCurrentX96 = uint160(bound(sqrtPriceCurrentX96, MIN_SQRT_PRICE, MAX_SQRT_PRICE));
        sqrtPriceNextTickX96 = uint160(bound(sqrtPriceNextTickX96, MIN_SQRT_PRICE, MAX_SQRT_PRICE));
        sqrtPriceLimitX96 = uint160(bound(sqrtPriceLimitX96, MIN_SQRT_PRICE, MAX_SQRT_PRICE));
        liquidity = uint128(bound(liquidity, 1, type(uint128).max));

        // Determine swap direction from relationship between current and limit
        // zeroForOne: selling token0 for token1, price decreases, limit must be below current
        // oneForZero: selling token1 for token0, price increases, limit must be above current
        bool zeroForOne = sqrtPriceLimitX96 < sqrtPriceCurrentX96;

        // Ensure limit is on the correct side of current price for the swap direction
        // (This is a requirement for valid swap parameters)
        if (zeroForOne) {
            // For zeroForOne, limit must be strictly below current
            vm.assume(sqrtPriceLimitX96 < sqrtPriceCurrentX96);
        } else {
            // For oneForZero, limit must be strictly above current
            vm.assume(sqrtPriceLimitX96 > sqrtPriceCurrentX96);
        }

        // Handle fee constraints based on swap type
        if (amountRemaining >= 0) {
            // Exact output requires fee < 100%
            feePips = uint24(bound(feePips, 0, MAX_SWAP_FEE - 1));
        } else {
            feePips = uint24(bound(feePips, 0, MAX_SWAP_FEE));
        }

        // Derive sqrtPriceTargetX96 via getSqrtPriceTarget (as pool swap loops do)
        uint160 sqrtPriceTargetX96 = SwapMath.getSqrtPriceTarget(
            zeroForOne,
            sqrtPriceNextTickX96,
            sqrtPriceLimitX96
        );

        // Execute the swap step
        (uint160 sqrtPriceNextX96,,,) = SwapMath.computeSwapStep(
            sqrtPriceCurrentX96,
            sqrtPriceTargetX96,
            liquidity,
            amountRemaining,
            feePips
        );

        // CORE INVARIANT: sqrtPriceNextX96 must never cross sqrtPriceLimitX96
        if (zeroForOne) {
            // For zeroForOne swaps, price decreases but must not go below limit
            assertGe(
                sqrtPriceNextX96,
                sqrtPriceLimitX96,
                "zeroForOne: sqrtPriceNextX96 crossed below sqrtPriceLimitX96"
            );
        } else {
            // For oneForZero swaps, price increases but must not go above limit
            assertLe(
                sqrtPriceNextX96,
                sqrtPriceLimitX96,
                "oneForZero: sqrtPriceNextX96 crossed above sqrtPriceLimitX96"
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                     Direction Consistency Fuzz Tests                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: Price movement direction is consistent with swap direction
     * @dev zeroForOne means price decreases; oneForZero means price increases
     * @param sqrtPriceCurrent Current sqrt price
     * @param sqrtPriceTarget Target sqrt price
     * @param liquidity Pool liquidity
     * @param amount Amount for the swap
     * @param feePips Fee in hundredths of a bip
     */
    function testFuzz_computeSwapStep_directionConsistency(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        uint256 amount,
        uint24 feePips
    ) public pure {
        // Use conservative bounds to avoid overflow
        uint160 midPrice = 79228162514264337593543950336; // 2^96
        sqrtPriceCurrent = uint160(bound(sqrtPriceCurrent, midPrice / 1000, midPrice * 1000));
        sqrtPriceTarget = uint160(bound(sqrtPriceTarget, midPrice / 1000, midPrice * 1000));
        liquidity = uint128(bound(liquidity, 1e12, 1e24));
        amount = bound(amount, 1e12, 1e24);
        feePips = uint24(bound(feePips, 0, 500000)); // Max 50% fee

        // Ensure different prices
        if (sqrtPriceCurrent == sqrtPriceTarget) {
            sqrtPriceTarget = sqrtPriceCurrent > MIN_SQRT_PRICE
                ? sqrtPriceCurrent - 1
                : sqrtPriceCurrent + 1;
        }

        // Use exact input (negative amountRemaining)
        int256 amountRemaining = -int256(amount);

        bool zeroForOne = sqrtPriceCurrent >= sqrtPriceTarget;

        (uint160 sqrtPriceNext,,,) = SwapMath.computeSwapStep(
            sqrtPriceCurrent,
            sqrtPriceTarget,
            liquidity,
            amountRemaining,
            feePips
        );

        // Verify direction consistency
        if (zeroForOne) {
            assertLe(sqrtPriceNext, sqrtPriceCurrent, "zeroForOne: price should not increase");
        } else {
            assertGe(sqrtPriceNext, sqrtPriceCurrent, "oneForZero: price should not decrease");
        }
    }
}
