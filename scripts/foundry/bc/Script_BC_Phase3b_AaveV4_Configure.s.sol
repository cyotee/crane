// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {BcAavePhase3Deploy} from "./BcAavePhase3Deploy.sol";

/// @notice Phase 3b configure: list WETH/USDC/DAI on hub/spoke with BC Chainlink feeds.
/// @dev Expects V4 core already deployed in the same process (use fork test / combined script).
///      Standalone: re-run deployV4Core then configure (idempotent where salts allow).
contract Script_BC_Phase3b_AaveV4_Configure is Script {
    address internal constant FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function run() external {
        address deployer = msg.sender;
        require(deployer != FOUNDRY_DEFAULT_SENDER, "AaveV4Cfg: pass --sender");

        vm.startBroadcast();
        // Deploy core then configure in one broadcast for resume-safe local/fork runs.
        BcAavePhase3Deploy.V4DeployResult memory core = BcAavePhase3Deploy.deployV4Core(deployer);
        BcAavePhase3Deploy.V4ConfigureResult memory cfg = BcAavePhase3Deploy.configureV4Market(deployer, core);
        vm.stopBroadcast();

        console2.log("configured hub", core.hub);
        console2.log("configured spoke", core.spoke);
        console2.log("wethReserveId", cfg.wethReserveId);
        console2.log("usdcReserveId", cfg.usdcReserveId);
        console2.log("daiReserveId", cfg.daiReserveId);
    }
}
