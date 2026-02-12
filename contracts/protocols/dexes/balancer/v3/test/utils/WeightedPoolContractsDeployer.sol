// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";

import {WeightedPool} from "@crane/contracts/external/balancer/v3/pool-weighted/contracts/WeightedPool.sol";
import {WeightedPoolFactory} from "@crane/contracts/external/balancer/v3/pool-weighted/contracts/WeightedPoolFactory.sol";
import {WeightedPool8020Factory} from "@crane/contracts/external/balancer/v3/pool-weighted/contracts/WeightedPool8020Factory.sol";

/// @notice Crane-local port of Balancer's WeightedPoolContractsDeployer for testing purposes.
/// @dev This is a simplified version that doesn't support artifact reuse from hardhat.
/// It directly deploys contracts using standard Solidity deployment.
contract WeightedPoolContractsDeployer {

    function deployWeightedPoolFactory(
        IVault vault,
        uint32 pauseWindowDuration,
        string memory factoryVersion,
        string memory poolVersion
    ) internal returns (WeightedPoolFactory) {
        return new WeightedPoolFactory(vault, pauseWindowDuration, factoryVersion, poolVersion);
    }

    function deployWeightedPool8020Factory(
        IVault vault,
        uint32 pauseWindowDuration,
        string memory factoryVersion,
        string memory poolVersion
    ) internal returns (WeightedPool8020Factory) {
        return new WeightedPool8020Factory(vault, pauseWindowDuration, factoryVersion, poolVersion);
    }
}
