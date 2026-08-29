// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {TestBase_NetNet} from "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNet.sol";
import {Behavior_IPTEAM} from "@crane/contracts/protocols/pol/net/test/bases/Behavior_IPTEAM.sol";
import {NetNetBondService} from
    "@crane/contracts/protocols/pol/net/services/NetNetBondService.sol";
import {PTeam} from "@crane/contracts/protocols/pol/net/src/PTeam.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";

contract NetNet_PTeam_Test is TestBase_NetNet {
    function test_exercise_holder_pays_strike_into_treasury() public {
        assertTrue(Behavior_IPTEAM.isValid_IPTEAM_strike(pTeam));
        vm.warp(block.timestamp + Constants.VEST_DURATION / 10);
        uint256 amt = pTeam.exercisableNow();
        assertGt(amt, 0, "vested cap");
        if (amt > 1e9) amt = 1e9;

        uint256 paidWad = FixedPointMath.mulDiv(amt, Constants.PTEAM_STRIKE_WAD, Constants.NET_UNIT);
        uint256 paidRaw = FixedPointMath.mulDivUp(paidWad, 1, 1e12);
        usdg.mint(address(this), paidRaw);
        uint256 treBefore = usdg.balanceOf(address(treasury));
        uint256 netBefore = net.balanceOf(address(this));
        NetNetBondService._exercisePTeam(
            NetNetBondService.PTeamExerciseParams({
                pteam: pTeam,
                usdg: IERC20(address(usdg)),
                treasury: address(treasury),
                netAmount: amt,
                usdgPayRaw: paidRaw
            })
        );
        assertEq(usdg.balanceOf(address(treasury)) - treBefore, paidRaw, "strike to treasury");
        assertEq(net.balanceOf(address(this)) - netBefore, amt, "NET minted to holder");
    }

    function test_not_holder_reverts() public {
        address rando = makeAddr("notPTeam");
        vm.prank(rando);
        vm.expectRevert(Behavior_IPTEAM.selector_IPTEAM_NotHolder());
        pTeam.exercise(1);
    }

    function test_exceeds_vested_cap_reverts() public {
        uint256 cap = pTeam.exercisableNow();
        vm.expectRevert(Behavior_IPTEAM.selector_IPTEAM_ExceedsVestedCap());
        pTeam.exercise(cap + 1);
    }
}
