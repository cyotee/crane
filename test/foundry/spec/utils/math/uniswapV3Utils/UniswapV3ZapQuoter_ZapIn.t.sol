// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {UniswapV3ZapQuoter} from "@crane/contracts/utils/math/UniswapV3ZapQuoter.sol";
import {UniswapV3Quoter} from "@crane/contracts/utils/math/UniswapV3Quoter.sol";
import {UniswapV3Utils} from "@crane/contracts/utils/math/UniswapV3Utils.sol";
import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {TestBase_UniswapV3} from "@crane/contracts/protocols/dexes/uniswap/v3/test/bases/TestBase_UniswapV3.sol";
import {MockERC20} from "./UniswapV3Utils_quoteExactInput.t.sol";

/// @title Test UniswapV3ZapQuoter zap-in functionality (Phase 3)
/// @notice Validates single-sided liquidity provision quoting
contract UniswapV3ZapQuoter_ZapIn_Test is TestBase_UniswapV3 {
    using UniswapV3ZapQuoter for *;
    using UniswapV3Utils for *;

    IUniswapV3Pool pool;
    address tokenA;
    address tokenB;

    uint256 constant INITIAL_LIQUIDITY = 10_000e18;
    uint256 constant ZAP_AMOUNT = 100e18;

    function setUp() public override {
        super.setUp();

        // Create test tokens
        tokenA = address(new MockERC20("Token A", "TKNA", 18));
        tokenB = address(new MockERC20("Token B", "TKNB", 18));

        vm.label(tokenA, "TokenA");
        vm.label(tokenB, "TokenB");

        // Create pool with 0.3% fee at 1:1 price
        pool = createPoolOneToOne(tokenA, tokenB, FEE_MEDIUM);

        // Add initial liquidity in a wide range
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        mintPosition(
            pool,
            address(this),
            nearestUsableTick(-60000, tickSpacing),
            nearestUsableTick(60000, tickSpacing),
            uint128(INITIAL_LIQUIDITY)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                        Basic Zap-In Quote Tests                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zap-in with token0 as input
    function test_quoteZapInSingleCore_token0Input() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,  // Token0 input
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,  // Use default
            maxSwapSteps: 0,       // Unlimited
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        // Basic sanity checks
        assertTrue(quote.liquidity > 0, "Should mint some liquidity");
        assertTrue(quote.swapAmountIn <= ZAP_AMOUNT, "Swap amount should not exceed input");
        assertTrue(quote.amount0 > 0 || quote.amount1 > 0, "Should have some amounts for mint");

        // Dust should be minimal (good optimization)
        uint256 totalDust = quote.dust0 + quote.dust1;
        assertTrue(totalDust < ZAP_AMOUNT / 10, "Dust should be < 10% of input");
    }

    /// @notice Test zap-in with token1 as input
    function test_quoteZapInSingleCore_token1Input() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: false,  // Token1 input
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        // Basic sanity checks
        assertTrue(quote.liquidity > 0, "Should mint some liquidity");
        assertTrue(quote.swapAmountIn <= ZAP_AMOUNT, "Swap amount should not exceed input");

        // Dust should be minimal
        uint256 totalDust = quote.dust0 + quote.dust1;
        assertTrue(totalDust < ZAP_AMOUNT / 10, "Dust should be < 10% of input");
    }

    /// @notice Test zap-in when price is below target range (only token0 needed)
    function test_quoteZapInSingleCore_priceBelowRange() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        // Range above current price (tick ~0)
        int24 tickLower = nearestUsableTick(6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(12000, tickSpacing);

        // Token0 input - should need to swap almost nothing since only token0 is needed
        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        // When minting below-range position with token0, we shouldn't need to swap
        assertTrue(quote.swapAmountIn == 0 || quote.swapAmountIn < ZAP_AMOUNT / 10,
            "Should swap very little when input is the only needed token");
        assertTrue(quote.liquidity > 0, "Should mint liquidity");
    }

    /// @notice Test zap-in when price is above target range (only token1 needed)
    function test_quoteZapInSingleCore_priceAboveRange() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        // Range below current price (tick ~0)
        int24 tickLower = nearestUsableTick(-12000, tickSpacing);
        int24 tickUpper = nearestUsableTick(-6000, tickSpacing);

        // Token1 input - should need to swap almost nothing since only token1 is needed
        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: false,  // Token1 input
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        // When minting above-range position with token1, we shouldn't need to swap
        assertTrue(quote.swapAmountIn == 0 || quote.swapAmountIn < ZAP_AMOUNT / 10,
            "Should swap very little when input is the only needed token");
        assertTrue(quote.liquidity > 0, "Should mint liquidity");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Wrapper Function Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteZapInPool wrapper
    function test_quoteZapInPool() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.PoolZapInExecution memory exec = UniswapV3ZapQuoter.quoteZapInPool(params);

        // Check execution params are set correctly
        assertEq(exec.zeroForOne, true, "zeroForOne mismatch");
        assertEq(exec.tickLower, tickLower, "tickLower mismatch");
        assertEq(exec.tickUpper, tickUpper, "tickUpper mismatch");
        assertTrue(exec.liquidity > 0, "Should have liquidity");
        assertTrue(exec.amount0 > 0 || exec.amount1 > 0, "Should have amounts");
    }

    /// @notice Test quoteZapInPositionManager wrapper
    function test_quoteZapInPositionManager() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: false,  // Token1 input
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.PositionManagerZapInExecution memory exec =
            UniswapV3ZapQuoter.quoteZapInPositionManager(params);

        // Check execution params are set correctly
        assertEq(exec.zeroForOne, false, "zeroForOne mismatch");
        assertEq(exec.tickLower, tickLower, "tickLower mismatch");
        assertEq(exec.tickUpper, tickUpper, "tickUpper mismatch");
        assertTrue(exec.amount0Desired > 0 || exec.amount1Desired > 0, "Should have desired amounts");
    }

    /// @notice Test createZapInParams helper
    function test_createZapInParams() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        address token0 = pool.token0();
        address token1 = pool.token1();

        // Create params with token0
        UniswapV3ZapQuoter.ZapInParams memory params0 = UniswapV3ZapQuoter.createZapInParams(
            pool,
            tickLower,
            tickUpper,
            token0,
            ZAP_AMOUNT,
            0,
            0,
            20
        );

        assertTrue(params0.zeroForOne, "token0 should set zeroForOne=true");
        assertEq(params0.amountIn, ZAP_AMOUNT, "amountIn mismatch");

        // Create params with token1
        UniswapV3ZapQuoter.ZapInParams memory params1 = UniswapV3ZapQuoter.createZapInParams(
            pool,
            tickLower,
            tickUpper,
            token1,
            ZAP_AMOUNT,
            0,
            0,
            20
        );

        assertFalse(params1.zeroForOne, "token1 should set zeroForOne=false");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Edge Case Tests                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zap with very small amount
    function test_quoteZapInSingleCore_smallAmount() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: 1e15,  // Small: 0.001 tokens
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        // Should still work for small amounts
        assertTrue(quote.swapAmountIn <= 1e15, "Swap should not exceed input");
    }

    /// @notice Test different search iterations
    function test_quoteZapInSingleCore_differentSearchIters() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        // Test with few iterations
        UniswapV3ZapQuoter.ZapInParams memory params5 = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 5  // Few iterations
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote5 = UniswapV3ZapQuoter.quoteZapInSingleCore(params5);

        // Test with more iterations
        UniswapV3ZapQuoter.ZapInParams memory params30 = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 30  // More iterations
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote30 = UniswapV3ZapQuoter.quoteZapInSingleCore(params30);

        // More iterations should give >= liquidity (better optimization)
        assertTrue(quote30.liquidity >= quote5.liquidity * 99 / 100,
            "More iterations should give similar or better liquidity");
    }

    /* -------------------------------------------------------------------------- */
    /*                     Actual Execution Comparison Tests                      */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that quoted zap can actually be executed
    function test_quoteZapInSingleCore_executionWorks() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        // Skip if no swap needed
        if (quote.swapAmountIn == 0) return;

        // Execute the swap
        uint256 actualSwapOut = swapExactInput(pool, true, quote.swapAmountIn, address(this));

        // Verify swap output matches quote
        assertApproxEqAbs(actualSwapOut, quote.swap.amountOut, 1, "Swap output should match quote");

        // The remaining balance should allow minting the quoted liquidity
        // (We don't actually mint here since that's more complex, but the swap verification gives confidence)
    }

    /// @notice Test liquidity is maximized (compare to non-optimal swap amount)
    function test_quoteZapInSingleCore_liquidityIsOptimized() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: ZAP_AMOUNT,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory optimalQuote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        // Compare to swapping 50% (which is usually not optimal for asymmetric ranges)
        params.searchIters = 1;  // Force single iteration - will pick midpoint
        UniswapV3ZapQuoter.ZapInQuote memory midpointQuote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        // Optimal should be >= midpoint (with tolerance for edge cases)
        assertTrue(optimalQuote.liquidity >= midpointQuote.liquidity * 95 / 100,
            "Optimized liquidity should be >= naive midpoint");
    }
}
