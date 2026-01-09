// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {UniswapV3ZapQuoter} from "@crane/contracts/utils/math/UniswapV3ZapQuoter.sol";
import {UniswapV3Quoter} from "@crane/contracts/utils/math/UniswapV3Quoter.sol";
import {UniswapV3Utils} from "@crane/contracts/utils/math/UniswapV3Utils.sol";
import {TestBase_UniswapV3Fork} from "./TestBase_UniswapV3Fork.sol";

/// @title UniswapV3ZapQuoter Fork Tests
/// @notice Validates zap-in and zap-out quote accuracy against production Uniswap V3 pools
/// @dev Tests single-sided liquidity provision and withdrawal operations
contract UniswapV3ZapQuoter_Fork_Test is TestBase_UniswapV3Fork {
    using UniswapV3ZapQuoter for UniswapV3ZapQuoter.ZapInParams;
    using UniswapV3ZapQuoter for UniswapV3ZapQuoter.ZapOutParams;

    /* -------------------------------------------------------------------------- */
    /*                              Zap-In Tests                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zap-in with WETH on WETH/USDC 0.3% pool
    function test_quoteZapIn_WETH_USDC_3000_token0() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);

        // Position range around current tick
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        // Zap in with 1 ETH
        uint256 amountIn = 1 ether;

        bool inputIsToken0 = tokenIsToken0(pool, WETH);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: inputIsToken0,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0, // Use default
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        // Validate quote structure
        assertTrue(quote.liquidity > 0, "should mint liquidity");
        assertTrue(quote.swapAmountIn <= amountIn, "swap amount should be <= input");
        assertTrue(quote.amount0 > 0 || quote.amount1 > 0, "should have token amounts");

        // The total tokens should roughly equal the input (minus fees)
        // swapAmountIn + remaining input + dust should ~ amountIn
        uint256 inputDust = inputIsToken0 ? quote.dust0 : quote.dust1;
        uint256 totalAccountedFor = quote.swapAmountIn + (amountIn - quote.swap.amountIn) + inputDust;
        assertApproxEqRel(totalAccountedFor, amountIn, 0.01e18, "token accounting mismatch");

        // Execute the zap manually and compare
        // 1. Swap part of the input
        if (quote.swapAmountIn > 0) {
            uint256 actualSwapOut = swapExactInput(pool, inputIsToken0, quote.swapAmountIn, address(this));
            // Compare quoted swap output to actual
            assertQuoteAccuracy(quote.swap.amountOut, actualSwapOut, 50, "swap quote mismatch"); // 0.5% tolerance

            // 2. Mint with the resulting amounts
            (uint256 mintedAmount0, uint256 mintedAmount1) = mintPosition(
                pool,
                address(this),
                tickLower,
                tickUpper,
                quote.liquidity
            );

            // The minted amounts should be close to quoted
            assertQuoteAccuracy(quote.amount0, mintedAmount0, 100, "mint amount0 mismatch");
            assertQuoteAccuracy(quote.amount1, mintedAmount1, 100, "mint amount1 mismatch");
        }
    }

    /// @notice Test zap-in with USDC on WETH/USDC 0.3% pool
    function test_quoteZapIn_WETH_USDC_3000_token1() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);

        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        // Zap in with 1000 USDC
        uint256 amountIn = 1000e6;

        bool inputIsToken0 = tokenIsToken0(pool, USDC);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: inputIsToken0,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        assertTrue(quote.liquidity > 0, "should mint liquidity");
        assertTrue(quote.swapAmountIn <= amountIn, "swap amount should be <= input");
    }

    /// @notice Test zap-in on stablecoin pool
    function test_quoteZapIn_USDC_USDT_500() public {
        IUniswapV3Pool pool = getPool(USDC_USDT_500);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_LOW);

        // Tight range for stablecoin
        int24 tickLower = nearestUsableTick(tick - 100, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 100, tickSpacing);

        uint256 amountIn = 5000e6; // 5000 USDC

        bool inputIsToken0 = tokenIsToken0(pool, USDC);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: inputIsToken0,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 24 // More iterations for precision
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        assertTrue(quote.liquidity > 0, "should mint liquidity");

        // For stablecoins at 1:1, dust should be minimal
        assertTrue(quote.dust0 + quote.dust1 < amountIn / 100, "dust should be < 1% of input");
    }

    /// @notice Test zap-in on 1% fee pool
    function test_quoteZapIn_WETH_USDC_10000() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_10000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_HIGH);

        int24 tickLower = nearestUsableTick(tick - 2000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 2000, tickSpacing);

        uint256 amountIn = 0.5 ether;

        bool inputIsToken0 = tokenIsToken0(pool, WETH);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: inputIsToken0,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        assertTrue(quote.liquidity > 0, "should mint liquidity");
    }

    /// @notice Test createZapInParams helper
    function test_createZapInParams() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        // Create params using WETH address
        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.createZapInParams(
            pool,
            tickLower,
            tickUpper,
            WETH, // tokenIn
            1 ether,
            0,
            0,
            20
        );

        bool expectedZeroForOne = tokenIsToken0(pool, WETH);
        assertEq(params.zeroForOne, expectedZeroForOne, "zeroForOne should match tokenIn == pool.token0()");
        assertEq(params.amountIn, 1 ether, "amountIn should match");
    }

    /// @notice Test quoteZapInPool wrapper
    function test_quoteZapInPool() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        bool inputIsToken0 = tokenIsToken0(pool, WETH);
        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: inputIsToken0,
            amountIn: 1 ether,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.PoolZapInExecution memory exec = UniswapV3ZapQuoter.quoteZapInPool(params);

        assertTrue(exec.liquidity > 0, "should have liquidity");
        assertEq(exec.tickLower, tickLower, "tickLower should match");
        assertEq(exec.tickUpper, tickUpper, "tickUpper should match");
        assertEq(exec.zeroForOne, inputIsToken0, "zeroForOne should match");
    }

    /// @notice Test quoteZapInPositionManager wrapper
    function test_quoteZapInPositionManager() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        bool inputIsToken0 = tokenIsToken0(pool, WETH);
        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: inputIsToken0,
            amountIn: 1 ether,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.PositionManagerZapInExecution memory exec = UniswapV3ZapQuoter.quoteZapInPositionManager(params);

        assertTrue(exec.amount0Desired > 0 || exec.amount1Desired > 0, "should have desired amounts");
        assertEq(exec.tickLower, tickLower, "tickLower should match");
        assertEq(exec.tickUpper, tickUpper, "tickUpper should match");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Zap-Out Tests                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zap-out to WETH on WETH/USDC pool
    function test_quoteZapOut_WETH_USDC_3000_wantToken0() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        // First mint a position to have liquidity to burn
        uint128 liquidity = 1e15;
        mintPosition(pool, address(this), tickLower, tickUpper, liquidity);

        bool wantToken0 = tokenIsToken0(pool, WETH);

        // Now quote zap-out (exit to WETH only)
        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            wantToken0: wantToken0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.ZapOutQuote memory quote = UniswapV3ZapQuoter.quoteZapOutSingleCore(params);

        // Validate quote
        assertTrue(quote.amountOut > 0, "should have output");
        assertTrue(quote.burnAmount0 > 0 || quote.burnAmount1 > 0, "should burn something");

        // The burn returns both tokens; we swap the *unwanted* token fully into the wanted token.
        if (wantToken0) {
            if (quote.burnAmount1 > 0) assertEq(quote.swapAmountIn, quote.burnAmount1, "should swap all unwanted token1");
            assertEq(quote.amountOut, quote.burnAmount0 + quote.swap.amountOut, "output accounting");
        } else {
            if (quote.burnAmount0 > 0) assertEq(quote.swapAmountIn, quote.burnAmount0, "should swap all unwanted token0");
            assertEq(quote.amountOut, quote.burnAmount1 + quote.swap.amountOut, "output accounting");
        }
    }

    /// @notice Test zap-out to USDC on WETH/USDC pool
    function test_quoteZapOut_WETH_USDC_3000_wantToken1() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        uint128 liquidity = 1e15;
        mintPosition(pool, address(this), tickLower, tickUpper, liquidity);

        bool wantToken0 = tokenIsToken0(pool, USDC);

        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            wantToken0: wantToken0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.ZapOutQuote memory quote = UniswapV3ZapQuoter.quoteZapOutSingleCore(params);

        assertTrue(quote.amountOut > 0, "should have output");

        // The burn returns both tokens; we swap the *unwanted* token fully into the wanted token.
        if (wantToken0) {
            if (quote.burnAmount1 > 0) assertEq(quote.swapAmountIn, quote.burnAmount1, "should swap all unwanted token1");
            assertEq(quote.amountOut, quote.burnAmount0 + quote.swap.amountOut, "output accounting");
        } else {
            if (quote.burnAmount0 > 0) assertEq(quote.swapAmountIn, quote.burnAmount0, "should swap all unwanted token0");
            assertEq(quote.amountOut, quote.burnAmount1 + quote.swap.amountOut, "output accounting");
        }
    }

    /// @notice Test zap-out when position is entirely in one token
    function test_quoteZapOut_singleSidedPosition() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);

        // Create a position entirely above current tick (only token0)
        int24 tickLower = nearestUsableTick(tick + 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        uint128 liquidity = 1e15;
        mintPosition(pool, address(this), tickLower, tickUpper, liquidity);

        // Zap out wanting token0 (no swap expected)
        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.ZapOutQuote memory quote = UniswapV3ZapQuoter.quoteZapOutSingleCore(params);

        // Position is above current tick, so it's all token0
        // Wanting token0 means no swap needed
        assertTrue(quote.burnAmount0 > 0, "should have token0 from burn");
        assertEq(quote.burnAmount1, 0, "should have no token1");
        assertEq(quote.swapAmountIn, 0, "should not need to swap");
        assertEq(quote.amountOut, quote.burnAmount0, "output should equal burn amount");
    }

    /// @notice Test createZapOutParams helper
    function test_createZapOutParams() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        uint128 liquidity = 1e15;

        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.createZapOutParams(
            pool,
            tickLower,
            tickUpper,
            liquidity,
            WETH, // tokenOut
            0,
            0
        );

        bool expectedWantToken0 = tokenIsToken0(pool, WETH);
        assertEq(params.wantToken0, expectedWantToken0, "wantToken0 should match tokenOut == pool.token0()");
        assertEq(params.liquidity, liquidity, "liquidity should match");
    }

    /// @notice Test quoteZapOutPool wrapper
    function test_quoteZapOutPool() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        uint128 liquidity = 1e15;
        mintPosition(pool, address(this), tickLower, tickUpper, liquidity);

        bool wantToken0 = tokenIsToken0(pool, WETH);

        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            wantToken0: wantToken0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.PoolZapOutExecution memory exec = UniswapV3ZapQuoter.quoteZapOutPool(params);

        assertEq(exec.liquidity, liquidity, "liquidity should match");
        assertEq(exec.tickLower, tickLower, "tickLower should match");
        assertEq(exec.tickUpper, tickUpper, "tickUpper should match");
    }

    /// @notice Test quoteZapOutPositionManager wrapper
    function test_quoteZapOutPositionManager() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        uint128 liquidity = 1e15;
        mintPosition(pool, address(this), tickLower, tickUpper, liquidity);

        bool wantToken0 = tokenIsToken0(pool, WETH);

        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            wantToken0: wantToken0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.PositionManagerZapOutExecution memory exec = UniswapV3ZapQuoter.quoteZapOutPositionManager(params);

        assertEq(exec.liquidity, liquidity, "liquidity should match");
        assertEq(exec.tickLower, tickLower, "tickLower should match");
        assertEq(exec.tickUpper, tickUpper, "tickUpper should match");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Zap Edge Cases                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zap-in with very small amount
    function test_quoteZapIn_smallAmount() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        // Very small amount
        uint256 amountIn = 0.001 ether;

        bool inputIsToken0 = tokenIsToken0(pool, WETH);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: inputIsToken0,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        // Should still produce some liquidity
        assertTrue(quote.liquidity > 0, "should mint some liquidity");
    }

    /// @notice Test zap-in with narrow range (more token imbalance)
    function test_quoteZapIn_narrowRange() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);

        // Very narrow range
        int24 tickLower = nearestUsableTick(tick - 60, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 60, tickSpacing);

        uint256 amountIn = 1 ether;

        bool inputIsToken0 = tokenIsToken0(pool, WETH);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: inputIsToken0,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 24 // More iterations for narrow range
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        assertTrue(quote.liquidity > 0, "should mint liquidity");
        // Narrow range means more concentrated liquidity
    }

    /// @notice Test zap-in with wide range
    function test_quoteZapIn_wideRange() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);

        // Wide range
        int24 tickLower = nearestUsableTick(tick - 6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 6000, tickSpacing);

        uint256 amountIn = 1 ether;

        bool inputIsToken0 = tokenIsToken0(pool, WETH);

        UniswapV3ZapQuoter.ZapInParams memory params = UniswapV3ZapQuoter.ZapInParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: inputIsToken0,
            amountIn: amountIn,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV3ZapQuoter.ZapInQuote memory quote = UniswapV3ZapQuoter.quoteZapInSingleCore(params);

        assertTrue(quote.liquidity > 0, "should mint liquidity");
    }
}
