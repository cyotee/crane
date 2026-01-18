// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/**
 * @title TickMath_Bijection_Test
 * @notice Fuzz tests verifying the bijection property of TickMath functions.
 * @dev Tests that tick <-> sqrtPrice conversions are correct and consistent.
 *
 * Key properties tested:
 * 1. getTickAtSqrtRatio(getSqrtRatioAtTick(tick)) == tick for all valid ticks
 * 2. getSqrtRatioAtTick(getTickAtSqrtRatio(sqrtPrice)) approximates sqrtPrice
 * 3. Edge cases at MIN_TICK, MAX_TICK, MIN_SQRT_RATIO, MAX_SQRT_RATIO boundaries
 */
contract TickMath_Bijection_Test is Test {

    /* -------------------------------------------------------------------------- */
    /*                            Constants from TickMath                         */
    /* -------------------------------------------------------------------------- */

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = 887272;
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /* -------------------------------------------------------------------------- */
    /*                  Bijection: tick -> sqrtPrice -> tick                      */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that getTickAtSqrtRatio(getSqrtRatioAtTick(tick)) == tick
     * @dev This is the primary bijection property: tick -> sqrtPrice -> tick is identity.
     *      Note: MAX_TICK is excluded because getSqrtRatioAtTick(MAX_TICK) returns MAX_SQRT_RATIO,
     *      and getTickAtSqrtRatio requires input < MAX_SQRT_RATIO (exclusive upper bound).
     * @param tick The fuzzed tick value to test
     */
    function testFuzz_bijection_tickToSqrtToTick(int24 tick) public pure {
        // Bound tick to valid range (exclude MAX_TICK since MAX_SQRT_RATIO is not valid reverse input)
        tick = int24(bound(int256(tick), MIN_TICK, MAX_TICK - 1));

        // Forward: tick -> sqrtPrice
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        // Reverse: sqrtPrice -> tick
        int24 recoveredTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        // The bijection property: recovered tick must equal original tick
        assertEq(recoveredTick, tick, "Bijection violated: tick -> sqrtPrice -> tick != tick");
    }

    /**
     * @notice Tests bijection across the entire tick range using strategic sampling
     * @dev Tests MIN_TICK, MAX_TICK-1, zero, and fuzzed positive/negative values.
     *      Note: MAX_TICK is excluded because getSqrtRatioAtTick(MAX_TICK) returns MAX_SQRT_RATIO,
     *      and getTickAtSqrtRatio requires input < MAX_SQRT_RATIO.
     */
    function testFuzz_bijection_fullRange(uint256 seed) public pure {
        // Test strategic points: MIN_TICK, MAX_TICK-1, 0, random positive, random negative
        _testBijectionAtTick(MIN_TICK);
        _testBijectionAtTick(MAX_TICK - 1); // MAX_TICK excluded (MAX_SQRT_RATIO not valid for reverse)
        _testBijectionAtTick(0);

        // Random positive tick (excluding MAX_TICK)
        int24 positiveTick = int24(int256(bound(seed, 1, uint256(int256(MAX_TICK - 1)))));
        _testBijectionAtTick(positiveTick);

        // Random negative tick
        int24 negativeTick = -int24(int256(bound(seed >> 128, 1, uint256(int256(-MIN_TICK)))));
        _testBijectionAtTick(negativeTick);
    }

    /**
     * @dev Helper to test bijection at a specific tick
     */
    function _testBijectionAtTick(int24 tick) internal pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        int24 recoveredTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        require(recoveredTick == tick, "Bijection failed at tick");
    }

    /* -------------------------------------------------------------------------- */
    /*                  Approximation: sqrtPrice -> tick -> sqrtPrice             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that getSqrtRatioAtTick(getTickAtSqrtRatio(sqrtPrice)) approximates sqrtPrice
     * @dev Due to discrete ticks, we cannot expect exact equality. The recovered sqrtPrice
     *      should be <= the original (since getTickAtSqrtRatio returns floor tick).
     * @param sqrtPriceX96 The fuzzed sqrt price to test
     */
    function testFuzz_approximation_sqrtToTickToSqrt(uint160 sqrtPriceX96) public pure {
        // Bound to valid sqrtPrice range (exclusive of MAX_SQRT_RATIO per TickMath)
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, MIN_SQRT_RATIO, MAX_SQRT_RATIO - 1));

        // Forward: sqrtPrice -> tick
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        // Reverse: tick -> sqrtPrice
        uint160 recoveredSqrtPrice = TickMath.getSqrtRatioAtTick(tick);

        // The recovered sqrtPrice should be <= original (floor behavior)
        assertLe(
            recoveredSqrtPrice,
            sqrtPriceX96,
            "Recovered sqrtPrice exceeds original (floor violation)"
        );

        // The recovered sqrtPrice should be close: the next tick's sqrtPrice should exceed original
        if (tick < MAX_TICK) {
            uint160 nextTickSqrtPrice = TickMath.getSqrtRatioAtTick(tick + 1);
            assertGt(
                nextTickSqrtPrice,
                sqrtPriceX96,
                "Next tick sqrtPrice should exceed original"
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            Edge Case: MIN_TICK                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests bijection at MIN_TICK boundary
     */
    function test_bijection_minTick() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(MIN_TICK);
        int24 recoveredTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        assertEq(sqrtPriceX96, MIN_SQRT_RATIO, "MIN_TICK should produce MIN_SQRT_RATIO");
        assertEq(recoveredTick, MIN_TICK, "MIN_SQRT_RATIO should recover MIN_TICK");
    }

    /**
     * @notice Tests MAX_TICK boundary behavior
     * @dev Note: getTickAtSqrtRatio(MAX_SQRT_RATIO) reverts because it requires sqrtPrice < MAX_SQRT_RATIO.
     *      This is by design - MAX_SQRT_RATIO is the exclusive upper bound.
     */
    function test_bijection_maxTick() public pure {
        // MAX_TICK -> MAX_SQRT_RATIO works
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(MAX_TICK);
        assertEq(sqrtPriceX96, MAX_SQRT_RATIO, "MAX_TICK should produce MAX_SQRT_RATIO");

        // However, getTickAtSqrtRatio(MAX_SQRT_RATIO) reverts, so we test MAX_TICK - 1 roundtrip instead
        uint160 sqrtPriceAtMaxMinus1 = TickMath.getSqrtRatioAtTick(MAX_TICK - 1);
        int24 recoveredTick = TickMath.getTickAtSqrtRatio(sqrtPriceAtMaxMinus1);
        assertEq(recoveredTick, MAX_TICK - 1, "MAX_TICK - 1 roundtrip should work");
    }

    /**
     * @notice Tests behavior at MAX_SQRT_RATIO - 1 (highest valid input to getTickAtSqrtRatio)
     */
    function test_approximation_maxSqrtRatioMinusOne() public pure {
        uint160 sqrtPriceX96 = MAX_SQRT_RATIO - 1;
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        // The tick should be MAX_TICK - 1 (floor of the highest valid sqrtPrice)
        assertEq(tick, MAX_TICK - 1, "MAX_SQRT_RATIO - 1 should yield MAX_TICK - 1");

        // Verify the approximation holds
        uint160 recoveredSqrtPrice = TickMath.getSqrtRatioAtTick(tick);
        assertLe(recoveredSqrtPrice, sqrtPriceX96, "Recovered should be <= original");
    }

    /**
     * @notice Tests bijection at tick zero (1:1 price ratio)
     */
    function test_bijection_tickZero() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(0);
        int24 recoveredTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        // tick 0 should give sqrtPriceX96 = 2^96 (1:1 ratio)
        uint160 expectedSqrtPrice = 2 ** 96;
        assertEq(sqrtPriceX96, expectedSqrtPrice, "Tick 0 should give sqrtPrice = 2^96");
        assertEq(recoveredTick, 0, "sqrtPrice 2^96 should recover tick 0");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Edge Case: MIN_SQRT_RATIO                         */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that MIN_SQRT_RATIO produces MIN_TICK
     */
    function test_approximation_minSqrtRatio() public pure {
        int24 tick = TickMath.getTickAtSqrtRatio(MIN_SQRT_RATIO);
        assertEq(tick, MIN_TICK, "MIN_SQRT_RATIO should yield MIN_TICK");
    }

    /* -------------------------------------------------------------------------- */
    /*                       Revert Cases: Invalid Inputs                         */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that ticks outside valid range revert with 'T'
     * @dev TickMath.getSqrtRatioAtTick reverts with bytes("T") when tick is out of range
     */
    function test_revert_tickOutOfRange_tooLow() public {
        vm.expectRevert(bytes("T"));
        this.external_getSqrtRatioAtTick(MIN_TICK - 1);
    }

    /**
     * @notice Tests that ticks outside valid range revert with 'T'
     * @dev TickMath.getSqrtRatioAtTick reverts with bytes("T") when tick is out of range
     */
    function test_revert_tickOutOfRange_tooHigh() public {
        vm.expectRevert(bytes("T"));
        this.external_getSqrtRatioAtTick(MAX_TICK + 1);
    }

    /**
     * @notice Tests that sqrtPrice below MIN_SQRT_RATIO reverts with 'R'
     * @dev TickMath.getTickAtSqrtRatio reverts with bytes("R") when sqrtPrice is out of range
     */
    function test_revert_sqrtPriceTooLow() public {
        vm.expectRevert(bytes("R"));
        this.external_getTickAtSqrtRatio(MIN_SQRT_RATIO - 1);
    }

    /**
     * @notice Tests that sqrtPrice at or above MAX_SQRT_RATIO reverts with 'R'
     * @dev TickMath.getTickAtSqrtRatio reverts with bytes("R") when sqrtPrice >= MAX_SQRT_RATIO
     */
    function test_revert_sqrtPriceTooHigh() public {
        vm.expectRevert(bytes("R"));
        this.external_getTickAtSqrtRatio(MAX_SQRT_RATIO);
    }

    /* -------------------------------------------------------------------------- */
    /*                       External Wrappers for Revert Tests                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev External wrapper for getSqrtRatioAtTick to allow vm.expectRevert
     */
    function external_getSqrtRatioAtTick(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    /**
     * @dev External wrapper for getTickAtSqrtRatio to allow vm.expectRevert
     */
    function external_getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24) {
        return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }

    /* -------------------------------------------------------------------------- */
    /*                     Monotonicity: Higher tick = Higher sqrtPrice           */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that getSqrtRatioAtTick is strictly monotonically increasing
     * @dev Higher ticks should always produce higher sqrt prices
     */
    function testFuzz_monotonicity_tickToSqrtPrice(int24 tickA, int24 tickB) public pure {
        // Bound to valid range
        tickA = int24(bound(int256(tickA), MIN_TICK, MAX_TICK));
        tickB = int24(bound(int256(tickB), MIN_TICK, MAX_TICK));

        // Ensure tickA < tickB for the test
        if (tickA > tickB) {
            (tickA, tickB) = (tickB, tickA);
        }

        uint160 sqrtPriceA = TickMath.getSqrtRatioAtTick(tickA);
        uint160 sqrtPriceB = TickMath.getSqrtRatioAtTick(tickB);

        if (tickA < tickB) {
            assertLt(sqrtPriceA, sqrtPriceB, "Monotonicity violated: higher tick should give higher sqrtPrice");
        } else {
            assertEq(sqrtPriceA, sqrtPriceB, "Equal ticks should give equal sqrtPrice");
        }
    }

    /**
     * @notice Verifies that getTickAtSqrtRatio is monotonically non-decreasing
     * @dev Higher sqrt prices should produce >= ticks (floor function behavior)
     */
    function testFuzz_monotonicity_sqrtPriceToTick(uint160 sqrtPriceA, uint160 sqrtPriceB) public pure {
        // Bound to valid range
        sqrtPriceA = uint160(bound(sqrtPriceA, MIN_SQRT_RATIO, MAX_SQRT_RATIO - 1));
        sqrtPriceB = uint160(bound(sqrtPriceB, MIN_SQRT_RATIO, MAX_SQRT_RATIO - 1));

        // Ensure sqrtPriceA <= sqrtPriceB for the test
        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }

        int24 tickA = TickMath.getTickAtSqrtRatio(sqrtPriceA);
        int24 tickB = TickMath.getTickAtSqrtRatio(sqrtPriceB);

        assertLe(tickA, tickB, "Monotonicity violated: higher sqrtPrice should give >= tick");
    }

    /* -------------------------------------------------------------------------- */
    /*                        Boundary Transitions                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that consecutive ticks produce distinct sqrt prices
     * @dev Ensures no "flat spots" in the tick -> sqrtPrice mapping
     */
    function testFuzz_consecutiveTicks_distinctSqrtPrices(int24 tick) public pure {
        // Bound to valid range, leaving room for tick + 1
        tick = int24(bound(int256(tick), MIN_TICK, MAX_TICK - 1));

        uint160 sqrtPrice1 = TickMath.getSqrtRatioAtTick(tick);
        uint160 sqrtPrice2 = TickMath.getSqrtRatioAtTick(tick + 1);

        assertLt(sqrtPrice1, sqrtPrice2, "Consecutive ticks should produce distinct sqrtPrices");
    }

    /* -------------------------------------------------------------------------- */
    /*                   Sanity Check: Known Values                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests some known tick/sqrtPrice pairs for sanity
     * @dev These values can be verified against Uniswap's reference implementation
     */
    function test_knownValues() public pure {
        // tick 0 -> 2^96
        assertEq(TickMath.getSqrtRatioAtTick(0), 2 ** 96);

        // MIN_TICK -> MIN_SQRT_RATIO
        assertEq(TickMath.getSqrtRatioAtTick(MIN_TICK), MIN_SQRT_RATIO);

        // MAX_TICK -> MAX_SQRT_RATIO
        assertEq(TickMath.getSqrtRatioAtTick(MAX_TICK), MAX_SQRT_RATIO);

        // Verify reverse
        assertEq(TickMath.getTickAtSqrtRatio(2 ** 96), 0);
        assertEq(TickMath.getTickAtSqrtRatio(MIN_SQRT_RATIO), MIN_TICK);
    }
}
