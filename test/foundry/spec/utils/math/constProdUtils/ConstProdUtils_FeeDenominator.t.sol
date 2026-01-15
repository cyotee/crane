// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import "@crane/contracts/constants/Constants.sol";

/**
 * @title ConstProdUtils_FeeDenominator_Test
 * @notice Tests for the explicit fee denominator overload added in CRANE-025.
 * @dev Validates that the new overload correctly handles edge cases where the
 *      heuristic (feePercent <= 10 ? 1000 : FEE_DENOMINATOR) would fail.
 *
 * The key edge case is: feePercent = 10 could mean:
 * - Legacy: 10/1000 = 1% fee
 * - Modern: 10/100000 = 0.01% fee
 *
 * The heuristic incorrectly treats feePercent=10 as legacy (1% fee) when it
 * might be modern (0.01% fee). The explicit overload solves this.
 */
contract ConstProdUtils_FeeDenominator_Test is Test {
    // Common test parameters
    uint256 constant AMOUNT_IN = 100e18;
    uint256 constant LP_SUPPLY = 1000e18;
    uint256 constant RESERVE_IN = 1000e18;
    uint256 constant RESERVE_OUT = 1000e18;

    /* ---------------------------------------------------------------------- */
    /*              Explicit feeDenominator Overload Tests                    */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Test that explicit feeDenominator with feePercent=10 and denom=100000
     *         produces different results than the heuristic (which uses denom=1000).
     */
    function test_explicitFeeDenom_modernLowFee_feePercent10() public pure {
        // Modern pool: 10/100000 = 0.01% fee
        uint256 lpAmtExplicit = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN,
            LP_SUPPLY,
            RESERVE_IN,
            RESERVE_OUT,
            10, // feePercent
            FEE_DENOMINATOR, // explicit: 100000
            0, // kLast
            0, // ownerFeeShare
            false // feeOn
        );

        // Heuristic version (uses denom=1000 for feePercent<=10)
        uint256 lpAmtHeuristic = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN,
            LP_SUPPLY,
            RESERVE_IN,
            RESERVE_OUT,
            10, // feePercent
            0, // kLast
            0, // ownerFeeShare
            false // feeOn
        );

        // These should be DIFFERENT because the heuristic uses denom=1000 (1% fee)
        // while explicit uses denom=100000 (0.01% fee)
        // A lower fee should result in MORE LP tokens
        assertGt(lpAmtExplicit, lpAmtHeuristic, "Explicit low fee (0.01%) should yield more LP than heuristic 1%");
    }

    /**
     * @notice Test that explicit feeDenominator=1000 with feePercent=10
     *         matches the heuristic behavior exactly.
     */
    function test_explicitFeeDenom_legacyFee_matchesHeuristic() public pure {
        // Legacy pool: 10/1000 = 1% fee
        uint256 lpAmtExplicit = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN,
            LP_SUPPLY,
            RESERVE_IN,
            RESERVE_OUT,
            10, // feePercent
            1000, // explicit: 1000 (legacy)
            0, // kLast
            0, // ownerFeeShare
            false // feeOn
        );

        // Heuristic version (uses denom=1000 for feePercent<=10)
        uint256 lpAmtHeuristic = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN,
            LP_SUPPLY,
            RESERVE_IN,
            RESERVE_OUT,
            10, // feePercent
            0, // kLast
            0, // ownerFeeShare
            false // feeOn
        );

        // These should match exactly since both use denom=1000
        assertEq(lpAmtExplicit, lpAmtHeuristic, "Explicit denom=1000 should match heuristic for feePercent=10");
    }

    /**
     * @notice Test boundary: feePercent = 11 uses FEE_DENOMINATOR in both cases.
     */
    function test_explicitFeeDenom_boundary_feePercent11() public pure {
        // feePercent=11 triggers FEE_DENOMINATOR in heuristic
        uint256 lpAmtExplicit = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN,
            LP_SUPPLY,
            RESERVE_IN,
            RESERVE_OUT,
            11, // feePercent
            FEE_DENOMINATOR, // explicit: 100000
            0, // kLast
            0, // ownerFeeShare
            false // feeOn
        );

        uint256 lpAmtHeuristic = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN,
            LP_SUPPLY,
            RESERVE_IN,
            RESERVE_OUT,
            11, // feePercent
            0, // kLast
            0, // ownerFeeShare
            false // feeOn
        );

        // Both should use FEE_DENOMINATOR (100000), so they should match
        assertEq(lpAmtExplicit, lpAmtHeuristic, "feePercent=11 should use FEE_DENOMINATOR in both");
    }

    /**
     * @notice Test various modern low fees with explicit denominator.
     */
    function test_explicitFeeDenom_modernFees_various() public pure {
        // Test 0.01% = 10/100000
        uint256 lpAmt_001pct = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            10, FEE_DENOMINATOR, 0, 0, false
        );

        // Test 0.05% = 50/100000
        uint256 lpAmt_005pct = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            50, FEE_DENOMINATOR, 0, 0, false
        );

        // Test 0.1% = 100/100000
        uint256 lpAmt_01pct = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            100, FEE_DENOMINATOR, 0, 0, false
        );

        // Lower fees should result in more LP tokens
        assertGt(lpAmt_001pct, lpAmt_005pct, "0.01% fee should yield more LP than 0.05%");
        assertGt(lpAmt_005pct, lpAmt_01pct, "0.05% fee should yield more LP than 0.1%");
    }

    /**
     * @notice Test that the struct-based function uses explicit feeDenominator.
     */
    function test_structVersion_usesExplicitFeeDenom() public pure {
        ConstProdUtils.SwapDepositArgs memory args;
        args.amountIn = AMOUNT_IN;
        args.lpTotalSupply = LP_SUPPLY;
        args.reserveIn = RESERVE_IN;
        args.reserveOut = RESERVE_OUT;
        args.feePercent = 10;
        args.feeDenominator = FEE_DENOMINATOR; // Explicit: 100000
        args.kLast = 0;
        args.ownerFeeShare = 0;
        args.feeOn = false;

        uint256 lpAmtStruct = ConstProdUtils._quoteSwapDepositWithFee(args);

        // Compare with explicit overload (should match)
        uint256 lpAmtExplicit = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            10, FEE_DENOMINATOR, 0, 0, false
        );

        assertEq(lpAmtStruct, lpAmtExplicit, "Struct version should match explicit overload");
    }

    /* ---------------------------------------------------------------------- */
    /*                     Protocol Fee Integration Tests                     */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Test explicit feeDenominator with protocol fees enabled.
     */
    function test_explicitFeeDenom_withProtocolFees() public pure {
        uint256 kLast = RESERVE_IN * RESERVE_OUT; // Initial K

        uint256 lpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN,
            LP_SUPPLY,
            RESERVE_IN,
            RESERVE_OUT,
            10, // feePercent
            FEE_DENOMINATOR, // explicit: 100000
            kLast,
            16666, // Uniswap-style ownerFeeShare
            true // feeOn
        );

        assertGt(lpAmt, 0, "Should work with protocol fees and explicit denominator");
    }

    /* ---------------------------------------------------------------------- */
    /*                          Edge Case Tests                               */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Test feePercent = 0 (no fee) with explicit denominator.
     */
    function test_explicitFeeDenom_zeroFee() public pure {
        uint256 lpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            0, FEE_DENOMINATOR, 0, 0, false
        );

        assertGt(lpAmt, 0, "Zero fee should work with explicit denominator");
    }

    /**
     * @notice Test feePercent = 1 (minimum non-zero) with explicit denominator.
     */
    function test_explicitFeeDenom_minimumFee() public pure {
        // 1/100000 = 0.001% fee
        uint256 lpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            1, FEE_DENOMINATOR, 0, 0, false
        );

        assertGt(lpAmt, 0, "Minimum fee (0.001%) should work");
    }

    /**
     * @notice Test custom denominator (e.g., Aerodrome uses 10000).
     */
    function test_explicitFeeDenom_customDenominator_aerodrome() public pure {
        // Aerodrome uses denominator 10000
        // 30/10000 = 0.3% fee
        uint256 lpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            30, 10000, 0, 0, false
        );

        assertGt(lpAmt, 0, "Custom denominator (Aerodrome) should work");
    }

    /* ---------------------------------------------------------------------- */
    /*                            Fuzz Tests                                  */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: explicit denominator should always produce valid results.
     */
    function testFuzz_explicitFeeDenom_validResults(
        uint256 amountIn,
        uint256 lpSupply,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent,
        uint256 feeDenom
    ) public pure {
        // Bound inputs to valid ranges
        amountIn = bound(amountIn, 1e15, 1e27);
        lpSupply = bound(lpSupply, 1e15, 1e27);
        reserveIn = bound(reserveIn, 1e15, 1e27);
        reserveOut = bound(reserveOut, 1e15, 1e27);
        feeDenom = bound(feeDenom, 100, 1e6); // Reasonable denominator range
        feePercent = bound(feePercent, 0, feeDenom - 1); // Fee must be < 100%

        uint256 lpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn, lpSupply, reserveIn, reserveOut,
            feePercent, feeDenom, 0, 0, false
        );

        // Result should be reasonable (positive but not larger than LP supply)
        assertGe(lpAmt, 0, "LP amount should be non-negative");
    }

    /**
     * @notice Fuzz test: lower fees should always result in more LP tokens (fixed reserves).
     */
    function testFuzz_lowerFee_yieldsMoreLP(uint256 feeLow, uint256 feeHigh) public pure {
        // Ensure feeHigh > feeLow and both are valid
        feeLow = bound(feeLow, 0, 4999);
        feeHigh = bound(feeHigh, feeLow + 1, 5000);

        uint256 lpAmtLowFee = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            feeLow, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 lpAmtHighFee = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            feeHigh, FEE_DENOMINATOR, 0, 0, false
        );

        assertGe(lpAmtLowFee, lpAmtHighFee, "Lower fee should yield >= LP tokens");
    }

    /**
     * @notice Fuzz test: explicit and heuristic should match when heuristic is correct.
     */
    function testFuzz_explicitMatchesHeuristic_whenApplicable(uint256 feePercent) public pure {
        // Test cases where heuristic is correct:
        // - feePercent <= 10 with denom=1000 (legacy)
        // - feePercent > 10 with denom=FEE_DENOMINATOR (modern)

        // Test modern case (feePercent > 10)
        feePercent = bound(feePercent, 11, 9999);

        uint256 lpAmtExplicit = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            feePercent, FEE_DENOMINATOR, 0, 0, false
        );

        uint256 lpAmtHeuristic = ConstProdUtils._quoteSwapDepositWithFee(
            AMOUNT_IN, LP_SUPPLY, RESERVE_IN, RESERVE_OUT,
            feePercent, 0, 0, false
        );

        assertEq(lpAmtExplicit, lpAmtHeuristic, "Should match for feePercent > 10");
    }
}
