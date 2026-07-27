// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";

import {BCPhaseScriptBase} from "./BCPhaseScriptBase.s.sol";
import {Script_BC_Phase1_Factories} from "./Script_BC_Phase1_Factories.s.sol";
import {Script_BC_Phase2_BalancerV3} from "./Script_BC_Phase2_BalancerV3.s.sol";

/// @notice One broadcast: Phase 1 factories then Phase 2 Balancer V3.
/// @dev Standalone Phase 1 / Phase 2 scripts remain primary for resume after partial failure.
///      Phase 2 receives Phase 1's newly deployed factory addresses (not BC_TESTNET constants).
contract Script_BC_FullStack is BCPhaseScriptBase {
    function _protocolName() internal pure override returns (string memory) {
        return "Crane BC FullStack Phase1+Phase2";
    }

    function run() external {
        vm.startBroadcast();
        address deployer = msg.sender;
        _requireNotFoundryDefaultSender(deployer);

        console2.log("=== FullStack: Phase 1 ===");
        Script_BC_Phase1_Factories p1 = new Script_BC_Phase1_Factories();
        p1.deployForFullStack(deployer);

        console2.log("=== FullStack: Phase 2 (handoff Phase1 factories) ===");
        Script_BC_Phase2_BalancerV3 p2 = new Script_BC_Phase2_BalancerV3();
        p2.deployForFullStack(
            deployer,
            address(p1.coreFactory()),
            address(p1.diamondFactory()),
            p1.weth(),
            p1.permit2()
        );

        vm.stopBroadcast();
        console2.log("FullStack complete; manifests written by each phase.");
        console2.log("Phase1 Create3Factory", address(p1.coreFactory()));
        console2.log("Phase1 DiamondFactory", address(p1.diamondFactory()));
        console2.log("Phase1 Permit2", p1.permit2());
    }
}
