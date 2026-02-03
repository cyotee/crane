// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {AerodromeUtils} from "@crane/contracts/utils/math/AerodromeUtils.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {TestBase_AerodromeFork} from "./TestBase_AerodromeFork.sol";

/// @title AerodromeVolatileUtils Fork Tests
/// @notice Validates Crane volatile pool math against production Aerodrome pools on Base mainnet
/// @dev Tests AerodromeUtils and ConstProdUtils quote calculations against actual swap results
///
/// ## Test Strategy
///
/// For volatile pools (xy = k curve), we compare:
/// 1. Pool's `getAmountOut()` - the on-chain reference implementation
/// 2. Router's actual swap execution
/// 3. Our local quote utilities (when applicable)
///
/// The pool's `getAmountOut` is the ground truth for Aerodrome math.
/// We verify our utilities match this for parity.
contract AerodromeVolatileUtils_Fork_Test is TestBase_AerodromeFork {
    using ConstProdUtils for uint256;

    /* -------------------------------------------------------------------------- */
    /*                     WETH/USDC Volatile Pool Tests                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Test volatile pool quote parity: pool.getAmountOut vs router execution
    /// @dev Validates that the pool's quote function matches actual swap output
    function test_volatileQuote_WETH_USDC_sellWETH_small() public {
        skipIfPoolInvalid(WETH_USDC_VOLATILE, "WETH_USDC_VOLATILE");

        IPool pool = getPool(WETH_USDC_VOLATILE);

        // Log pool state
        (uint256 reserve0, uint256 reserve1) = getPoolReserves(pool);
        uint256 fee = getPoolFee(pool);

        console.log("Pool: WETH/USDC Volatile");
        console.log("  token0:", pool.token0());
        console.log("  token1:", pool.token1());
        console.log("  reserve0:", reserve0);
        console.log("  reserve1:", reserve1);
        console.log("  fee (bps):", fee);

        // Small swap: 0.01 WETH -> USDC
        uint256 amountIn = 0.01 ether;

        // Quote via pool
        uint256 quotedOut = pool.getAmountOut(amountIn, WETH);

        console.log("  amountIn (WETH):", amountIn);
        console.log("  quotedOut (USDC):", quotedOut);

        // Execute swap via router
        uint256 actualOut = swapViaRouter(WETH, USDC, amountIn, false, address(this));

        console.log("  actualOut (USDC):", actualOut);

        // Pool quote should match router execution exactly for volatile pools
        assertExactMatch(quotedOut, actualOut, "Volatile quote should match router execution");
    }

    /// @notice Test volatile pool quote parity: sell USDC for WETH (reverse direction)
    function test_volatileQuote_WETH_USDC_sellUSDC_small() public {
        skipIfPoolInvalid(WETH_USDC_VOLATILE, "WETH_USDC_VOLATILE");

        IPool pool = getPool(WETH_USDC_VOLATILE);

        // Small swap: 100 USDC -> WETH
        uint256 amountIn = 100e6; // 100 USDC (6 decimals)

        // Quote via pool
        uint256 quotedOut = pool.getAmountOut(amountIn, USDC);

        console.log("Pool: WETH/USDC Volatile (sell USDC)");
        console.log("  amountIn (USDC):", amountIn);
        console.log("  quotedOut (WETH):", quotedOut);

        // Execute swap via router
        uint256 actualOut = swapViaRouter(USDC, WETH, amountIn, false, address(this));

        console.log("  actualOut (WETH):", actualOut);

        assertExactMatch(quotedOut, actualOut, "Volatile quote should match router execution (reverse)");
    }

    /// @notice Test volatile pool quote with medium trade size
    function test_volatileQuote_WETH_USDC_sellWETH_medium() public {
        skipIfPoolInvalid(WETH_USDC_VOLATILE, "WETH_USDC_VOLATILE");

        IPool pool = getPool(WETH_USDC_VOLATILE);

        // Medium swap: 1 WETH -> USDC
        uint256 amountIn = 1 ether;

        // Quote via pool
        uint256 quotedOut = pool.getAmountOut(amountIn, WETH);

        console.log("Pool: WETH/USDC Volatile (medium size)");
        console.log("  amountIn (WETH):", amountIn);
        console.log("  quotedOut (USDC):", quotedOut);

        // Execute swap via router
        uint256 actualOut = swapViaRouter(WETH, USDC, amountIn, false, address(this));

        console.log("  actualOut (USDC):", actualOut);

        assertExactMatch(quotedOut, actualOut, "Medium trade quote should match execution");
    }

    /// @notice Test volatile pool quote with large trade size
    function test_volatileQuote_WETH_USDC_sellWETH_large() public {
        skipIfPoolInvalid(WETH_USDC_VOLATILE, "WETH_USDC_VOLATILE");

        IPool pool = getPool(WETH_USDC_VOLATILE);

        // Large swap: 10 WETH -> USDC (significant price impact)
        uint256 amountIn = 10 ether;

        // Quote via pool
        uint256 quotedOut = pool.getAmountOut(amountIn, WETH);

        console.log("Pool: WETH/USDC Volatile (large size)");
        console.log("  amountIn (WETH):", amountIn);
        console.log("  quotedOut (USDC):", quotedOut);

        // Execute swap via router
        uint256 actualOut = swapViaRouter(WETH, USDC, amountIn, false, address(this));

        console.log("  actualOut (USDC):", actualOut);

        assertExactMatch(quotedOut, actualOut, "Large trade quote should match execution");
    }

    /* -------------------------------------------------------------------------- */
    /*                      WETH/AERO Volatile Pool Tests                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Test volatile pool quote on WETH/AERO pair
    function test_volatileQuote_WETH_AERO_sellWETH() public {
        skipIfPoolInvalid(WETH_AERO_VOLATILE, "WETH_AERO_VOLATILE");

        IPool pool = getPool(WETH_AERO_VOLATILE);

        (uint256 reserve0, uint256 reserve1) = getPoolReserves(pool);
        uint256 fee = getPoolFee(pool);

        console.log("Pool: WETH/AERO Volatile");
        console.log("  token0:", pool.token0());
        console.log("  token1:", pool.token1());
        console.log("  reserve0:", reserve0);
        console.log("  reserve1:", reserve1);
        console.log("  fee (bps):", fee);

        // Swap: 0.1 WETH -> AERO
        uint256 amountIn = 0.1 ether;

        // Quote via pool
        uint256 quotedOut = pool.getAmountOut(amountIn, WETH);

        console.log("  amountIn (WETH):", amountIn);
        console.log("  quotedOut (AERO):", quotedOut);

        // Execute swap via router
        uint256 actualOut = swapViaRouter(WETH, AERO, amountIn, false, address(this));

        console.log("  actualOut (AERO):", actualOut);

        assertExactMatch(quotedOut, actualOut, "WETH/AERO quote should match execution");
    }

    /// @notice Test volatile pool quote on WETH/AERO pair (reverse direction)
    function test_volatileQuote_WETH_AERO_sellAERO() public {
        skipIfPoolInvalid(WETH_AERO_VOLATILE, "WETH_AERO_VOLATILE");

        IPool pool = getPool(WETH_AERO_VOLATILE);

        // Swap: 1000 AERO -> WETH
        uint256 amountIn = 1000 ether; // AERO has 18 decimals

        // Quote via pool
        uint256 quotedOut = pool.getAmountOut(amountIn, AERO);

        console.log("Pool: WETH/AERO Volatile (sell AERO)");
        console.log("  amountIn (AERO):", amountIn);
        console.log("  quotedOut (WETH):", quotedOut);

        // Execute swap via router
        uint256 actualOut = swapViaRouter(AERO, WETH, amountIn, false, address(this));

        console.log("  actualOut (WETH):", actualOut);

        assertExactMatch(quotedOut, actualOut, "AERO/WETH quote should match execution");
    }

    /* -------------------------------------------------------------------------- */
    /*                     ConstProdUtils Parity Tests                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Test ConstProdUtils._saleQuote matches pool.getAmountOut for volatile pools
    /// @dev This validates our local math library against Aerodrome's implementation
    function test_constProdUtils_saleQuote_parity() public {
        skipIfPoolInvalid(WETH_USDC_VOLATILE, "WETH_USDC_VOLATILE");

        IPool pool = getPool(WETH_USDC_VOLATILE);

        (uint256 reserve0, uint256 reserve1) = getPoolReserves(pool);
        uint256 fee = getPoolFee(pool);

        address token0 = pool.token0();
        bool wethIsToken0 = token0 == WETH;

        // Swap: 0.05 WETH -> USDC
        uint256 amountIn = 0.05 ether;

        // Pool quote (ground truth)
        uint256 poolQuote = pool.getAmountOut(amountIn, WETH);

        // ConstProdUtils._saleQuote expects:
        // - amountIn: amount being sold
        // - reserveIn: reserve of the token being sold
        // - reserveOut: reserve of the token being bought
        // - feePercent: fee in same units as feeDenominator
        // - feeDenominator: fee base (10000 for Aerodrome)
        uint256 reserveIn = wethIsToken0 ? reserve0 : reserve1;
        uint256 reserveOut = wethIsToken0 ? reserve1 : reserve0;

        uint256 constProdQuote = ConstProdUtils._saleQuote(
            amountIn,
            reserveIn,
            reserveOut,
            fee,
            AERO_FEE_DENOM
        );

        console.log("ConstProdUtils parity test:");
        console.log("  amountIn (WETH):", amountIn);
        console.log("  poolQuote:", poolQuote);
        console.log("  constProdQuote:", constProdQuote);
        console.log("  reserveIn:", reserveIn);
        console.log("  reserveOut:", reserveOut);
        console.log("  fee:", fee);

        // Allow 1 wei tolerance for rounding differences
        assertApproxEqAbs(
            constProdQuote,
            poolQuote,
            1,
            "ConstProdUtils quote should match pool quote (1 wei tolerance)"
        );
    }

    /// @notice Test ConstProdUtils parity with reverse direction
    function test_constProdUtils_saleQuote_parity_reverse() public {
        skipIfPoolInvalid(WETH_USDC_VOLATILE, "WETH_USDC_VOLATILE");

        IPool pool = getPool(WETH_USDC_VOLATILE);

        (uint256 reserve0, uint256 reserve1) = getPoolReserves(pool);
        uint256 fee = getPoolFee(pool);

        address token0 = pool.token0();
        bool usdcIsToken0 = token0 == USDC;

        // Swap: 500 USDC -> WETH
        uint256 amountIn = 500e6;

        // Pool quote (ground truth)
        uint256 poolQuote = pool.getAmountOut(amountIn, USDC);

        // ConstProdUtils._saleQuote
        uint256 reserveIn = usdcIsToken0 ? reserve0 : reserve1;
        uint256 reserveOut = usdcIsToken0 ? reserve1 : reserve0;

        uint256 constProdQuote = ConstProdUtils._saleQuote(
            amountIn,
            reserveIn,
            reserveOut,
            fee,
            AERO_FEE_DENOM
        );

        console.log("ConstProdUtils parity test (reverse):");
        console.log("  amountIn (USDC):", amountIn);
        console.log("  poolQuote:", poolQuote);
        console.log("  constProdQuote:", constProdQuote);

        assertApproxEqAbs(
            constProdQuote,
            poolQuote,
            1,
            "ConstProdUtils quote should match pool quote (reverse)"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                        Fee Handling Validation                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Validate fee is applied correctly by comparing with/without fee
    function test_volatileFee_isApplied() public {
        skipIfPoolInvalid(WETH_USDC_VOLATILE, "WETH_USDC_VOLATILE");

        IPool pool = getPool(WETH_USDC_VOLATILE);

        (uint256 reserve0, uint256 reserve1) = getPoolReserves(pool);
        uint256 fee = getPoolFee(pool);

        address token0 = pool.token0();
        bool wethIsToken0 = token0 == WETH;

        uint256 amountIn = 1 ether;

        // Calculate output WITHOUT fee (pure xy=k math)
        uint256 saleReserve = wethIsToken0 ? reserve0 : reserve1;
        uint256 purchaseReserve = wethIsToken0 ? reserve1 : reserve0;

        // Pure xy=k: dy = (dx * reserveOut) / (reserveIn + dx)
        uint256 outputNoFee = (amountIn * purchaseReserve) / (saleReserve + amountIn);

        // Actual pool quote (with fee)
        uint256 poolQuote = pool.getAmountOut(amountIn, WETH);

        console.log("Fee validation:");
        console.log("  amountIn:", amountIn);
        console.log("  outputNoFee:", outputNoFee);
        console.log("  poolQuote (with fee):", poolQuote);
        console.log("  fee (bps):", fee);
        console.log("  difference:", outputNoFee - poolQuote);

        // Pool output should be less than no-fee output
        assertTrue(poolQuote < outputNoFee, "Fee should reduce output");

        // Verify fee is approximately correct
        // With fee: output = (amountInAfterFee * reserveOut) / (reserveIn + amountInAfterFee)
        // amountInAfterFee = amountIn * (10000 - fee) / 10000
        uint256 amountInAfterFee = (amountIn * (AERO_FEE_DENOM - fee)) / AERO_FEE_DENOM;
        uint256 expectedOutput = (amountInAfterFee * purchaseReserve) / (saleReserve + amountInAfterFee);

        console.log("  expectedOutput (manual calc):", expectedOutput);

        assertApproxEqAbs(
            poolQuote,
            expectedOutput,
            1,
            "Pool output should match manual fee calculation"
        );
    }

    /// @notice Verify Aerodrome uses 10000 denominator (not 100000 like UniswapV2)
    function test_volatileFee_denominator_is_10000() public {
        skipIfPoolInvalid(WETH_USDC_VOLATILE, "WETH_USDC_VOLATILE");

        IPool pool = getPool(WETH_USDC_VOLATILE);
        uint256 fee = getPoolFee(pool);

        console.log("Fee denominator test:");
        console.log("  fee (raw):", fee);

        // Aerodrome V1 default volatile fee is typically 30 (0.30%)
        // If using 100000 denom, fee would be 300
        assertTrue(fee < 100, "Fee should be < 100 (using 10000 denominator, not 100000)");
        assertTrue(fee > 0, "Fee should be > 0");
    }
}
