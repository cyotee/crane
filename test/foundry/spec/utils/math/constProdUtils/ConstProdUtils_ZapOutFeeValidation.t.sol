// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

/**
 * @title ConstProdUtils_ZapOutFeeValidation_Test
 * @notice Tests for CRANE-024: Harden Zap-Out Fee-On Input Validation
 * @dev Ensures `_quoteZapOutToTargetWithFee` handles ownerFeeShare == 0 gracefully
 *      without reverting when feeOn is enabled.
 */
contract ConstProdUtils_ZapOutFeeValidation_Test is Test {
    // Standard pool parameters for testing
    uint256 constant RESERVE_A = 1000e18;
    uint256 constant RESERVE_B = 1000e18;
    uint256 constant LP_TOTAL_SUPPLY = 1000e18;
    uint256 constant FEE_PERCENT = 300; // 0.3%
    uint256 constant FEE_DENOMINATOR = 100000;
    uint256 constant PROTOCOL_FEE_DENOMINATOR = 100000;

    // K value representing pool state with accumulated fees
    uint256 constant K_LAST = RESERVE_A * RESERVE_B; // 1e36

    /* ---------------------------------------------------------------------- */
    /*                    CRANE-024: ownerFeeShare == 0 Tests                 */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Test that _quoteZapOutToTargetWithFee does not revert when
     *         feeOn == true, kLast != 0, and ownerFeeShare == 0.
     * @dev This is the primary acceptance criterion for CRANE-024.
     *      Before the fix, this would cause a division-by-zero panic at:
     *      `feeFactor = (protocolFeeDenominator / ownerFeeShare) - 1`
     */
    function test_quoteZapOutToTargetWithFee_ownerFeeShareZero_feeOn_noRevert() public pure {
        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: 100e18, // 10% of reserve
            lpTotalSupply: LP_TOTAL_SUPPLY,
            reserveDesired: RESERVE_A,
            reserveOther: RESERVE_B,
            feePercent: FEE_PERCENT,
            feeDenominator: FEE_DENOMINATOR,
            kLast: K_LAST, // Non-zero kLast
            ownerFeeShare: 0, // Zero ownerFeeShare - the edge case being tested
            feeOn: true, // Fees enabled
            protocolFeeDenominator: PROTOCOL_FEE_DENOMINATOR
        });

        // Should not revert - the fix ensures we skip the fee calculation
        // when ownerFeeShare == 0 (treat as "fees disabled")
        uint256 lpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(args);

        // Should return a positive value (normal operation without protocol fee)
        assertGt(lpNeeded, 0, "Should return positive LP amount when ownerFeeShare is 0");
        assertLe(lpNeeded, LP_TOTAL_SUPPLY, "LP needed should not exceed total supply");
    }

    /**
     * @notice Test consistency: ownerFeeShare == 0 with feeOn should behave
     *         the same as feeOn == false (fees disabled).
     * @dev Verifies the "treat as fees disabled" behavior matches actual
     *      disabled fees.
     */
    function test_quoteZapOutToTargetWithFee_ownerFeeShareZero_matchesFeesDisabled() public pure {
        // Args with ownerFeeShare == 0, feeOn == true
        ConstProdUtils.ZapOutToTargetWithFeeArgs memory argsZeroShare = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: 100e18,
            lpTotalSupply: LP_TOTAL_SUPPLY,
            reserveDesired: RESERVE_A,
            reserveOther: RESERVE_B,
            feePercent: FEE_PERCENT,
            feeDenominator: FEE_DENOMINATOR,
            kLast: K_LAST,
            ownerFeeShare: 0, // Zero ownerFeeShare
            feeOn: true, // Fees "enabled" but share is 0
            protocolFeeDenominator: PROTOCOL_FEE_DENOMINATOR
        });

        // Args with feeOn == false (explicitly disabled)
        ConstProdUtils.ZapOutToTargetWithFeeArgs memory argsFeesOff = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: 100e18,
            lpTotalSupply: LP_TOTAL_SUPPLY,
            reserveDesired: RESERVE_A,
            reserveOther: RESERVE_B,
            feePercent: FEE_PERCENT,
            feeDenominator: FEE_DENOMINATOR,
            kLast: K_LAST,
            ownerFeeShare: 16666, // Non-zero share but...
            feeOn: false, // ...fees disabled
            protocolFeeDenominator: PROTOCOL_FEE_DENOMINATOR
        });

        uint256 lpNeededZeroShare = ConstProdUtils._quoteZapOutToTargetWithFee(argsZeroShare);
        uint256 lpNeededFeesOff = ConstProdUtils._quoteZapOutToTargetWithFee(argsFeesOff);

        // Both should produce the same result (no protocol fee adjustment)
        assertEq(
            lpNeededZeroShare,
            lpNeededFeesOff,
            "ownerFeeShare=0 should behave same as feeOn=false"
        );
    }

    /**
     * @notice Fuzz test: verify no revert for any ownerFeeShare value.
     * @dev Ensures the guard handles all values gracefully.
     */
    function testFuzz_quoteZapOutToTargetWithFee_ownerFeeShare_noRevert(
        uint256 ownerFeeShare,
        uint256 desiredOut,
        bool feeOn
    ) public pure {
        // Bound inputs to valid ranges
        ownerFeeShare = bound(ownerFeeShare, 0, PROTOCOL_FEE_DENOMINATOR);
        desiredOut = bound(desiredOut, 1, RESERVE_A - 1); // Must be < reserve

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: LP_TOTAL_SUPPLY,
            reserveDesired: RESERVE_A,
            reserveOther: RESERVE_B,
            feePercent: FEE_PERCENT,
            feeDenominator: FEE_DENOMINATOR,
            kLast: K_LAST,
            ownerFeeShare: ownerFeeShare,
            feeOn: feeOn,
            protocolFeeDenominator: PROTOCOL_FEE_DENOMINATOR
        });

        // Should never revert for any valid ownerFeeShare
        uint256 lpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(args);

        // Result should be reasonable
        assertLe(lpNeeded, LP_TOTAL_SUPPLY, "LP needed should not exceed total supply");
    }

    /**
     * @notice Test edge case: ownerFeeShare == 0 with kLast == 0.
     * @dev Both conditions should skip fee calculation, ensuring no issues.
     */
    function test_quoteZapOutToTargetWithFee_ownerFeeShareZero_kLastZero() public pure {
        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: 100e18,
            lpTotalSupply: LP_TOTAL_SUPPLY,
            reserveDesired: RESERVE_A,
            reserveOther: RESERVE_B,
            feePercent: FEE_PERCENT,
            feeDenominator: FEE_DENOMINATOR,
            kLast: 0, // kLast is zero
            ownerFeeShare: 0, // ownerFeeShare is also zero
            feeOn: true,
            protocolFeeDenominator: PROTOCOL_FEE_DENOMINATOR
        });

        uint256 lpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(args);

        assertGt(lpNeeded, 0, "Should return positive LP amount");
    }

    /**
     * @notice Test that K growth with ownerFeeShare == 0 doesn't apply protocol fee.
     * @dev With K growth, protocol fee would normally be minted. With ownerFeeShare == 0,
     *      this should be skipped.
     */
    function test_quoteZapOutToTargetWithFee_ownerFeeShareZero_withKGrowth() public pure {
        // Simulate K growth (current K > kLast)
        uint256 currentK = (RESERVE_A * 2) * (RESERVE_B * 2); // 4x growth
        uint256 kLast = RESERVE_A * RESERVE_B;

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: 100e18,
            lpTotalSupply: LP_TOTAL_SUPPLY,
            reserveDesired: RESERVE_A * 2,
            reserveOther: RESERVE_B * 2,
            feePercent: FEE_PERCENT,
            feeDenominator: FEE_DENOMINATOR,
            kLast: kLast, // Original K
            ownerFeeShare: 0, // Zero ownerFeeShare
            feeOn: true,
            protocolFeeDenominator: PROTOCOL_FEE_DENOMINATOR
        });

        // Should not revert even with K growth
        uint256 lpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(args);

        assertGt(lpNeeded, 0, "Should return positive LP amount with K growth");
    }

    /* ---------------------------------------------------------------------- */
    /*                      Consistency with _calculateProtocolFee           */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Verify _calculateProtocolFee also handles ownerFeeShare == 0.
     * @dev This confirms consistency between the two functions.
     */
    function test_calculateProtocolFee_ownerFeeShareZero_returnsZero() public pure {
        uint256 lpTotalSupply = 1000e18;
        uint256 newK = 2e36; // Represents growth
        uint256 kLast = 1e36;
        uint256 ownerFeeShare = 0;

        uint256 protocolFee = ConstProdUtils._calculateProtocolFee(
            lpTotalSupply,
            newK,
            kLast,
            ownerFeeShare
        );

        assertEq(protocolFee, 0, "_calculateProtocolFee should return 0 when ownerFeeShare is 0");
    }
}
