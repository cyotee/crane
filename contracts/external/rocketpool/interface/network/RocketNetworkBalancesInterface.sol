// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface RocketNetworkBalancesInterface {
    function getTotalETHBalance() external view returns (uint256);
    function getTotalRETHSupply() external view returns (uint256);
}
