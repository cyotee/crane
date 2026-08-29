// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {TestBase_NetNetFork} from
    "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNetFork.sol";
import {Behavior_IStaking} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_IStaking.sol";
import {NetNetStakingService} from
    "@crane/contracts/protocols/pol/net/services/NetNetStakingService.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";

contract NetNetFork_Stake_Test is TestBase_NetNetFork {
    function test_live_stake_unstake() public {
        deal(address(usdg), address(this), 50e6);
        _buyNet(50e6, 0);
        uint256 amt = net.balanceOf(address(this));
        uint256 staked = NetNetStakingService._stake(
            NetNetStakingService.StakeParams({
                staking: staking, net: IERC20(address(net)), to: address(this), amount: amt
            })
        );
        assertTrue(Behavior_IStaking.isValid_IStaking_stakeOneToOne(amt, staked));
        uint256 unstaked = NetNetStakingService._unstake(
            NetNetStakingService.UnstakeParams({
                staking: staking, sNet: sNet, to: address(this), amount: staked
            })
        );
        assertTrue(Behavior_IStaking.isValid_IStaking_unstakeOneToOne(staked, unstaked));
    }
}
