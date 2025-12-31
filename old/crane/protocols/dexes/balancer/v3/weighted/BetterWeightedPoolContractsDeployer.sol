// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase, TestBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                  Balancer V3                               */
/* -------------------------------------------------------------------------- */

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

// import { BaseContractsDeployer } from "@balancer-labs/v3-solidity-utils/test/foundry/utils/BaseContractsDeployer.sol";

import {WeightedPoolMock} from "@balancer-labs/v3-pool-weighted/contracts/test/WeightedPoolMock.sol";
import {WeightedMathMock} from "@balancer-labs/v3-pool-weighted/contracts/test/WeightedMathMock.sol";
import {WeightedBasePoolMathMock} from "@balancer-labs/v3-pool-weighted/contracts/test/WeightedBasePoolMathMock.sol";
import {WeightedPool} from "@balancer-labs/v3-pool-weighted/contracts/WeightedPool.sol";
import {WeightedPoolFactory} from "@balancer-labs/v3-pool-weighted/contracts/WeightedPoolFactory.sol";
import {WeightedPool8020Factory} from "@balancer-labs/v3-pool-weighted/contracts/WeightedPool8020Factory.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {
    BetterBaseContractsDeployer
} from "contracts/crane/protocols/dexes/balancer/v3/solidity-utils/BetterBaseContractsDeployer.sol";

/**
 * @dev This contract contains functions for deploying mocks and contracts related to the "WeightedPool". These functions should have support for reusing artifacts from the hardhat compilation.
 */
contract BetterWeightedPoolContractsDeployer is
    CommonBase,
    ScriptBase,
    StdChains,
    StdCheatsSafe,
    StdUtils,
    Script,
    BetterScript,
    BetterBaseContractsDeployer
{
    string private artifactsRootDir = "artifacts/";

    constructor() {
        // if this external artifact path exists, it means we are running outside of this repo
        if (vm.exists("artifacts/@balancer-labs/v3-pool-weighted/")) {
            artifactsRootDir = "artifacts/@balancer-labs/v3-pool-weighted/";
        }
    }

    function deployWeightedPoolFactory(
        IVault vault,
        uint32 pauseWindowDuration,
        string memory factoryVersion,
        string memory poolVersion
    ) internal returns (WeightedPoolFactory) {
        if (reusingArtifacts) {
            return WeightedPoolFactory(
                deployCode(
                    _computeWeightedPath(type(WeightedPoolFactory).name),
                    abi.encode(vault, pauseWindowDuration, factoryVersion, poolVersion)
                )
            );
        } else {
            return new WeightedPoolFactory(vault, pauseWindowDuration, factoryVersion, poolVersion);
        }
    }

    function deployWeightedPool8020Factory(
        IVault vault,
        uint32 pauseWindowDuration,
        string memory factoryVersion,
        string memory poolVersion
    ) internal returns (WeightedPool8020Factory) {
        if (reusingArtifacts) {
            return WeightedPool8020Factory(
                deployCode(
                    _computeWeightedPath(type(WeightedPool8020Factory).name),
                    abi.encode(vault, pauseWindowDuration, factoryVersion, poolVersion)
                )
            );
        } else {
            return new WeightedPool8020Factory(vault, pauseWindowDuration, factoryVersion, poolVersion);
        }
    }

    function deployWeightedPoolMock(WeightedPool.NewPoolParams memory params, IVault vault)
        internal
        returns (WeightedPoolMock)
    {
        if (reusingArtifacts) {
            return WeightedPoolMock(
                deployCode(_computeWeightedPathTest(type(WeightedPoolMock).name), abi.encode(params, vault))
            );
        } else {
            return new WeightedPoolMock(params, vault);
        }
    }

    function deployWeightedMathMock() internal returns (WeightedMathMock) {
        if (reusingArtifacts) {
            return WeightedMathMock(deployCode(_computeWeightedPathTest(type(WeightedMathMock).name), ""));
        } else {
            return new WeightedMathMock();
        }
    }

    function deployWeightedBasePoolMathMock(uint256[] memory weights) internal returns (WeightedBasePoolMathMock) {
        if (reusingArtifacts) {
            return WeightedBasePoolMathMock(
                deployCode(_computeWeightedPathTest(type(WeightedBasePoolMathMock).name), abi.encode(weights))
            );
        } else {
            return new WeightedBasePoolMathMock(weights);
        }
    }

    function _computeWeightedPath(string memory name) private view returns (string memory) {
        return string(abi.encodePacked(artifactsRootDir, "contracts/", name, ".sol/", name, ".json"));
    }

    function _computeWeightedPathTest(string memory name) private view returns (string memory) {
        return string(abi.encodePacked(artifactsRootDir, "contracts/test/", name, ".sol/", name, ".json"));
    }
}
