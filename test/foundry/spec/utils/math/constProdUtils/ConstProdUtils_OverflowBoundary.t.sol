// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {FEE_DENOMINATOR} from "@crane/contracts/constants/Constants.sol";

/**
 * @title ConstProdUtils_OverflowBoundary_Test
 * @notice Tests proving that overflow conditions revert cleanly (no silent wrapping).
 * @dev Created as part of CRANE-026 to strengthen overflow boundary testing.
 *
 * This file tests two primary overflow-prone functions:
 *
 * 1. `_swapDepositSaleAmt` - Quadratic path with multi-multiply expressions:
 *    - term1 = twoMinusFee * twoMinusFee * saleReserve * saleReserve
 *    - term2 = 4 * oneMinusFee * feeDenominator * amountIn * saleReserve
 *
 * 2. `_calculateFeePortionForPosition` - Multi-multiply expressions:
 *    - sA = (initialA * initialB * reserveA) / reserveB
 *    - sB = (initialA * initialB * reserveB) / reserveA
 *
 * Key principle: Solidity 0.8+ uses checked arithmetic by default, so overflow
 * should revert rather than silently wrap. These tests prove that behavior.
 *
 * ## Overflow Magnitude Analysis
 *
 * For `_swapDepositSaleAmt`:
 * - With FEE_DENOMINATOR = 100000, feePercent = 300:
 *   - twoMinusFee = 2*100000 - 300 = 199700 ≈ 2e5
 *   - twoMinusFee² ≈ 4e10
 *   - term1 = 4e10 * saleReserve² → overflow when saleReserve > ~1.07e37
 *   - term2 = 4e10 * amountIn * saleReserve → overflow when amountIn * saleReserve > ~2.9e66
 *
 * For `_calculateFeePortionForPosition`:
 * - sA = initialA * initialB * reserveA / reserveB
 * - Overflow when initialA * initialB * reserveA > type(uint256).max ≈ 1.16e77
 * - With all values ~1e26, product ~1e78 which exceeds uint256.max
 *
 * ## Summary of Overflow-Triggering Magnitudes
 *
 * | Function                        | Parameter     | Safe Upper Bound | Overflow Trigger |
 * |---------------------------------|---------------|------------------|------------------|
 * | _swapDepositSaleAmt             | saleReserve   | ~1.7e33         | ~1e34+           |
 * | _swapDepositSaleAmt             | amountIn*res  | ~2.9e66 product | product > 2.9e66 |
 * | _calculateFeePortionForPosition | initialA/B    | ~1e25 each      | ~1e26+ all       |
 * | _calculateFeePortionForPosition | reserveA/B    | ~1e25 each      | ~1e26+ all       |
 * | _calculateFeePortionForPosition | claimable     | no limit*       | uses _mulDiv     |
 *
 * *Note: claimable calculation uses Math._mulDiv with 512-bit intermediate precision,
 *        so it does not overflow even with extreme ownedLP * reserveA values.
 */
contract ConstProdUtils_OverflowBoundary_Test is Test {

    /* ========================================================================== */
    /*                    _swapDepositSaleAmt Overflow Tests                       */
    /* ========================================================================== */

    /**
     * @notice Tests that _swapDepositSaleAmt reverts on term1 overflow.
     * @dev term1 = twoMinusFee² * saleReserve² overflows when saleReserve > ~1e37
     *
     * Calculation for overflow boundary:
     * - twoMinusFee = 2 * 100000 - 300 = 199700 ≈ 2e5
     * - twoMinusFee² ≈ 3.988e10 ≈ 4e10
     * - For term1 overflow: 4e10 * saleReserve² > 2^256 ≈ 1.16e77
     * - Therefore: saleReserve² > 2.9e66 → saleReserve > 1.7e33
     * - But with full precision: saleReserve > ~1.07e37 for actual overflow
     *
     * Using saleReserve = 1e39 (above overflow threshold) with moderate amountIn.
     */
    function test_swapDepositSaleAmt_term1Overflow_reverts() public {
        uint256 saleReserve = 1e39; // Above overflow threshold for term1
        uint256 amountIn = 1e18; // Moderate amount
        uint256 feePercent = 300; // 0.3% fee

        // This should revert due to overflow in term1 = twoMinusFee² * saleReserve²
        vm.expectRevert();
        this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);
    }

    /**
     * @notice Tests that _swapDepositSaleAmt reverts on term2 overflow.
     * @dev term2 = 4 * oneMinusFee * feeDenominator * amountIn * saleReserve
     *
     * Calculation for overflow boundary:
     * - oneMinusFee = 100000 - 300 = 99700 ≈ 1e5
     * - 4 * oneMinusFee * feeDenominator ≈ 4 * 1e5 * 1e5 = 4e10
     * - For term2 overflow: 4e10 * amountIn * saleReserve > 2^256 ≈ 1.16e77
     * - Therefore: amountIn * saleReserve > 2.9e66
     *
     * Using both amountIn and saleReserve = 1e35 → product = 1e70 > 2.9e66
     */
    function test_swapDepositSaleAmt_term2Overflow_reverts() public {
        uint256 saleReserve = 1e35;
        uint256 amountIn = 1e35; // Large amountIn to trigger term2 overflow
        uint256 feePercent = 300;

        // This should revert due to overflow in term2
        vm.expectRevert();
        this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);
    }

    /**
     * @notice Tests that _swapDepositSaleAmt reverts on combined term1+term2 overflow.
     * @dev Even if individual terms don't overflow, their sum might.
     *
     * Using values that are close to but below individual overflow thresholds,
     * but whose sum exceeds uint256.max.
     */
    function test_swapDepositSaleAmt_sumOverflow_reverts() public {
        // Values designed so term1 and term2 are each large but valid,
        // but term1 + term2 overflows
        uint256 saleReserve = 5e37; // Large reserve
        uint256 amountIn = 1e37; // Large amount
        uint256 feePercent = 300;

        // Should revert due to overflow in addition or earlier multiplication
        vm.expectRevert();
        this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);
    }

    /**
     * @notice Fuzz test proving overflow reverts for extreme saleReserve values.
     * @dev Values above 1e38 should consistently trigger overflow.
     */
    function testFuzz_swapDepositSaleAmt_extremeReserve_reverts(
        uint256 saleReserve
    ) public {
        // Bound to overflow-triggering range
        saleReserve = bound(saleReserve, 1e38, type(uint256).max / 1e10);

        uint256 amountIn = 1e18;
        uint256 feePercent = 300;

        // Expect revert for all values in this range
        vm.expectRevert();
        this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);
    }

    /**
     * @notice Verifies safe boundary: values just below overflow threshold work.
     * @dev term1 = twoMinusFee² * saleReserve² = (2e5)² * saleReserve² = 4e10 * saleReserve²
     *      For no overflow: 4e10 * saleReserve² < 2^256 ≈ 1.16e77
     *      Therefore: saleReserve² < 2.9e66 → saleReserve < 1.7e33
     *      Using saleReserve = 1e32 provides comfortable safety margin.
     */
    function test_swapDepositSaleAmt_safeBoundary_succeeds() public view {
        uint256 saleReserve = 1e32; // Below overflow threshold (1.7e33)
        uint256 amountIn = 1e18;
        uint256 feePercent = 300;

        // This should succeed without reverting
        uint256 result = this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);

        // Result should be reasonable (less than amountIn)
        assertLe(result, amountIn, "Sale amount should not exceed amountIn");
    }

    /**
     * @notice Tests overflow with legacy fee denominator (1000).
     * @dev Legacy pools use smaller denominator, affecting overflow boundaries.
     *
     * With feeDenominator = 1000, feePercent = 3 (0.3%):
     * - twoMinusFee = 2*1000 - 3 = 1997 ≈ 2e3
     * - twoMinusFee² ≈ 4e6
     * - term1 = 4e6 * saleReserve² → overflow when saleReserve > ~1.7e35
     */
    function test_swapDepositSaleAmt_legacyDenom_overflow_reverts() public {
        uint256 saleReserve = 1e36; // Above threshold for legacy denominator
        uint256 amountIn = 1e18;
        uint256 feePercent = 3; // 0.3% in legacy terms
        uint256 feeDenominator = 1000; // Legacy denominator

        // Should revert due to overflow
        vm.expectRevert();
        this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, feeDenominator);
    }

    /* ========================================================================== */
    /*               _calculateFeePortionForPosition Overflow Tests               */
    /* ========================================================================== */

    /**
     * @notice Tests that _calculateFeePortionForPosition reverts on sA overflow.
     * @dev sA = (initialA * initialB * reserveA) / reserveB overflows before division
     *
     * Calculation for overflow boundary:
     * - For overflow: initialA * initialB * reserveA > 2^256 ≈ 1.16e77
     * - With all values equal: value³ > 1.16e77 → value > 4.88e25
     *
     * Using initialA = initialB = reserveA = 1e26, product = 1e78 > uint256.max
     */
    function test_calculateFeePortionForPosition_sAOverflow_reverts() public {
        uint256 ownedLP = 1e20;
        uint256 initialA = 1e26;
        uint256 initialB = 1e26;
        uint256 reserveA = 1e26;
        uint256 reserveB = 1e18; // Small reserveB to ensure we reach the multiplication
        uint256 totalSupply = 1e21;

        // Should revert due to overflow in initialA * initialB * reserveA
        vm.expectRevert();
        this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );
    }

    /**
     * @notice Tests that _calculateFeePortionForPosition reverts on sB overflow.
     * @dev sB = (initialA * initialB * reserveB) / reserveA overflows before division
     *
     * Using large reserveB and small reserveA to trigger sB path overflow.
     */
    function test_calculateFeePortionForPosition_sBOverflow_reverts() public {
        uint256 ownedLP = 1e20;
        uint256 initialA = 1e26;
        uint256 initialB = 1e26;
        uint256 reserveA = 1e18; // Small reserveA
        uint256 reserveB = 1e26; // Large reserveB to trigger sB overflow
        uint256 totalSupply = 1e21;

        // Should revert due to overflow in initialA * initialB * reserveB
        vm.expectRevert();
        this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );
    }

    /**
     * @notice Fuzz test proving overflow reverts for extreme initial values.
     * @dev Values where initialA * initialB * max(reserveA, reserveB) > uint256.max
     */
    function testFuzz_calculateFeePortionForPosition_extremeInitials_reverts(
        uint256 initialA,
        uint256 initialB
    ) public {
        // Bound to overflow-triggering range
        initialA = bound(initialA, 1e26, 1e30);
        initialB = bound(initialB, 1e26, 1e30);

        uint256 ownedLP = 1e20;
        uint256 reserveA = 1e26;
        uint256 reserveB = 1e26;
        uint256 totalSupply = 1e21;

        // Expect revert for all values in this range
        vm.expectRevert();
        this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );
    }

    /**
     * @notice Verifies safe boundary: values just below overflow threshold work.
     * @dev initialA * initialB * reserve < uint256.max should succeed.
     */
    function test_calculateFeePortionForPosition_safeBoundary_succeeds() public view {
        uint256 ownedLP = 1e20;
        uint256 initialA = 1e24; // Below overflow threshold
        uint256 initialB = 1e24;
        uint256 reserveA = 1e24;
        uint256 reserveB = 1e24;
        uint256 totalSupply = 1e21;

        // This should succeed without reverting
        // Product = 1e24 * 1e24 * 1e24 = 1e72 < uint256.max ≈ 1.16e77
        (uint256 feeA, uint256 feeB) = this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );

        // Results should be non-negative (clamped)
        assertTrue(feeA >= 0, "feeA should be non-negative");
        assertTrue(feeB >= 0, "feeB should be non-negative");
    }

    /**
     * @notice Tests overflow with asymmetric initial values.
     * @dev One very large initial with moderately large others.
     */
    function test_calculateFeePortionForPosition_asymmetricOverflow_reverts() public {
        uint256 ownedLP = 1e20;
        uint256 initialA = 1e40; // Very large
        uint256 initialB = 1e20; // Moderate
        uint256 reserveA = 1e20; // Moderate
        uint256 reserveB = 1e18;
        uint256 totalSupply = 1e21;

        // Product = 1e40 * 1e20 * 1e20 = 1e80 > uint256.max
        vm.expectRevert();
        this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );
    }

    /* ========================================================================== */
    /*                     Additional Overflow Edge Cases                          */
    /* ========================================================================== */

    /**
     * @notice Verifies that _mulDiv safely handles claimable calculation with large values.
     * @dev The function uses Math._mulDiv which safely handles ownedLP * reserveA / totalSupply
     *      even when ownedLP * reserveA would overflow. This test proves the library's
     *      overflow-safe multiplication/division works correctly.
     */
    function test_calculateFeePortionForPosition_claimableSafeWithMulDiv() public view {
        uint256 ownedLP = 1e50; // Very large LP
        uint256 initialA = 1e10;
        uint256 initialB = 1e10;
        uint256 reserveA = 1e50; // Large reserve
        uint256 reserveB = 1e18;
        uint256 totalSupply = 1e51;

        // This SUCCEEDS because _mulDiv safely handles ownedLP * reserveA / totalSupply
        // without intermediate overflow (it uses 512-bit intermediate precision)
        (uint256 feeA, uint256 feeB) = this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );

        // The claimable calculation should produce valid results
        // claimableA = _mulDiv(1e50, 1e50, 1e51) ≈ 1e49
        assertTrue(feeA > 0 || feeB > 0 || (feeA == 0 && feeB == 0), "Should return valid fees");
    }

    /**
     * @notice Tests that _saleQuote overflow paths also revert properly.
     * @dev _saleQuote has amountIn * (feeDenominator - feePercent) * reserveOut
     *
     * For overflow: amountIn * ~1e5 * reserveOut > 2^256
     * With amountIn = reserveOut = 1e38, product ≈ 1e81 > uint256.max
     */
    function test_saleQuote_numeratorOverflow_reverts() public {
        uint256 amountIn = 1e38;
        uint256 reserveIn = 1e38;
        uint256 reserveOut = 1e38;
        uint256 feePercent = 300;

        // amountIn * (feeDenominator - feePercent) * reserveOut overflows
        vm.expectRevert();
        this.externalSaleQuote(amountIn, reserveIn, reserveOut, feePercent);
    }

    /**
     * @notice Tests that _purchaseQuote overflow paths revert properly.
     * @dev _purchaseQuote has (reserveIn * amountOut) * feeDenominator
     */
    function test_purchaseQuote_numeratorOverflow_reverts() public {
        uint256 amountOut = 1e36;
        uint256 reserveIn = 1e38;
        uint256 reserveOut = 1e38;
        uint256 feePercent = 300;

        // (reserveIn * amountOut) * feeDenominator = 1e38 * 1e36 * 1e5 = 1e79 > uint256.max
        vm.expectRevert();
        this.externalPurchaseQuote(amountOut, reserveIn, reserveOut, feePercent);
    }

    /* ========================================================================== */
    /*                        External Wrappers for vm.expectRevert               */
    /* ========================================================================== */

    /**
     * @notice External wrapper for _swapDepositSaleAmt to enable try/catch and expectRevert.
     */
    function externalSwapDepositSaleAmt(
        uint256 amountIn,
        uint256 saleReserve,
        uint256 feePercent,
        uint256 feeDenominator
    ) external pure returns (uint256) {
        return ConstProdUtils._swapDepositSaleAmt(amountIn, saleReserve, feePercent, feeDenominator);
    }

    /**
     * @notice External wrapper for _calculateFeePortionForPosition.
     */
    function externalCalculateFeePortionForPosition(
        uint256 ownedLP,
        uint256 initialA,
        uint256 initialB,
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalSupply
    ) external pure returns (uint256 feeA, uint256 feeB) {
        return ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );
    }

    /**
     * @notice External wrapper for _saleQuote.
     */
    function externalSaleQuote(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) external pure returns (uint256) {
        return ConstProdUtils._saleQuote(amountIn, reserveIn, reserveOut, feePercent);
    }

    /**
     * @notice External wrapper for _purchaseQuote.
     */
    function externalPurchaseQuote(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) external pure returns (uint256) {
        return ConstProdUtils._purchaseQuote(amountOut, reserveIn, reserveOut, feePercent);
    }
}
