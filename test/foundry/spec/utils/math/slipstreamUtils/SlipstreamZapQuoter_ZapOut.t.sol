// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SlipstreamZapQuoter} from "@crane/contracts/utils/math/SlipstreamZapQuoter.sol";
import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/// @title Test SlipstreamZapQuoter Zap-Out functionality
/// @notice Validates burn + swap to single token quoting for Slipstream
contract SlipstreamZapQuoter_ZapOut_Test is TestBase_Slipstream {
    using SlipstreamZapQuoter for SlipstreamZapQuoter.ZapOutParams;

    MockCLPool pool;
    address tokenA;
    address tokenB;

    uint128 constant INITIAL_LIQUIDITY = 1_000_000e18;
    uint128 constant BURN_LIQUIDITY = 1_000e18;

    int24 tickLower;
    int24 tickUpper;

    function setUp() public override {
        super.setUp();

        tokenA = makeAddr("TokenA");
        tokenB = makeAddr("TokenB");

        // Create pool at 1:1 price
        pool = createMockPoolOneToOne(tokenA, tokenB, FEE_MEDIUM, TICK_SPACING_MEDIUM);

        // Define position range
        tickLower = nearestUsableTick(-5000, TICK_SPACING_MEDIUM);
        tickUpper = nearestUsableTick(5000, TICK_SPACING_MEDIUM);

        // Add initial liquidity
        addLiquidity(pool, tickLower, tickUpper, INITIAL_LIQUIDITY);
    }

    /* -------------------------------------------------------------------------- */
    /*                          Basic Zap-Out Tests                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Test basic zap-out to token0
    function test_zapOut_toToken0_basic() public {
        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: BURN_LIQUIDITY,
            wantToken0: true,  // Output is token0
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        SlipstreamZapQuoter.ZapOutQuote memory quote = SlipstreamZapQuoter.quoteZapOutSingleCore(params);

        // Validate quote structure
        assertTrue(quote.amountOut > 0, "Should have output");
        assertTrue(quote.burnAmount0 > 0 || quote.burnAmount1 > 0, "Should burn to get tokens");
    }

    /// @notice Test basic zap-out to token1
    function test_zapOut_toToken1_basic() public {
        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: BURN_LIQUIDITY,
            wantToken0: false,  // Output is token1
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        SlipstreamZapQuoter.ZapOutQuote memory quote = SlipstreamZapQuoter.quoteZapOutSingleCore(params);

        assertTrue(quote.amountOut > 0, "Should have output");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Output Validation Tests                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that zap-out output combines burn + swap
    function test_zapOut_outputCombinesBurnAndSwap() public {
        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: BURN_LIQUIDITY,
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        SlipstreamZapQuoter.ZapOutQuote memory quote = SlipstreamZapQuoter.quoteZapOutSingleCore(params);

        // Total output should be burn amount0 + swap output
        // swap converts burnAmount1 to token0
        uint256 expectedMinOutput = quote.burnAmount0;
        assertTrue(quote.amountOut >= expectedMinOutput, "Output should include burn amount");

        // If there was token1 to swap, output should be greater than just burn0
        if (quote.burnAmount1 > 0 && quote.swap.amountOut > 0) {
            assertTrue(quote.amountOut > quote.burnAmount0, "Output should include swap result");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                          Pool/Position Manager Tests                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteZapOutPool returns valid execution params
    function test_quoteZapOutPool() public {
        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: BURN_LIQUIDITY,
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        SlipstreamZapQuoter.PoolZapOutExecution memory exec = SlipstreamZapQuoter.quoteZapOutPool(params);

        assertEq(exec.tickLower, tickLower, "tickLower should match");
        assertEq(exec.tickUpper, tickUpper, "tickUpper should match");
        assertEq(exec.liquidity, BURN_LIQUIDITY, "liquidity should match");
        // For wantToken0=true, we swap token1->token0, so zeroForOne=false
        assertEq(exec.zeroForOne, false, "Direction should be oneForZero when wanting token0");
    }

    /// @notice Test quoteZapOutPositionManager returns valid execution params
    function test_quoteZapOutPositionManager() public {
        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: BURN_LIQUIDITY,
            wantToken0: false,  // Want token1
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        SlipstreamZapQuoter.PositionManagerZapOutExecution memory exec = SlipstreamZapQuoter.quoteZapOutPositionManager(params);

        assertEq(exec.tickLower, tickLower, "tickLower should match");
        assertEq(exec.tickUpper, tickUpper, "tickUpper should match");
        assertEq(exec.liquidity, BURN_LIQUIDITY, "liquidity should match");
        // For wantToken0=false (want token1), we swap token0->token1, so zeroForOne=true
        assertEq(exec.zeroForOne, true, "Direction should be zeroForOne when wanting token1");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Helper Function Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test createZapOutParams with token address
    function test_createZapOutParams() public {
        address token0 = pool.token0();
        address token1 = pool.token1();

        // Create params wanting token0 output
        SlipstreamZapQuoter.ZapOutParams memory params0 = SlipstreamZapQuoter.createZapOutParams(
            ICLPool(address(pool)),
            tickLower,
            tickUpper,
            BURN_LIQUIDITY,
            token0,  // Output token
            0,
            0
        );

        assertTrue(params0.wantToken0, "Should want token0");

        // Create params wanting token1 output
        SlipstreamZapQuoter.ZapOutParams memory params1 = SlipstreamZapQuoter.createZapOutParams(
            ICLPool(address(pool)),
            tickLower,
            tickUpper,
            BURN_LIQUIDITY,
            token1,  // Output token
            0,
            0
        );

        assertFalse(params1.wantToken0, "Should not want token0 (wants token1)");
    }

    /// @notice Test createZapOutParams with invalid token reverts
    function test_createZapOutParams_invalidToken_reverts() public {
        address invalidToken = makeAddr("InvalidToken");

        bool reverted = false;
        try this.helperCreateZapOutParams(invalidToken) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        assertTrue(reverted, "Should revert for invalid token");
    }

    /// @notice External helper for testing revert
    function helperCreateZapOutParams(address tokenOut) external view {
        SlipstreamZapQuoter.createZapOutParams(
            ICLPool(address(pool)),
            tickLower,
            tickUpper,
            BURN_LIQUIDITY,
            tokenOut,
            0,
            0
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Edge Cases                                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zap-out with zero liquidity reverts
    function test_zapOut_zeroLiquidity_reverts() public {
        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 0,
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        bool reverted = false;
        try this.helperQuoteZapOut(params) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        assertTrue(reverted, "Should revert for zero liquidity");
    }

    /// @notice Test zap-out with invalid tick range reverts
    function test_zapOut_invalidRange_reverts() public {
        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickUpper,  // Wrong order
            tickUpper: tickLower,
            liquidity: BURN_LIQUIDITY,
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        bool reverted = false;
        try this.helperQuoteZapOut(params) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        assertTrue(reverted, "Should revert for invalid range");
    }

    /// @notice External helper for testing revert
    function helperQuoteZapOut(SlipstreamZapQuoter.ZapOutParams memory params) external view {
        SlipstreamZapQuoter.quoteZapOutSingleCore(params);
    }

    /// @notice Test zap-out when already holding wanted token (no swap needed)
    function test_zapOut_noSwapNeeded() public {
        // At 1:1 price (tick=0), a position range ABOVE tick 0 contains only token0
        // Position [10000, 20000] is above current tick 0, so it contains only token0
        // (When current price is BELOW the position range, the position is "waiting to sell token0")
        int24 upperTickLower = nearestUsableTick(10000, TICK_SPACING_MEDIUM);
        int24 upperTickUpper = nearestUsableTick(20000, TICK_SPACING_MEDIUM);

        MockCLPool testPool = createMockPoolOneToOne(
            makeAddr("TokenC"),
            makeAddr("TokenD"),
            FEE_MEDIUM,
            TICK_SPACING_MEDIUM
        );
        addLiquidity(testPool, upperTickLower, upperTickUpper, BURN_LIQUIDITY);

        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(testPool)),
            tickLower: upperTickLower,
            tickUpper: upperTickUpper,
            liquidity: BURN_LIQUIDITY,
            wantToken0: true,  // Want token0 as output
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        SlipstreamZapQuoter.ZapOutQuote memory quote = SlipstreamZapQuoter.quoteZapOutSingleCore(params);

        // For a position ABOVE current price, burnAmount1 = 0 (only token0 in range)
        // So swapAmountIn (which is burnAmount1 when wantToken0=true) should be 0
        assertTrue(quote.amountOut > 0, "Should have output");
        assertEq(quote.burnAmount1, 0, "Position above current price should have no token1");
        assertEq(quote.swapAmountIn, 0, "No swap needed when burnAmount1 is 0");
        assertEq(quote.amountOut, quote.burnAmount0, "Output should equal burn amount");
    }

    /// @notice Test zap-out dust handling
    function test_zapOut_dustHandling() public {
        SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: BURN_LIQUIDITY,
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        SlipstreamZapQuoter.ZapOutQuote memory quote = SlipstreamZapQuoter.quoteZapOutSingleCore(params);

        // If swap was fully filled, dust should be 0
        if (quote.swap.fullyFilled) {
            assertEq(quote.dust, 0, "Dust should be 0 when fully filled");
        }
    }

    /// @notice Test zap-out with varying liquidity amounts
    function test_zapOut_varyingLiquidity() public {
        uint128[3] memory liquidityAmounts = [uint128(100e18), uint128(10_000e18), uint128(100_000e18)];

        for (uint256 i = 0; i < liquidityAmounts.length; i++) {
            SlipstreamZapQuoter.ZapOutParams memory params = SlipstreamZapQuoter.ZapOutParams({
                pool: ICLPool(address(pool)),
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidity: liquidityAmounts[i],
                wantToken0: true,
                sqrtPriceLimitX96: 0,
                maxSwapSteps: 0
            });

            SlipstreamZapQuoter.ZapOutQuote memory quote = SlipstreamZapQuoter.quoteZapOutSingleCore(params);

            assertTrue(quote.amountOut > 0, "Should have output for any valid liquidity");
        }
    }
}
