// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    AaveV4InterestRateStrategyDeployProcedure
} from "@crane/contracts/protocols/lending/aave/v4/deployments/procedures/deploy/hub/AaveV4InterestRateStrategyDeployProcedure.sol";

contract AaveV4InterestRateStrategyDeployProcedureWrapper is AaveV4InterestRateStrategyDeployProcedure {
    bool public IS_TEST = true;

    function deployInterestRateStrategy(address hub, bytes32 salt) external returns (address) {
        return _deployInterestRateStrategy(hub, salt);
    }
}
