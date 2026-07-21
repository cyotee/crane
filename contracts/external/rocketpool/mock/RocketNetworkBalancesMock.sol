// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {RocketNetworkBalancesInterface} from
    "@crane/contracts/external/rocketpool/interface/network/RocketNetworkBalancesInterface.sol";

contract RocketNetworkBalancesMock is RocketNetworkBalancesInterface {
    uint256 public totalETH;
    uint256 public totalRETH;

    function setBalances(uint256 _eth, uint256 _reth) external {
        totalETH = _eth;
        totalRETH = _reth;
    }

    function getTotalETHBalance() external view returns (uint256) {
        return totalETH;
    }

    function getTotalRETHSupply() external view returns (uint256) {
        return totalRETH;
    }
}
