// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SlipstreamZapQuoter} from "@crane/contracts/utils/math/SlipstreamZapQuoter.sol";
import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TestBase_Slipstream, MockCLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_Slipstream.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";

/// @title Test SlipstreamZapQuoter Zap-In functionality
/// @notice Validates single-sided liquidity provision quoting for Slipstream
contract SlipstreamZapQuoter_ZapIn_Test is TestBase_Slipstream {
    using SlipstreamZapQuoter for SlipstreamZapQuoter.ZapInParams;

    MockCLPool pool;
    address tokenA;
    address tokenB;

    uint128 constant INITIAL_LIQUIDITY = 1_000_000e18;
    uint256 constant ZAP_AMOUNT = 10e18;

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
    /*                          Basic Zap-In Tests                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Test basic zap-in with token0
    function test_zapIn_token0_basic() public {
        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,  // Input is token0
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,  // Use default
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.ZapInQuote memory quote = SlipstreamZapQuoter.quoteZapInSingleCore(params);

        // Validate quote structure
        assertTrue(quote.liquidity > 0, "Should produce liquidity");
        assertTrue(quote.amount0 > 0 || quote.amount1 > 0, "Should have token amounts");
        assertTrue(quote.swapAmountIn < ZAP_AMOUNT, "Swap amount should be less than input");
    }

    /// @notice Test basic zap-in with token1
    function test_zapIn_token1_basic() public {
        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: false,  // Input is token1
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.ZapInQuote memory quote = SlipstreamZapQuoter.quoteZapInSingleCore(params);

        assertTrue(quote.liquidity > 0, "Should produce liquidity");
        assertTrue(quote.swapAmountIn < ZAP_AMOUNT, "Swap amount should be less than input");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Dust Minimization Tests                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that zap-in minimizes dust
    function test_zapIn_minimizesDust() public {
        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 24,  // More iterations for better optimization
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.ZapInQuote memory quote = SlipstreamZapQuoter.quoteZapInSingleCore(params);

        // Total dust should be small relative to input
        uint256 totalDust = quote.dust0 + quote.dust1;
        uint256 maxAcceptableDust = ZAP_AMOUNT / 100;  // 1% of input

        assertTrue(totalDust < maxAcceptableDust, "Dust should be minimal");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Pool/Position Manager Tests                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteZapInPool returns valid execution params
    function test_quoteZapInPool() public {
        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.PoolZapInExecution memory exec = SlipstreamZapQuoter.quoteZapInPool(params);

        assertEq(exec.zeroForOne, true, "Direction should match");
        assertEq(exec.tickLower, tickLower, "tickLower should match");
        assertEq(exec.tickUpper, tickUpper, "tickUpper should match");
        assertTrue(exec.liquidity > 0, "Should have liquidity");
    }

    /// @notice Test quoteZapInPositionManager returns valid execution params
    function test_quoteZapInPositionManager() public {
        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.PositionManagerZapInExecution memory exec = SlipstreamZapQuoter.quoteZapInPositionManager(params);

        assertEq(exec.zeroForOne, true, "Direction should match");
        assertEq(exec.tickLower, tickLower, "tickLower should match");
        assertEq(exec.tickUpper, tickUpper, "tickUpper should match");
        assertTrue(exec.amount0Desired > 0 || exec.amount1Desired > 0, "Should have desired amounts");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Helper Function Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test createZapInParams with token address
    function test_createZapInParams() public {
        address token0 = pool.token0();
        address token1 = pool.token1();

        // Create params with token0 as input
        SlipstreamZapQuoter.ZapInParams memory params0 = SlipstreamZapQuoter.createZapInParams(
            ICLPool(address(pool)),
            tickLower,
            tickUpper,
            token0,  // Input token
            ZAP_AMOUNT,
            0,
            0,
            20
        );

        assertTrue(params0.zeroForOne, "Should be zeroForOne when inputting token0");

        // Create params with token1 as input
        SlipstreamZapQuoter.ZapInParams memory params1 = SlipstreamZapQuoter.createZapInParams(
            ICLPool(address(pool)),
            tickLower,
            tickUpper,
            token1,  // Input token
            ZAP_AMOUNT,
            0,
            0,
            20
        );

        assertFalse(params1.zeroForOne, "Should not be zeroForOne when inputting token1");
    }

    /// @notice Test createZapInParams with invalid token reverts
    function test_createZapInParams_invalidToken_reverts() public {
        address invalidToken = makeAddr("InvalidToken");

        // Internal library functions can't be caught with vm.expectRevert
        // Use try-catch by wrapping in an external call
        bool reverted = false;
        try this.helperCreateZapInParams(invalidToken) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        assertTrue(reverted, "Should revert for invalid token");
    }

    /// @notice External helper for testing revert
    function helperCreateZapInParams(address tokenIn) external view {
        SlipstreamZapQuoter.createZapInParams(
            ICLPool(address(pool)),
            tickLower,
            tickUpper,
            tokenIn,
            ZAP_AMOUNT,
            0,
            0,
            20
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Edge Cases                                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zap-in with zero amount reverts
    function test_zapIn_zeroAmount_reverts() public {
        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: 0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: false
        });

        bool reverted = false;
        try this.helperQuoteZapIn(params) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        assertTrue(reverted, "Should revert for zero amount");
    }

    /// @notice Test zap-in with invalid tick range reverts
    function test_zapIn_invalidRange_reverts() public {
        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickUpper,  // Wrong order
            tickUpper: tickLower,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: false
        });

        bool reverted = false;
        try this.helperQuoteZapIn(params) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        assertTrue(reverted, "Should revert for invalid range");
    }

    /// @notice External helper for testing revert
    function helperQuoteZapIn(SlipstreamZapQuoter.ZapInParams memory params) external view {
        SlipstreamZapQuoter.quoteZapInSingleCore(params);
    }

    /// @notice Test zap-in with small amount
    function test_zapIn_smallAmount() public {
        uint256 smallAmount = 1000;  // Small amount

        SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: smallAmount,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: false
        });

        SlipstreamZapQuoter.ZapInQuote memory quote = SlipstreamZapQuoter.quoteZapInSingleCore(params);

        // Small amount might produce minimal or zero liquidity due to rounding
        // Just ensure it doesn't revert
        assertTrue(quote.swapAmountIn <= smallAmount, "Swap should not exceed input");
    }

    /* -------------------------------------------------------------------------- */
    /*                     Unstaked Fee Positive-Path Tests                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that includeUnstakedFee=true changes zap-in swap quote for token0 input
    function test_zapIn_unstakedFee_token0_reducesSwapOutput() public {
        uint24 unstakedFee = 500; // 0.05%
        pool.setUnstakedFee(unstakedFee);

        // Baseline: without unstaked fee
        SlipstreamZapQuoter.ZapInParams memory baseline = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: false
        });
        SlipstreamZapQuoter.ZapInQuote memory baseQuote = SlipstreamZapQuoter.quoteZapInSingleCore(baseline);

        // With unstaked fee
        SlipstreamZapQuoter.ZapInParams memory withFee = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: true
        });
        SlipstreamZapQuoter.ZapInQuote memory feeQuote = SlipstreamZapQuoter.quoteZapInSingleCore(withFee);

        assertTrue(baseQuote.liquidity > 0, "Baseline should produce liquidity");
        assertTrue(feeQuote.liquidity > 0, "Fee quote should produce liquidity");
        // Higher fees mean the swap portion produces less output, so less liquidity
        assertTrue(feeQuote.liquidity <= baseQuote.liquidity, "Unstaked fee should not increase liquidity");
    }

    /// @notice Test that includeUnstakedFee=true changes zap-in for token1 input
    function test_zapIn_unstakedFee_token1_reducesSwapOutput() public {
        uint24 unstakedFee = 500; // 0.05%
        pool.setUnstakedFee(unstakedFee);

        SlipstreamZapQuoter.ZapInParams memory baseline = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: false,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: false
        });
        SlipstreamZapQuoter.ZapInQuote memory baseQuote = SlipstreamZapQuoter.quoteZapInSingleCore(baseline);

        SlipstreamZapQuoter.ZapInParams memory withFee = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: false,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: true
        });
        SlipstreamZapQuoter.ZapInQuote memory feeQuote = SlipstreamZapQuoter.quoteZapInSingleCore(withFee);

        assertTrue(baseQuote.liquidity > 0, "Baseline should produce liquidity");
        assertTrue(feeQuote.liquidity > 0, "Fee quote should produce liquidity");
        assertTrue(feeQuote.liquidity <= baseQuote.liquidity, "Unstaked fee should not increase liquidity for token1 input");
    }

    /// @notice Test that includeUnstakedFee=true produces distinct swap amounts
    function test_zapIn_unstakedFee_swapAmountsDiffer() public {
        uint24 unstakedFee = 1000; // 0.1% — larger fee to ensure visible difference
        pool.setUnstakedFee(unstakedFee);

        SlipstreamZapQuoter.ZapInParams memory baseline = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: false
        });
        SlipstreamZapQuoter.ZapInQuote memory baseQuote = SlipstreamZapQuoter.quoteZapInSingleCore(baseline);

        SlipstreamZapQuoter.ZapInParams memory withFee = SlipstreamZapQuoter.ZapInParams({
            pool: ICLPool(address(pool)),
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20,
            includeUnstakedFee: true
        });
        SlipstreamZapQuoter.ZapInQuote memory feeQuote = SlipstreamZapQuoter.quoteZapInSingleCore(withFee);

        // The swap output should differ because the effective fee changed
        assertTrue(
            baseQuote.swap.amountOut != feeQuote.swap.amountOut
            || baseQuote.swapAmountIn != feeQuote.swapAmountIn,
            "Swap amounts should differ when unstaked fee is included"
        );
    }

    /// @notice Test zap-in varying search iterations
    function test_zapIn_varyingSearchIterations() public {
        uint16[3] memory iterCounts = [uint16(5), uint16(15), uint16(25)];
        uint128 prevLiquidity = 0;

        for (uint256 i = 0; i < iterCounts.length; i++) {
            SlipstreamZapQuoter.ZapInParams memory params = SlipstreamZapQuoter.ZapInParams({
                pool: ICLPool(address(pool)),
                tickLower: tickLower,
                tickUpper: tickUpper,
                zeroForOne: true,
                amountIn: ZAP_AMOUNT,
                sqrtPriceLimitX96: 0,
                maxSwapSteps: 0,
                searchIters: iterCounts[i],
                includeUnstakedFee: false
            });

            SlipstreamZapQuoter.ZapInQuote memory quote = SlipstreamZapQuoter.quoteZapInSingleCore(params);

            // More iterations should generally produce equal or better results
            if (i > 0) {
                assertTrue(
                    quote.liquidity >= prevLiquidity - 1,  // Allow small variance
                    "More iterations should not significantly reduce liquidity"
                );
            }
            prevLiquidity = quote.liquidity;
        }
    }
}
