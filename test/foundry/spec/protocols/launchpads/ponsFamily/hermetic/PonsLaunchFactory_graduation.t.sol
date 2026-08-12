// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    TestBase_PonsFamily
} from "@crane/contracts/protocols/launchpads/ponsFamily/v1/test/bases/TestBase_PonsFamily.sol";
import {PonsLauncherToken} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v1/PonsLauncherToken.sol";

contract PonsLaunchFactory_graduation_Test is TestBase_PonsFamily {
    function test_graduationStatus_falseThenTrue_afterPairedPrincipal() public {
        address token = _launchWithoutSeed(keccak256("grad-1"));
        _warpPastRestrictions(token);

        (uint256 principal0, uint256 threshold0, bool graduated0) = ponsFactory.graduationStatus(token);
        assertEq(threshold0, PONS_GRADUATION_THRESHOLD);
        assertFalse(graduated0, "fresh launch not graduated");
        // One-sided LP at the range edge: little/no paired principal yet.
        assertLt(principal0, PONS_GRADUATION_THRESHOLD);

        // Drive real swaps so locked position accumulates paired WETH principal.
        // Multiple wallets stay under post-window ERC-20 rules (no anti-snipe).
        address buyer1 = makeAddr("gradBuyer1");
        address buyer2 = makeAddr("gradBuyer2");
        address buyer3 = makeAddr("gradBuyer3");

        _buyTokensWithEth(token, buyer1, 2 ether);
        _buyTokensWithEth(token, buyer2, 2 ether);
        _buyTokensWithEth(token, buyer3, 2 ether);

        (uint256 principal1, uint256 threshold1, bool graduated1) = ponsFactory.graduationStatus(token);
        assertEq(threshold1, PONS_GRADUATION_THRESHOLD);
        assertGe(principal1, principal0, "principal non-decreasing after buys");
        assertTrue(graduated1, "graduated once locked principal >= 4.2 ETH");
        assertGe(principal1, PONS_GRADUATION_THRESHOLD);

        // Sanity: pool still the canonical one (no fake wallet graduation).
        assertTrue(PonsLauncherToken(token).liquidityPool() != address(0));
    }
}
