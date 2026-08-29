// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IStaking} from "@crane/contracts/protocols/pol/net/src/interfaces/IStaking.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";

// tag::NetNetStakingService[]
/**
 * @title NetNetStakingService - Stake / unstake / rebase helpers.
 * @author Crane
 * @dev Caller context is the token holder.
 */
library NetNetStakingService {
    // tag::StakeParams[]
    struct StakeParams {
        IStaking staking;
        IERC20 net;
        address to;
        uint256 amount;
    }
    // end::StakeParams[]

    // tag::UnstakeParams[]
    struct UnstakeParams {
        IStaking staking;
        IsNET sNet;
        address to;
        uint256 amount;
    }
    // end::UnstakeParams[]

    // tag::_stake(StakeParams)[]
    /**
     * @notice Stake NET 1:1 for sNET.
     * @custom:signature _stake((address,address,address,uint256))
     */
    function _stake(StakeParams memory p) internal returns (uint256) {
        p.net.approve(address(p.staking), p.amount);
        return p.staking.stake(p.to, p.amount);
    }
    // end::_stake(StakeParams)[]

    // tag::_unstake(UnstakeParams)[]
    /**
     * @notice Unstake sNET 1:1 for NET.
     * @custom:signature _unstake((address,address,address,uint256))
     */
    function _unstake(UnstakeParams memory p) internal returns (uint256) {
        p.sNet.approve(address(p.staking), p.amount);
        return p.staking.unstake(p.to, p.amount);
    }
    // end::_unstake(UnstakeParams)[]

    // tag::_rebase(IStaking)[]
    /**
     * @notice Permissionless epoch rebase.
     * @custom:signature _rebase(address)
     */
    function _rebase(IStaking staking) internal {
        staking.rebase();
    }
    // end::_rebase(IStaking)[]
}
// end::NetNetStakingService[]
