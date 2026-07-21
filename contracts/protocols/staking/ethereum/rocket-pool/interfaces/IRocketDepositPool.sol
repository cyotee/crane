// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IRocketDepositPool
 * @notice Rocket Pool deposit pool (ETH → rETH when capacity allows).
 */
interface IRocketDepositPool {
    function deposit() external payable;

    function getBalance() external view returns (uint256);

    function getMaximumDepositAmount() external view returns (uint256);

    function getExcessBalance() external view returns (uint256);
}
