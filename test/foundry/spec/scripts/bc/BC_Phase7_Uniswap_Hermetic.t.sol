// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {BcUniswapPhase7Deploy, BcV4Router} from "scripts/foundry/bc/BcUniswapPhase7Deploy.sol";

/// @notice Phase 7 hermetic smoke: PoolManager + periphery + concrete BcV4Router.
/// @dev Drives shipped BcUniswapPhase7Deploy. No live BC broadcast.
contract BC_Phase7_Uniswap_Hermetic_Test is Test {
    BcUniswapPhase7Deploy internal phase7;
    BcUniswapPhase7Deploy.DeployResult internal graph;
    address internal owner;

    function setUp() public {
        owner = makeAddr("uniOwner");
        phase7 = new BcUniswapPhase7Deploy();
        graph = phase7.deployHermetic(owner);
    }

    function test_hermetic_periphery_and_v4Router_have_code() public view {
        assertTrue(graph.poolManager.code.length > 0, "poolManager");
        assertTrue(graph.permit2.code.length > 0, "permit2");
        assertTrue(graph.positionDescriptor.code.length > 0, "descriptor");
        assertTrue(graph.positionManager.code.length > 0, "positionManager");
        assertTrue(graph.v4Router.code.length > 0, "v4Router concrete");
        assertTrue(graph.stateView.code.length > 0, "stateView");
        assertTrue(graph.v4Quoter.code.length > 0, "v4Quoter");

        // BcV4Router is concrete (not address(0) abstract skip).
        assertTrue(graph.v4Router != address(0), "v4Router non-zero");
        // poolManager immutables on router match deploy
        assertEq(address(BcV4Router(payable(graph.v4Router)).poolManager()), graph.poolManager, "router.pm");

        console2.log("poolManager", graph.poolManager);
        console2.log("v4Router", graph.v4Router);
        console2.log("positionManager", graph.positionManager);
        console2.log("stateView", graph.stateView);
    }

    function test_hermetic_v4Router_is_not_abstract_zero() public view {
        // Regression: old script left v4Router = address(0)
        assertTrue(graph.v4Router.code.length > 10, "router bytecode");
    }
}
