// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.30;

import "forge-std/Test.sol";

import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/// @title SlipstreamUtils Edge Case Tests
/// @notice Tests for edge cases identified in CRANE-011 review:
///         - MIN_TICK/MAX_TICK positions
///         - Zero liquidity swaps
///         - Extreme liquidity values
///         - Tick spacing variations
///         - Price limit exactness
/// @dev Origin: CRANE-040 (spawned from CRANE-011 code review)
/// @dev CRANE-090: Added exact-output counterparts for all edge case categories
contract SlipstreamUtils_edgeCases_Test is TestBase_Slipstream {
    using SlipstreamUtils for *;

    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    uint256 constant TEST_AMOUNT = 1e18;
    uint256 constant LARGE_AMOUNT = 1e30;
    uint256 constant DUST_AMOUNT = 1;  // 1 wei
    uint128 constant DEFAULT_LIQUIDITY = 1_000_000e18;

    /* -------------------------------------------------------------------------- */
    /*                               Setup                                        */
    /* -------------------------------------------------------------------------- */

    function setUp() public override {
        super.setUp();
    }

    /* ========================================================================== */
    /*                    US-CRANE-040.1: Edge Tick Value Tests                   */
    /* ========================================================================== */

    /// @notice Test position at MIN_TICK boundary
    /// @dev Verifies graceful handling at minimum tick boundary
    /// @dev At MIN_TICK, swapping oneForZero (price increasing) should work
    function test_edgeTicks_positionAtMinTick() public {
        MockCLPool pool = createMockPoolOneToOne(
            makeAddr("TokenA_min"),
            makeAddr("TokenB_min"),
            FEE_MEDIUM,
            TICK_SPACING_LOW  // Use spacing of 1 for exact MIN_TICK
        );

        // Position from MIN_TICK to MIN_TICK + 10000 (wider range for more liquidity)
        int24 tickLower = TickMath.MIN_TICK;
        int24 tickUpper = TickMath.MIN_TICK + 10000;

        addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

        // Set pool state to be within this range, near MIN_TICK
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TickMath.MIN_TICK + 100);
        pool.setState(sqrtPriceX96, TickMath.MIN_TICK + 100, DEFAULT_LIQUIDITY);

        // At MIN_TICK boundary, we can only swap oneForZero (price increasing toward center)
        // Swapping zeroForOne would push price below MIN_TICK which is not allowed
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            false  // oneForZero (price increasing, moving away from MIN_TICK boundary)
        );

        assertTrue(quotedOut > 0, "Quote at MIN_TICK boundary should produce output");
    }

    /// @notice Test position at MAX_TICK boundary
    /// @dev Verifies graceful handling at maximum tick boundary
    /// @dev At MAX_TICK, swapping zeroForOne (price decreasing) should work
    function test_edgeTicks_positionAtMaxTick() public {
        MockCLPool pool = createMockPoolOneToOne(
            makeAddr("TokenA_max"),
            makeAddr("TokenB_max"),
            FEE_MEDIUM,
            TICK_SPACING_LOW
        );

        // Position from MAX_TICK - 10000 to MAX_TICK (wider range)
        int24 tickLower = TickMath.MAX_TICK - 10000;
        int24 tickUpper = TickMath.MAX_TICK;

        addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

        // Set pool state to be within this range, near MAX_TICK
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TickMath.MAX_TICK - 100);
        pool.setState(sqrtPriceX96, TickMath.MAX_TICK - 100, DEFAULT_LIQUIDITY);

        // At MAX_TICK boundary, we can only swap zeroForOne (price decreasing toward center)
        // Swapping oneForZero would push price above MAX_TICK which is not allowed
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true  // zeroForOne (price decreasing, moving away from MAX_TICK boundary)
        );

        assertTrue(quotedOut > 0, "Quote at MAX_TICK boundary should produce output");
    }

    /// @notice Test position spanning entire tick range (MIN_TICK to MAX_TICK)
    /// @dev Verifies handling of full-range positions
    function test_edgeTicks_fullRangePosition() public {
        MockCLPool pool = createMockPoolOneToOne(
            makeAddr("TokenA_full"),
            makeAddr("TokenB_full"),
            FEE_MEDIUM,
            TICK_SPACING_LOW
        );

        // Full range position
        int24 tickLower = TickMath.MIN_TICK;
        int24 tickUpper = TickMath.MAX_TICK;

        addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

        // Set pool state at center (tick 0)
        uint160 sqrtPriceX96 = uint160(1) << 96;  // 1:1 price
        pool.setState(sqrtPriceX96, 0, DEFAULT_LIQUIDITY);

        // Quote should work for both directions
        uint256 quotedOutZeroForOne = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT, sqrtPriceX96, DEFAULT_LIQUIDITY, FEE_MEDIUM, true
        );

        uint256 quotedOutOneForZero = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT, sqrtPriceX96, DEFAULT_LIQUIDITY, FEE_MEDIUM, false
        );

        assertTrue(quotedOutZeroForOne > 0, "Quote zeroForOne should produce output");
        assertTrue(quotedOutOneForZero > 0, "Quote oneForZero should produce output");
        // At 1:1 price, outputs should be approximately equal
        assertApproxEqRel(quotedOutZeroForOne, quotedOutOneForZero, 0.01e18, "Outputs should be approximately equal at 1:1 price");
    }

    /// @notice Test that liquidity amounts compute correctly at tick boundaries
    function test_edgeTicks_liquidityAmountsAtBoundaries() public {
        // Test _quoteAmountsForLiquidity at MIN_TICK
        (uint256 amount0Min, uint256 amount1Min) = SlipstreamUtils._quoteAmountsForLiquidity(
            TickMath.MIN_TICK + 1,  // Current tick just above MIN
            TickMath.MIN_TICK,
            TickMath.MIN_TICK + 1000,
            DEFAULT_LIQUIDITY
        );
        // Should compute without overflow/underflow
        assertTrue(amount0Min > 0 || amount1Min > 0, "Should compute amounts at MIN_TICK");

        // Test _quoteAmountsForLiquidity at MAX_TICK
        (uint256 amount0Max, uint256 amount1Max) = SlipstreamUtils._quoteAmountsForLiquidity(
            TickMath.MAX_TICK - 1,  // Current tick just below MAX
            TickMath.MAX_TICK - 1000,
            TickMath.MAX_TICK,
            DEFAULT_LIQUIDITY
        );
        assertTrue(amount0Max > 0 || amount1Max > 0, "Should compute amounts at MAX_TICK");
    }

    /* ========================================================================== */
    /*                    US-CRANE-040.2: Extreme Value Tests                     */
    /* ========================================================================== */

    /// @notice Test with uint128.max liquidity
    /// @dev Verifies no overflow with maximum liquidity value
    function test_extremeValues_maxLiquidity() public {
        uint128 maxLiquidity = type(uint128).max;
        uint160 sqrtPriceX96 = uint160(1) << 96;  // 1:1 price

        // This should not overflow
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            maxLiquidity,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedOut > 0, "Quote with max liquidity should produce output");
        assertTrue(quotedOut < TEST_AMOUNT, "Output should be less than input due to fees");
    }

    /// @notice Test with very high liquidity (close to max)
    function test_extremeValues_highLiquidity() public {
        uint128 highLiquidity = type(uint128).max / 2;
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            highLiquidity,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedOut > 0, "Quote with high liquidity should produce output");
    }

    /// @notice Test zero liquidity swap returns zero output (graceful failure)
    /// @dev With zero liquidity, no swap can occur
    function test_extremeValues_zeroLiquidity() public {
        uint128 zeroLiquidity = 0;
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            zeroLiquidity,
            FEE_MEDIUM,
            true
        );

        assertEq(quotedOut, 0, "Zero liquidity should give zero output");
    }

    /// @notice Test with very small amount (1 wei)
    function test_extremeValues_dustAmount_oneWei() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            DUST_AMOUNT,  // 1 wei
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true
        );

        // 1 wei input may result in 0 output due to fee deduction
        assertTrue(quotedOut <= DUST_AMOUNT, "Output should not exceed 1 wei input");
    }

    /// @notice Test with very small amounts across different values
    function test_extremeValues_dustAmounts_range() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint256[5] memory dustAmounts = [uint256(1), 2, 10, 100, 1000];

        for (uint256 i = 0; i < dustAmounts.length; i++) {
            uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
                dustAmounts[i],
                sqrtPriceX96,
                DEFAULT_LIQUIDITY,
                FEE_MEDIUM,
                true
            );

            // Dust amounts should not revert and output <= input
            assertTrue(quotedOut <= dustAmounts[i], "Output should not exceed dust input");
        }
    }

    /// @notice Test with very large amounts (1e30+)
    function test_extremeValues_largeAmount_1e30() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            LARGE_AMOUNT,  // 1e30
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedOut > 0, "Large amount should produce output");
        assertTrue(quotedOut < LARGE_AMOUNT, "Output should be less than input");
    }

    /// @notice Test with extreme amounts (approaching uint256 max)
    function test_extremeValues_veryLargeAmount() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint256 veryLargeAmount = 1e50;

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            veryLargeAmount,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedOut > 0, "Very large amount should produce output");
    }

    /// @notice Test liquidity computation with extreme token amounts
    function test_extremeValues_liquidityForExtremeAmounts() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        int24 tickLower = -60000;
        int24 tickUpper = 60000;

        // Test with large amounts
        uint128 liquidityFromLarge = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            LARGE_AMOUNT,  // 1e30
            LARGE_AMOUNT
        );

        assertTrue(liquidityFromLarge > 0, "Should compute liquidity for large amounts");

        // Test with dust amounts
        uint128 liquidityFromDust = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            DUST_AMOUNT,
            DUST_AMOUNT
        );

        // Dust amounts should produce less (or equal) liquidity than large amounts
        assertTrue(liquidityFromDust <= liquidityFromLarge, "Dust liquidity should not exceed large-amount liquidity");
    }

    /* ========================================================================== */
    /*                  US-CRANE-040.3: Tick Spacing Variation Tests              */
    /* ========================================================================== */

    /// @notice Test with tick spacing 1
    function test_tickSpacing_1() public {
        _testTickSpacing(1);
    }

    /// @notice Test with tick spacing 10
    function test_tickSpacing_10() public {
        _testTickSpacing(10);
    }

    /// @notice Test with tick spacing 50
    function test_tickSpacing_50() public {
        _testTickSpacing(50);
    }

    /// @notice Test with tick spacing 100
    function test_tickSpacing_100() public {
        _testTickSpacing(100);
    }

    /// @notice Test with tick spacing 200
    function test_tickSpacing_200() public {
        _testTickSpacing(200);
    }

    /// @notice Internal helper to test a specific tick spacing
    function _testTickSpacing(int24 tickSpacing_) internal {
        MockCLPool pool = createMockPool(
            makeAddr(string(abi.encodePacked("TokenA_ts", vm.toString(uint256(uint24(tickSpacing_)))))),
            makeAddr(string(abi.encodePacked("TokenB_ts", vm.toString(uint256(uint24(tickSpacing_)))))),
            FEE_MEDIUM,
            tickSpacing_,
            uint160(1) << 96  // 1:1 price
        );

        // Create aligned tick range
        int24 tickLower = nearestUsableTick(-60000, tickSpacing_);
        int24 tickUpper = nearestUsableTick(60000, tickSpacing_);

        addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Quote should work regardless of tick spacing
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedOut > 0, string(abi.encodePacked("Quote should work with tick spacing ", vm.toString(uint256(uint24(tickSpacing_))))));

        // Verify mock swap matches quote
        uint160 sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        (, int256 amount1) = pool.swap(
            address(this),
            true,
            int256(TEST_AMOUNT),
            sqrtPriceLimitX96,
            ""
        );

        uint256 actualOut = uint256(-amount1);
        assertApproxEqAbs(quotedOut, actualOut, 1, "Quote should match swap result");
    }

    /// @notice Test that tick alignment works correctly for all spacings
    function test_tickSpacing_alignmentAtBoundaries() public {
        int24[5] memory tickSpacings = [int24(1), int24(10), int24(50), int24(100), int24(200)];

        for (uint256 i = 0; i < tickSpacings.length; i++) {
            int24 spacing = tickSpacings[i];

            // Test alignment of MIN_TICK
            int24 alignedMin = nearestUsableTick(TickMath.MIN_TICK, spacing);
            assertTrue(alignedMin % spacing == 0 || alignedMin == TickMath.MIN_TICK, "MIN_TICK should be properly aligned");
            assertTrue(alignedMin >= TickMath.MIN_TICK, "Aligned MIN should not be below MIN_TICK");

            // Test alignment of MAX_TICK
            int24 alignedMax = nearestUsableTick(TickMath.MAX_TICK, spacing);
            assertTrue(alignedMax % spacing == 0 || alignedMax == TickMath.MAX_TICK, "MAX_TICK should be properly aligned");
            assertTrue(alignedMax <= TickMath.MAX_TICK, "Aligned MAX should not be above MAX_TICK");
        }
    }

    /* ========================================================================== */
    /*                  US-CRANE-040.4: Price Limit Exactness Tests               */
    /* ========================================================================== */

    /// @notice Test swap stops exactly at sqrtPriceLimitX96 (zeroForOne)
    /// @dev CRANE-093: Enhanced with exact equality assertion and input consumption check.
    ///      When amountSpecified far exceeds what is needed to reach the limit,
    ///      SwapMath.computeSwapStep sets sqrtRatioNextX96 = sqrtRatioTargetX96 exactly.
    ///      No rounding tolerance is needed because the mock uses a single-tick swap
    ///      and SwapMath assigns the target price directly when the limit is reached.
    function test_priceLimitExactness_zeroForOne() public {
        MockCLPool pool = createMockPoolOneToOne(
            makeAddr("TokenA_limit"),
            makeAddr("TokenB_limit"),
            FEE_MEDIUM,
            TICK_SPACING_MEDIUM
        );

        int24 tickLower = nearestUsableTick(-60000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(60000, TICK_SPACING_MEDIUM);
        addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

        (uint160 sqrtPriceX96Start, , , , , ) = pool.slot0();

        // Set a price limit that should be reached mid-swap
        // For zeroForOne, price decreases, so limit should be lower than current
        int24 targetTick = -1000;
        uint160 sqrtPriceLimitX96 = TickMath.getSqrtRatioAtTick(targetTick);

        // Execute swap with large amount to ensure we hit the limit
        (int256 amount0, int256 amount1) = pool.swap(
            address(this),
            true,  // zeroForOne
            int256(LARGE_AMOUNT),
            sqrtPriceLimitX96,
            ""
        );

        // Get final price
        (uint160 sqrtPriceX96End, , , , , ) = pool.slot0();

        // Guard: final price should not overshoot limit (zeroForOne: price decreases, so final >= limit)
        assertTrue(
            sqrtPriceX96End >= sqrtPriceLimitX96,
            "Price should not overshoot limit (zeroForOne)"
        );

        // CRANE-093: Assert end price equals the price limit exactly
        assertEq(
            sqrtPriceX96End,
            sqrtPriceLimitX96,
            "End price must equal sqrtPriceLimitX96 exactly (zeroForOne)"
        );

        // CRANE-093: Assert swap consumed enough input to plausibly reach the limit
        // amount0 is positive (tokens in), and must be less than LARGE_AMOUNT to prove
        // the swap was constrained by the price limit, not by running out of input
        uint256 consumed = uint256(amount0);
        assertTrue(consumed > 0, "Swap must consume some input (zeroForOne)");
        assertTrue(consumed < LARGE_AMOUNT, "Swap must be limit-constrained, not input-constrained (zeroForOne)");
    }

    /// @notice Test swap stops exactly at sqrtPriceLimitX96 (oneForZero)
    /// @dev CRANE-093: Enhanced with exact equality assertion and input consumption check.
    ///      Same reasoning as zeroForOne — SwapMath assigns the target price directly
    ///      when the amount specified exceeds the amount needed to reach the price limit.
    function test_priceLimitExactness_oneForZero() public {
        MockCLPool pool = createMockPoolOneToOne(
            makeAddr("TokenA_limit2"),
            makeAddr("TokenB_limit2"),
            FEE_MEDIUM,
            TICK_SPACING_MEDIUM
        );

        int24 tickLower = nearestUsableTick(-60000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(60000, TICK_SPACING_MEDIUM);
        addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

        (uint160 sqrtPriceX96Start, , , , , ) = pool.slot0();

        // For oneForZero, price increases, so limit should be higher than current
        int24 targetTick = 1000;
        uint160 sqrtPriceLimitX96 = TickMath.getSqrtRatioAtTick(targetTick);

        // Execute swap with large amount
        (int256 amount0, int256 amount1) = pool.swap(
            address(this),
            false,  // oneForZero
            int256(LARGE_AMOUNT),
            sqrtPriceLimitX96,
            ""
        );

        // Get final price
        (uint160 sqrtPriceX96End, , , , , ) = pool.slot0();

        // Guard: final price should not overshoot limit (oneForZero: price increases, so final <= limit)
        assertTrue(
            sqrtPriceX96End <= sqrtPriceLimitX96,
            "Price should not overshoot limit (oneForZero)"
        );

        // CRANE-093: Assert end price equals the price limit exactly
        assertEq(
            sqrtPriceX96End,
            sqrtPriceLimitX96,
            "End price must equal sqrtPriceLimitX96 exactly (oneForZero)"
        );

        // CRANE-093: Assert swap consumed enough input to plausibly reach the limit
        // amount1 is positive (tokens in), and must be less than LARGE_AMOUNT
        uint256 consumed = uint256(amount1);
        assertTrue(consumed > 0, "Swap must consume some input (oneForZero)");
        assertTrue(consumed < LARGE_AMOUNT, "Swap must be limit-constrained, not input-constrained (oneForZero)");
    }

    /// @notice Test that quote uses correct price limits internally
    function test_priceLimitExactness_quoteUsesCorrectLimits() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;

        // Quote zeroForOne uses MIN_SQRT_RATIO + 1 as target
        uint256 quoteZeroForOne = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT, sqrtPriceX96, DEFAULT_LIQUIDITY, FEE_MEDIUM, true
        );

        // Quote oneForZero uses MAX_SQRT_RATIO - 1 as target
        uint256 quoteOneForZero = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT, sqrtPriceX96, DEFAULT_LIQUIDITY, FEE_MEDIUM, false
        );

        // Both should produce valid outputs
        assertTrue(quoteZeroForOne > 0, "zeroForOne quote should be positive");
        assertTrue(quoteOneForZero > 0, "oneForZero quote should be positive");
    }

    /// @notice Test price-limit exactness across multiple target ticks (zeroForOne)
    /// @dev CRANE-093: Proves the exact-landing property holds for various price targets
    function test_priceLimitExactness_zeroForOne_multipleTargets() public {
        int24[4] memory targetTicks = [int24(-100), int24(-500), int24(-2000), int24(-10000)];

        for (uint256 i = 0; i < targetTicks.length; i++) {
            // Fresh pool for each target
            MockCLPool pool = createMockPoolOneToOne(
                makeAddr(string(abi.encodePacked("TokenA_mt_zfo_", vm.toString(i)))),
                makeAddr(string(abi.encodePacked("TokenB_mt_zfo_", vm.toString(i)))),
                FEE_MEDIUM,
                TICK_SPACING_MEDIUM
            );

            int24 tickLower = nearestUsableTick(-60000, TICK_SPACING_MEDIUM);
            int24 tickUpper = nearestUsableTick(60000, TICK_SPACING_MEDIUM);
            addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

            uint160 sqrtPriceLimitX96 = TickMath.getSqrtRatioAtTick(targetTicks[i]);

            (int256 amount0, ) = pool.swap(
                address(this), true, int256(LARGE_AMOUNT), sqrtPriceLimitX96, ""
            );

            (uint160 sqrtPriceX96End, , , , , ) = pool.slot0();

            assertEq(
                sqrtPriceX96End,
                sqrtPriceLimitX96,
                string(abi.encodePacked(
                    "End price must equal limit at target tick ",
                    vm.toString(int256(targetTicks[i]))
                ))
            );
            assertTrue(uint256(amount0) < LARGE_AMOUNT, "Must be limit-constrained");
        }
    }

    /// @notice Test price-limit exactness across multiple target ticks (oneForZero)
    /// @dev CRANE-093: Proves the exact-landing property holds for various price targets
    function test_priceLimitExactness_oneForZero_multipleTargets() public {
        int24[4] memory targetTicks = [int24(100), int24(500), int24(2000), int24(10000)];

        for (uint256 i = 0; i < targetTicks.length; i++) {
            MockCLPool pool = createMockPoolOneToOne(
                makeAddr(string(abi.encodePacked("TokenA_mt_ofz_", vm.toString(i)))),
                makeAddr(string(abi.encodePacked("TokenB_mt_ofz_", vm.toString(i)))),
                FEE_MEDIUM,
                TICK_SPACING_MEDIUM
            );

            int24 tickLower = nearestUsableTick(-60000, TICK_SPACING_MEDIUM);
            int24 tickUpper = nearestUsableTick(60000, TICK_SPACING_MEDIUM);
            addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

            uint160 sqrtPriceLimitX96 = TickMath.getSqrtRatioAtTick(targetTicks[i]);

            ( , int256 amount1) = pool.swap(
                address(this), false, int256(LARGE_AMOUNT), sqrtPriceLimitX96, ""
            );

            (uint160 sqrtPriceX96End, , , , , ) = pool.slot0();

            assertEq(
                sqrtPriceX96End,
                sqrtPriceLimitX96,
                string(abi.encodePacked(
                    "End price must equal limit at target tick ",
                    vm.toString(int256(targetTicks[i]))
                ))
            );
            assertTrue(uint256(amount1) < LARGE_AMOUNT, "Must be limit-constrained");
        }
    }

    /// @notice Test price-limit exactness with exact-output swaps
    /// @dev CRANE-093: When the exact-output amount exceeds what's available before hitting
    ///      the price limit, the swap should stop exactly at the limit price.
    function test_priceLimitExactness_exactOutput_hitsLimit() public {
        MockCLPool pool = createMockPoolOneToOne(
            makeAddr("TokenA_eo_limit"),
            makeAddr("TokenB_eo_limit"),
            FEE_MEDIUM,
            TICK_SPACING_MEDIUM
        );

        int24 tickLower = nearestUsableTick(-60000, TICK_SPACING_MEDIUM);
        int24 tickUpper = nearestUsableTick(60000, TICK_SPACING_MEDIUM);
        addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

        // zeroForOne exact output with large desired output and tight price limit
        int24 targetTick = -500;
        uint160 sqrtPriceLimitX96 = TickMath.getSqrtRatioAtTick(targetTick);

        pool.swap(
            address(this),
            true,  // zeroForOne
            -int256(LARGE_AMOUNT),  // negative = exact output
            sqrtPriceLimitX96,
            ""
        );

        (uint160 sqrtPriceX96End, , , , , ) = pool.slot0();

        // Guard: no overshoot
        assertTrue(sqrtPriceX96End >= sqrtPriceLimitX96, "No overshoot (exact output, zeroForOne)");

        // Exact landing
        assertEq(
            sqrtPriceX96End,
            sqrtPriceLimitX96,
            "End price must equal limit exactly (exact output, zeroForOne)"
        );
    }

    /// @notice Test no overshoot with exact output quotes
    function test_priceLimitExactness_exactOutputNoOvershoot() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint256 desiredOutput = TEST_AMOUNT / 2;

        // Get required input for exact output
        uint256 requiredInput = SlipstreamUtils._quoteExactOutputSingle(
            desiredOutput,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true
        );

        // Now verify: using the required input should give approximately the desired output
        uint256 actualOutput = SlipstreamUtils._quoteExactInputSingle(
            requiredInput,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true
        );

        // The round-trip should be close (within rounding tolerance)
        assertApproxEqRel(actualOutput, desiredOutput, 0.001e18, "Round-trip should be consistent");
    }

    /* ========================================================================== */
    /*                           Additional Edge Cases                            */
    /* ========================================================================== */

    /// @notice Test exact input with all zero fees
    function test_edgeCases_zeroFee() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;

        // Zero fee should give output approximately equal to input (at 1:1 price)
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            0,  // Zero fee
            true
        );

        // With zero fee and 1:1 price, output should be very close to input
        assertApproxEqRel(quotedOut, TEST_AMOUNT, 0.001e18, "Zero fee should give ~input output");
    }

    /// @notice Test max fee (1%)
    function test_edgeCases_maxFee() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint24 maxFee = 10000;  // 1%

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            maxFee,
            true
        );

        assertTrue(quotedOut > 0, "Max fee quote should produce output");
        assertTrue(quotedOut < TEST_AMOUNT, "Output should be less than input with max fee");
    }

    /// @notice Test sqrtPrice at MIN_SQRT_RATIO boundary
    function test_edgeCases_minSqrtRatioBoundary() public {
        // MIN_SQRT_RATIO + 1 is the lowest valid price for swaps
        uint160 sqrtPriceX96 = TickMath.MIN_SQRT_RATIO + 1;

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            false  // oneForZero (can still go up from near-min)
        );

        // oneForZero at near-minimum price should produce non-zero output
        assertTrue(quotedOut > 0, "Should produce positive output at MIN_SQRT_RATIO boundary");
    }

    /// @notice Test sqrtPrice at MAX_SQRT_RATIO boundary
    function test_edgeCases_maxSqrtRatioBoundary() public {
        // MAX_SQRT_RATIO - 1 is the highest valid price for swaps
        uint160 sqrtPriceX96 = TickMath.MAX_SQRT_RATIO - 1;

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true  // zeroForOne (can still go down from near-max)
        );

        assertTrue(quotedOut > 0, "Should produce positive output at MAX_SQRT_RATIO boundary");
    }

    /// @notice Test getSqrtPriceFromReserves edge cases
    function test_edgeCases_sqrtPriceFromReserves() public {
        // Equal reserves = 1:1 price
        uint160 priceEqual = SlipstreamUtils._getSqrtPriceFromReserves(1e18, 1e18);
        uint160 expectedOneToOne = uint160(1) << 96;
        assertApproxEqRel(priceEqual, expectedOneToOne, 0.01e18, "Equal reserves should give 1:1 price");

        // Very different reserves
        uint160 priceSkewed = SlipstreamUtils._getSqrtPriceFromReserves(1e6, 1e30);
        assertTrue(priceSkewed > expectedOneToOne, "Higher reserve1 should give higher price");

        // Minimum reserves (1, 1)
        uint160 priceMin = SlipstreamUtils._getSqrtPriceFromReserves(1, 1);
        assertApproxEqRel(priceMin, expectedOneToOne, 0.1e18, "Min reserves should give ~1:1 price");
    }

    /* ========================================================================== */
    /*          CRANE-090: Exact-Output Counterparts for Edge Cases               */
    /* ========================================================================== */

    /* ------ Edge Tick Values (Exact Output) ------ */

    /// @notice Test exact output at MIN_TICK boundary
    function test_edgeTicks_exactOutput_positionAtMinTick() public {
        MockCLPool pool = createMockPoolOneToOne(
            makeAddr("TokenA_min_eo"),
            makeAddr("TokenB_min_eo"),
            FEE_MEDIUM,
            TICK_SPACING_LOW
        );

        int24 tickLower = TickMath.MIN_TICK;
        int24 tickUpper = TickMath.MIN_TICK + 10000;
        addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TickMath.MIN_TICK + 100);
        pool.setState(sqrtPriceX96, TickMath.MIN_TICK + 100, DEFAULT_LIQUIDITY);

        // Exact output: oneForZero at MIN_TICK boundary
        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e6,  // small output to stay within tick
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            false  // oneForZero
        );

        assertTrue(quotedIn > 0, "ExactOutput at MIN_TICK boundary should require positive input");
    }

    /// @notice Test exact output at MAX_TICK boundary
    function test_edgeTicks_exactOutput_positionAtMaxTick() public {
        MockCLPool pool = createMockPoolOneToOne(
            makeAddr("TokenA_max_eo"),
            makeAddr("TokenB_max_eo"),
            FEE_MEDIUM,
            TICK_SPACING_LOW
        );

        int24 tickLower = TickMath.MAX_TICK - 10000;
        int24 tickUpper = TickMath.MAX_TICK;
        addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(TickMath.MAX_TICK - 100);
        pool.setState(sqrtPriceX96, TickMath.MAX_TICK - 100, DEFAULT_LIQUIDITY);

        // Exact output: zeroForOne at MAX_TICK boundary
        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e6,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true  // zeroForOne
        );

        assertTrue(quotedIn > 0, "ExactOutput at MAX_TICK boundary should require positive input");
    }

    /// @notice Test exact output with full-range position
    function test_edgeTicks_exactOutput_fullRangePosition() public {
        MockCLPool pool = createMockPoolOneToOne(
            makeAddr("TokenA_full_eo"),
            makeAddr("TokenB_full_eo"),
            FEE_MEDIUM,
            TICK_SPACING_LOW
        );

        addLiquidity(pool, TickMath.MIN_TICK, TickMath.MAX_TICK, DEFAULT_LIQUIDITY);

        uint160 sqrtPriceX96 = uint160(1) << 96;
        pool.setState(sqrtPriceX96, 0, DEFAULT_LIQUIDITY);

        uint256 quotedIn_zfo = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT, sqrtPriceX96, DEFAULT_LIQUIDITY, FEE_MEDIUM, true
        );

        uint256 quotedIn_ofz = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT, sqrtPriceX96, DEFAULT_LIQUIDITY, FEE_MEDIUM, false
        );

        assertTrue(quotedIn_zfo > 0, "ExactOutput zeroForOne on full range should work");
        assertTrue(quotedIn_ofz > 0, "ExactOutput oneForZero on full range should work");
        assertApproxEqRel(quotedIn_zfo, quotedIn_ofz, 0.01e18, "Full range exact output should be symmetric at 1:1");
    }

    /* ------ Extreme Values (Exact Output) ------ */

    /// @notice Test exact output with max liquidity
    function test_extremeValues_exactOutput_maxLiquidity() public {
        uint128 maxLiquidity = type(uint128).max;
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            maxLiquidity,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedIn > 0, "ExactOutput with max liquidity should compute");
        assertTrue(quotedIn > TEST_AMOUNT, "Input should exceed output due to fees");
    }

    /// @notice Test exact output with zero liquidity
    function test_extremeValues_exactOutput_zeroLiquidity() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            0,  // zero liquidity
            FEE_MEDIUM,
            true
        );

        assertEq(quotedIn, 0, "ExactOutput zero liquidity should give zero input");
    }

    /// @notice Test exact output dust amount (1 wei)
    function test_extremeValues_exactOutput_dustAmount() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            DUST_AMOUNT,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true
        );

        // Should compute without reverting; input >= 1 wei to produce 1 wei output
        assertTrue(quotedIn >= DUST_AMOUNT, "ExactOutput dust: input should be >= output");
    }

    /// @notice Test exact output dust amounts across a range
    function test_extremeValues_exactOutput_dustAmounts_range() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint256[5] memory dustAmounts = [uint256(1), 2, 10, 100, 1000];

        for (uint256 i = 0; i < dustAmounts.length; i++) {
            uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
                dustAmounts[i],
                sqrtPriceX96,
                DEFAULT_LIQUIDITY,
                FEE_MEDIUM,
                true
            );

            // Input should be >= output due to fees
            assertTrue(quotedIn >= dustAmounts[i], "ExactOutput dust: input >= output");
        }
    }

    /// @notice Test exact output with large amounts
    function test_extremeValues_exactOutput_largeAmount() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            LARGE_AMOUNT,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedIn > 0, "ExactOutput large amount should produce positive input");
        assertTrue(quotedIn > LARGE_AMOUNT, "ExactOutput large: input > output due to fees");
    }

    /* ------ Tick Spacing Variations (Exact Output) ------ */

    function test_tickSpacing_exactOutput_1() public {
        _testExactOutputTickSpacing(1);
    }

    function test_tickSpacing_exactOutput_10() public {
        _testExactOutputTickSpacing(10);
    }

    function test_tickSpacing_exactOutput_50() public {
        _testExactOutputTickSpacing(50);
    }

    function test_tickSpacing_exactOutput_100() public {
        _testExactOutputTickSpacing(100);
    }

    function test_tickSpacing_exactOutput_200() public {
        _testExactOutputTickSpacing(200);
    }

    function _testExactOutputTickSpacing(int24 tickSpacing_) internal {
        MockCLPool pool = createMockPool(
            makeAddr(string(abi.encodePacked("TokenA_eo_ts_ec", vm.toString(uint256(uint24(tickSpacing_)))))),
            makeAddr(string(abi.encodePacked("TokenB_eo_ts_ec", vm.toString(uint256(uint24(tickSpacing_)))))),
            FEE_MEDIUM,
            tickSpacing_,
            uint160(1) << 96
        );

        int24 tickLower = nearestUsableTick(-60000, tickSpacing_);
        int24 tickUpper = nearestUsableTick(60000, tickSpacing_);
        addLiquidity(pool, tickLower, tickUpper, DEFAULT_LIQUIDITY);

        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedIn > 0, string(abi.encodePacked("ExactOutput should work with tick spacing ", vm.toString(uint256(uint24(tickSpacing_))))));

        // Verify mock swap matches
        uint160 sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        (int256 amount0, ) = pool.swap(
            address(this),
            true,
            -int256(TEST_AMOUNT),
            sqrtPriceLimitX96,
            ""
        );

        uint256 actualIn = uint256(amount0);
        assertApproxEqAbs(quotedIn, actualIn, 1, "ExactOutput quote should match mock swap");
    }

    /* ------ Price Limit Exactness (Exact Output) ------ */

    /// @notice Test exact output round-trip with oneForZero
    function test_priceLimitExactness_exactOutput_roundTrip_oneForZero() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint256 desiredOutput = TEST_AMOUNT / 2;

        uint256 requiredInput = SlipstreamUtils._quoteExactOutputSingle(
            desiredOutput, sqrtPriceX96, DEFAULT_LIQUIDITY, FEE_MEDIUM, false
        );

        uint256 actualOutput = SlipstreamUtils._quoteExactInputSingle(
            requiredInput, sqrtPriceX96, DEFAULT_LIQUIDITY, FEE_MEDIUM, false
        );

        assertApproxEqRel(actualOutput, desiredOutput, 0.001e18, "ExactOutput round-trip oneForZero should be consistent");
    }

    /* ------ Additional Exact-Output Edge Cases ------ */

    /// @notice Test exact output with zero fee
    function test_edgeCases_exactOutput_zeroFee() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            0,  // Zero fee
            true
        );

        // With zero fee and 1:1 price, input should be very close to output
        assertApproxEqRel(quotedIn, TEST_AMOUNT, 0.001e18, "ExactOutput zero fee: input ~= output");
    }

    /// @notice Test exact output with max fee (1%)
    function test_edgeCases_exactOutput_maxFee() public {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint24 maxFee = 10000;  // 1%

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            maxFee,
            true
        );

        assertTrue(quotedIn > TEST_AMOUNT, "ExactOutput max fee: input should exceed output");
    }

    /// @notice Test exact output at MIN_SQRT_RATIO boundary
    function test_edgeCases_exactOutput_minSqrtRatioBoundary() public {
        uint160 sqrtPriceX96 = TickMath.MIN_SQRT_RATIO + 1;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e6,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            false  // oneForZero
        );

        assertTrue(quotedIn > 0, "ExactOutput should produce positive input at MIN_SQRT_RATIO boundary");
    }

    /// @notice Test exact output at MAX_SQRT_RATIO boundary
    function test_edgeCases_exactOutput_maxSqrtRatioBoundary() public {
        uint160 sqrtPriceX96 = TickMath.MAX_SQRT_RATIO - 1;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e6,
            sqrtPriceX96,
            DEFAULT_LIQUIDITY,
            FEE_MEDIUM,
            true  // zeroForOne
        );

        assertTrue(quotedIn > 0, "ExactOutput should produce positive input at MAX_SQRT_RATIO boundary");
    }
}
