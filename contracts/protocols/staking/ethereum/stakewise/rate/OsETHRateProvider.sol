// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IOsTokenVaultController} from
    "@crane/contracts/protocols/staking/ethereum/stakewise/interfaces/IOsTokenVaultController.sol";
import {IStakingRateProvider} from "@crane/contracts/protocols/staking/ethereum/common/rate/IStakingRateProvider.sol";

/**
 * @title OsETHRateProvider
 * @notice IRateProvider for osETH via OsTokenVaultController.convertToAssets(1e18).
 */
contract OsETHRateProvider is IStakingRateProvider {
    IOsTokenVaultController public immutable CONTROLLER;

    constructor(IOsTokenVaultController controller_) {
        require(address(controller_) != address(0), "zero");
        CONTROLLER = controller_;
    }

    function getRate() external view returns (uint256) {
        return CONTROLLER.convertToAssets(1e18);
    }
}
