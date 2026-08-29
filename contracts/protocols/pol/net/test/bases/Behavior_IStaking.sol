// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IStaking} from "@crane/contracts/protocols/pol/net/src/interfaces/IStaking.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";

// tag::Behavior_IStaking[]
/**
 * @title Behavior_IStaking
 * @notice Stake / unstake 1:1 and rebase monotonicity helpers.
 */
library Behavior_IStaking {
    function _Behavior_IStakingName() internal pure returns (string memory) {
        return type(Behavior_IStaking).name;
    }

    // tag::isValid_IStaking_stakeOneToOne[]
    function isValid_IStaking_stakeOneToOne(uint256 netIn, uint256 sNetOut) internal pure returns (bool) {
        return netIn == sNetOut;
    }
    // end::isValid_IStaking_stakeOneToOne[]

    // tag::isValid_IStaking_unstakeOneToOne[]
    function isValid_IStaking_unstakeOneToOne(uint256 sNetIn, uint256 netOut) internal pure returns (bool) {
        return sNetIn == netOut;
    }
    // end::isValid_IStaking_unstakeOneToOne[]

    // tag::isValid_IStaking_totalStakedBacksSNet[]
    function isValid_IStaking_totalStakedBacksSNet(IStaking staking, IsNET sNet)
        internal
        view
        returns (bool)
    {
        return staking.totalStaked() == sNet.totalSupply() - sNet.balanceOf(address(staking));
    }
    // end::isValid_IStaking_totalStakedBacksSNet[]

    // tag::isValid_IStaking_rebaseIndexMonotonic[]
    function isValid_IStaking_rebaseIndexMonotonic(uint256 indexBefore, uint256 indexAfter)
        internal
        pure
        returns (bool)
    {
        return indexAfter >= indexBefore;
    }
    // end::isValid_IStaking_rebaseIndexMonotonic[]
}
// end::Behavior_IStaking[]
