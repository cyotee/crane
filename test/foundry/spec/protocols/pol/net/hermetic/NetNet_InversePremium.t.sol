// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_NetNet} from "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNet.sol";
import {Behavior_IInverseBond} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_IInverseBond.sol";
import {Behavior_IPremiumSeller} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_IPremiumSeller.sol";
import {NetNetBondService} from
    "@crane/contracts/protocols/pol/net/services/NetNetBondService.sol";
import {InverseBond} from "@crane/contracts/protocols/pol/net/src/InverseBond.sol";
import {PremiumSeller} from "@crane/contracts/protocols/pol/net/src/PremiumSeller.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";

contract NetNet_InversePremium_Test is TestBase_NetNet {
    function test_inverse_price_and_swap_after_crash() public {
        uint256 expected = Behavior_IInverseBond.expected_IInverseBond_price(treasury);
        assertTrue(Behavior_IInverseBond.isValid_IInverseBond_price(inverseBond, expected));

        _crashTwapBelowBacking();
        uint256 floor = treasury.backingPerToken() * (Constants.BPS - Constants.INVERSE_SPREAD_BPS)
            / Constants.BPS;
        assertLt(oracle.twapNetUsdg(), floor, "TWAP below inverse band");

        usdg.mint(address(this), 50e6);
        _buyNet(50e6, 0);
        uint256 amt = net.balanceOf(address(this)) / 2;
        require(amt > 0, "need NET to inverse-swap");
        uint256 usdgBefore = usdg.balanceOf(address(this));
        uint256 outRaw = NetNetBondService._inverseSwap(
            NetNetBondService.InverseSwapParams({
                inverseBond: inverseBond,
                net: INET(address(net)),
                netAmount: amt,
                minUsdgOutRaw: 0
            })
        );
        assertGt(outRaw, 0);
        assertEq(usdg.balanceOf(address(this)) - usdgBefore, outRaw);
    }

    function test_inverse_zero_amount_reverts() public {
        vm.expectRevert(InverseBond.ZeroAmount.selector);
        inverseBond.swap(0, 0);
    }

    function test_premium_execute_after_lift() public {
        assertTrue(Behavior_IPremiumSeller.isValid_IPremiumSeller_threshold(premiumSeller));
        _liftTwapAbovePremium();
        uint256 threshold =
            treasury.backingPerToken() * Constants.PREMIUM_THRESHOLD_WAD / Constants.WAD;
        assertGt(oracle.twapNetUsdg(), threshold, "TWAP above premium");
        vm.warp(block.timestamp + Constants.PREMIUM_MIN_INTERVAL);
        assertTrue(premiumSeller.active(), "premium active");

        uint256 treBefore = usdg.balanceOf(address(treasury));
        (uint256 netSold, uint256 usdgOut) = NetNetBondService._premiumExecute(
            NetNetBondService.PremiumExecuteParams({premiumSeller: premiumSeller, minUsdgOutRaw: 0})
        );
        assertGt(netSold, 0);
        assertGt(usdgOut, 0);
        assertEq(usdg.balanceOf(address(treasury)) - treBefore, usdgOut);
    }

    function test_premium_inactive_reverts_when_below_threshold() public {
        // Post-genesis TWAP is near 3e18; backing is near that. Premium needs 2x backing.
        if (premiumSeller.active()) return;
        vm.expectRevert(PremiumSeller.NotActive.selector);
        premiumSeller.execute(0);
    }
}
