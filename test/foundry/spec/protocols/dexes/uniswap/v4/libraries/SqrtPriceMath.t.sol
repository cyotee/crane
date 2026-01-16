// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SqrtPriceMath} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/TickMath.sol";
import {FixedPoint96} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/FixedPoint96.sol";

/**
 * @title SqrtPriceMath_V4_Test
 * @notice Unit tests for Uniswap V4 SqrtPriceMath library pure math functions.
 * @dev Tests amount calculations with known inputs/outputs.
 *
 * Key properties tested:
 * 1. getNextSqrtPriceFromInput correctness
 * 2. getNextSqrtPriceFromOutput correctness
 * 3. getAmount0Delta and getAmount1Delta calculations
 * 4. Rounding behavior (up vs down)
 * 5. Edge cases and revert conditions
 */
contract SqrtPriceMath_V4_Test is Test {

    /* -------------------------------------------------------------------------- */
    /*                            Constants                                       */
    /* -------------------------------------------------------------------------- */

    uint160 internal constant MIN_SQRT_PRICE = 4295128739;
    uint160 internal constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342;
    uint160 internal constant SQRT_PRICE_1_1 = 79228162514264337593543950336; // 2^96, 1:1 price
    uint128 internal constant LIQUIDITY_1E18 = 1e18;
    uint256 internal constant Q96 = FixedPoint96.Q96;

    /* -------------------------------------------------------------------------- */
    /*                    getNextSqrtPriceFromInput Tests                         */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests getNextSqrtPriceFromInput with zero amount
     * @dev Zero amount should return the same price
     */
    function test_getNextSqrtPriceFromInput_zeroAmount() public pure {
        uint160 result = SqrtPriceMath.getNextSqrtPriceFromInput(
            SQRT_PRICE_1_1,
            LIQUIDITY_1E18,
            0, // zero amount
            true // zeroForOne
        );

        assertEq(result, SQRT_PRICE_1_1, "Zero input should return same price");
    }

    /**
     * @notice Tests getNextSqrtPriceFromInput for zeroForOne direction
     * @dev Adding token0 should decrease the sqrt price
     */
    function test_getNextSqrtPriceFromInput_zeroForOne() public pure {
        uint160 sqrtPriceX96 = SQRT_PRICE_1_1;
        uint128 liquidity = LIQUIDITY_1E18;
        uint256 amountIn = 1e17; // 0.1 tokens

        uint160 newSqrtPrice = SqrtPriceMath.getNextSqrtPriceFromInput(
            sqrtPriceX96,
            liquidity,
            amountIn,
            true // zeroForOne
        );

        // Price should decrease when adding token0
        assertLt(newSqrtPrice, sqrtPriceX96, "Adding token0 should decrease sqrt price");
        assertGt(newSqrtPrice, 0, "New sqrt price should be positive");
    }

    /**
     * @notice Tests getNextSqrtPriceFromInput for oneForZero direction
     * @dev Adding token1 should increase the sqrt price
     */
    function test_getNextSqrtPriceFromInput_oneForZero() public pure {
        uint160 sqrtPriceX96 = SQRT_PRICE_1_1;
        uint128 liquidity = LIQUIDITY_1E18;
        uint256 amountIn = 1e17; // 0.1 tokens

        uint160 newSqrtPrice = SqrtPriceMath.getNextSqrtPriceFromInput(
            sqrtPriceX96,
            liquidity,
            amountIn,
            false // oneForZero
        );

        // Price should increase when adding token1
        assertGt(newSqrtPrice, sqrtPriceX96, "Adding token1 should increase sqrt price");
    }

    /**
     * @notice Tests that getNextSqrtPriceFromInput reverts with zero price
     */
    function test_getNextSqrtPriceFromInput_revert_zeroPrice() public {
        vm.expectRevert(SqrtPriceMath.InvalidPriceOrLiquidity.selector);
        this.external_getNextSqrtPriceFromInput(0, LIQUIDITY_1E18, 1e18, true);
    }

    /**
     * @notice Tests that getNextSqrtPriceFromInput reverts with zero liquidity
     */
    function test_getNextSqrtPriceFromInput_revert_zeroLiquidity() public {
        vm.expectRevert(SqrtPriceMath.InvalidPriceOrLiquidity.selector);
        this.external_getNextSqrtPriceFromInput(SQRT_PRICE_1_1, 0, 1e18, true);
    }

    /* -------------------------------------------------------------------------- */
    /*                   getNextSqrtPriceFromOutput Tests                         */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests getNextSqrtPriceFromOutput for zeroForOne direction
     * @dev Taking token1 output should decrease the sqrt price
     */
    function test_getNextSqrtPriceFromOutput_zeroForOne() public pure {
        uint160 sqrtPriceX96 = SQRT_PRICE_1_1;
        uint128 liquidity = LIQUIDITY_1E18;
        uint256 amountOut = 1e16; // 0.01 tokens

        uint160 newSqrtPrice = SqrtPriceMath.getNextSqrtPriceFromOutput(
            sqrtPriceX96,
            liquidity,
            amountOut,
            true // zeroForOne
        );

        // Price should decrease when taking token1 output
        assertLt(newSqrtPrice, sqrtPriceX96, "Taking token1 output should decrease sqrt price");
        assertGt(newSqrtPrice, 0, "New sqrt price should be positive");
    }

    /**
     * @notice Tests getNextSqrtPriceFromOutput for oneForZero direction
     * @dev Taking token0 output should increase the sqrt price
     */
    function test_getNextSqrtPriceFromOutput_oneForZero() public pure {
        uint160 sqrtPriceX96 = SQRT_PRICE_1_1;
        uint128 liquidity = LIQUIDITY_1E18;
        uint256 amountOut = 1e16; // 0.01 tokens

        uint160 newSqrtPrice = SqrtPriceMath.getNextSqrtPriceFromOutput(
            sqrtPriceX96,
            liquidity,
            amountOut,
            false // oneForZero
        );

        // Price should increase when taking token0 output
        assertGt(newSqrtPrice, sqrtPriceX96, "Taking token0 output should increase sqrt price");
    }

    /**
     * @notice Tests that getNextSqrtPriceFromOutput reverts with zero price
     */
    function test_getNextSqrtPriceFromOutput_revert_zeroPrice() public {
        vm.expectRevert(SqrtPriceMath.InvalidPriceOrLiquidity.selector);
        this.external_getNextSqrtPriceFromOutput(0, LIQUIDITY_1E18, 1e18, true);
    }

    /**
     * @notice Tests that getNextSqrtPriceFromOutput reverts with zero liquidity
     */
    function test_getNextSqrtPriceFromOutput_revert_zeroLiquidity() public {
        vm.expectRevert(SqrtPriceMath.InvalidPriceOrLiquidity.selector);
        this.external_getNextSqrtPriceFromOutput(SQRT_PRICE_1_1, 0, 1e18, true);
    }

    /* -------------------------------------------------------------------------- */
    /*                       getAmount0Delta Tests                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests getAmount0Delta with known price range
     */
    function test_getAmount0Delta_basicCalculation() public pure {
        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(-100);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(100);
        uint128 liquidity = LIQUIDITY_1E18;

        uint256 amount0RoundUp = SqrtPriceMath.getAmount0Delta(sqrtPriceA, sqrtPriceB, liquidity, true);
        uint256 amount0RoundDown = SqrtPriceMath.getAmount0Delta(sqrtPriceA, sqrtPriceB, liquidity, false);

        // Round up should be >= round down
        assertGe(amount0RoundUp, amount0RoundDown, "Round up should be >= round down");

        // Both should be positive
        assertGt(amount0RoundUp, 0, "Amount should be positive");
    }

    /**
     * @notice Tests getAmount0Delta with swapped price order
     * @dev Function should handle either order of prices
     */
    function test_getAmount0Delta_priceOrderIndependent() public pure {
        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(-100);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(100);
        uint128 liquidity = LIQUIDITY_1E18;

        uint256 amount1 = SqrtPriceMath.getAmount0Delta(sqrtPriceA, sqrtPriceB, liquidity, true);
        uint256 amount2 = SqrtPriceMath.getAmount0Delta(sqrtPriceB, sqrtPriceA, liquidity, true);

        // Order shouldn't matter
        assertEq(amount1, amount2, "Amount should be same regardless of price order");
    }

    /**
     * @notice Tests getAmount0Delta with same prices
     * @dev Same prices should give zero amount
     */
    function test_getAmount0Delta_samePrices() public pure {
        uint160 sqrtPrice = SQRT_PRICE_1_1;
        uint128 liquidity = LIQUIDITY_1E18;

        uint256 amount = SqrtPriceMath.getAmount0Delta(sqrtPrice, sqrtPrice, liquidity, true);

        assertEq(amount, 0, "Same prices should give zero amount");
    }

    /**
     * @notice Tests getAmount0Delta with zero liquidity
     */
    function test_getAmount0Delta_zeroLiquidity() public pure {
        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(-100);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(100);

        uint256 amount = SqrtPriceMath.getAmount0Delta(sqrtPriceA, sqrtPriceB, 0, true);

        assertEq(amount, 0, "Zero liquidity should give zero amount");
    }

    /**
     * @notice Tests that getAmount0Delta reverts with zero price
     */
    function test_getAmount0Delta_revert_zeroPrice() public {
        vm.expectRevert(SqrtPriceMath.InvalidPrice.selector);
        this.external_getAmount0Delta(0, SQRT_PRICE_1_1, LIQUIDITY_1E18, true);
    }

    /* -------------------------------------------------------------------------- */
    /*                       getAmount1Delta Tests                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests getAmount1Delta with known price range
     */
    function test_getAmount1Delta_basicCalculation() public pure {
        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(-100);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(100);
        uint128 liquidity = LIQUIDITY_1E18;

        uint256 amount1RoundUp = SqrtPriceMath.getAmount1Delta(sqrtPriceA, sqrtPriceB, liquidity, true);
        uint256 amount1RoundDown = SqrtPriceMath.getAmount1Delta(sqrtPriceA, sqrtPriceB, liquidity, false);

        // Round up should be >= round down
        assertGe(amount1RoundUp, amount1RoundDown, "Round up should be >= round down");

        // Both should be positive
        assertGt(amount1RoundUp, 0, "Amount should be positive");
    }

    /**
     * @notice Tests getAmount1Delta with swapped price order
     * @dev Function uses absDiff so order shouldn't matter
     */
    function test_getAmount1Delta_priceOrderIndependent() public pure {
        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(-100);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(100);
        uint128 liquidity = LIQUIDITY_1E18;

        uint256 amount1 = SqrtPriceMath.getAmount1Delta(sqrtPriceA, sqrtPriceB, liquidity, true);
        uint256 amount2 = SqrtPriceMath.getAmount1Delta(sqrtPriceB, sqrtPriceA, liquidity, true);

        // Order shouldn't matter
        assertEq(amount1, amount2, "Amount should be same regardless of price order");
    }

    /**
     * @notice Tests getAmount1Delta with same prices
     */
    function test_getAmount1Delta_samePrices() public pure {
        uint160 sqrtPrice = SQRT_PRICE_1_1;
        uint128 liquidity = LIQUIDITY_1E18;

        uint256 amount = SqrtPriceMath.getAmount1Delta(sqrtPrice, sqrtPrice, liquidity, true);

        assertEq(amount, 0, "Same prices should give zero amount");
    }

    /**
     * @notice Tests getAmount1Delta with zero liquidity
     */
    function test_getAmount1Delta_zeroLiquidity() public pure {
        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(-100);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(100);

        uint256 amount = SqrtPriceMath.getAmount1Delta(sqrtPriceA, sqrtPriceB, 0, true);

        assertEq(amount, 0, "Zero liquidity should give zero amount");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Signed Amount Delta Tests                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests signed getAmount0Delta with positive liquidity
     * @dev Positive liquidity means removing liquidity, returns negative amount
     */
    function test_getAmount0Delta_signed_positiveLiquidity() public pure {
        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(-100);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(100);
        int128 liquidity = int128(int256(uint256(LIQUIDITY_1E18)));

        int256 amount = SqrtPriceMath.getAmount0Delta(sqrtPriceA, sqrtPriceB, liquidity);

        // Positive liquidity (removing) gives negative amount (owed to pool)
        assertLt(amount, 0, "Positive liquidity should give negative amount");
    }

    /**
     * @notice Tests signed getAmount0Delta with negative liquidity
     * @dev Negative liquidity means adding liquidity, returns positive amount
     */
    function test_getAmount0Delta_signed_negativeLiquidity() public pure {
        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(-100);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(100);
        int128 liquidity = -int128(int256(uint256(LIQUIDITY_1E18)));

        int256 amount = SqrtPriceMath.getAmount0Delta(sqrtPriceA, sqrtPriceB, liquidity);

        // Negative liquidity (adding) gives positive amount (owed to user)
        assertGt(amount, 0, "Negative liquidity should give positive amount");
    }

    /**
     * @notice Tests signed getAmount1Delta with positive liquidity
     */
    function test_getAmount1Delta_signed_positiveLiquidity() public pure {
        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(-100);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(100);
        int128 liquidity = int128(int256(uint256(LIQUIDITY_1E18)));

        int256 amount = SqrtPriceMath.getAmount1Delta(sqrtPriceA, sqrtPriceB, liquidity);

        // Positive liquidity (removing) gives negative amount
        assertLt(amount, 0, "Positive liquidity should give negative amount");
    }

    /**
     * @notice Tests signed getAmount1Delta with negative liquidity
     */
    function test_getAmount1Delta_signed_negativeLiquidity() public pure {
        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(-100);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(100);
        int128 liquidity = -int128(int256(uint256(LIQUIDITY_1E18)));

        int256 amount = SqrtPriceMath.getAmount1Delta(sqrtPriceA, sqrtPriceB, liquidity);

        // Negative liquidity (adding) gives positive amount
        assertGt(amount, 0, "Negative liquidity should give positive amount");
    }

    /* -------------------------------------------------------------------------- */
    /*                           absDiff Tests                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests absDiff function for correct absolute difference
     */
    function test_absDiff_aGreaterThanB() public pure {
        uint160 a = 100;
        uint160 b = 50;

        uint256 result = SqrtPriceMath.absDiff(a, b);

        assertEq(result, 50, "absDiff(100, 50) should be 50");
    }

    /**
     * @notice Tests absDiff when b > a
     */
    function test_absDiff_bGreaterThanA() public pure {
        uint160 a = 50;
        uint160 b = 100;

        uint256 result = SqrtPriceMath.absDiff(a, b);

        assertEq(result, 50, "absDiff(50, 100) should be 50");
    }

    /**
     * @notice Tests absDiff when a == b
     */
    function test_absDiff_equal() public pure {
        uint160 a = 100;

        uint256 result = SqrtPriceMath.absDiff(a, a);

        assertEq(result, 0, "absDiff of equal values should be 0");
    }

    /**
     * @notice Fuzz test for absDiff symmetry
     */
    function testFuzz_absDiff_symmetric(uint160 a, uint160 b) public pure {
        uint256 diff1 = SqrtPriceMath.absDiff(a, b);
        uint256 diff2 = SqrtPriceMath.absDiff(b, a);

        assertEq(diff1, diff2, "absDiff should be symmetric");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Invariant Tests                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: verifies rounding consistency
     * @dev Round up should always be >= round down
     */
    function testFuzz_roundingConsistency_amount0(
        uint160 sqrtPriceA,
        uint160 sqrtPriceB,
        uint128 liquidity
    ) public pure {
        // Bound inputs
        sqrtPriceA = uint160(bound(sqrtPriceA, MIN_SQRT_PRICE, MAX_SQRT_PRICE - 1));
        sqrtPriceB = uint160(bound(sqrtPriceB, MIN_SQRT_PRICE, MAX_SQRT_PRICE - 1));
        liquidity = uint128(bound(liquidity, 0, type(uint128).max / 2));

        // Ensure sqrtPriceA <= sqrtPriceB to avoid zero price in calculation
        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }

        // Skip if lower price is zero
        if (sqrtPriceA == 0) return;

        uint256 amountUp = SqrtPriceMath.getAmount0Delta(sqrtPriceA, sqrtPriceB, liquidity, true);
        uint256 amountDown = SqrtPriceMath.getAmount0Delta(sqrtPriceA, sqrtPriceB, liquidity, false);

        assertGe(amountUp, amountDown, "Round up should be >= round down");
    }

    /**
     * @notice Fuzz test: verifies rounding consistency for amount1
     */
    function testFuzz_roundingConsistency_amount1(
        uint160 sqrtPriceA,
        uint160 sqrtPriceB,
        uint128 liquidity
    ) public pure {
        // Bound inputs
        sqrtPriceA = uint160(bound(sqrtPriceA, MIN_SQRT_PRICE, MAX_SQRT_PRICE - 1));
        sqrtPriceB = uint160(bound(sqrtPriceB, MIN_SQRT_PRICE, MAX_SQRT_PRICE - 1));
        liquidity = uint128(bound(liquidity, 0, type(uint128).max / 2));

        uint256 amountUp = SqrtPriceMath.getAmount1Delta(sqrtPriceA, sqrtPriceB, liquidity, true);
        uint256 amountDown = SqrtPriceMath.getAmount1Delta(sqrtPriceA, sqrtPriceB, liquidity, false);

        assertGe(amountUp, amountDown, "Round up should be >= round down");
    }

    /**
     * @notice Fuzz test: input/output roundtrip consistency
     * @dev Adding then removing amount should get back close to original price
     */
    function testFuzz_inputOutputRoundtrip(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amountIn
    ) public pure {
        // Use bounded price around 2^96 (1:1 ratio) for more predictable behavior
        uint160 midPrice = SQRT_PRICE_1_1;
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, midPrice / 10, midPrice * 10));

        // Keep liquidity moderate to avoid precision issues
        liquidity = uint128(bound(liquidity, 1e15, 1e21));

        // amountIn should be significant relative to liquidity to cause price movement
        amountIn = bound(amountIn, 1e15, 1e21);

        // Calculate new price after input
        uint160 sqrtPriceAfterInput = SqrtPriceMath.getNextSqrtPriceFromInput(
            sqrtPriceX96,
            liquidity,
            amountIn,
            true // zeroForOne
        );

        // Price should have decreased (or stayed same if amount is too small)
        assertLe(sqrtPriceAfterInput, sqrtPriceX96, "Price should decrease or stay same after input");

        // Only test roundtrip if price actually changed
        if (sqrtPriceAfterInput < sqrtPriceX96) {
            // Calculate amount to get back
            uint256 amountToReverse = SqrtPriceMath.getAmount0Delta(
                sqrtPriceAfterInput,
                sqrtPriceX96,
                liquidity,
                false // round down for output
            );

            // Due to rounding, amountToReverse should be <= amountIn
            assertLe(amountToReverse, amountIn, "Reverse amount should be <= input");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                       External Wrappers for Revert Tests                   */
    /* -------------------------------------------------------------------------- */

    function external_getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) external pure returns (uint160) {
        return SqrtPriceMath.getNextSqrtPriceFromInput(sqrtPX96, liquidity, amountIn, zeroForOne);
    }

    function external_getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) external pure returns (uint160) {
        return SqrtPriceMath.getNextSqrtPriceFromOutput(sqrtPX96, liquidity, amountOut, zeroForOne);
    }

    function external_getAmount0Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint128 liquidity,
        bool roundUp
    ) external pure returns (uint256) {
        return SqrtPriceMath.getAmount0Delta(sqrtPriceAX96, sqrtPriceBX96, liquidity, roundUp);
    }
}
