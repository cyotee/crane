// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    CREATE3 as BalancerCREATE3
} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/solmate/CREATE3.sol";

library CREATE3 {
    function deploy(bytes32 salt, bytes memory creationCode, uint256 value) internal returns (address deployed) {
        return BalancerCREATE3.deploy(salt, creationCode, value);
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        return BalancerCREATE3.getDeployed(salt);
    }

    function getDeployed(bytes32 salt, address creator) internal pure returns (address) {
        return BalancerCREATE3.getDeployed(salt, creator);
    }
}
