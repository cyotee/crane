// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {Create2Utils} from
    "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/Create2Utils.sol";
import {SpokeBytecodeLinker} from
    "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/SpokeBytecodeLinker.sol";

/// @notice Pre-deploy Aave V4 LiquidationLogic via CREATE2 and print FOUNDRY_LIBRARIES (Crane path).
/// @dev Path B: ensures Safe Singleton Factory via Create2Utils.ensureCreate2Factory when missing on BC.
contract Script_BC_Phase3b_AaveV4_LibraryPreCompile is Script {
    address internal constant FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function run() external {
        address deployer = msg.sender;
        require(deployer != FOUNDRY_DEFAULT_SENDER, "AaveV4Lib: pass --sender");

        vm.startBroadcast();
        Create2Utils.ensureCreate2Factory();
        (address lib,) = SpokeBytecodeLinker.deployLiquidationLogicAndLinkSpoke();
        vm.stopBroadcast();

        address factory = Create2Utils.getFactory();
        console2.log("LiquidationLogic", lib);
        console2.log(SpokeBytecodeLinker.foundryLibrariesEnv(lib));
        console2.log("CREATE2_FACTORY (active Path A or Path B)", factory);
        console2.log("CREATE2_FACTORY code length", factory.code.length);
        console2.log("Path A canonical", Create2Utils.CREATE2_FACTORY);
        console2.log("Path A code length", Create2Utils.CREATE2_FACTORY.code.length);
    }
}
