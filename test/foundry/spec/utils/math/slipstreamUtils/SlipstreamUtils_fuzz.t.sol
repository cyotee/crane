// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// ═══════════════════════════════════════════════════════════════════════════
// TEST REPRODUCTION
// ═══════════════════════════════════════════════════════════════════════════
// Run all fuzz tests in this file (11 tests):
//   forge test --match-path test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_fuzz.t.sol -vvv
//
// Run all Slipstream fuzz tests (both files, 20 tests):
//   forge test --match-path "test/foundry/spec/utils/math/slipstreamUtils/*_fuzz.t.sol" -vvv
//
// Run specific test with more fuzz runs (default: 256):
//   forge test --match-test testFuzz_quoteExactInput_zeroForOne_matchesSwap --fuzz-runs 1000 -vvv
// ═══════════════════════════════════════════════════════════════════════════

import "forge-std/Test.sol";

import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/// @title Fuzz Tests for SlipstreamUtils Quote Functions
/// @notice Validates quote correctness across arbitrary inputs via fuzzing
/// @dev SlipstreamUtils assumes swaps stay within a single tick, so tests use very high liquidity
///      and moderate swap amounts to ensure single-tick operation
contract SlipstreamUtils_fuzz_Test is TestBase_Slipstream {
    using SlipstreamUtils for *;

    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev High minimum liquidity to ensure swaps stay within single tick
    /// @notice Increased from 1e24 to 1e27 based on single-tick guard findings
    uint128 constant MIN_LIQUIDITY = 1e27;

    /// @dev Maximum liquidity
    uint128 constant MAX_LIQUIDITY = 1e30;

    /// @dev Minimum amount to swap (avoid dust)
    uint256 constant MIN_AMOUNT = 1e15;

    /// @dev Maximum amount - must be small relative to liquidity to stay in single tick
    /// @notice Reduced from 1e21 to 1e18 based on single-tick guard findings
    uint256 constant MAX_AMOUNT = 1e18;

    /// @dev Safe tick range to avoid extreme price calculations
    int24 constant SAFE_TICK_MIN = -100000;
    int24 constant SAFE_TICK_MAX = 100000;

    /* -------------------------------------------------------------------------- */
    /*                       Fuzz: quoteExactInputSingle                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Fuzz test: exact input quote matches mock swap (zeroForOne)
    /// @dev Single-tick operation guaranteed by high liquidity relative to swap amount
    function testFuzz_quoteExactInput_zeroForOne_matchesSwap(
        uint256 amountIn,
        int24 tick,
        uint128 liquidity
    ) public {
        // Bound inputs
        amountIn = bound(amountIn, MIN_AMOUNT, MAX_AMOUNT);
        tick = int24(bound(int256(tick), SAFE_TICK_MIN, SAFE_TICK_MAX));
        liquidity = uint128(bound(liquidity, MIN_LIQUIDITY, MAX_LIQUIDITY));

        // Create pool at the specified tick
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        MockCLPool pool = _createPoolWithState(sqrtPriceX96, tick, liquidity);

        // Get quote from SlipstreamUtils
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true  // zeroForOne
        );

        // Execute mock swap
        uint160 sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        (, int256 amount1) = pool.swap(
            address(this),
            true,
            int256(amountIn),
            sqrtPriceLimitX96,
            ""
        );

        // Single-tick guard: verify swap didn't cross ticks
        _assertSingleTickSwap(pool, tick, "quoteExactInput zeroForOne");

        uint256 actualOut = uint256(-amount1);

        // Quote should match actual within 1 wei tolerance
        assertApproxEqAbs(quotedOut, actualOut, 1, "Quote mismatch for zeroForOne");
    }

    /// @notice Fuzz test: exact input quote matches mock swap (oneForZero)
    function testFuzz_quoteExactInput_oneForZero_matchesSwap(
        uint256 amountIn,
        int24 tick,
        uint128 liquidity
    ) public {
        // Bound inputs
        amountIn = bound(amountIn, MIN_AMOUNT, MAX_AMOUNT);
        tick = int24(bound(int256(tick), SAFE_TICK_MIN, SAFE_TICK_MAX));
        liquidity = uint128(bound(liquidity, MIN_LIQUIDITY, MAX_LIQUIDITY));

        // Create pool at the specified tick
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        MockCLPool pool = _createPoolWithState(sqrtPriceX96, tick, liquidity);

        // Get quote from SlipstreamUtils
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            false  // oneForZero
        );

        // Execute mock swap
        uint160 sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
        (int256 amount0, ) = pool.swap(
            address(this),
            false,
            int256(amountIn),
            sqrtPriceLimitX96,
            ""
        );

        // Single-tick guard: verify swap didn't cross ticks
        _assertSingleTickSwap(pool, tick, "quoteExactInput oneForZero");

        uint256 actualOut = uint256(-amount0);

        // Quote should match actual within 1 wei tolerance
        assertApproxEqAbs(quotedOut, actualOut, 1, "Quote mismatch for oneForZero");
    }

    /// @notice Fuzz test: exact input quote with tick overload matches sqrtPrice version
    function testFuzz_quoteExactInput_tickOverload_matchesSqrtPriceVersion(
        uint256 amountIn,
        int24 tick,
        uint128 liquidity,
        bool zeroForOne
    ) public pure {
        // Bound inputs
        amountIn = bound(amountIn, MIN_AMOUNT, MAX_AMOUNT);
        tick = int24(bound(int256(tick), SAFE_TICK_MIN, SAFE_TICK_MAX));
        liquidity = uint128(bound(liquidity, MIN_LIQUIDITY, MAX_LIQUIDITY));

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        // Quote using sqrtPriceX96
        uint256 quotedWithSqrtPrice = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        // Quote using tick
        uint256 quotedWithTick = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            tick,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        // Both versions should produce identical results
        assertEq(quotedWithSqrtPrice, quotedWithTick, "Tick overload should match sqrtPrice version");
    }

    /// @notice Fuzz test: exact input across all fee tiers
    function testFuzz_quoteExactInput_allFeeTiers(
        uint256 amountIn,
        int24 tick,
        uint128 liquidity,
        uint8 feeIndex,
        bool zeroForOne
    ) public {
        // Bound inputs
        amountIn = bound(amountIn, MIN_AMOUNT, MAX_AMOUNT);
        tick = int24(bound(int256(tick), SAFE_TICK_MIN, SAFE_TICK_MAX));
        liquidity = uint128(bound(liquidity, MIN_LIQUIDITY, MAX_LIQUIDITY));
        feeIndex = uint8(bound(feeIndex, 0, 2));

        uint24[3] memory fees = [FEE_LOW, FEE_MEDIUM, FEE_HIGH];
        uint24 fee = fees[feeIndex];

        // Create pool and execute test
        _testFeeTier(amountIn, tick, liquidity, fee, zeroForOne);
    }

    /// @notice Internal helper to test fee tier - reduces stack depth
    function _testFeeTier(
        uint256 amountIn,
        int24 tick,
        uint128 liquidity,
        uint24 fee,
        bool zeroForOne
    ) internal {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        MockCLPool pool = _createPoolWithState(sqrtPriceX96, tick, liquidity, fee);

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn, sqrtPriceX96, liquidity, fee, zeroForOne
        );

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_RATIO + 1
            : TickMath.MAX_SQRT_RATIO - 1;

        (int256 amount0, int256 amount1) = pool.swap(
            address(this), zeroForOne, int256(amountIn), sqrtPriceLimitX96, ""
        );

        // Single-tick guard: verify swap didn't cross ticks
        _assertSingleTickSwap(pool, tick, "quoteExactInput allFeeTiers");

        uint256 actualOut = zeroForOne ? uint256(-amount1) : uint256(-amount0);
        assertApproxEqAbs(quotedOut, actualOut, 1, "Quote mismatch for fee tier");
    }

    /* -------------------------------------------------------------------------- */
    /*                       Fuzz: quoteExactOutputSingle                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Fuzz test: exact output quote matches mock swap (zeroForOne)
    /// @dev Uses smaller amounts to ensure single-tick operation
    function testFuzz_quoteExactOutput_zeroForOne_matchesSwap(
        uint256 amountOut,
        int24 tick,
        uint128 liquidity
    ) public {
        // Bound inputs - keep amounts small relative to liquidity
        tick = int24(bound(int256(tick), SAFE_TICK_MIN, SAFE_TICK_MAX));
        liquidity = uint128(bound(liquidity, MIN_LIQUIDITY, MAX_LIQUIDITY));
        // Limit output to tiny fraction of liquidity to stay within single tick
        // Cap at MAX_AMOUNT to ensure single-tick operation
        uint256 maxAmountOut = liquidity / 10000;
        if (maxAmountOut > MAX_AMOUNT) maxAmountOut = MAX_AMOUNT;
        amountOut = bound(amountOut, MIN_AMOUNT, maxAmountOut);

        // Create pool
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        MockCLPool pool = _createPoolWithState(sqrtPriceX96, tick, liquidity);

        // Get quote
        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true  // zeroForOne
        );

        // Execute mock swap with exact output
        uint160 sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        (int256 amount0, int256 amount1) = pool.swap(
            address(this),
            true,
            -int256(amountOut),  // Negative for exact output
            sqrtPriceLimitX96,
            ""
        );

        // Single-tick guard: verify swap didn't cross ticks
        _assertSingleTickSwap(pool, tick, "quoteExactOutput zeroForOne");

        uint256 actualIn = uint256(amount0);
        uint256 actualOut = uint256(-amount1);

        // Verify output matches requested (within rounding)
        assertApproxEqAbs(actualOut, amountOut, 1, "Mock did not fill requested output");
        // Verify quote matches actual input
        assertApproxEqAbs(quotedIn, actualIn, 1, "Quote mismatch for zeroForOne exact output");
    }

    /// @notice Fuzz test: exact output quote matches mock swap (oneForZero)
    function testFuzz_quoteExactOutput_oneForZero_matchesSwap(
        uint256 amountOut,
        int24 tick,
        uint128 liquidity
    ) public {
        // Bound inputs
        tick = int24(bound(int256(tick), SAFE_TICK_MIN, SAFE_TICK_MAX));
        liquidity = uint128(bound(liquidity, MIN_LIQUIDITY, MAX_LIQUIDITY));
        // Cap at MAX_AMOUNT to ensure single-tick operation
        uint256 maxAmountOut = liquidity / 10000;
        if (maxAmountOut > MAX_AMOUNT) maxAmountOut = MAX_AMOUNT;
        amountOut = bound(amountOut, MIN_AMOUNT, maxAmountOut);

        // Create pool
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        MockCLPool pool = _createPoolWithState(sqrtPriceX96, tick, liquidity);

        // Get quote
        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            false  // oneForZero
        );

        // Execute mock swap with exact output
        uint160 sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
        (int256 amount0, int256 amount1) = pool.swap(
            address(this),
            false,
            -int256(amountOut),
            sqrtPriceLimitX96,
            ""
        );

        // Single-tick guard: verify swap didn't cross ticks
        _assertSingleTickSwap(pool, tick, "quoteExactOutput oneForZero");

        uint256 actualIn = uint256(amount1);
        uint256 actualOut = uint256(-amount0);

        // Verify
        assertApproxEqAbs(actualOut, amountOut, 1, "Mock did not fill requested output");
        assertApproxEqAbs(quotedIn, actualIn, 1, "Quote mismatch for oneForZero exact output");
    }

    /// @notice Fuzz test: exact output tick overload matches sqrtPrice version
    function testFuzz_quoteExactOutput_tickOverload_matchesSqrtPriceVersion(
        uint256 amountOut,
        int24 tick,
        uint128 liquidity,
        bool zeroForOne
    ) public pure {
        // Bound inputs
        tick = int24(bound(int256(tick), SAFE_TICK_MIN, SAFE_TICK_MAX));
        liquidity = uint128(bound(liquidity, MIN_LIQUIDITY, MAX_LIQUIDITY));
        amountOut = bound(amountOut, MIN_AMOUNT, liquidity / 10000);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        // Quote using sqrtPriceX96
        uint256 quotedWithSqrtPrice = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        // Quote using tick
        uint256 quotedWithTick = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            tick,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        // Both versions should produce identical results
        assertEq(quotedWithSqrtPrice, quotedWithTick, "Tick overload should match sqrtPrice version");
    }

    /* -------------------------------------------------------------------------- */
    /*                       Fuzz: Roundtrip Consistency                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Fuzz test: quoteExactInput(quoteExactOutput(x)) ≈ x roundtrip
    /// @dev Verifies that quoting exact output, then quoting exact input with that result
    ///      gives back approximately the original amount
    function testFuzz_roundtrip_quoteExactOutput_then_quoteExactInput(
        uint256 amountOut,
        int24 tick,
        uint128 liquidity,
        bool zeroForOne
    ) public pure {
        // Bound inputs - use very small amounts for stable roundtrip
        tick = int24(bound(int256(tick), SAFE_TICK_MIN, SAFE_TICK_MAX));
        liquidity = uint128(bound(liquidity, MIN_LIQUIDITY, MAX_LIQUIDITY));
        amountOut = bound(amountOut, MIN_AMOUNT, liquidity / 100000);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        // Step 1: Get input required for desired output
        uint256 requiredInput = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        // Step 2: Quote output for the required input
        uint256 resultingOutput = SlipstreamUtils._quoteExactInputSingle(
            requiredInput,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        // The resulting output should be >= the original amountOut (due to fee rounding in our favor)
        assertTrue(
            resultingOutput >= amountOut - 1,  // Allow 1 wei tolerance
            "Roundtrip: output should be >= original amountOut"
        );

        // The resulting output should not be significantly more than requested
        // Due to double fee application, allow up to ~1% tolerance
        uint256 tolerance = (amountOut * 20) / 1000 + 2;  // 2% + 2 wei
        assertTrue(
            resultingOutput <= amountOut + tolerance,
            "Roundtrip: output should not significantly exceed requested"
        );
    }

    /// @notice Fuzz test: Higher fees always require more input for same output
    function testFuzz_higherFee_requiresMoreInput(
        uint256 amountOut,
        int24 tick,
        uint128 liquidity,
        bool zeroForOne
    ) public pure {
        // Bound inputs - use moderate amounts
        tick = int24(bound(int256(tick), SAFE_TICK_MIN, SAFE_TICK_MAX));
        liquidity = uint128(bound(liquidity, MIN_LIQUIDITY, MAX_LIQUIDITY));
        amountOut = bound(amountOut, MIN_AMOUNT, liquidity / 10000);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        // Quote with low fee
        uint256 inputLowFee = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_LOW,
            zeroForOne
        );

        // Quote with high fee
        uint256 inputHighFee = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_HIGH,
            zeroForOne
        );

        // Higher fee should require more input (or equal for very small amounts due to rounding)
        assertTrue(
            inputHighFee >= inputLowFee,
            "Higher fee should require at least as much input"
        );
    }

    /// @notice Fuzz test: Higher fees always give less output for same input
    function testFuzz_higherFee_givesLessOutput(
        uint256 amountIn,
        int24 tick,
        uint128 liquidity,
        bool zeroForOne
    ) public pure {
        // Bound inputs
        amountIn = bound(amountIn, MIN_AMOUNT, MAX_AMOUNT);
        tick = int24(bound(int256(tick), SAFE_TICK_MIN, SAFE_TICK_MAX));
        liquidity = uint128(bound(liquidity, MIN_LIQUIDITY, MAX_LIQUIDITY));

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        // Quote with low fee
        uint256 outputLowFee = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_LOW,
            zeroForOne
        );

        // Quote with high fee
        uint256 outputHighFee = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_HIGH,
            zeroForOne
        );

        // Higher fee should give less output (or equal for very small amounts)
        assertTrue(
            outputLowFee >= outputHighFee,
            "Lower fee should give at least as much output"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                       Fuzz: Liquidity/Amount Helpers                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Fuzz test: quoteLiquidityForAmounts/quoteAmountsForLiquidity roundtrip
    function testFuzz_liquidityAmounts_roundtrip(
        int24 tick,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) public pure {
        // Bound ticks - ensure valid ordering with reasonable spacing
        tick = int24(bound(int256(tick), SAFE_TICK_MIN + 1000, SAFE_TICK_MAX - 1000));
        tickLower = int24(bound(int256(tickLower), SAFE_TICK_MIN, tick - 100));
        tickUpper = int24(bound(int256(tickUpper), tick + 100, SAFE_TICK_MAX));

        // Bound amounts
        amount0 = bound(amount0, 1e15, 1e24);
        amount1 = bound(amount1, 1e15, 1e24);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        // Step 1: Get liquidity for the given amounts
        uint128 liquidity = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        // Step 2: Get amounts for that liquidity
        (uint256 resultAmount0, uint256 resultAmount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        // Result amounts should be <= original amounts (liquidity is limited by smaller contribution)
        assertTrue(resultAmount0 <= amount0, "Result amount0 should not exceed original");
        assertTrue(resultAmount1 <= amount1, "Result amount1 should not exceed original");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Internal Helpers                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Create a mock pool with specified state
    function _createPoolWithState(
        uint160 sqrtPriceX96,
        int24 tick,
        uint128 liquidity
    ) internal returns (MockCLPool pool) {
        return _createPoolWithState(sqrtPriceX96, tick, liquidity, FEE_MEDIUM);
    }

    /// @notice Create a mock pool with specified state and fee
    function _createPoolWithState(
        uint160 sqrtPriceX96,
        int24 tick,
        uint128 liquidity,
        uint24 fee
    ) internal returns (MockCLPool pool) {
        address tokenA = makeAddr(string(abi.encodePacked("TokenA_", vm.toString(block.timestamp))));
        address tokenB = makeAddr(string(abi.encodePacked("TokenB_", vm.toString(block.timestamp))));

        int24 tickSpacing = getTickSpacing(fee);
        pool = createMockPool(tokenA, tokenB, fee, tickSpacing, sqrtPriceX96);

        // Set state directly using the mock helper
        pool.setState(sqrtPriceX96, tick, liquidity);
    }

    /* -------------------------------------------------------------------------- */
    /*                        Single-Tick Guard Assertion                         */
    /* -------------------------------------------------------------------------- */

    /// @dev Maximum allowed tick movement during a swap
    /// @notice A movement of ±1 tick is acceptable due to rounding at tick boundaries
    int24 constant MAX_TICK_MOVEMENT = 1;

    /// @notice Assert that a swap stayed within acceptable tick range
    /// @dev SlipstreamUtils quotes assume near single-tick operation. This guard makes
    ///      test failures easier to diagnose by explicitly checking this invariant.
    ///      We allow ±1 tick movement to account for rounding at tick boundaries.
    /// @param pool The pool to check
    /// @param tickBefore The tick before the swap
    /// @param context Description of which test/swap this is for error messages
    function _assertSingleTickSwap(
        MockCLPool pool,
        int24 tickBefore,
        string memory context
    ) internal view {
        (, int24 tickAfter,,,,) = pool.slot0();

        int24 tickDelta = tickAfter > tickBefore
            ? tickAfter - tickBefore
            : tickBefore - tickAfter;

        assertTrue(
            tickDelta <= MAX_TICK_MOVEMENT,
            string(abi.encodePacked(
                "Single-tick invariant violated: ",
                context,
                " - tick moved by ",
                vm.toString(int256(tickDelta)),
                " (from ",
                vm.toString(tickBefore),
                " to ",
                vm.toString(tickAfter),
                "). Max allowed: ",
                vm.toString(int256(MAX_TICK_MOVEMENT)),
                ". Quote accuracy depends on near single-tick operation. ",
                "Consider increasing MIN_LIQUIDITY or reducing MAX_AMOUNT."
            ))
        );
    }
}
