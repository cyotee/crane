// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

contract RocketDAOProtocolSettingsDepositMock {
    bool public depositEnabled = true;
    bool public assignDepositsEnabled = false;
    uint256 public minimumDeposit = 0.01 ether;
    uint256 public maximumDepositPoolSize = 1000 ether;
    uint256 public depositFee = 0; // 1e18 scale

    function setDepositEnabled(bool v) external { depositEnabled = v; }
    function setAssignDepositsEnabled(bool v) external { assignDepositsEnabled = v; }
    function setMaximumDepositPoolSize(uint256 v) external { maximumDepositPoolSize = v; }
    function setDepositFee(uint256 v) external { depositFee = v; }

    function getDepositEnabled() external view returns (bool) { return depositEnabled; }
    function getAssignDepositsEnabled() external view returns (bool) { return assignDepositsEnabled; }
    function getMinimumDeposit() external view returns (uint256) { return minimumDeposit; }
    function getMaximumDepositPoolSize() external view returns (uint256) { return maximumDepositPoolSize; }
    function getDepositFee() external view returns (uint256) { return depositFee; }
}
