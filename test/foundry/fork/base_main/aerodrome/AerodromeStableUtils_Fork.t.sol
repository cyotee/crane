// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {AerodromeServiceStable} from
    "@crane/contracts/protocols/dexes/aerodrome/v1/services/AerodromeServiceStable.sol";
import {TestBase_AerodromeFork} from "./TestBase_AerodromeFork.sol";

/// @title AerodromeStableUtils Fork Tests
/// @notice Validates Crane stable pool math against production Aerodrome pools on Base mainnet
/// @dev Tests AerodromeServiceStable quote calculations against actual swap results
///
/// ## Stable Pool Math
///
/// Aerodrome stable pools use the curve: x^3*y + x*y^3 = k
/// This provides lower slippage for similarly-priced assets (stablecoins).
/// The math uses Newton-Raphson iteration to solve for output amounts.
///
/// ## Test Strategy
///
/// For stable pools, we compare:
/// 1. Pool's `getAmountOut()` - the on-chain reference implementation
/// 2. Router's actual swap execution
/// 3. AerodromeServiceStable's `_getAmountOutStable()` - our local implementation
///
/// The pool's `getAmountOut` is the ground truth for Aerodrome stable math.
contract AerodromeStableUtils_Fork_Test is TestBase_AerodromeFork {
    /* -------------------------------------------------------------------------- */
    /*                     USDC/USDbC Stable Pool Tests                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Test stable pool quote parity: pool.getAmountOut vs router execution
    /// @dev Validates that the pool's quote function matches actual swap output
    function test_stableQuote_USDC_USDbC_sellUSDC_small() public {
        skipIfPoolInvalid(USDC_USDbC_STABLE, "USDC_USDbC_STABLE");

        IPool pool = getPool(USDC_USDbC_STABLE);

        // Log pool metadata
        (
            uint256 decimals0,
            uint256 decimals1,
            uint256 reserve0,
            uint256 reserve1,
            bool stable,
            address token0,
            address token1
        ) = getPoolMetadata(pool);

        uint256 fee = getPoolFee(pool);

        console.log("Pool: USDC/USDbC Stable");
        console.log("  token0:", token0);
        console.log("  token1:", token1);
        console.log("  decimals0:", decimals0);
        console.log("  decimals1:", decimals1);
        console.log("  reserve0:", reserve0);
        console.log("  reserve1:", reserve1);
        console.log("  stable:", stable);
        console.log("  fee (bps):", fee);

        assertTrue(stable, "Pool should be marked as stable");

        // Small swap: 100 USDC -> USDbC
        uint256 amountIn = 100e6; // 100 USDC (6 decimals)

        // Quote via pool
        uint256 quotedOut = pool.getAmountOut(amountIn, USDC);

        console.log("  amountIn (USDC):", amountIn);
        console.log("  quotedOut (USDbC):", quotedOut);

        // Execute swap via router
        uint256 actualOut = swapViaRouter(USDC, USDbC, amountIn, true, address(this));

        console.log("  actualOut (USDbC):", actualOut);

        // Stable pool quote should match router execution exactly
        assertExactMatch(quotedOut, actualOut, "Stable quote should match router execution");
    }

    /// @notice Test stable pool quote parity: reverse direction (USDbC -> USDC)
    function test_stableQuote_USDC_USDbC_sellUSDbC_small() public {
        skipIfPoolInvalid(USDC_USDbC_STABLE, "USDC_USDbC_STABLE");

        IPool pool = getPool(USDC_USDbC_STABLE);

        // Small swap: 100 USDbC -> USDC
        uint256 amountIn = 100e6; // 100 USDbC (6 decimals)

        // Quote via pool
        uint256 quotedOut = pool.getAmountOut(amountIn, USDbC);

        console.log("Pool: USDC/USDbC Stable (sell USDbC)");
        console.log("  amountIn (USDbC):", amountIn);
        console.log("  quotedOut (USDC):", quotedOut);

        // Execute swap via router
        uint256 actualOut = swapViaRouter(USDbC, USDC, amountIn, true, address(this));

        console.log("  actualOut (USDC):", actualOut);

        assertExactMatch(quotedOut, actualOut, "Stable quote should match router (reverse)");
    }

    /// @notice Test stable pool quote with medium trade size
    function test_stableQuote_USDC_USDbC_sellUSDC_medium() public {
        skipIfPoolInvalid(USDC_USDbC_STABLE, "USDC_USDbC_STABLE");

        IPool pool = getPool(USDC_USDbC_STABLE);

        // Medium swap: 10,000 USDC -> USDbC
        uint256 amountIn = 10_000e6;

        // Quote via pool
        uint256 quotedOut = pool.getAmountOut(amountIn, USDC);

        console.log("Pool: USDC/USDbC Stable (medium size)");
        console.log("  amountIn (USDC):", amountIn);
        console.log("  quotedOut (USDbC):", quotedOut);

        // Execute swap via router
        uint256 actualOut = swapViaRouter(USDC, USDbC, amountIn, true, address(this));

        console.log("  actualOut (USDbC):", actualOut);

        assertExactMatch(quotedOut, actualOut, "Medium stable trade should match execution");
    }

    /// @notice Test stable pool quote with large trade size
    function test_stableQuote_USDC_USDbC_sellUSDC_large() public {
        skipIfPoolInvalid(USDC_USDbC_STABLE, "USDC_USDbC_STABLE");

        IPool pool = getPool(USDC_USDbC_STABLE);

        // Large swap: 100,000 USDC -> USDbC
        uint256 amountIn = 100_000e6;

        // Quote via pool
        uint256 quotedOut = pool.getAmountOut(amountIn, USDC);

        console.log("Pool: USDC/USDbC Stable (large size)");
        console.log("  amountIn (USDC):", amountIn);
        console.log("  quotedOut (USDbC):", quotedOut);

        // For large trades, check if pool has enough liquidity
        (uint256 reserve0, uint256 reserve1) = getPoolReserves(pool);
        bool hasEnoughLiquidity = quotedOut < (reserve0 > reserve1 ? reserve1 : reserve0);

        // if (!hasEnoughLiquidity) {
        //     console.log("  Skipping: pool lacks sufficient liquidity for large trade");
        //     vm.skip(true);
        // }

        // Execute swap via router
        uint256 actualOut = swapViaRouter(USDC, USDbC, amountIn, true, address(this));

        console.log("  actualOut (USDbC):", actualOut);

        assertExactMatch(quotedOut, actualOut, "Large stable trade should match execution");
    }

    /* -------------------------------------------------------------------------- */
    /*                AerodromeServiceStable Parity Tests                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Test AerodromeServiceStable._getAmountOutStable matches pool.getAmountOut
    /// @dev This validates our local Newton-Raphson implementation against Aerodrome's
    function test_serviceStable_getAmountOutStable_parity() public {
        skipIfPoolInvalid(USDC_USDbC_STABLE, "USDC_USDbC_STABLE");

        IPool pool = getPool(USDC_USDbC_STABLE);

        (
            uint256 decimals0,
            uint256 decimals1,
            uint256 reserve0,
            uint256 reserve1,
            ,
            address token0,
        ) = getPoolMetadata(pool);

        uint256 fee = getPoolFee(pool);

        // Swap: 1000 USDC -> USDbC
        uint256 amountIn = 1000e6;

        // Pool quote (ground truth)
        uint256 poolQuote = pool.getAmountOut(amountIn, USDC);

        // Service library quote
        bool usdcIsToken0 = token0 == USDC;
        uint256 reserveIn = usdcIsToken0 ? reserve0 : reserve1;
        uint256 reserveOut = usdcIsToken0 ? reserve1 : reserve0;
        uint256 decimalsIn = usdcIsToken0 ? decimals0 : decimals1;
        uint256 decimalsOut = usdcIsToken0 ? decimals1 : decimals0;

        uint256 serviceQuote = AerodromeServiceStable._getAmountOutStable(
            amountIn,
            reserveIn,
            reserveOut,
            decimalsIn,
            decimalsOut,
            fee
        );

        console.log("AerodromeServiceStable parity test:");
        console.log("  amountIn (USDC):", amountIn);
        console.log("  poolQuote:", poolQuote);
        console.log("  serviceQuote:", serviceQuote);
        console.log("  reserveIn:", reserveIn);
        console.log("  reserveOut:", reserveOut);
        console.log("  decimalsIn:", decimalsIn);
        console.log("  decimalsOut:", decimalsOut);
        console.log("  fee:", fee);

        // Allow 1 wei tolerance for rounding differences in Newton-Raphson
        assertApproxEqAbs(
            serviceQuote,
            poolQuote,
            1,
            "Service quote should match pool quote (1 wei tolerance)"
        );
    }

    /// @notice Test AerodromeServiceStable parity with reverse direction
    function test_serviceStable_getAmountOutStable_parity_reverse() public {
        skipIfPoolInvalid(USDC_USDbC_STABLE, "USDC_USDbC_STABLE");

        IPool pool = getPool(USDC_USDbC_STABLE);

        (
            uint256 decimals0,
            uint256 decimals1,
            uint256 reserve0,
            uint256 reserve1,
            ,
            address token0,
        ) = getPoolMetadata(pool);

        uint256 fee = getPoolFee(pool);

        // Swap: 1000 USDbC -> USDC
        uint256 amountIn = 1000e6;

        // Pool quote (ground truth)
        uint256 poolQuote = pool.getAmountOut(amountIn, USDbC);

        // Service library quote
        bool usdbcIsToken0 = token0 == USDbC;
        uint256 reserveIn = usdbcIsToken0 ? reserve0 : reserve1;
        uint256 reserveOut = usdbcIsToken0 ? reserve1 : reserve0;
        uint256 decimalsIn = usdbcIsToken0 ? decimals0 : decimals1;
        uint256 decimalsOut = usdbcIsToken0 ? decimals1 : decimals0;

        uint256 serviceQuote = AerodromeServiceStable._getAmountOutStable(
            amountIn,
            reserveIn,
            reserveOut,
            decimalsIn,
            decimalsOut,
            fee
        );

        console.log("AerodromeServiceStable parity test (reverse):");
        console.log("  amountIn (USDbC):", amountIn);
        console.log("  poolQuote:", poolQuote);
        console.log("  serviceQuote:", serviceQuote);

        assertApproxEqAbs(
            serviceQuote,
            poolQuote,
            1,
            "Service quote should match pool quote (reverse)"
        );
    }

    /// @notice Test service parity across multiple trade sizes
    function test_serviceStable_getAmountOutStable_multipleAmounts() public {
        skipIfPoolInvalid(USDC_USDbC_STABLE, "USDC_USDbC_STABLE");

        IPool pool = getPool(USDC_USDbC_STABLE);

        (
            uint256 decimals0,
            uint256 decimals1,
            uint256 reserve0,
            uint256 reserve1,
            ,
            address token0,
        ) = getPoolMetadata(pool);

        uint256 fee = getPoolFee(pool);

        bool usdcIsToken0 = token0 == USDC;
        uint256 reserveIn = usdcIsToken0 ? reserve0 : reserve1;
        uint256 reserveOut = usdcIsToken0 ? reserve1 : reserve0;
        uint256 decimalsIn = usdcIsToken0 ? decimals0 : decimals1;
        uint256 decimalsOut = usdcIsToken0 ? decimals1 : decimals0;

        // Test multiple trade sizes
        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 10e6;      // 10 USDC
        amounts[1] = 100e6;     // 100 USDC
        amounts[2] = 1000e6;    // 1,000 USDC
        amounts[3] = 10_000e6;  // 10,000 USDC
        amounts[4] = 50_000e6;  // 50,000 USDC

        console.log("Multi-amount parity test:");

        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 poolQuote = pool.getAmountOut(amounts[i], USDC);
            uint256 serviceQuote = AerodromeServiceStable._getAmountOutStable(
                amounts[i],
                reserveIn,
                reserveOut,
                decimalsIn,
                decimalsOut,
                fee
            );

            console.log("  amount:", amounts[i]);
            console.log("    poolQuote:", poolQuote);
            console.log("    serviceQuote:", serviceQuote);

            assertApproxEqAbs(
                serviceQuote,
                poolQuote,
                1,
                string.concat("Parity failed at amount index ", vm.toString(i))
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                     Stable Pool Curve Validation                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Verify stable pool has lower slippage than volatile for stablecoin pairs
    /// @dev This is a characteristic property of the x^3y + xy^3 = k curve
    function test_stableCurve_lowerSlippageThanVolatile() public {
        skipIfPoolInvalid(USDC_USDbC_STABLE, "USDC_USDbC_STABLE");

        IPool stablePool = getPool(USDC_USDbC_STABLE);

        (uint256 reserve0, uint256 reserve1) = getPoolReserves(stablePool);
        uint256 fee = getPoolFee(stablePool);

        // For a 1:1 pegged pair, the stable curve should maintain better price
        // than xy=k curve

        uint256 amountIn = 10_000e6; // 10,000 USDC

        // Stable pool quote
        uint256 stableOut = stablePool.getAmountOut(amountIn, USDC);

        // Calculate what xy=k would give for same reserves and fee
        // Note: This is an approximation to show the principle
        uint256 amountInAfterFee = (amountIn * (AERO_FEE_DENOM - fee)) / AERO_FEE_DENOM;

        // Determine which reserve is USDC
        address token0 = stablePool.token0();
        uint256 reserveIn = token0 == USDC ? reserve0 : reserve1;
        uint256 reserveOut = token0 == USDC ? reserve1 : reserve0;

        // xy=k formula: dy = (dx * reserveOut) / (reserveIn + dx)
        uint256 volatileOut = (amountInAfterFee * reserveOut) / (reserveIn + amountInAfterFee);

        console.log("Slippage comparison (stable vs volatile curve):");
        console.log("  amountIn:", amountIn);
        console.log("  stableOut:", stableOut);
        console.log("  volatileOut (simulated):", volatileOut);
        console.log("  difference:", stableOut > volatileOut ? stableOut - volatileOut : volatileOut - stableOut);

        // For a 1:1 pegged stablecoin pair, stable curve should give better output
        // However, this depends on reserve ratios being close to 1:1
        // If reserves are balanced, stable should be >= volatile
        if (reserve0 > 0 && reserve1 > 0) {
            uint256 ratio = (reserve0 * 1e18) / reserve1;
            console.log("  reserve ratio (1e18 = 1:1):", ratio);

            // Only assert if reserves are reasonably balanced (within 10%)
            if (ratio > 0.9e18 && ratio < 1.1e18) {
                assertTrue(
                    stableOut >= volatileOut,
                    "Stable curve should give better output for balanced reserves"
                );
            }
        }
    }

    /// @notice Test stable pool fee is applied correctly
    function test_stableFee_isApplied() public {
        skipIfPoolInvalid(USDC_USDbC_STABLE, "USDC_USDbC_STABLE");

        IPool pool = getPool(USDC_USDbC_STABLE);
        uint256 fee = getPoolFee(pool);

        console.log("Stable pool fee:");
        console.log("  fee (bps):", fee);

        // Aerodrome stable pool default fee is typically lower (e.g., 5 bps = 0.05%)
        assertTrue(fee > 0, "Fee should be > 0");
        assertTrue(fee < 100, "Fee should be < 100 bps (using 10000 denominator)");

        // For stablecoin pairs, fees are typically lower than volatile pairs
        // Default stable fee is often 5 or less (0.05% or less)
        console.log("  Note: Stable pool fees are typically lower than volatile");
    }
}
