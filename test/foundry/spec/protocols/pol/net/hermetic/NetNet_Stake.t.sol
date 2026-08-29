// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {TestBase_NetNet} from "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNet.sol";
import {Behavior_IStaking} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_IStaking.sol";
import {NetNetStakingService} from
    "@crane/contracts/protocols/pol/net/services/NetNetStakingService.sol";
import {Staking} from "@crane/contracts/protocols/pol/net/src/Staking.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";

contract NetNet_Stake_Test is TestBase_NetNet {
    function test_stake_unstake_one_to_one() public {
        usdg.mint(address(this), 1_000e6);
        _buyNet(1_000e6, 0);
        uint256 amt = net.balanceOf(address(this));
        uint256 sBefore = sNet.balanceOf(address(this));
        uint256 staked = NetNetStakingService._stake(
            NetNetStakingService.StakeParams({
                staking: staking, net: IERC20(address(net)), to: address(this), amount: amt
            })
        );
        uint256 sGot = sNet.balanceOf(address(this)) - sBefore;
        assertTrue(Behavior_IStaking.isValid_IStaking_stakeOneToOne(amt, staked));
        assertTrue(Behavior_IStaking.isValid_IStaking_stakeOneToOne(amt, sGot));
        assertTrue(Behavior_IStaking.isValid_IStaking_totalStakedBacksSNet(staking, IsNET(address(sNet))));

        uint256 netBefore = net.balanceOf(address(this));
        uint256 unstaked = NetNetStakingService._unstake(
            NetNetStakingService.UnstakeParams({
                staking: staking, sNet: IsNET(address(sNet)), to: address(this), amount: sGot
            })
        );
        uint256 netGot = net.balanceOf(address(this)) - netBefore;
        assertTrue(Behavior_IStaking.isValid_IStaking_unstakeOneToOne(sGot, unstaked));
        assertTrue(Behavior_IStaking.isValid_IStaking_unstakeOneToOne(sGot, netGot));
    }

    function test_rebase_after_epoch_length_monotonic_index() public {
        usdg.mint(address(this), 1_000e6);
        _buyNet(1_000e6, 0);
        NetNetStakingService._stake(
            NetNetStakingService.StakeParams({
                staking: staking,
                net: IERC20(address(net)),
                to: address(this),
                amount: net.balanceOf(address(this))
            })
        );
        uint256 indexBefore = sNet.index();
        vm.warp(block.timestamp + Constants.EPOCH_LENGTH);
        NetNetStakingService._rebase(staking);
        uint256 indexAfter = sNet.index();
        assertTrue(Behavior_IStaking.isValid_IStaking_rebaseIndexMonotonic(indexBefore, indexAfter));
    }

    function test_stake_not_enabled_selector() public {
        // Already enabled after boot; call a fresh Staking that is unwired/disabled.
        Staking cold = new Staking(address(net), address(sNet), 0);
        vm.expectRevert(Staking.NotEnabled.selector);
        cold.stake(address(this), 1);
    }
}
