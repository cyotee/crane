// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SlipstreamQuoter} from "@crane/contracts/utils/math/SlipstreamQuoter.sol";
import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";
import {SqrtPriceMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/SqrtPriceMath.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/// @title Test SlipstreamQuoter tick crossing
/// @notice Validates Slipstream quoter with tick-crossing swaps
contract SlipstreamQuoter_tickCrossing_Test is TestBase_Slipstream {
    using SlipstreamQuoter for SlipstreamQuoter.SwapQuoteParams;

    MockCLPool pool;
    address tokenA;
    address tokenB;

    uint128 constant LIQUIDITY_PER_RANGE = 100_000e18;

    function setUp() public override {
        super.setUp();

        tokenA = makeAddr("TokenA");
        tokenB = makeAddr("TokenB");

        // Create pool at 1:1 price
        pool = createMockPoolOneToOne(tokenA, tokenB, FEE_MEDIUM, TICK_SPACING_MEDIUM);

        // Add liquidity in multiple, adjacent ranges so swaps can cross multiple initialized ticks.
        // Start tick is ~0, so only the [-5000, 5000) range is active initially.
        addLiquidity(
            pool,
            nearestUsableTick(-5000, TICK_SPACING_MEDIUM),
            nearestUsableTick(5000, TICK_SPACING_MEDIUM),
            LIQUIDITY_PER_RANGE
        );
        addLiquidity(
            pool,
            nearestUsableTick(-10000, TICK_SPACING_MEDIUM),
            nearestUsableTick(-5000, TICK_SPACING_MEDIUM),
            LIQUIDITY_PER_RANGE / 2
        );
        addLiquidity(
            pool,
            nearestUsableTick(5000, TICK_SPACING_MEDIUM),
            nearestUsableTick(10000, TICK_SPACING_MEDIUM),
            LIQUIDITY_PER_RANGE / 3
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Basic Quote Tests                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactInput basic functionality
    function test_quoteExactInput_basic() public view {
        uint256 amountIn = 1e18;

        SlipstreamQuoter.SwapQuoteParams memory params = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0  // unlimited
        });

        SlipstreamQuoter.SwapQuoteResult memory result = SlipstreamQuoter.quoteExactInput(params);

        assertTrue(result.amountIn > 0, "amountIn should be positive");
        assertTrue(result.amountOut > 0, "amountOut should be positive");
        assertTrue(result.fullyFilled, "Should be fully filled");
    }

    /// @notice Test quoteExactOutput basic functionality
    function test_quoteExactOutput_basic() public view {
        uint256 amountOut = 1e18;

        SlipstreamQuoter.SwapQuoteParams memory params = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: amountOut,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        SlipstreamQuoter.SwapQuoteResult memory result = SlipstreamQuoter.quoteExactOutput(params);

        assertTrue(result.amountIn > 0, "amountIn should be positive");
        assertTrue(result.amountOut > 0, "amountOut should be positive");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Swap Direction Tests                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote for zeroForOne direction
    function test_quoteExactInput_zeroForOne() public view {
        uint256 amountIn = 1e18;

        SlipstreamQuoter.SwapQuoteParams memory params = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        SlipstreamQuoter.SwapQuoteResult memory result = SlipstreamQuoter.quoteExactInput(params);

        // Price should decrease for zeroForOne (selling token0)
        (uint160 initialPrice, , , , , ) = pool.slot0();
        assertTrue(result.sqrtPriceAfterX96 <= initialPrice, "Price should decrease for zeroForOne");
    }

    /// @notice Test quote for oneForZero direction
    function test_quoteExactInput_oneForZero() public view {
        uint256 amountIn = 1e18;

        SlipstreamQuoter.SwapQuoteParams memory params = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: false,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MAX_SQRT_RATIO - 1,
            maxSteps: 0
        });

        SlipstreamQuoter.SwapQuoteResult memory result = SlipstreamQuoter.quoteExactInput(params);

        // Price should increase for oneForZero (selling token1)
        (uint160 initialPrice, , , , , ) = pool.slot0();
        assertTrue(result.sqrtPriceAfterX96 >= initialPrice, "Price should increase for oneForZero");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Fee Amount Tests                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that fee amount is correctly calculated
    function test_quoteExactInput_feeAmountCorrect() public view {
        uint256 amountIn = 1000e18;

        SlipstreamQuoter.SwapQuoteParams memory params = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        SlipstreamQuoter.SwapQuoteResult memory result = SlipstreamQuoter.quoteExactInput(params);

        // Fee should be approximately 0.3% of amountIn
        uint256 expectedFeeApprox = (amountIn * FEE_MEDIUM) / 1e6;
        assertApproxEqRel(result.feeAmount, expectedFeeApprox, 0.1e18, "Fee should be ~0.3%");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Max Steps Tests                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Test maxSteps limits iterations
    function test_quoteExactInput_maxStepsLimit() public view {
        // Pick an amount that is guaranteed to reach the next initialized tick at -5000.
        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();
        uint160 sqrtPriceAtMinus5000 = TickMath.getSqrtRatioAtTick(nearestUsableTick(-5000, TICK_SPACING_MEDIUM));
        uint128 activeLiquidity = pool.liquidity();

        // amount0 required (pre-fee) to move price from current -> -5000
        uint256 amountInToCross = SqrtPriceMath.getAmount0Delta(sqrtPriceAtMinus5000, sqrtPriceX96, activeLiquidity, true);
        uint256 amountIn = amountInToCross * 3;

        SlipstreamQuoter.SwapQuoteParams memory unlimitedParams = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        SlipstreamQuoter.SwapQuoteResult memory unlimitedResult = SlipstreamQuoter.quoteExactInput(unlimitedParams);
        assertTrue(unlimitedResult.steps > 1, "Setup should require multiple steps");

        SlipstreamQuoter.SwapQuoteParams memory limitedParams = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 1
        });

        SlipstreamQuoter.SwapQuoteResult memory limitedResult = SlipstreamQuoter.quoteExactInput(limitedParams);
        assertEq(limitedResult.steps, 1, "Should only take 1 step");
        assertTrue(!limitedResult.fullyFilled, "Limited should stop early");
        assertTrue(limitedResult.amountOut < unlimitedResult.amountOut, "Limited should output less");
        assertTrue(limitedResult.steps < unlimitedResult.steps, "Unlimited should take more steps");
    }

    function test_quoteExactInput_multiStep_happensInPractice() public view {
        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();
        uint160 sqrtPriceAtMinus5000 = TickMath.getSqrtRatioAtTick(nearestUsableTick(-5000, TICK_SPACING_MEDIUM));
        uint128 activeLiquidity = pool.liquidity();

        uint256 amountInToCross = SqrtPriceMath.getAmount0Delta(sqrtPriceAtMinus5000, sqrtPriceX96, activeLiquidity, true);

        SlipstreamQuoter.SwapQuoteParams memory params = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: amountInToCross * 2,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        SlipstreamQuoter.SwapQuoteResult memory result = SlipstreamQuoter.quoteExactInput(params);
        assertTrue(result.steps > 1, "Expected to cross at least one initialized tick");
        assertTrue(result.sqrtPriceAfterX96 <= sqrtPriceAtMinus5000, "Expected price to reach <= -5000 boundary");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Edge Cases                                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote with zero amount
    function test_quoteExactInput_zeroAmount() public view {
        SlipstreamQuoter.SwapQuoteParams memory params = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: 0,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        SlipstreamQuoter.SwapQuoteResult memory result = SlipstreamQuoter.quoteExactInput(params);

        assertEq(result.amountIn, 0, "amountIn should be 0");
        assertEq(result.amountOut, 0, "amountOut should be 0");
        assertTrue(result.fullyFilled, "Zero amount should be considered filled");
    }

    /// @notice Test quote with dust amount
    function test_quoteExactInput_dustAmount() public view {
        SlipstreamQuoter.SwapQuoteParams memory params = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: 1,  // 1 wei
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        SlipstreamQuoter.SwapQuoteResult memory result = SlipstreamQuoter.quoteExactInput(params);

        assertTrue(result.amountIn <= 1, "amountIn should be <= 1 wei");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Price Limit Tests                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that price limit is respected
    function test_quoteExactInput_respectsPriceLimit() public view {
        uint256 amountIn = 100e18;

        // Get current price
        (uint160 currentPrice, , , , , ) = pool.slot0();

        // Set a tight price limit (only allow small price movement)
        uint160 sqrtPriceLimitX96 = currentPrice - (currentPrice / 100);  // 1% below current

        SlipstreamQuoter.SwapQuoteParams memory params = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: 0
        });

        SlipstreamQuoter.SwapQuoteResult memory result = SlipstreamQuoter.quoteExactInput(params);

        // Price should not go below limit
        assertTrue(result.sqrtPriceAfterX96 >= sqrtPriceLimitX96, "Price should not exceed limit");
    }

    /// @notice Test invalid price limit reverts
    function test_quoteExactInput_invalidPriceLimit_reverts() public view {
        (uint160 currentPrice, , , , , ) = pool.slot0();

        // For zeroForOne, limit must be below current price
        SlipstreamQuoter.SwapQuoteParams memory params = SlipstreamQuoter.SwapQuoteParams({
            pool: ICLPool(address(pool)),
            zeroForOne: true,
            amount: 1e18,
            sqrtPriceLimitX96: currentPrice + 1,  // Invalid: above current for zeroForOne
            maxSteps: 0
        });

        bool reverted = false;
        try this.helperQuoteExactInput(params) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        assertTrue(reverted, "Should revert for invalid price limit");
    }

    /// @notice External helper for testing revert
    function helperQuoteExactInput(SlipstreamQuoter.SwapQuoteParams memory params) external view {
        SlipstreamQuoter.quoteExactInput(params);
    }
}
