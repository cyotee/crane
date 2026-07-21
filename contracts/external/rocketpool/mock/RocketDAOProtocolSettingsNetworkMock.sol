// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

contract RocketDAOProtocolSettingsNetworkMock {
    uint256 public targetRethCollateralRate = 0; // prefer vault path

    function setTargetRethCollateralRate(uint256 v) external { targetRethCollateralRate = v; }
    function getTargetRethCollateralRate() external view returns (uint256) { return targetRethCollateralRate; }
}
