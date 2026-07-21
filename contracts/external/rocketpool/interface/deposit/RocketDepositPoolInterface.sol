// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface RocketDepositPoolInterface {
    function getBalance() external view returns (uint256);
    function getExcessBalance() external view returns (uint256);
    function deposit() external payable;
    function getMaximumDepositAmount() external view returns (uint256);
    function recycleExcessCollateral() external payable;
}
