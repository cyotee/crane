// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/TickMath.sol";

/**
 * @title TickMath_V4_Test
 * @notice Unit tests for Uniswap V4 TickMath library pure math functions.
 * @dev Tests the bijection property and edge cases for tick <-> sqrtPrice conversions.
 *
 * Key properties tested:
 * 1. getTickAtSqrtPrice(getSqrtPriceAtTick(tick)) == tick for all valid ticks
 * 2. getSqrtPriceAtTick(getTickAtSqrtPrice(sqrtPrice)) approximates sqrtPrice
 * 3. Edge cases at MIN_TICK, MAX_TICK, MIN_SQRT_PRICE, MAX_SQRT_PRICE boundaries
 * 4. Known value verification against expected outputs
 */
contract TickMath_V4_Test is Test {

    /* -------------------------------------------------------------------------- */
    /*                            Constants from TickMath                         */
    /* -------------------------------------------------------------------------- */

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = 887272;
    uint160 internal constant MIN_SQRT_PRICE = 4295128739;
    uint160 internal constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342;

    /* -------------------------------------------------------------------------- */
    /*                  Exact Known Pairs for tick ↔ sqrtPrice                   */
    /* -------------------------------------------------------------------------- */

    // tick 0 -> 2^96 (1:1 price ratio)
    uint160 internal constant SQRT_PRICE_AT_TICK_0 = 79228162514264337593543950336; // 2**96

    // tick ±1 - smallest deviation from 1:1
    uint160 internal constant SQRT_PRICE_AT_TICK_1 = 79232123823359799118286999568;
    uint160 internal constant SQRT_PRICE_AT_TICK_NEG_1 = 79224201403219477170569942574;

    // tick ±10 - 0.05% pool tick spacing boundary
    uint160 internal constant SQRT_PRICE_AT_TICK_10 = 79267784519130042428790663799;
    uint160 internal constant SQRT_PRICE_AT_TICK_NEG_10 = 79188560314459151373725315960;

    // tick ±60 - 0.3% pool tick spacing boundary
    uint160 internal constant SQRT_PRICE_AT_TICK_60 = 79466191966197645195421774833;
    uint160 internal constant SQRT_PRICE_AT_TICK_NEG_60 = 78990846045029531151608375686;

    // tick ±200 - 1% pool tick spacing boundary
    uint160 internal constant SQRT_PRICE_AT_TICK_200 = 80024378775772204256025656563;
    uint160 internal constant SQRT_PRICE_AT_TICK_NEG_200 = 78439868342809377387252074393;

    /* -------------------------------------------------------------------------- */
    /*                         Known Value Unit Tests                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests getSqrtPriceAtTick with known tick/sqrtPrice pairs
     * @dev These values are verified against Uniswap V4's reference implementation
     */
    function test_getSqrtPriceAtTick_knownValues() public pure {
        // tick 0 -> 2^96 (1:1 price ratio)
        assertEq(
            TickMath.getSqrtPriceAtTick(0),
            SQRT_PRICE_AT_TICK_0,
            "tick 0 should give sqrtPrice = 2^96"
        );

        // MIN_TICK -> MIN_SQRT_PRICE
        assertEq(
            TickMath.getSqrtPriceAtTick(MIN_TICK),
            MIN_SQRT_PRICE,
            "MIN_TICK should give MIN_SQRT_PRICE"
        );

        // MAX_TICK -> MAX_SQRT_PRICE
        assertEq(
            TickMath.getSqrtPriceAtTick(MAX_TICK),
            MAX_SQRT_PRICE,
            "MAX_TICK should give MAX_SQRT_PRICE"
        );

        // tick ±1 - exact values
        assertEq(
            TickMath.getSqrtPriceAtTick(1),
            SQRT_PRICE_AT_TICK_1,
            "tick 1 should give exact sqrtPrice"
        );
        assertEq(
            TickMath.getSqrtPriceAtTick(-1),
            SQRT_PRICE_AT_TICK_NEG_1,
            "tick -1 should give exact sqrtPrice"
        );

        // tick ±10 - exact values (0.05% pool spacing)
        assertEq(
            TickMath.getSqrtPriceAtTick(10),
            SQRT_PRICE_AT_TICK_10,
            "tick 10 should give exact sqrtPrice"
        );
        assertEq(
            TickMath.getSqrtPriceAtTick(-10),
            SQRT_PRICE_AT_TICK_NEG_10,
            "tick -10 should give exact sqrtPrice"
        );

        // tick ±60 - exact values (0.3% pool spacing)
        assertEq(
            TickMath.getSqrtPriceAtTick(60),
            SQRT_PRICE_AT_TICK_60,
            "tick 60 should give exact sqrtPrice"
        );
        assertEq(
            TickMath.getSqrtPriceAtTick(-60),
            SQRT_PRICE_AT_TICK_NEG_60,
            "tick -60 should give exact sqrtPrice"
        );

        // tick ±200 - exact values (1% pool spacing)
        assertEq(
            TickMath.getSqrtPriceAtTick(200),
            SQRT_PRICE_AT_TICK_200,
            "tick 200 should give exact sqrtPrice"
        );
        assertEq(
            TickMath.getSqrtPriceAtTick(-200),
            SQRT_PRICE_AT_TICK_NEG_200,
            "tick -200 should give exact sqrtPrice"
        );
    }

    /**
     * @notice Tests getTickAtSqrtPrice with known sqrtPrice/tick pairs
     */
    function test_getTickAtSqrtPrice_knownValues() public pure {
        // 2^96 -> tick 0
        assertEq(
            TickMath.getTickAtSqrtPrice(SQRT_PRICE_AT_TICK_0),
            0,
            "sqrtPrice 2^96 should give tick 0"
        );

        // MIN_SQRT_PRICE -> MIN_TICK
        assertEq(
            TickMath.getTickAtSqrtPrice(MIN_SQRT_PRICE),
            MIN_TICK,
            "MIN_SQRT_PRICE should give MIN_TICK"
        );

        // MAX_SQRT_PRICE - 1 -> MAX_TICK - 1
        // Note: MAX_SQRT_PRICE itself is invalid input (exclusive upper bound)
        assertEq(
            TickMath.getTickAtSqrtPrice(MAX_SQRT_PRICE - 1),
            MAX_TICK - 1,
            "MAX_SQRT_PRICE - 1 should give MAX_TICK - 1"
        );

        // sqrtPrice for tick ±1 -> tick ±1
        assertEq(
            TickMath.getTickAtSqrtPrice(SQRT_PRICE_AT_TICK_1),
            1,
            "SQRT_PRICE_AT_TICK_1 should give tick 1"
        );
        assertEq(
            TickMath.getTickAtSqrtPrice(SQRT_PRICE_AT_TICK_NEG_1),
            -1,
            "SQRT_PRICE_AT_TICK_NEG_1 should give tick -1"
        );

        // sqrtPrice for tick ±10 -> tick ±10
        assertEq(
            TickMath.getTickAtSqrtPrice(SQRT_PRICE_AT_TICK_10),
            10,
            "SQRT_PRICE_AT_TICK_10 should give tick 10"
        );
        assertEq(
            TickMath.getTickAtSqrtPrice(SQRT_PRICE_AT_TICK_NEG_10),
            -10,
            "SQRT_PRICE_AT_TICK_NEG_10 should give tick -10"
        );

        // sqrtPrice for tick ±60 -> tick ±60
        assertEq(
            TickMath.getTickAtSqrtPrice(SQRT_PRICE_AT_TICK_60),
            60,
            "SQRT_PRICE_AT_TICK_60 should give tick 60"
        );
        assertEq(
            TickMath.getTickAtSqrtPrice(SQRT_PRICE_AT_TICK_NEG_60),
            -60,
            "SQRT_PRICE_AT_TICK_NEG_60 should give tick -60"
        );

        // sqrtPrice for tick ±200 -> tick ±200
        assertEq(
            TickMath.getTickAtSqrtPrice(SQRT_PRICE_AT_TICK_200),
            200,
            "SQRT_PRICE_AT_TICK_200 should give tick 200"
        );
        assertEq(
            TickMath.getTickAtSqrtPrice(SQRT_PRICE_AT_TICK_NEG_200),
            -200,
            "SQRT_PRICE_AT_TICK_NEG_200 should give tick -200"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                  Bijection: tick -> sqrtPrice -> tick                      */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that getTickAtSqrtPrice(getSqrtPriceAtTick(tick)) == tick
     * @dev This is the primary bijection property: tick -> sqrtPrice -> tick is identity.
     *      MAX_TICK is excluded because getSqrtPriceAtTick(MAX_TICK) returns MAX_SQRT_PRICE,
     *      and getTickAtSqrtPrice requires input < MAX_SQRT_PRICE (exclusive upper bound).
     * @param tick The fuzzed tick value to test
     */
    function testFuzz_bijection_tickToSqrtToTick(int24 tick) public pure {
        // Bound tick to valid range (exclude MAX_TICK since MAX_SQRT_PRICE is not valid reverse input)
        tick = int24(bound(int256(tick), MIN_TICK, MAX_TICK - 1));

        // Forward: tick -> sqrtPrice
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(tick);

        // Reverse: sqrtPrice -> tick
        int24 recoveredTick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);

        // The bijection property: recovered tick must equal original tick
        assertEq(recoveredTick, tick, "Bijection violated: tick -> sqrtPrice -> tick != tick");
    }

    /**
     * @notice Tests bijection at strategic boundary points
     */
    function test_bijection_boundaryPoints() public pure {
        // MIN_TICK
        _testBijectionAtTick(MIN_TICK);

        // MAX_TICK - 1 (MAX_TICK excluded because MAX_SQRT_PRICE is invalid reverse input)
        _testBijectionAtTick(MAX_TICK - 1);

        // Zero
        _testBijectionAtTick(0);

        // Common tick spacing boundaries
        _testBijectionAtTick(60);     // Common for 0.3% pools
        _testBijectionAtTick(-60);
        _testBijectionAtTick(200);    // Common for 1% pools
        _testBijectionAtTick(-200);
        _testBijectionAtTick(10);     // Common for 0.05% pools
        _testBijectionAtTick(-10);
    }

    /**
     * @dev Helper to test bijection at a specific tick
     */
    function _testBijectionAtTick(int24 tick) internal pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(tick);
        int24 recoveredTick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);
        require(recoveredTick == tick, "Bijection failed at tick");
    }

    /* -------------------------------------------------------------------------- */
    /*                  Approximation: sqrtPrice -> tick -> sqrtPrice             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that getSqrtPriceAtTick(getTickAtSqrtPrice(sqrtPrice)) approximates sqrtPrice
     * @dev Due to discrete ticks, exact equality is not expected. The recovered sqrtPrice
     *      should be <= the original (since getTickAtSqrtPrice returns floor tick).
     * @param sqrtPriceX96 The fuzzed sqrt price to test
     */
    function testFuzz_approximation_sqrtToTickToSqrt(uint160 sqrtPriceX96) public pure {
        // Bound to valid sqrtPrice range (exclusive of MAX_SQRT_PRICE per TickMath)
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, MIN_SQRT_PRICE, MAX_SQRT_PRICE - 1));

        // Forward: sqrtPrice -> tick
        int24 tick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);

        // Reverse: tick -> sqrtPrice
        uint160 recoveredSqrtPrice = TickMath.getSqrtPriceAtTick(tick);

        // The recovered sqrtPrice should be <= original (floor behavior)
        assertLe(
            recoveredSqrtPrice,
            sqrtPriceX96,
            "Recovered sqrtPrice exceeds original (floor violation)"
        );

        // The recovered sqrtPrice should be close: the next tick's sqrtPrice should exceed original
        if (tick < MAX_TICK) {
            uint160 nextTickSqrtPrice = TickMath.getSqrtPriceAtTick(tick + 1);
            assertGt(
                nextTickSqrtPrice,
                sqrtPriceX96,
                "Next tick sqrtPrice should exceed original"
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            Edge Cases                                      */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests MIN_TICK boundary
     */
    function test_edge_minTick() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(MIN_TICK);
        int24 recoveredTick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);

        assertEq(sqrtPriceX96, MIN_SQRT_PRICE, "MIN_TICK should produce MIN_SQRT_PRICE");
        assertEq(recoveredTick, MIN_TICK, "MIN_SQRT_PRICE should recover MIN_TICK");
    }

    /**
     * @notice Tests MAX_TICK boundary
     * @dev getTickAtSqrtPrice(MAX_SQRT_PRICE) reverts - MAX_SQRT_PRICE is exclusive upper bound
     */
    function test_edge_maxTick() public pure {
        // MAX_TICK -> MAX_SQRT_PRICE works
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(MAX_TICK);
        assertEq(sqrtPriceX96, MAX_SQRT_PRICE, "MAX_TICK should produce MAX_SQRT_PRICE");

        // Test MAX_TICK - 1 roundtrip instead (MAX_SQRT_PRICE is invalid reverse input)
        uint160 sqrtPriceAtMaxMinus1 = TickMath.getSqrtPriceAtTick(MAX_TICK - 1);
        int24 recoveredTick = TickMath.getTickAtSqrtPrice(sqrtPriceAtMaxMinus1);
        assertEq(recoveredTick, MAX_TICK - 1, "MAX_TICK - 1 roundtrip should work");
    }

    /**
     * @notice Tests MIN_SQRT_PRICE boundary
     */
    function test_edge_minSqrtPrice() public pure {
        int24 tick = TickMath.getTickAtSqrtPrice(MIN_SQRT_PRICE);
        assertEq(tick, MIN_TICK, "MIN_SQRT_PRICE should yield MIN_TICK");
    }

    /**
     * @notice Tests MAX_SQRT_PRICE - 1 (highest valid input to getTickAtSqrtPrice)
     */
    function test_edge_maxSqrtPriceMinusOne() public pure {
        uint160 sqrtPriceX96 = MAX_SQRT_PRICE - 1;
        int24 tick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);

        // The tick should be MAX_TICK - 1 (floor of the highest valid sqrtPrice)
        assertEq(tick, MAX_TICK - 1, "MAX_SQRT_PRICE - 1 should yield MAX_TICK - 1");

        // Verify the approximation holds
        uint160 recoveredSqrtPrice = TickMath.getSqrtPriceAtTick(tick);
        assertLe(recoveredSqrtPrice, sqrtPriceX96, "Recovered should be <= original");
    }

    /**
     * @notice Tests tick zero (1:1 price ratio)
     */
    function test_edge_tickZero() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(0);
        int24 recoveredTick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);

        // tick 0 should give sqrtPriceX96 = 2^96 (1:1 ratio)
        uint160 expectedSqrtPrice = 2 ** 96;
        assertEq(sqrtPriceX96, expectedSqrtPrice, "Tick 0 should give sqrtPrice = 2^96");
        assertEq(recoveredTick, 0, "sqrtPrice 2^96 should recover tick 0");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Tick Spacing Helpers                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests minUsableTick and maxUsableTick helpers
     */
    function test_usableTicks() public pure {
        // Common tick spacings
        int24[] memory spacings = new int24[](4);
        spacings[0] = 1;    // 0.01% pools
        spacings[1] = 10;   // 0.05% pools
        spacings[2] = 60;   // 0.3% pools
        spacings[3] = 200;  // 1% pools

        for (uint256 i = 0; i < spacings.length; i++) {
            int24 spacing = spacings[i];

            int24 minUsable = TickMath.minUsableTick(spacing);
            int24 maxUsable = TickMath.maxUsableTick(spacing);

            // Verify divisibility
            assertEq(minUsable % spacing, 0, "minUsableTick should be divisible by spacing");
            assertEq(maxUsable % spacing, 0, "maxUsableTick should be divisible by spacing");

            // Verify bounds
            assertGe(minUsable, MIN_TICK, "minUsableTick should be >= MIN_TICK");
            assertLe(maxUsable, MAX_TICK, "maxUsableTick should be <= MAX_TICK");

            // Verify they're the closest usable ticks to the limits
            assertLt(minUsable - spacing, MIN_TICK, "minUsable - spacing should be < MIN_TICK");
            assertGt(maxUsable + spacing, MAX_TICK, "maxUsable + spacing should be > MAX_TICK");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                     Monotonicity: Higher tick = Higher sqrtPrice           */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that getSqrtPriceAtTick is strictly monotonically increasing
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

        uint160 sqrtPriceA = TickMath.getSqrtPriceAtTick(tickA);
        uint160 sqrtPriceB = TickMath.getSqrtPriceAtTick(tickB);

        if (tickA < tickB) {
            assertLt(sqrtPriceA, sqrtPriceB, "Monotonicity violated: higher tick should give higher sqrtPrice");
        } else {
            assertEq(sqrtPriceA, sqrtPriceB, "Equal ticks should give equal sqrtPrice");
        }
    }

    /**
     * @notice Verifies that getTickAtSqrtPrice is monotonically non-decreasing
     * @dev Higher sqrt prices should produce >= ticks (floor function behavior)
     */
    function testFuzz_monotonicity_sqrtPriceToTick(uint160 sqrtPriceA, uint160 sqrtPriceB) public pure {
        // Bound to valid range
        sqrtPriceA = uint160(bound(sqrtPriceA, MIN_SQRT_PRICE, MAX_SQRT_PRICE - 1));
        sqrtPriceB = uint160(bound(sqrtPriceB, MIN_SQRT_PRICE, MAX_SQRT_PRICE - 1));

        // Ensure sqrtPriceA <= sqrtPriceB for the test
        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }

        int24 tickA = TickMath.getTickAtSqrtPrice(sqrtPriceA);
        int24 tickB = TickMath.getTickAtSqrtPrice(sqrtPriceB);

        assertLe(tickA, tickB, "Monotonicity violated: higher sqrtPrice should give >= tick");
    }

    /**
     * @notice Tests that consecutive ticks produce distinct sqrt prices
     * @dev Ensures no "flat spots" in the tick -> sqrtPrice mapping
     */
    function testFuzz_consecutiveTicks_distinctSqrtPrices(int24 tick) public pure {
        // Bound to valid range, leaving room for tick + 1
        tick = int24(bound(int256(tick), MIN_TICK, MAX_TICK - 1));

        uint160 sqrtPrice1 = TickMath.getSqrtPriceAtTick(tick);
        uint160 sqrtPrice2 = TickMath.getSqrtPriceAtTick(tick + 1);

        assertLt(sqrtPrice1, sqrtPrice2, "Consecutive ticks should produce distinct sqrtPrices");
    }

    /* -------------------------------------------------------------------------- */
    /*                       Revert Cases: Invalid Inputs                         */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that tick below MIN_TICK reverts
     */
    function test_revert_tickTooLow() public {
        vm.expectRevert(abi.encodeWithSelector(TickMath.InvalidTick.selector, MIN_TICK - 1));
        this.external_getSqrtPriceAtTick(MIN_TICK - 1);
    }

    /**
     * @notice Tests that tick above MAX_TICK reverts
     */
    function test_revert_tickTooHigh() public {
        vm.expectRevert(abi.encodeWithSelector(TickMath.InvalidTick.selector, MAX_TICK + 1));
        this.external_getSqrtPriceAtTick(MAX_TICK + 1);
    }

    /**
     * @notice Tests that sqrtPrice below MIN_SQRT_PRICE reverts
     */
    function test_revert_sqrtPriceTooLow() public {
        vm.expectRevert(abi.encodeWithSelector(TickMath.InvalidSqrtPrice.selector, MIN_SQRT_PRICE - 1));
        this.external_getTickAtSqrtPrice(MIN_SQRT_PRICE - 1);
    }

    /**
     * @notice Tests that sqrtPrice at MAX_SQRT_PRICE reverts (exclusive upper bound)
     */
    function test_revert_sqrtPriceAtMax() public {
        vm.expectRevert(abi.encodeWithSelector(TickMath.InvalidSqrtPrice.selector, MAX_SQRT_PRICE));
        this.external_getTickAtSqrtPrice(MAX_SQRT_PRICE);
    }

    /**
     * @notice Tests that sqrtPrice = 0 reverts
     */
    function test_revert_sqrtPriceZero() public {
        vm.expectRevert(abi.encodeWithSelector(TickMath.InvalidSqrtPrice.selector, uint160(0)));
        this.external_getTickAtSqrtPrice(0);
    }

    /* -------------------------------------------------------------------------- */
    /*                       External Wrappers for Revert Tests                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev External wrapper for getSqrtPriceAtTick to allow vm.expectRevert
     */
    function external_getSqrtPriceAtTick(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtPriceAtTick(tick);
    }

    /**
     * @dev External wrapper for getTickAtSqrtPrice to allow vm.expectRevert
     */
    function external_getTickAtSqrtPrice(uint160 sqrtPriceX96) external pure returns (int24) {
        return TickMath.getTickAtSqrtPrice(sqrtPriceX96);
    }
}
