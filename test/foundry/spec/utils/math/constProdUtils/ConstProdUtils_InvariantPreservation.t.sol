// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {FEE_DENOMINATOR} from "@crane/contracts/constants/Constants.sol";

/**
 * @title ConstProdUtils_InvariantPreservation_Test
 * @notice High-signal tests verifying the x*y=k invariant is preserved or strengthened after operations.
 * @dev These tests focus on adversarial boundary conditions and invariant preservation guarantees.
 *
 * Key invariants tested:
 * 1. After a swap, k' >= k (reserves product must not decrease)
 * 2. Round-trip swap-then-reverse should not extract value
 * 3. Extreme reserve ratios should not break math
 * 4. Near-overflow values should revert safely, not silently wrap
 */
contract ConstProdUtils_InvariantPreservation_Test is Test {
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    /* -------------------------------------------------------------------------- */
    /*                       Invariant: k' >= k After Swap                        */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that after a swap, the product of reserves (k) never decreases.
     * @dev The fee mechanism should always result in k' > k (or k' = k for zero-amount swaps).
     */
    function testFuzz_saleQuote_invariant_kNeverDecreases(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountIn,
        uint256 feePercent
    ) public pure {
        // Bound to realistic values to avoid overflow
        reserveIn = bound(reserveIn, 1e15, 1e30);
        reserveOut = bound(reserveOut, 1e15, 1e30);
        amountIn = bound(amountIn, 1, reserveIn / 10); // Max 10% of reserve
        feePercent = bound(feePercent, 0, 9900); // Max 9.9% fee

        uint256 kBefore = reserveIn * reserveOut;

        uint256 amountOut = ConstProdUtils._saleQuote(amountIn, reserveIn, reserveOut, feePercent);

        // Skip if amountOut would exceed reserveOut (shouldn't happen with bounded amountIn)
        if (amountOut >= reserveOut) return;

        uint256 reserveInAfter = reserveIn + amountIn;
        uint256 reserveOutAfter = reserveOut - amountOut;

        uint256 kAfter = reserveInAfter * reserveOutAfter;

        // k should never decrease after a swap (it increases due to fees)
        assertGe(kAfter, kBefore, "Invariant violated: k decreased after swap");
    }

    /**
     * @notice Verifies k preservation with the standard Uniswap V2 fee (0.3%).
     * @dev Uses the exact fee parameters from Uniswap V2.
     */
    function testFuzz_saleQuote_invariant_uniswapV2Fee(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountIn
    ) public pure {
        reserveIn = bound(reserveIn, 1e18, 1e27);
        reserveOut = bound(reserveOut, 1e18, 1e27);
        amountIn = bound(amountIn, 1e15, reserveIn / 100);

        uint256 kBefore = reserveIn * reserveOut;

        // Standard UniswapV2 fee: 300 out of 100000 = 0.3%
        uint256 amountOut = ConstProdUtils._saleQuote(amountIn, reserveIn, reserveOut, 300);

        uint256 kAfter = (reserveIn + amountIn) * (reserveOut - amountOut);

        assertGe(kAfter, kBefore, "UniswapV2 fee should preserve k invariant");
    }

    /* -------------------------------------------------------------------------- */
    /*                  Invariant: Round-Trip Swap Value Extraction               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that a round-trip swap (A->B then B->A) does not extract value.
     * @dev Due to fees, the user should end up with less than they started with.
     */
    function testFuzz_roundTripSwap_noValueExtraction(
        uint256 reserveA,
        uint256 reserveB,
        uint256 amountIn,
        uint256 feePercent
    ) public pure {
        reserveA = bound(reserveA, 1e18, 1e27);
        reserveB = bound(reserveB, 1e18, 1e27);
        amountIn = bound(amountIn, 1e15, reserveA / 100);
        feePercent = bound(feePercent, 100, 5000); // 0.1% to 5%

        // Step 1: Swap A -> B
        uint256 amountB = ConstProdUtils._saleQuote(amountIn, reserveA, reserveB, feePercent);

        // Skip if the swap would fail
        if (amountB == 0 || amountB >= reserveB) return;

        // Update reserves after first swap
        uint256 newReserveA = reserveA + amountIn;
        uint256 newReserveB = reserveB - amountB;

        // Step 2: Swap B -> A (reverse swap with all received B)
        uint256 amountABack = ConstProdUtils._saleQuote(amountB, newReserveB, newReserveA, feePercent);

        // User should get back LESS than they started with (fees taken both ways)
        assertLt(amountABack, amountIn, "Round-trip should not extract value");
    }

    /**
     * @notice Verifies that purchase quote followed by sale quote doesn't allow arbitrage.
     * @dev Getting a quote for X output, then selling that input, should not yield > X.
     */
    function testFuzz_purchaseThenSale_noArbitrage(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 desiredOut,
        uint256 feePercent
    ) public pure {
        reserveIn = bound(reserveIn, 1e18, 1e27);
        reserveOut = bound(reserveOut, 1e18, 1e27);
        feePercent = bound(feePercent, 100, 3000);

        // Ensure desiredOut is achievable
        uint256 maxOut = reserveOut * 90 / 100; // Max 90% of reserves
        desiredOut = bound(desiredOut, 1e15, maxOut);

        // Get required input for desired output
        uint256 requiredIn = ConstProdUtils._purchaseQuote(desiredOut, reserveIn, reserveOut, feePercent);

        // Now verify: if we sell requiredIn, do we get at least desiredOut?
        uint256 actualOut = ConstProdUtils._saleQuote(requiredIn, reserveIn, reserveOut, feePercent);

        // actualOut should be >= desiredOut (purchaseQuote should overestimate input)
        assertGe(actualOut, desiredOut, "Purchase quote should provide sufficient output");
    }

    /* -------------------------------------------------------------------------- */
    /*                       Boundary: Extreme Reserve Ratios                     */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests swap math with extremely imbalanced reserves (1000:1 ratio).
     * @dev Verifies math doesn't break down with common extreme ratios.
     */
    function test_saleQuote_extremeRatio_1000to1() public pure {
        uint256 reserveA = 1000e18; // Large reserve
        uint256 reserveB = 1e18; // Small reserve

        uint256 amountIn = 1e18;

        uint256 amountOut = ConstProdUtils._saleQuote(amountIn, reserveA, reserveB, 300);

        // Should get some output
        assertGt(amountOut, 0, "Should produce output for 1000:1 ratio");
        assertLt(amountOut, reserveB, "Output should not exceed reserve");

        // Verify k preservation
        uint256 kBefore = reserveA * reserveB;
        uint256 kAfter = (reserveA + amountIn) * (reserveB - amountOut);
        assertGe(kAfter, kBefore, "k should be preserved with extreme ratio");
    }

    /**
     * @notice Tests swap math with inverted extreme ratio (1:1000).
     */
    function test_saleQuote_extremeRatio_1to1000() public pure {
        uint256 reserveA = 1e18; // Small reserve
        uint256 reserveB = 1000e18; // Large reserve

        uint256 amountIn = 0.1e18; // Small input

        uint256 amountOut = ConstProdUtils._saleQuote(amountIn, reserveA, reserveB, 300);

        assertGt(amountOut, 0, "Should produce output for 1:1000 ratio");
        assertLt(amountOut, reserveB, "Output should not exceed reserve");

        uint256 kBefore = reserveA * reserveB;
        uint256 kAfter = (reserveA + amountIn) * (reserveB - amountOut);
        assertGe(kAfter, kBefore, "k should be preserved with inverted extreme ratio");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Boundary: Near-Overflow Values                        */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that operations with large values revert safely rather than overflow.
     * @dev Values chosen to be near the overflow boundary for multiplication.
     */
    function test_saleQuote_nearOverflow_revertsOrHandles() public {
        // sqrt(type(uint256).max) ≈ 3.4e38
        // Two values that would overflow when multiplied: 1e39 * 1e39 > uint256.max
        uint256 largeReserve = 1e38;

        // This should either work correctly or revert, not silently overflow
        try this.externalSaleQuote(1e18, largeReserve, largeReserve, 300) returns (uint256 result) {
            // If it succeeds, verify the result is reasonable
            assertGt(result, 0, "Non-zero output expected");
            assertLt(result, largeReserve, "Output should not exceed reserve");
        } catch {
            // Revert is acceptable for extreme values
            assertTrue(true, "Revert is acceptable for near-overflow values");
        }
    }

    // External wrapper to catch reverts
    function externalSaleQuote(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) external pure returns (uint256) {
        return ConstProdUtils._saleQuote(amountIn, reserveIn, reserveOut, fee);
    }

    /**
     * @notice Tests deposit quote with values that could overflow in sqrt calculation.
     */
    function test_depositQuote_nearOverflow_firstDeposit() public {
        // For first deposit: sqrt(amountA * amountB)
        // Max safe value before overflow: sqrt(type(uint256).max) ≈ 3.4e38
        uint256 largeAmount = 1e38;

        try this.externalDepositQuote(largeAmount, largeAmount, 0, 0, 0) returns (uint256 lp) {
            // sqrt(1e38 * 1e38) = 1e38, - 1000
            assertGt(lp, 0, "Should mint LP tokens");
        } catch {
            // Revert is acceptable for extreme values
            assertTrue(true, "Revert is acceptable for near-overflow first deposit");
        }
    }

    // External wrapper for deposit quote
    function externalDepositQuote(
        uint256 amountA,
        uint256 amountB,
        uint256 supply,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256) {
        return ConstProdUtils._depositQuote(amountA, amountB, supply, reserveA, reserveB);
    }

    /* -------------------------------------------------------------------------- */
    /*                       Boundary: Single Wei Precision                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that single wei swaps behave correctly.
     * @dev Single wei is the minimum meaningful amount; should not cause issues.
     */
    function test_saleQuote_singleWei_producesOutput() public pure {
        uint256 reserveIn = 1000e18;
        uint256 reserveOut = 1000e18;

        // Even a single wei should produce some output in a balanced pool
        uint256 amountOut = ConstProdUtils._saleQuote(1, reserveIn, reserveOut, 300);

        // For a balanced 1:1 pool with 0.3% fee:
        // amountOut ≈ 1 * 0.997 * 1000e18 / (1000e18 + 0.997) ≈ 0
        // This will be 0 due to integer division, which is correct behavior
        assertEq(amountOut, 0, "Single wei in large pool should round to 0 output");
    }

    /**
     * @notice Tests single wei output requirement via purchase quote.
     */
    function test_purchaseQuote_singleWei_requiresReasonableInput() public pure {
        uint256 reserveIn = 1000e18;
        uint256 reserveOut = 1000e18;

        // Buying exactly 1 wei should require some input
        uint256 requiredIn = ConstProdUtils._purchaseQuote(1, reserveIn, reserveOut, 300);

        // Should require at least 1 wei (plus fees plus safety margin)
        assertGe(requiredIn, 2, "Should require some input for 1 wei output");
    }

    /* -------------------------------------------------------------------------- */
    /*                 Invariant: First Deposit MINIMUM_LIQUIDITY Lock            */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that first deposit always locks MINIMUM_LIQUIDITY.
     * @dev This prevents first-depositor attacks.
     */
    function testFuzz_depositQuote_firstDeposit_locksMinimumLiquidity(
        uint256 amountA,
        uint256 amountB
    ) public pure {
        // Bound to ensure sqrt result > MINIMUM_LIQUIDITY
        amountA = bound(amountA, 1e6, 1e30);
        amountB = bound(amountB, 1e6, 1e30);

        // Only test if product is large enough for meaningful LP
        uint256 product = amountA * amountB;
        if (product <= 1e6) return; // sqrt would be <= 1000

        uint256 lpAmount = ConstProdUtils._depositQuote(amountA, amountB, 0, 0, 0);

        // The actual minted LP should always be less than sqrt(product) by exactly MINIMUM_LIQUIDITY
        // (unless the sqrt itself equals MINIMUM_LIQUIDITY, in which case lpAmount = 0)
        uint256 sqrtProduct = sqrt(product);
        if (sqrtProduct > MINIMUM_LIQUIDITY) {
            assertEq(lpAmount, sqrtProduct - MINIMUM_LIQUIDITY, "Should lock exactly MINIMUM_LIQUIDITY");
        }
    }

    // Simple sqrt for test verification (not gas-optimized)
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                    Invariant: Protocol Fee Monotonicity                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies protocol fee is monotonic with k growth.
     * @dev Larger k growth should always result in >= protocol fee.
     */
    function testFuzz_calculateProtocolFee_monotonicWithKGrowth(
        uint256 lpSupply,
        uint256 kLast,
        uint256 growth1,
        uint256 growth2
    ) public pure {
        lpSupply = bound(lpSupply, 1e18, 1e27);
        kLast = bound(kLast, 1e30, 1e50);
        growth1 = bound(growth1, 1e24, 1e30);
        growth2 = bound(growth2, growth1, growth1 * 2); // growth2 >= growth1

        uint256 newK1 = kLast + growth1;
        uint256 newK2 = kLast + growth2;

        uint256 fee1 = ConstProdUtils._calculateProtocolFee(lpSupply, newK1, kLast, 16667);
        uint256 fee2 = ConstProdUtils._calculateProtocolFee(lpSupply, newK2, kLast, 16667);

        // Larger growth should result in >= fee (monotonic)
        assertGe(fee2, fee1, "Protocol fee should be monotonic with k growth");
    }

    /* -------------------------------------------------------------------------- */
    /*                   Invariant: Withdrawal Pro-Rata Distribution              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies withdrawal is strictly pro-rata to LP ownership.
     * @dev Withdrawing X% of supply should yield X% of each reserve.
     */
    function testFuzz_withdrawQuote_proRataDistribution(
        uint256 ownedLP,
        uint256 totalSupply,
        uint256 reserveA,
        uint256 reserveB
    ) public pure {
        totalSupply = bound(totalSupply, 1e18, 1e27);
        ownedLP = bound(ownedLP, 1e15, totalSupply);
        reserveA = bound(reserveA, 1e18, 1e27);
        reserveB = bound(reserveB, 1e18, 1e27);

        (uint256 amountA, uint256 amountB) = ConstProdUtils._withdrawQuote(
            ownedLP, totalSupply, reserveA, reserveB
        );

        // Verify pro-rata: amountA / reserveA ≈ ownedLP / totalSupply
        // Using cross-multiplication to avoid division precision loss:
        // amountA * totalSupply <= ownedLP * reserveA (due to floor division)
        assertLe(
            amountA * totalSupply,
            ownedLP * reserveA,
            "Withdrawal should not exceed pro-rata share of reserve A"
        );
        assertLe(
            amountB * totalSupply,
            ownedLP * reserveB,
            "Withdrawal should not exceed pro-rata share of reserve B"
        );

        // Also verify it's close (within 1 unit difference from floor)
        assertGe(
            amountA * totalSupply + totalSupply,
            ownedLP * reserveA,
            "Withdrawal should be within rounding of pro-rata"
        );
    }
}
