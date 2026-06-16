// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    PoolConfiguratorInstance
} from "@crane/contracts/protocols/lending/aave/v3.6/instances/PoolConfiguratorInstance.sol";

contract AaveV3PoolConfigProcedure {
    function _deployPoolConfigurator() internal returns (address) {
        PoolConfiguratorInstance poolConfiguratorImplementation = new PoolConfiguratorInstance();

        return address(poolConfiguratorImplementation);
    }
}
