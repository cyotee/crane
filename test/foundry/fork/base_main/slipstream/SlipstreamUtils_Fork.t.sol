// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {TestBase_SlipstreamFork} from "./TestBase_SlipstreamFork.sol";

/// @title SlipstreamUtils Fork Tests
/// @notice Validates single-tick quote accuracy against production Slipstream pools on Base mainnet
/// @dev Tests quoteExactInputSingle and quoteExactOutputSingle against actual swap results
contract SlipstreamUtils_Fork_Test is TestBase_SlipstreamFork {
    using SlipstreamUtils for uint256;

    /* -------------------------------------------------------------------------- */
    /*                      WETH/USDC Pool Tests (0.05% fee)                      */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactInputSingle on WETH/USDC 0.05% pool (sell USDC for WETH)
    function test_quoteExactInputSingle_WETH_USDC_500_buyWETH() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        // Get pool state
        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Log pool state for debugging
        console.log("Pool: WETH/USDC 0.05%");
        console.log("  token0:", pool.token0());
        console.log("  token1:", pool.token1());
        console.log("  fee:", fee);
        console.log("  liquidity:", liquidity);
        console.log("  sqrtPriceX96:", sqrtPriceX96);

        // Small swap amount to stay within single tick (100 USDC)
        uint256 amountIn = 100e6; // 100 USDC (6 decimals)

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        // Quote using SlipstreamUtils
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        console.log("  amountIn (USDC):", amountIn);
        console.log("  quotedOut (WETH):", quotedOut);

        // Execute actual swap
        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        console.log("  actualOut (WETH):", actualOut);

        // Assert quote accuracy (0.1% tolerance)
        assertQuoteAccuracy(quotedOut, actualOut, "WETH/USDC 500 exactIn quote mismatch");
    }

    /// @notice Test quoteExactInputSingle on WETH/USDC 0.05% pool (sell WETH for USDC)
    function test_quoteExactInputSingle_WETH_USDC_500_sellWETH() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Small WETH swap to stay in single tick
        uint256 amountIn = 0.01 ether; // 0.01 WETH

        bool zeroForOne = zeroForOneForTokens(pool, WETH, USDC);

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        uint256 actualOut = swapExactInputTokens(pool, WETH, USDC, amountIn, address(this));

        console.log("Pool: WETH/USDC 0.05% (sell WETH)");
        console.log("  amountIn (WETH):", amountIn);
        console.log("  quotedOut (USDC):", quotedOut);
        console.log("  actualOut (USDC):", actualOut);

        assertQuoteAccuracy(quotedOut, actualOut, "WETH/USDC 500 sellWETH quote mismatch");
    }

    /// @notice Test quoteExactOutputSingle on WETH/USDC 0.05% pool (buy exact WETH)
    function test_quoteExactOutputSingle_WETH_USDC_500_buyWETH() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Want 0.01 WETH
        uint256 amountOut = 0.01 ether;

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        uint256 actualIn = swapExactOutputTokens(pool, USDC, WETH, amountOut, address(this));

        console.log("Pool: WETH/USDC 0.05% (exactOut buy WETH)");
        console.log("  amountOut (WETH):", amountOut);
        console.log("  quotedIn (USDC):", quotedIn);
        console.log("  actualIn (USDC):", actualIn);

        assertQuoteAccuracy(quotedIn, actualIn, "WETH/USDC 500 exactOut quote mismatch");
    }

    /// @notice Test quoteExactOutputSingle on WETH/USDC 0.05% pool (buy exact USDC with WETH)
    function test_quoteExactOutputSingle_WETH_USDC_500_buyUSDC() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Want 100 USDC
        uint256 amountOut = 100e6;

        bool zeroForOne = zeroForOneForTokens(pool, WETH, USDC);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        uint256 actualIn = swapExactOutputTokens(pool, WETH, USDC, amountOut, address(this));

        console.log("Pool: WETH/USDC 0.05% (exactOut buy USDC)");
        console.log("  amountOut (USDC):", amountOut);
        console.log("  quotedIn (WETH):", quotedIn);
        console.log("  actualIn (WETH):", actualIn);

        assertQuoteAccuracy(quotedIn, actualIn, "WETH/USDC 500 exactOut buyUSDC quote mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                      cbBTC/WETH Pool Tests                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactInputSingle on cbBTC/WETH pool (sell WETH for cbBTC)
    function test_quoteExactInputSingle_cbBTC_WETH_buycbBTC() public {
        // Skip if pool doesn't exist at fork block
        skipIfPoolInvalid(cbBTC_WETH_CL, "cbBTC_WETH_CL");

        ICLPool pool = getPool(cbBTC_WETH_CL);

        // Get pool state
        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Log pool state for debugging
        console.log("Pool: cbBTC/WETH CL 0.05%");
        console.log("  token0:", pool.token0());
        console.log("  token1:", pool.token1());
        console.log("  fee:", fee);
        console.log("  liquidity:", liquidity);
        console.log("  sqrtPriceX96:", sqrtPriceX96);

        // Small swap amount to stay within single tick (0.1 WETH)
        uint256 amountIn = 0.1 ether; // 0.1 WETH

        bool zeroForOne = zeroForOneForTokens(pool, WETH, cbBTC);

        // Quote using SlipstreamUtils
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        console.log("  amountIn (WETH):", amountIn);
        console.log("  quotedOut (cbBTC):", quotedOut);

        // Execute actual swap
        uint256 actualOut = swapExactInputTokens(pool, WETH, cbBTC, amountIn, address(this));

        console.log("  actualOut (cbBTC):", actualOut);

        // Assert quote accuracy (0.1% tolerance)
        assertQuoteAccuracy(quotedOut, actualOut, "cbBTC/WETH exactIn quote mismatch");
    }

    /// @notice Test quoteExactInputSingle on cbBTC/WETH pool (sell cbBTC for WETH)
    function test_quoteExactInputSingle_cbBTC_WETH_sellcbBTC() public {
        // Skip if pool doesn't exist at fork block
        skipIfPoolInvalid(cbBTC_WETH_CL, "cbBTC_WETH_CL");

        ICLPool pool = getPool(cbBTC_WETH_CL);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Small cbBTC swap to stay in single tick (0.001 cbBTC = ~$100 worth)
        uint256 amountIn = 0.001e8; // 0.001 cbBTC (8 decimals)

        bool zeroForOne = zeroForOneForTokens(pool, cbBTC, WETH);

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        uint256 actualOut = swapExactInputTokens(pool, cbBTC, WETH, amountIn, address(this));

        console.log("Pool: cbBTC/WETH CL (sell cbBTC)");
        console.log("  amountIn (cbBTC):", amountIn);
        console.log("  quotedOut (WETH):", quotedOut);
        console.log("  actualOut (WETH):", actualOut);

        assertQuoteAccuracy(quotedOut, actualOut, "cbBTC/WETH sellcbBTC quote mismatch");
    }

    /// @notice Test quoteExactOutputSingle on cbBTC/WETH pool (buy exact cbBTC)
    function test_quoteExactOutputSingle_cbBTC_WETH_buycbBTC() public {
        // Skip if pool doesn't exist at fork block
        skipIfPoolInvalid(cbBTC_WETH_CL, "cbBTC_WETH_CL");

        ICLPool pool = getPool(cbBTC_WETH_CL);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Want 0.001 cbBTC (~$100)
        uint256 amountOut = 0.001e8;

        bool zeroForOne = zeroForOneForTokens(pool, WETH, cbBTC);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        uint256 actualIn = swapExactOutputTokens(pool, WETH, cbBTC, amountOut, address(this));

        console.log("Pool: cbBTC/WETH CL (exactOut buy cbBTC)");
        console.log("  amountOut (cbBTC):", amountOut);
        console.log("  quotedIn (WETH):", quotedIn);
        console.log("  actualIn (WETH):", actualIn);

        assertQuoteAccuracy(quotedIn, actualIn, "cbBTC/WETH exactOut quote mismatch");
    }

    /// @notice Test quoteExactOutputSingle on cbBTC/WETH pool (buy exact WETH with cbBTC)
    function test_quoteExactOutputSingle_cbBTC_WETH_buyWETH() public {
        // Skip if pool doesn't exist at fork block
        skipIfPoolInvalid(cbBTC_WETH_CL, "cbBTC_WETH_CL");

        ICLPool pool = getPool(cbBTC_WETH_CL);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Want 0.1 WETH
        uint256 amountOut = 0.1 ether;

        bool zeroForOne = zeroForOneForTokens(pool, cbBTC, WETH);

        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        uint256 actualIn = swapExactOutputTokens(pool, cbBTC, WETH, amountOut, address(this));

        console.log("Pool: cbBTC/WETH CL (exactOut buy WETH)");
        console.log("  amountOut (WETH):", amountOut);
        console.log("  quotedIn (cbBTC):", quotedIn);
        console.log("  actualIn (cbBTC):", actualIn);

        assertQuoteAccuracy(quotedIn, actualIn, "cbBTC/WETH exactOut buyWETH quote mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Tick Overload Tests                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Test using tick overload function
    function test_quoteExactInputSingle_withTick() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, int24 tick, uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Small amount to stay in single tick
        uint256 amountIn = 50e6; // 50 USDC

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        // Quote using sqrtPriceX96
        uint256 quotedWithSqrtPrice = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        // Quote using tick
        uint256 quotedWithTick = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            tick,
            liquidity,
            fee,
            zeroForOne
        );

        console.log("Tick overload comparison:");
        console.log("  quotedWithSqrtPrice:", quotedWithSqrtPrice);
        console.log("  quotedWithTick:", quotedWithTick);

        // Execute actual swap for baseline
        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        console.log("  actualOut:", actualOut);

        // Both should be close to actual (tick-based may have slightly more error)
        assertQuoteAccuracy(quotedWithSqrtPrice, actualOut, "sqrtPrice overload mismatch");
        assertQuoteAccuracy(quotedWithTick, actualOut, 50, "tick overload mismatch"); // 0.5% tolerance
    }

    /// @notice Test quoteExactOutputSingle using tick overload
    function test_quoteExactOutputSingle_withTick() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, int24 tick, uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Small amount to stay in single tick
        uint256 amountOut = 0.005 ether; // 0.005 WETH

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        // Quote using sqrtPriceX96
        uint256 quotedWithSqrtPrice = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        // Quote using tick
        uint256 quotedWithTick = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            tick,
            liquidity,
            fee,
            zeroForOne
        );

        console.log("ExactOutput tick overload comparison:");
        console.log("  quotedWithSqrtPrice:", quotedWithSqrtPrice);
        console.log("  quotedWithTick:", quotedWithTick);

        uint256 actualIn = swapExactOutputTokens(pool, USDC, WETH, amountOut, address(this));

        console.log("  actualIn:", actualIn);

        assertQuoteAccuracy(quotedWithSqrtPrice, actualIn, "sqrtPrice overload exactOut mismatch");
        assertQuoteAccuracy(quotedWithTick, actualIn, 50, "tick overload exactOut mismatch"); // 0.5% tolerance
    }

    /* -------------------------------------------------------------------------- */
    /*                          Edge Case Tests                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Test small amount quote (dust)
    function test_quoteExactInputSingle_smallAmount() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Very small swap (1 USDC)
        uint256 amountIn = 1e6; // 1 USDC

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        console.log("Small amount test:");
        console.log("  amountIn (1 USDC):", amountIn);
        console.log("  quotedOut:", quotedOut);
        console.log("  actualOut:", actualOut);

        // For small amounts, allow slightly higher tolerance
        assertQuoteAccuracy(quotedOut, actualOut, 50, "small amount quote mismatch"); // 0.5% tolerance
    }

    /// @notice Test zero amount returns zero
    function test_quoteExactInputSingle_zeroAmount() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            0,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );

        assertEq(quotedOut, 0, "zero input should give zero output");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Liquidity Amount Helper Tests                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteAmountsForLiquidity
    function test_quoteAmountsForLiquidity() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = pool.tickSpacing();

        // Create a position range around current tick
        int24 tickLower = nearestUsableTick(tick - 1000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1000, tickSpacing);

        uint128 liquidity = 1e12; // Sample liquidity amount

        // Quote amounts needed
        (uint256 quotedAmount0, uint256 quotedAmount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        console.log("quoteAmountsForLiquidity:");
        console.log("  tickLower:", tickLower);
        console.log("  tickUpper:", tickUpper);
        console.log("  liquidity:", liquidity);
        console.log("  quotedAmount0:", quotedAmount0);
        console.log("  quotedAmount1:", quotedAmount1);

        // Verify amounts are non-zero when in range
        if (tick >= tickLower && tick < tickUpper) {
            assertTrue(quotedAmount0 > 0 || quotedAmount1 > 0, "should need at least one token");
        }
    }

    /// @notice Test quoteLiquidityForAmounts
    function test_quoteLiquidityForAmounts() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = pool.tickSpacing();

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        address token0 = pool.token0();
        uint256 amount0 = token0 == WETH ? 1 ether : 1000e6;
        uint256 amount1 = token0 == WETH ? 1000e6 : 1 ether;

        // Quote max liquidity
        uint128 quotedLiquidity = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        console.log("quoteLiquidityForAmounts:");
        console.log("  amount0:", amount0);
        console.log("  amount1:", amount1);
        console.log("  quotedLiquidity:", quotedLiquidity);

        // Verify: minting this liquidity should require <= provided amounts
        (uint256 requiredAmount0, uint256 requiredAmount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            quotedLiquidity
        );

        console.log("  requiredAmount0:", requiredAmount0);
        console.log("  requiredAmount1:", requiredAmount1);

        assertTrue(requiredAmount0 <= amount0, "requires too much amount0");
        assertTrue(requiredAmount1 <= amount1, "requires too much amount1");
        assertTrue(quotedLiquidity > 0, "liquidity should be > 0");
    }
}
