// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {EmissionManager} from "@crane/contracts/protocols/lending/aave/v3.6/rewards/EmissionManager.sol";
import {RewardsController} from "@crane/contracts/protocols/lending/aave/v3.6/rewards/RewardsController.sol";

contract AaveV3IncentiveProcedure {
    function _deployIncentives(address tempOwner) internal returns (address, address) {
        address emissionManager = address(new EmissionManager(tempOwner));
        address rewardsControllerImplementation = address(new RewardsController(emissionManager));

        return (emissionManager, rewardsControllerImplementation);
    }
}
