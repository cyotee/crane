// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {SlipstreamUtils} from "@crane/contracts/utils/math/SlipstreamUtils.sol";
import {TestBase_SlipstreamFork} from "./TestBase_SlipstreamFork.sol";

/// @title SlipstreamGas Fork Tests
/// @notice Gas benchmarks for SlipstreamUtils operations against production pools
/// @dev Measures gas costs for quoting operations with various input sizes
contract SlipstreamGas_Fork_Test is TestBase_SlipstreamFork {
    using SlipstreamUtils for uint256;

    /* -------------------------------------------------------------------------- */
    /*                          quoteExactInputSingle Gas                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Benchmark gas for quoteExactInputSingle with small amount (single tick)
    function test_gas_quoteExactInputSingle_small() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Small swap (100 USDC) - stays within single tick
        uint256 amountIn = 100e6;
        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 gasBefore = gasleft();
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("quoteExactInputSingle (100 USDC - single tick):");
        console.log("  Gas used:", gasUsed);
        console.log("  Quoted output:", quotedOut);

        // Verify quote is reasonable
        assertTrue(quotedOut > 0, "quote should be non-zero");
    }

    /// @notice Benchmark gas for quoteExactInputSingle with medium amount
    function test_gas_quoteExactInputSingle_medium() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Medium swap (1000 USDC)
        uint256 amountIn = 1000e6;
        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 gasBefore = gasleft();
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("quoteExactInputSingle (1000 USDC - medium):");
        console.log("  Gas used:", gasUsed);
        console.log("  Quoted output:", quotedOut);

        assertTrue(quotedOut > 0, "quote should be non-zero");
    }

    /// @notice Benchmark gas for quoteExactInputSingle with large amount
    function test_gas_quoteExactInputSingle_large() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Large swap (10,000 USDC) - may cross multiple ticks
        uint256 amountIn = 10_000e6;
        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 gasBefore = gasleft();
        uint256 quotedOut = SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("quoteExactInputSingle (10000 USDC - large):");
        console.log("  Gas used:", gasUsed);
        console.log("  Quoted output:", quotedOut);

        assertTrue(quotedOut > 0, "quote should be non-zero");
    }

    /* -------------------------------------------------------------------------- */
    /*                         quoteExactOutputSingle Gas                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Benchmark gas for quoteExactOutputSingle with small amount
    function test_gas_quoteExactOutputSingle_small() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Small output (0.01 WETH)
        uint256 amountOut = 0.01 ether;
        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 gasBefore = gasleft();
        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("quoteExactOutputSingle (0.01 WETH - small):");
        console.log("  Gas used:", gasUsed);
        console.log("  Quoted input:", quotedIn);

        assertTrue(quotedIn > 0, "quote should be non-zero");
    }

    /// @notice Benchmark gas for quoteExactOutputSingle with medium amount
    function test_gas_quoteExactOutputSingle_medium() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Medium output (0.1 WETH)
        uint256 amountOut = 0.1 ether;
        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 gasBefore = gasleft();
        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("quoteExactOutputSingle (0.1 WETH - medium):");
        console.log("  Gas used:", gasUsed);
        console.log("  Quoted input:", quotedIn);

        assertTrue(quotedIn > 0, "quote should be non-zero");
    }

    /// @notice Benchmark gas for quoteExactOutputSingle with large amount
    function test_gas_quoteExactOutputSingle_large() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, , uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        // Large output (1 WETH)
        uint256 amountOut = 1 ether;
        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        uint256 gasBefore = gasleft();
        uint256 quotedIn = SlipstreamUtils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("quoteExactOutputSingle (1 WETH - large):");
        console.log("  Gas used:", gasUsed);
        console.log("  Quoted input:", quotedIn);

        assertTrue(quotedIn > 0, "quote should be non-zero");
    }

    /* -------------------------------------------------------------------------- */
    /*                        Tick Overload Gas Comparison                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Compare gas for sqrtPrice vs tick overload
    function test_gas_tickOverload_comparison() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, int24 tick, uint128 liquidity) = getPoolState(pool);
        uint24 fee = getPoolFee(pool);

        uint256 amountIn = 100e6;
        bool zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        // Measure gas with sqrtPriceX96
        uint256 gasBefore = gasleft();
        SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            fee,
            zeroForOne
        );
        uint256 gasSqrtPrice = gasBefore - gasleft();

        // Measure gas with tick (requires TickMath.getSqrtRatioAtTick conversion)
        gasBefore = gasleft();
        SlipstreamUtils._quoteExactInputSingle(
            amountIn,
            tick,
            liquidity,
            fee,
            zeroForOne
        );
        uint256 gasTick = gasBefore - gasleft();

        console.log("Tick overload gas comparison:");
        console.log("  With sqrtPriceX96:", gasSqrtPrice);
        console.log("  With tick:", gasTick);
        console.log("  Tick overhead:", gasTick > gasSqrtPrice ? gasTick - gasSqrtPrice : 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                         Liquidity Helpers Gas                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Benchmark gas for quoteAmountsForLiquidity
    function test_gas_quoteAmountsForLiquidity() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = pool.tickSpacing();

        int24 tickLower = nearestUsableTick(tick - 1000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1000, tickSpacing);
        uint128 liquidity = 1e18;

        uint256 gasBefore = gasleft();
        (uint256 amount0, uint256 amount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("quoteAmountsForLiquidity:");
        console.log("  Gas used:", gasUsed);
        console.log("  amount0:", amount0);
        console.log("  amount1:", amount1);
    }

    /// @notice Benchmark gas for quoteLiquidityForAmounts
    function test_gas_quoteLiquidityForAmounts() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        (uint160 sqrtPriceX96, int24 tick, ) = getPoolState(pool);
        int24 tickSpacing = pool.tickSpacing();

        int24 tickLower = nearestUsableTick(tick - 1000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1000, tickSpacing);

        address token0 = pool.token0();
        uint256 amount0 = token0 == WETH ? 1 ether : 1000e6;
        uint256 amount1 = token0 == WETH ? 1000e6 : 1 ether;

        uint256 gasBefore = gasleft();
        uint128 liquidity = SlipstreamUtils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("quoteLiquidityForAmounts:");
        console.log("  Gas used:", gasUsed);
        console.log("  liquidity:", liquidity);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Gas Summary Report                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Struct to bundle pool state to avoid stack too deep
    struct PoolState {
        uint160 sqrtPriceX96;
        int24 tick;
        uint128 liquidity;
        uint24 fee;
        int24 tickSpacing;
        bool zeroForOne;
    }

    /// @notice Generate a complete gas benchmark report
    function test_gas_summary_report() public {
        ICLPool pool = getPool(WETH_USDC_CL_500);

        PoolState memory state;
        (state.sqrtPriceX96, state.tick, state.liquidity) = getPoolState(pool);
        state.fee = getPoolFee(pool);
        state.tickSpacing = pool.tickSpacing();
        state.zeroForOne = zeroForOneForTokens(pool, USDC, WETH);

        console.log("==================================================");
        console.log("  SlipstreamUtils Gas Benchmark Report");
        console.log("==================================================");
        console.log("");
        console.log("Pool: WETH/USDC 0.05% (Base mainnet)");
        console.log("  Fee:", state.fee);
        console.log("  Tick spacing:", state.tickSpacing);
        console.log("  Current liquidity:", state.liquidity);
        console.log("");

        _benchmarkExactInput(state);
        _benchmarkExactOutput(state);
        _benchmarkTickOverload(state);
        _benchmarkLiquidityHelpers(pool, state);

        console.log("==================================================");
    }

    function _benchmarkExactInput(PoolState memory state) internal view {
        console.log("quoteExactInputSingle Gas:");
        uint256 gasBefore;
        uint256 gasUsed;

        gasBefore = gasleft();
        SlipstreamUtils._quoteExactInputSingle(10e6, state.sqrtPriceX96, state.liquidity, state.fee, state.zeroForOne);
        gasUsed = gasBefore - gasleft();
        console.log("  10 USDC:", gasUsed);

        gasBefore = gasleft();
        SlipstreamUtils._quoteExactInputSingle(100e6, state.sqrtPriceX96, state.liquidity, state.fee, state.zeroForOne);
        gasUsed = gasBefore - gasleft();
        console.log("  100 USDC:", gasUsed);

        gasBefore = gasleft();
        SlipstreamUtils._quoteExactInputSingle(1000e6, state.sqrtPriceX96, state.liquidity, state.fee, state.zeroForOne);
        gasUsed = gasBefore - gasleft();
        console.log("  1000 USDC:", gasUsed);

        gasBefore = gasleft();
        SlipstreamUtils._quoteExactInputSingle(10_000e6, state.sqrtPriceX96, state.liquidity, state.fee, state.zeroForOne);
        gasUsed = gasBefore - gasleft();
        console.log("  10000 USDC:", gasUsed);
        console.log("");
    }

    function _benchmarkExactOutput(PoolState memory state) internal view {
        console.log("quoteExactOutputSingle Gas:");
        uint256 gasBefore;
        uint256 gasUsed;

        gasBefore = gasleft();
        SlipstreamUtils._quoteExactOutputSingle(0.001 ether, state.sqrtPriceX96, state.liquidity, state.fee, state.zeroForOne);
        gasUsed = gasBefore - gasleft();
        console.log("  0.001 WETH:", gasUsed);

        gasBefore = gasleft();
        SlipstreamUtils._quoteExactOutputSingle(0.01 ether, state.sqrtPriceX96, state.liquidity, state.fee, state.zeroForOne);
        gasUsed = gasBefore - gasleft();
        console.log("  0.01 WETH:", gasUsed);

        gasBefore = gasleft();
        SlipstreamUtils._quoteExactOutputSingle(0.1 ether, state.sqrtPriceX96, state.liquidity, state.fee, state.zeroForOne);
        gasUsed = gasBefore - gasleft();
        console.log("  0.1 WETH:", gasUsed);

        gasBefore = gasleft();
        SlipstreamUtils._quoteExactOutputSingle(1 ether, state.sqrtPriceX96, state.liquidity, state.fee, state.zeroForOne);
        gasUsed = gasBefore - gasleft();
        console.log("  1 WETH:", gasUsed);
        console.log("");
    }

    function _benchmarkTickOverload(PoolState memory state) internal view {
        console.log("Tick Overload Overhead:");

        uint256 gasBefore = gasleft();
        SlipstreamUtils._quoteExactInputSingle(100e6, state.sqrtPriceX96, state.liquidity, state.fee, state.zeroForOne);
        uint256 gasSqrtPrice = gasBefore - gasleft();

        gasBefore = gasleft();
        SlipstreamUtils._quoteExactInputSingle(100e6, state.tick, state.liquidity, state.fee, state.zeroForOne);
        uint256 gasTick = gasBefore - gasleft();

        console.log("  sqrtPriceX96 overload:", gasSqrtPrice);
        console.log("  tick overload:", gasTick);
        console.log("  overhead:", gasTick > gasSqrtPrice ? gasTick - gasSqrtPrice : 0);
        console.log("");
    }

    function _benchmarkLiquidityHelpers(ICLPool pool, PoolState memory state) internal view {
        console.log("Liquidity Helpers Gas:");

        int24 tickLower = nearestUsableTick(state.tick - 1000, state.tickSpacing);
        int24 tickUpper = nearestUsableTick(state.tick + 1000, state.tickSpacing);

        uint256 gasBefore = gasleft();
        SlipstreamUtils._quoteAmountsForLiquidity(state.sqrtPriceX96, tickLower, tickUpper, 1e18);
        uint256 gasUsed = gasBefore - gasleft();
        console.log("  quoteAmountsForLiquidity:", gasUsed);

        address token0 = pool.token0();
        uint256 amount0 = token0 == WETH ? 1 ether : 1000e6;
        uint256 amount1 = token0 == WETH ? 1000e6 : 1 ether;

        gasBefore = gasleft();
        SlipstreamUtils._quoteLiquidityForAmounts(state.sqrtPriceX96, tickLower, tickUpper, amount0, amount1);
        gasUsed = gasBefore - gasleft();
        console.log("  quoteLiquidityForAmounts:", gasUsed);
        console.log("");
    }
}
