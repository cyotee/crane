// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    TestBase_PonsFamilyV2
} from "@crane/contracts/protocols/launchpads/ponsFamily/v2/test/bases/TestBase_PonsFamilyV2.sol";
import {PonsV2LaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2LaunchFactory.sol";
import {PonsV2BondingCurve} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2BondingCurve.sol";
import {PonsV2LauncherToken} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2LauncherToken.sol";
import {
    GraduationPhase,
    IPonsV2LaunchFactory
} from "@crane/contracts/protocols/launchpads/ponsFamily/v2/interfaces/ILaunchpadV2.sol";

/// @notice Hermetic launch + curve trade + fee-escrow credit for pons v2 full stack.
contract PonsV2LaunchFactory_launch_Test is TestBase_PonsFamilyV2 {
    function test_launchToken_nativeQuote_deploysCurveAndToken() public {
        PonsV2LaunchFactory.TokenParams memory params = _defaultV2TokenParams("LaunchA", "LNA");
        (address token, address curve) = _launchV2(params);

        assertTrue(token != address(0), "token");
        assertTrue(curve != address(0), "curve");
        assertTrue(token.code.length > 0, "token code");
        assertTrue(curve.code.length > 0, "curve code");

        IPonsV2LaunchFactory.LaunchedToken memory launched = _launchedV2(token);
        assertTrue(launched.exists);
        assertEq(launched.token, token);
        assertEq(launched.curve, curve);
        assertEq(launched.deployer, ponsV2Launcher);
        assertEq(launched.creatorFeeRecipient, ponsV2Launcher);
        assertEq(launched.pairToken, address(0));
        assertEq(launched.graduationThreshold, PONS_V2_GRADUATION_THRESHOLD);
        assertEq(uint8(launched.phase), uint8(GraduationPhase.NotGraduated));
        assertEq(PonsV2LauncherToken(token).totalSupply(), PONS_V2_SUPPLY);
        assertEq(PonsV2LauncherToken(token).balanceOf(curve), PONS_V2_SUPPLY);
        assertEq(PonsV2BondingCurve(payable(curve)).token(), token);
        assertEq(address(PonsV2BondingCurve(payable(curve)).feeEscrow()), address(ponsV2FeeEscrow));
    }

    function test_launchToken_revertsWhenFeeUnderpaid() public {
        PonsV2LaunchFactory.TokenParams memory params = _defaultV2TokenParams("Under", "UND");
        vm.prank(ponsV2Launcher);
        vm.expectRevert(PonsV2LaunchFactory.LaunchFeeNotPaid.selector);
        ponsV2Factory.launchToken{value: PONS_V2_LAUNCH_FEE - 1}(params, ponsV2LaunchConfigId, address(0));
    }

    function test_curveBuy_creditsFeesToEscrow() public {
        PonsV2LaunchFactory.TokenParams memory params = _defaultV2TokenParams("Fees", "FEE");
        // Creator fee recipient distinct so we can observe creator leg.
        address creator = makeAddr("creatorFee");
        params.creatorFeeRecipient = creator;
        params.creatorTaxBps = 50; // 0.5% creator tax

        (address token, address curve) = _launchV2(params);
        token; // silence

        address buyer = makeAddr("buyer");
        vm.deal(buyer, 10 ether);

        uint256 quoteIn = 0.1 ether;
        vm.prank(buyer);
        uint256 tokensOut = PonsV2BondingCurve(payable(curve)).buy{value: quoteIn}(quoteIn, 0, buyer);
        assertGt(tokensOut, 0, "bought tokens");

        // Fees accrue on buy; curve.deployer is the creatorFeeRecipient (see
        // PonsV2LaunchDeployer._curveInit). That address (or feeSweepOperator) may sweep.
        vm.prank(creator);
        PonsV2BondingCurve(payable(curve)).sweepFees(0);
        uint256 sinkBal = ponsV2FeeEscrow.balanceOf(ponsV2FeeSink);
        // Creator leg credits curve.deployer == creatorFeeRecipient.
        uint256 creatorBal = ponsV2FeeEscrow.balanceOf(creator);
        assertTrue(sinkBal + creatorBal > 0, "fees credited to escrow after sweep");
    }

    function test_transferCreatorFeeRecipient_updatesRecord() public {
        PonsV2LaunchFactory.TokenParams memory params = _defaultV2TokenParams("CTO", "CTO");
        (address token,) = _launchV2(params);

        address newRecipient = makeAddr("newCreator");
        vm.prank(ponsV2Launcher);
        ponsV2Factory.transferCreatorFeeRecipient(token, newRecipient);

        IPonsV2LaunchFactory.LaunchedToken memory launched = _launchedV2(token);
        assertEq(launched.creatorFeeRecipient, newRecipient);
    }
}
