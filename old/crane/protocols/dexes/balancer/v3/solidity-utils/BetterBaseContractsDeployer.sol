// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                  Foundrey                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase, TestBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {CREATE3} from "@balancer-labs/v3-solidity-utils/contracts/solmate/CREATE3.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {BetterTest} from "contracts/crane/test/BetterTest.sol";

abstract contract BetterBaseContractsDeployer is
    CommonBase,
    ScriptBase,
    StdChains,
    StdCheatsSafe,
    StdUtils,
    Script,
    BetterScript
{
    bool reusingArtifacts;

    constructor() {
        reusingArtifacts = vm.envOr("REUSING_HARDHAT_ARTIFACTS", false);
    }

    function _create3(bytes memory constructorArgs, bytes memory bytecode, bytes32 salt) internal returns (address) {
        return CREATE3.deploy(salt, abi.encodePacked(bytecode, constructorArgs), 0);
    }
}
