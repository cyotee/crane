// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/// @dev Minimal rocketNetworkBalances for domain rate tests
contract RocketNetworkBalancesMock {
    uint256 public totalETH;
    uint256 public totalRETH;

    function setBalances(uint256 ethBal, uint256 rethSupply) external {
        totalETH = ethBal;
        totalRETH = rethSupply;
    }

    function getTotalETHBalance() external view returns (uint256) {
        return totalETH;
    }

    function getTotalRETHSupply() external view returns (uint256) {
        return totalRETH;
    }
}
