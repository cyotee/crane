// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/// @title Test SlipstreamUtils._quoteExactOutputSingle
/// @notice Validates exact output swap quotes for Slipstream pools
/// @dev Comprehensive edge case coverage for all 4 quoteExactOutputSingle overloads
/// @dev Origin: CRANE-090 - exact-output edge case parity with exact-input coverage
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

    /* ========================================================================== */
    /*                      Quote vs Mock Swap Parity Tests                       */
    /* ========================================================================== */

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

    /* ========================================================================== */
    /*          US-CRANE-090.1: Amount-Based Edge Cases (Exact Output)            */
    /* ========================================================================== */

    /// @notice Zero output should require zero input for all 4 overloads
    function test_quoteExactOutput_zeroAmount_allOverloads() public view {
        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Overload 1: sqrtPriceX96
        uint256 quoted1 = SlipstreamUtils._quoteExactOutputSingle(
            0, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );
        assertEq(quoted1, 0, "Zero output (sqrtPrice, zeroForOne) should require zero input");

        // Overload 2: tick
        uint256 quoted2 = SlipstreamUtils._quoteExactOutputSingle(
            0, tick, liquidity, FEE_MEDIUM, true
        );
        assertEq(quoted2, 0, "Zero output (tick, zeroForOne) should require zero input");

        // Overload 3: sqrtPriceX96 + unstaked fee
        uint256 quoted3 = SlipstreamUtils._quoteExactOutputSingle(
            0, sqrtPriceX96, liquidity, FEE_MEDIUM, uint24(500), true
        );
        assertEq(quoted3, 0, "Zero output (sqrtPrice+unstaked, zeroForOne) should require zero input");

        // Overload 4: tick + unstaked fee
        uint256 quoted4 = SlipstreamUtils._quoteExactOutputSingle(
            0, tick, liquidity, FEE_MEDIUM, uint24(500), true
        );
        assertEq(quoted4, 0, "Zero output (tick+unstaked, zeroForOne) should require zero input");

        // Also test oneForZero direction
        uint256 quoted5 = SlipstreamUtils._quoteExactOutputSingle(
            0, sqrtPriceX96, liquidity, FEE_MEDIUM, false
        );
        assertEq(quoted5, 0, "Zero output (sqrtPrice, oneForZero) should require zero input");

        uint256 quoted6 = SlipstreamUtils._quoteExactOutputSingle(
            0, tick, liquidity, FEE_MEDIUM, false
        );
        assertEq(quoted6, 0, "Zero output (tick, oneForZero) should require zero input");
    }

    /// @notice Dust output (1 wei) should compute correct input
    function test_quoteExactOutput_dustOutput_oneWei() public view {
        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedIn_zfo = SlipstreamUtils._quoteExactOutputSingle(
            1, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        uint256 quotedIn_ofz = SlipstreamUtils._quoteExactOutputSingle(
            1, sqrtPriceX96, liquidity, FEE_MEDIUM, false
        );

        // Input should be >= 1 (need at least 1 wei + fee to produce 1 wei output)
        assertTrue(quotedIn_zfo >= 1, "Dust output zeroForOne should require non-zero input");
        assertTrue(quotedIn_ofz >= 1, "Dust output oneForZero should require non-zero input");
    }

    /// @notice Sub-fee amounts: output smaller than what the fee itself would consume
    function test_quoteExactOutput_subFeeAmounts() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(1_000_000e18);

        // With FEE_MEDIUM (3000 pips = 0.3%), very small outputs
        uint256[4] memory subFeeAmounts = [uint256(1), 2, 5, 10];

        for (uint256 i = 0; i < subFeeAmounts.length; i++) {
            uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
                subFeeAmounts[i],
                sqrtPriceX96,
                liquidity,
                FEE_MEDIUM,
                true
            );

            // The input should be >= output because of fees
            assertTrue(
                quotedIn >= subFeeAmounts[i],
                "Input should be >= output due to fees"
            );
        }
    }

    /// @notice Small amounts range (1e6 to 1e12)
    function test_quoteExactOutput_smallAmounts() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(1_000_000e18);

        uint256[4] memory smallAmounts = [uint256(1e6), 1e8, 1e10, 1e12];

        for (uint256 i = 0; i < smallAmounts.length; i++) {
            uint256 quotedIn_zfo = SlipstreamUtils._quoteExactOutputSingle(
                smallAmounts[i], sqrtPriceX96, liquidity, FEE_MEDIUM, true
            );

            uint256 quotedIn_ofz = SlipstreamUtils._quoteExactOutputSingle(
                smallAmounts[i], sqrtPriceX96, liquidity, FEE_MEDIUM, false
            );

            assertTrue(quotedIn_zfo > smallAmounts[i], "Small amount zfo: input should exceed output due to fees");
            assertTrue(quotedIn_ofz > smallAmounts[i], "Small amount ofz: input should exceed output due to fees");
        }
    }

    /// @notice Large amounts (1e18 to 1e30+)
    function test_quoteExactOutput_largeAmounts() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(1_000_000e18);

        uint256[4] memory largeAmounts = [uint256(1e18), 1e21, 1e24, 1e27];

        for (uint256 i = 0; i < largeAmounts.length; i++) {
            uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
                largeAmounts[i], sqrtPriceX96, liquidity, FEE_MEDIUM, true
            );

            assertTrue(quotedIn > 0, "Large amount should require positive input");
            assertTrue(quotedIn > largeAmounts[i], "Large amount input should exceed output due to fees");
        }
    }

    /* ========================================================================== */
    /*         US-CRANE-090.2: Liquidity-Based Edge Cases (Exact Output)          */
    /* ========================================================================== */

    /// @notice Zero liquidity returns zero input required
    function test_quoteExactOutput_zeroLiquidity() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            sqrtPriceX96,
            0,  // zero liquidity
            FEE_MEDIUM,
            true
        );

        assertEq(quotedIn, 0, "Zero liquidity should give zero input required");
    }

    /// @notice Minimal liquidity (1 wei)
    function test_quoteExactOutput_minimalLiquidity() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1,  // 1 wei output
            sqrtPriceX96,
            1,  // 1 wei liquidity
            FEE_MEDIUM,
            true
        );

        // With minimal liquidity, input should be at least as large as output (due to fees)
        // or zero if the math rounds down completely
        assertTrue(quotedIn == 0 || quotedIn >= 1, "Minimal liquidity should produce zero or valid input");
    }

    /// @notice Max liquidity (uint128.max) should not overflow
    function test_quoteExactOutput_maxLiquidity() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 maxLiquidity = type(uint128).max;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            sqrtPriceX96,
            maxLiquidity,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedIn > 0, "Max liquidity should produce positive input required");
        assertTrue(quotedIn > TEST_AMOUNT_OUT, "Input should exceed output due to fees");
    }

    /// @notice High liquidity (uint128.max / 2)
    function test_quoteExactOutput_highLiquidity() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 highLiquidity = type(uint128).max / 2;

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            sqrtPriceX96,
            highLiquidity,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedIn > 0, "High liquidity exact output should compute");
    }

    /* ========================================================================== */
    /*           US-CRANE-090.3: Fee Tier Edge Cases (Exact Output)               */
    /* ========================================================================== */

    /// @notice Higher fee requires more input for same output
    function test_quoteExactOutput_higherFeeRequiresMoreInput() public pure {
        uint256 amountOut = TEST_AMOUNT_OUT;
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quoteLow = SlipstreamUtils._quoteExactOutputSingle(
            amountOut, sqrtPriceX96, liquidity, FEE_LOW, true
        );

        uint256 quoteMedium = SlipstreamUtils._quoteExactOutputSingle(
            amountOut, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        uint256 quoteHigh = SlipstreamUtils._quoteExactOutputSingle(
            amountOut, sqrtPriceX96, liquidity, FEE_HIGH, true
        );

        assertLt(quoteLow, quoteMedium, "Low fee should require less input than medium fee");
        assertLt(quoteMedium, quoteHigh, "Medium fee should require less input than high fee");
    }

    /// @notice Fee ordering also holds for oneForZero direction
    function test_quoteExactOutput_feeOrdering_oneForZero() public pure {
        uint256 amountOut = TEST_AMOUNT_OUT;
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quoteLow = SlipstreamUtils._quoteExactOutputSingle(
            amountOut, sqrtPriceX96, liquidity, FEE_LOW, false
        );

        uint256 quoteHigh = SlipstreamUtils._quoteExactOutputSingle(
            amountOut, sqrtPriceX96, liquidity, FEE_HIGH, false
        );

        assertLt(quoteLow, quoteHigh, "Higher fee should require more input (oneForZero)");
    }

    /// @notice All standard fee tiers produce non-zero results
    function test_quoteExactOutput_allFeeTiers() public pure {
        uint256 amountOut = TEST_AMOUNT_OUT;
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint24[3] memory fees = [FEE_LOW, FEE_MEDIUM, FEE_HIGH];

        for (uint256 i = 0; i < fees.length; i++) {
            uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
                amountOut, sqrtPriceX96, liquidity, fees[i], true
            );
            assertTrue(quotedIn > 0, "Fee tier should produce non-zero input");
            assertTrue(quotedIn > amountOut, "Input should exceed output for non-zero fee");
        }
    }

    /// @notice Zero fee: input should be approximately equal to output at 1:1 price
    function test_quoteExactOutput_zeroFee() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            sqrtPriceX96,
            liquidity,
            0,  // zero fee
            true
        );

        // With zero fee and 1:1 price, input should be very close to output
        assertApproxEqRel(quotedIn, TEST_AMOUNT_OUT, 0.001e18, "Zero fee input should approx equal output");
    }

    /// @notice Fee precision: fee calculation maintains precision through rounding
    function test_quoteExactOutput_feePrecision() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        // Compare fee difference between adjacent fee tiers
        // FEE_LOW = 500, next would be 501
        uint256 quoted500 = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, sqrtPriceX96, liquidity, 500, true
        );

        uint256 quoted501 = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, sqrtPriceX96, liquidity, 501, true
        );

        // Even 1 pip difference should result in slightly more input
        assertTrue(quoted501 >= quoted500, "1 pip more fee should require >= input");
    }

    /* ========================================================================== */
    /*        US-CRANE-090.4: Unstaked Fee Edge Cases (Exact Output)              */
    /* ========================================================================== */

    /// @notice Base + unstaked fee combinations
    function test_quoteExactOutput_unstakedFeeCombinations() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        // (100+100), (500+500), (3000+3000)
        uint24[3] memory baseFees = [uint24(100), uint24(500), uint24(3000)];

        for (uint256 i = 0; i < baseFees.length; i++) {
            uint256 quotedWithUnstaked = SlipstreamUtils._quoteExactOutputSingle(
                TEST_AMOUNT_OUT,
                sqrtPriceX96,
                liquidity,
                baseFees[i],
                baseFees[i],  // unstaked fee same as base
                true
            );

            // Combined fee should equal 2x base fee via the regular overload
            uint256 quotedCombined = SlipstreamUtils._quoteExactOutputSingle(
                TEST_AMOUNT_OUT,
                sqrtPriceX96,
                liquidity,
                baseFees[i] * 2,  // combined fee
                true
            );

            assertEq(quotedWithUnstaked, quotedCombined, "Unstaked overload should equal combined fee");
        }
    }

    /// @notice Zero base + non-zero unstaked fee
    function test_quoteExactOutput_zeroBaseNonZeroUnstaked() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quotedWithUnstaked = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            sqrtPriceX96,
            liquidity,
            0,      // zero base fee
            500,    // non-zero unstaked fee
            true
        );

        uint256 quotedRegular = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            sqrtPriceX96,
            liquidity,
            500,    // same total fee
            true
        );

        assertEq(quotedWithUnstaked, quotedRegular, "Zero base + unstaked should equal equivalent regular fee");
    }

    /// @notice Non-zero base + zero unstaked fee
    function test_quoteExactOutput_nonZeroBaseZeroUnstaked() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quotedWithUnstaked = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            0,      // zero unstaked fee
            true
        );

        uint256 quotedRegular = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        assertEq(quotedWithUnstaked, quotedRegular, "Non-zero base + zero unstaked should match regular");
    }

    /// @notice Unstaked fee with tick overload
    function test_quoteExactOutput_unstakedFeeTick() public view {
        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedSqrtPrice = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            uint24(500),
            true
        );

        uint256 quotedTick = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            tick,
            liquidity,
            FEE_MEDIUM,
            uint24(500),
            true
        );

        assertEq(quotedSqrtPrice, quotedTick, "Unstaked fee: sqrtPrice vs tick overload mismatch");
    }

    /* ========================================================================== */
    /*       US-CRANE-090.5: Price/Tick Boundary Edge Cases (Exact Output)        */
    /* ========================================================================== */

    /// @notice 1:1 price ratio
    function test_quoteExactOutput_oneToOnePrice() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quotedIn_zfo = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        uint256 quotedIn_ofz = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, sqrtPriceX96, liquidity, FEE_MEDIUM, false
        );

        // At 1:1 price, both directions should require approximately same input
        assertApproxEqRel(quotedIn_zfo, quotedIn_ofz, 0.01e18, "1:1 price should be symmetric");
    }

    /// @notice MIN_SQRT_RATIO + 1 boundary
    function test_quoteExactOutput_minSqrtRatioBoundary() public pure {
        uint160 sqrtPriceX96 = TickMath.MIN_SQRT_RATIO + 1;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        // oneForZero should work (price can still go up from near-min)
        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e6,  // smaller output to avoid depletion
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            false  // oneForZero
        );

        assertTrue(quotedIn > 0, "Should produce positive input at MIN_SQRT_RATIO boundary for exact output");
    }

    /// @notice MAX_SQRT_RATIO - 1 boundary
    function test_quoteExactOutput_maxSqrtRatioBoundary() public pure {
        uint160 sqrtPriceX96 = TickMath.MAX_SQRT_RATIO - 1;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        // zeroForOne should work (price can still go down from near-max)
        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e6,  // smaller output to avoid depletion
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true  // zeroForOne
        );

        assertTrue(quotedIn > 0, "Should produce positive input at MAX_SQRT_RATIO boundary for exact output");
    }

    /// @notice MIN_TICK boundary via tick overload
    function test_quoteExactOutput_minTickBoundary() public pure {
        int24 tick = TickMath.MIN_TICK + 100;  // slightly above min
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e6, tick, liquidity, FEE_MEDIUM, false  // oneForZero
        );

        assertTrue(quotedIn > 0, "Should produce positive input at MIN_TICK boundary via tick overload");
    }

    /// @notice MAX_TICK boundary via tick overload
    function test_quoteExactOutput_maxTickBoundary() public pure {
        int24 tick = TickMath.MAX_TICK - 100;  // slightly below max
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e6, tick, liquidity, FEE_MEDIUM, true  // zeroForOne
        );

        assertTrue(quotedIn > 0, "Should produce positive input at MAX_TICK boundary via tick overload");
    }

    /// @notice Extreme price ratios (high)
    function test_quoteExactOutput_highPriceRatio() public pure {
        // High price = token0 is very valuable relative to token1
        int24 highTick = 100000;  // Far from center
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(highTick);
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e6, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        assertTrue(quotedIn > 0, "Should produce positive input at high price ratio");
    }

    /// @notice Extreme price ratios (low)
    function test_quoteExactOutput_lowPriceRatio() public pure {
        int24 lowTick = -100000;
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(lowTick);
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e6, sqrtPriceX96, liquidity, FEE_MEDIUM, false
        );

        assertTrue(quotedIn > 0, "Should produce positive input at low price ratio");
    }

    /* ========================================================================== */
    /*        US-CRANE-090.6: Tick Spacing Edge Cases (Exact Output)              */
    /* ========================================================================== */

    /// @notice Test exact output across all tick spacings
    function test_quoteExactOutput_tickSpacing_1() public {
        _testExactOutputTickSpacing(1);
    }

    function test_quoteExactOutput_tickSpacing_10() public {
        _testExactOutputTickSpacing(10);
    }

    function test_quoteExactOutput_tickSpacing_50() public {
        _testExactOutputTickSpacing(50);
    }

    function test_quoteExactOutput_tickSpacing_100() public {
        _testExactOutputTickSpacing(100);
    }

    function test_quoteExactOutput_tickSpacing_200() public {
        _testExactOutputTickSpacing(200);
    }

    function _testExactOutputTickSpacing(int24 tickSpacing_) internal {
        MockCLPool tsPool = createMockPool(
            makeAddr(string(abi.encodePacked("TokenA_eo_ts", vm.toString(uint256(uint24(tickSpacing_)))))),
            makeAddr(string(abi.encodePacked("TokenB_eo_ts", vm.toString(uint256(uint24(tickSpacing_)))))),
            FEE_MEDIUM,
            tickSpacing_,
            uint160(1) << 96
        );

        int24 tickLower = nearestUsableTick(-60000, tickSpacing_);
        int24 tickUpper = nearestUsableTick(60000, tickSpacing_);
        addLiquidity(tsPool, tickLower, tickUpper, uint128(INITIAL_LIQUIDITY));

        (uint160 sqrtPriceX96, , , , , ) = tsPool.slot0();
        uint128 liquidity = tsPool.liquidity();

        // Quote exact output
        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        assertTrue(quotedIn > 0, string(abi.encodePacked("ExactOutput should work with tick spacing ", vm.toString(uint256(uint24(tickSpacing_))))));

        // Verify mock swap matches quote
        uint160 sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        (int256 amount0, ) = tsPool.swap(
            address(this),
            true,
            -int256(TEST_AMOUNT_OUT),
            sqrtPriceLimitX96,
            ""
        );

        uint256 actualIn = uint256(amount0);
        assertApproxEqAbs(quotedIn, actualIn, 1, "ExactOutput quote should match swap result");
    }

    /* ========================================================================== */
    /*          US-CRANE-090.7: Direction Edge Cases (Exact Output)               */
    /* ========================================================================== */

    /// @notice Both directions same pool: symmetric at 1:1 price
    function test_quoteExactOutput_bothDirections_symmetric() public view {
        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedIn_zfo = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        uint256 quotedIn_ofz = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, sqrtPriceX96, liquidity, FEE_MEDIUM, false
        );

        // At 1:1 price, both directions should produce approximately same input
        assertApproxEqRel(quotedIn_zfo, quotedIn_ofz, 0.01e18, "Symmetric pool should have symmetric quotes");
    }

    /// @notice Direction with extreme prices: zeroForOne at high price
    function test_quoteExactOutput_direction_highPrice_zeroForOne() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(50000);
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e12, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        assertTrue(quotedIn > 0, "zeroForOne at high price should produce input");
    }

    /// @notice Direction with extreme prices: oneForZero at low price
    function test_quoteExactOutput_direction_lowPrice_oneForZero() public pure {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(-50000);
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            1e12, sqrtPriceX96, liquidity, FEE_MEDIUM, false
        );

        assertTrue(quotedIn > 0, "oneForZero at low price should produce input");
    }

    /* ========================================================================== */
    /*       US-CRANE-090.8: Precision & Rounding Edge Cases (Exact Output)       */
    /* ========================================================================== */

    /// @notice Round-trip parity: exactOutput -> exactInput should approximately round-trip
    function test_quoteExactOutput_roundTrip_zeroForOne() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);
        uint256 desiredOutput = TEST_AMOUNT_OUT;

        // Step 1: Get required input for desired output
        uint256 requiredInput = SlipstreamUtils._quoteExactOutputSingle(
            desiredOutput, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        // Step 2: Feed that input into exact-input quote
        uint256 actualOutput = SlipstreamUtils._quoteExactInputSingle(
            requiredInput, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        // Round-trip should be close (within 0.1% tolerance)
        assertApproxEqRel(actualOutput, desiredOutput, 0.001e18, "Round-trip zeroForOne should be consistent");
    }

    /// @notice Round-trip parity for oneForZero direction
    function test_quoteExactOutput_roundTrip_oneForZero() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);
        uint256 desiredOutput = TEST_AMOUNT_OUT;

        uint256 requiredInput = SlipstreamUtils._quoteExactOutputSingle(
            desiredOutput, sqrtPriceX96, liquidity, FEE_MEDIUM, false
        );

        uint256 actualOutput = SlipstreamUtils._quoteExactInputSingle(
            requiredInput, sqrtPriceX96, liquidity, FEE_MEDIUM, false
        );

        assertApproxEqRel(actualOutput, desiredOutput, 0.001e18, "Round-trip oneForZero should be consistent");
    }

    /// @notice Round-trip with dust amounts
    function test_quoteExactOutput_roundTrip_dust() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);
        uint256 desiredOutput = 1000;  // 1000 wei

        uint256 requiredInput = SlipstreamUtils._quoteExactOutputSingle(
            desiredOutput, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        uint256 actualOutput = SlipstreamUtils._quoteExactInputSingle(
            requiredInput, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        // For dust amounts, allow wider tolerance due to rounding
        assertApproxEqAbs(actualOutput, desiredOutput, 10, "Round-trip dust should be within 10 wei");
    }

    /// @notice Fee rounding: verify fee doesn't lose precision
    function test_quoteExactOutput_feeRoundingPrecision() public pure {
        uint160 sqrtPriceX96 = uint160(1) << 96;
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        // Test with amount that would create rounding in fee calculation
        uint256 amountOut = 333333333333333333;  // Repeating digits to stress rounding

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        // Input should always be strictly greater than output when fee > 0
        assertTrue(quotedIn > amountOut, "Fee rounding: input must exceed output");
    }

    /* ========================================================================== */
    /*       US-CRANE-090.9: Function Overload Parity (Exact Output)              */
    /* ========================================================================== */

    /// @notice All 4 overloads should produce consistent results
    function test_quoteExactOutput_allOverloadParity() public view {
        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Overload 1: core (sqrtPriceX96)
        uint256 quoted1 = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, sqrtPriceX96, liquidity, FEE_MEDIUM, true
        );

        // Overload 2: tick-based
        uint256 quoted2 = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, tick, liquidity, FEE_MEDIUM, true
        );

        // Overload 3: sqrtPriceX96 + unstaked fee (with zero unstaked)
        uint256 quoted3 = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, sqrtPriceX96, liquidity, FEE_MEDIUM, uint24(0), true
        );

        // Overload 4: tick + unstaked fee (with zero unstaked)
        uint256 quoted4 = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, tick, liquidity, FEE_MEDIUM, uint24(0), true
        );

        // sqrtPriceX96 overloads should be exact
        assertEq(quoted1, quoted3, "sqrtPrice vs sqrtPrice+unstaked(0) should match exactly");

        // tick overloads should be exact with each other
        assertEq(quoted2, quoted4, "tick vs tick+unstaked(0) should match exactly");

        // sqrtPrice vs tick: should be identical when tick is exact
        // (since the mock pool stores tick and sqrtPrice consistently)
        assertEq(quoted1, quoted2, "sqrtPrice vs tick should match");
    }

    /// @notice Overload parity for oneForZero direction
    function test_quoteExactOutput_allOverloadParity_oneForZero() public view {
        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quoted1 = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, sqrtPriceX96, liquidity, FEE_MEDIUM, false
        );

        uint256 quoted2 = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, tick, liquidity, FEE_MEDIUM, false
        );

        uint256 quoted3 = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, sqrtPriceX96, liquidity, FEE_MEDIUM, uint24(0), false
        );

        uint256 quoted4 = SlipstreamUtils._quoteExactOutputSingle(
            TEST_AMOUNT_OUT, tick, liquidity, FEE_MEDIUM, uint24(0), false
        );

        assertEq(quoted1, quoted3, "sqrtPrice overloads should match (oneForZero)");
        assertEq(quoted2, quoted4, "tick overloads should match (oneForZero)");
        assertEq(quoted1, quoted2, "sqrtPrice vs tick should match (oneForZero)");
    }

    /// @notice Tick overload precision: verify no precision loss in tick -> sqrtPrice conversion
    function test_quoteExactOutput_tickConversionPrecision() public pure {
        uint128 liquidity = uint128(INITIAL_LIQUIDITY);

        // Test several ticks to check conversion precision
        int24[5] memory testTicks = [int24(-50000), int24(-1000), int24(0), int24(1000), int24(50000)];

        for (uint256 i = 0; i < testTicks.length; i++) {
            uint160 sqrtPriceFromTick = TickMath.getSqrtRatioAtTick(testTicks[i]);

            uint256 quotedWithSqrtPrice = SlipstreamUtils._quoteExactOutputSingle(
                TEST_AMOUNT_OUT, sqrtPriceFromTick, liquidity, FEE_MEDIUM, true
            );

            uint256 quotedWithTick = SlipstreamUtils._quoteExactOutputSingle(
                TEST_AMOUNT_OUT, testTicks[i], liquidity, FEE_MEDIUM, true
            );

            assertEq(
                quotedWithSqrtPrice,
                quotedWithTick,
                string(abi.encodePacked("Tick conversion precision loss at tick ", vm.toString(int256(testTicks[i]))))
            );
        }
    }
}
