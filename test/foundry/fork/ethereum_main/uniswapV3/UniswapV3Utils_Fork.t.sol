// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {UniswapV3Utils} from "@crane/contracts/utils/math/UniswapV3Utils.sol";
import {TestBase_UniswapV3Fork} from "./TestBase_UniswapV3Fork.sol";

/// @title UniswapV3Utils Fork Tests
/// @notice Validates single-tick quote accuracy against production Uniswap V3 pools on Ethereum mainnet
/// @dev Tests quoteExactInputSingle and quoteExactOutputSingle against actual swap results
contract UniswapV3Utils_Fork_Test is TestBase_UniswapV3Fork {
    using UniswapV3Utils for uint256;

    /* -------------------------------------------------------------------------- */
    /*                          Fee Tier: 0.05% (500)                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactInputSingle on USDC/USDT 0.05% pool (stablecoin pair)
    function test_quoteExactInputSingle_USDC_USDT_500_zeroForOne() public {
        IUniswapV3Pool pool = getPool(USDC_USDT_500);

        // Get pool state
        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);

        // Small swap amount to stay within single tick (100 USDC)
        uint256 amountIn = 100e6; // 100 USDC (6 decimals)

        bool zeroForOne = zeroForOneForTokens(pool, USDC, USDT);

        // Quote using UniswapV3Utils
        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_LOW,
            zeroForOne
        );

        // Execute actual swap
        uint256 actualOut = swapExactInputTokens(pool, USDC, USDT, amountIn, address(this));

        // Assert quote accuracy (0.1% tolerance)
        assertQuoteAccuracy(quotedOut, actualOut, "USDC/USDT 500 exactIn quote mismatch");
    }

    /// @notice Test quoteExactInputSingle on WETH/USDC 0.05% pool (reverse direction)
    /// @dev Using WETH/USDC instead of USDC/USDT to avoid USDT transfer issues
    function test_quoteExactInputSingle_WETH_USDC_500_oneForZero() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);

        // Small USDC swap (USDC is token0 in this pool)
        uint256 amountIn = 100e6; // 100 USDC

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_LOW,
            zeroForOne
        );

        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        assertQuoteAccuracy(quotedOut, actualOut, "WETH/USDC 500 exactIn quote mismatch");
    }

    /// @notice Test quoteExactOutputSingle on WETH/USDC 0.05% pool
    /// @dev Using WETH/USDC instead of USDC/USDT to avoid USDT transfer issues
    function test_quoteExactOutputSingle_WETH_USDC_500_zeroForOne() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);

        // Want 0.01 WETH (WETH is token1)
        uint256 amountOut = 0.01 ether;

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedIn = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_LOW,
            zeroForOne
        );

        uint256 actualIn = swapExactOutputTokens(pool, USDC, WETH, amountOut, address(this));

        assertQuoteAccuracy(quotedIn, actualIn, "WETH/USDC 500 exactOut quote mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Fee Tier: 0.3% (3000)                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactInputSingle on WETH/USDC 0.3% pool
    /// @dev Using very small amount to stay within single tick
    function test_quoteExactInputSingle_WETH_USDC_3000_zeroForOne() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);

        // Very small swap to stay in single tick
        uint256 amountIn = 100e6; // 100 USDC

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        assertQuoteAccuracy(quotedOut, actualOut, "WETH/USDC 3000 exactIn quote mismatch");
    }

    /// @notice Test quoteExactInputSingle on WETH/USDC 0.3% pool (buy USDC with ETH)
    /// @dev On mainnet: USDC is token0, WETH is token1
    function test_quoteExactInputSingle_WETH_USDC_3000_oneForZero() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);

        // Small swap: 0.001 WETH to stay in single tick
        uint256 amountIn = 0.001 ether;

        bool zeroForOne = zeroForOneForTokens(pool, WETH, USDC);

        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        uint256 actualOut = swapExactInputTokens(pool, WETH, USDC, amountIn, address(this));

        assertQuoteAccuracy(quotedOut, actualOut, "WETH/USDC 3000 reverse exactIn quote mismatch");
    }

    /// @notice Test quoteExactOutputSingle on WETH/USDC 0.3% pool
    /// @dev On mainnet: USDC is token0, WETH is token1
    function test_quoteExactOutputSingle_WETH_USDC_3000_zeroForOne() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);

        // Want 0.001 WETH (small amount to stay in single tick)
        uint256 amountOut = 0.001 ether;

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedIn = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        uint256 actualIn = swapExactOutputTokens(pool, USDC, WETH, amountOut, address(this));

        assertQuoteAccuracy(quotedIn, actualIn, "WETH/USDC 3000 exactOut quote mismatch");
    }

    /// @notice Test quoteExactOutputSingle on WETH/USDC 0.3% pool (want USDC)
    /// @dev On mainnet: USDC is token0, WETH is token1
    function test_quoteExactOutputSingle_WETH_USDC_3000_oneForZero() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);

        // Want 100 USDC (small amount to stay in single tick)
        uint256 amountOut = 100e6;

        bool zeroForOne = zeroForOneForTokens(pool, WETH, USDC);

        uint256 quotedIn = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        uint256 actualIn = swapExactOutputTokens(pool, WETH, USDC, amountOut, address(this));

        assertQuoteAccuracy(quotedIn, actualIn, "WETH/USDC 3000 reverse exactOut quote mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Fee Tier: 1% (10000)                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteExactInputSingle on WETH/USDC 1% pool (higher fee tier)
    /// @dev On mainnet WETH_USDC_10000: USDC is token0, WETH is token1
    function test_quoteExactInputSingle_WETH_USDC_10000_zeroForOne() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_10000);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);

        // Very small swap for 1% pool to stay in single tick
        uint256 amountIn = 10e6; // 10 USDC

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_HIGH,
            zeroForOne
        );

        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        assertQuoteAccuracy(quotedOut, actualOut, "WETH/USDC 10000 exactIn quote mismatch");
    }

    /// @notice Test quoteExactOutputSingle on WETH/USDC 1% pool
    /// @dev On mainnet WETH_USDC_10000: USDC is token0, WETH is token1
    function test_quoteExactOutputSingle_WETH_USDC_10000_zeroForOne() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_10000);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);

        // Want 0.0001 WETH (tiny amount to stay in single tick)
        uint256 amountOut = 0.0001 ether;

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedIn = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_HIGH,
            zeroForOne
        );

        uint256 actualIn = swapExactOutputTokens(pool, USDC, WETH, amountOut, address(this));

        assertQuoteAccuracy(quotedIn, actualIn, "WETH/USDC 10000 exactOut quote mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                          WBTC/WETH Pool Tests                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Test on WBTC/WETH pool (different token pair)
    function test_quoteExactInputSingle_WBTC_WETH_3000() public {
        IUniswapV3Pool pool = getPool(WBTC_WETH_3000);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);

        // Small swap: 0.001 WBTC (8 decimals)
        uint256 amountIn = 0.001e8;

        bool zeroForOne = zeroForOneForTokens(pool, WBTC, WETH);

        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        uint256 actualOut = swapExactInputTokens(pool, WBTC, WETH, amountIn, address(this));

        assertQuoteAccuracy(quotedOut, actualOut, "WBTC/WETH 3000 exactIn quote mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Tick Overload Tests                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Test using tick overload function
    /// @dev On mainnet WETH_USDC_3000: USDC is token0, WETH is token1
    function test_quoteExactInputSingle_withTick() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, uint128 liquidity) = getPoolState(pool);

        // Small amount to stay in single tick
        uint256 amountIn = 50e6; // 50 USDC

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            tick,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        uint256 actualOut = swapExactInputTokens(pool, USDC, WETH, amountIn, address(this));

        // Tick-based quote may have slightly more error due to tick rounding
        assertQuoteAccuracy(quotedOut, actualOut, 50, "tick overload exactIn quote mismatch"); // 0.5% tolerance
    }

    /// @notice Test quoteExactOutputSingle using tick overload
    /// @dev On mainnet WETH_USDC_3000: USDC is token0, WETH is token1
    function test_quoteExactOutputSingle_withTick() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (, int24 tick, uint128 liquidity) = getPoolState(pool);

        // Small amount to stay in single tick
        uint256 amountOut = 0.0005 ether; // 0.0005 WETH

        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 quotedIn = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            tick,
            liquidity,
            FEE_MEDIUM,
            zeroForOne
        );

        uint256 actualIn = swapExactOutputTokens(pool, USDC, WETH, amountOut, address(this));

        assertQuoteAccuracy(quotedIn, actualIn, 50, "tick overload exactOut quote mismatch"); // 0.5% tolerance
    }

    /* -------------------------------------------------------------------------- */
    /*                       Liquidity Amount Helpers Tests                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteAmountsForLiquidity matches actual mint
    function test_quoteAmountsForLiquidity_matchesMint() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96, int24 tick, ) = getPoolState(pool);

        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        uint128 liquidity = 1e12; // Small liquidity amount

        // Quote amounts needed
        (uint256 quotedAmount0, uint256 quotedAmount1) = UniswapV3Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        // Pre-deal enough tokens for the mint
        deal(pool.token0(), address(this), quotedAmount0 * 2);
        deal(pool.token1(), address(this), quotedAmount1 * 2);

        // Actually mint position
        (uint256 actualAmount0, uint256 actualAmount1) = pool.mint(
            address(this),
            tickLower,
            tickUpper,
            liquidity,
            abi.encode(address(this))
        );

        // Assert amounts match (within 1 wei due to rounding)
        assertApproxEqAbs(quotedAmount0, actualAmount0, 1, "amount0 mismatch");
        assertApproxEqAbs(quotedAmount1, actualAmount1, 1, "amount1 mismatch");
    }

    /// @notice Test quoteLiquidityForAmounts
    function test_quoteLiquidityForAmounts() public {
        IUniswapV3Pool pool = getPool(WETH_USDC_3000);

        (uint160 sqrtPriceX96, int24 tick, ) = getPoolState(pool);

        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        address token0 = pool.token0();
        uint256 amount0 = token0 == WETH ? 1 ether : 1000e6;
        uint256 amount1 = token0 == WETH ? 1000e6 : 1 ether;

        // Quote max liquidity
        uint128 quotedLiquidity = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        // Verify: minting this liquidity should require <= provided amounts
        (uint256 requiredAmount0, uint256 requiredAmount1) = UniswapV3Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            quotedLiquidity
        );

        assertTrue(requiredAmount0 <= amount0, "requires too much amount0");
        assertTrue(requiredAmount1 <= amount1, "requires too much amount1");
        assertTrue(quotedLiquidity > 0, "liquidity should be > 0");
    }
}
