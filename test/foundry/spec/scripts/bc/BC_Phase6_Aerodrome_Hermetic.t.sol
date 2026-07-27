// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {Voter} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Voter.sol";
import {CLFactory} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/CLFactory.sol";

import {BcAerodromePhase6Deploy} from "scripts/foundry/bc/BcAerodromePhase6Deploy.sol";

/// @notice Phase 6 hermetic smoke: full ve(3,3) + governors + fee modules + createPool.
/// @dev Drives shipped BcAerodromePhase6Deploy. No live BC broadcast.
contract BC_Phase6_Aerodrome_Hermetic_Test is Test {
    BcAerodromePhase6Deploy internal phase6;
    BcAerodromePhase6Deploy.DeployResult internal graph;
    address internal team;

    function setUp() public {
        team = makeAddr("aeroTeam");
        phase6 = new BcAerodromePhase6Deploy();
        graph = phase6.deployHermetic(team);
    }

    function test_hermetic_core_and_governors_have_code() public view {
        assertTrue(graph.aero.code.length > 0, "aero");
        assertTrue(graph.poolFactory.code.length > 0, "poolFactory");
        assertTrue(graph.voter.code.length > 0, "voter");
        assertTrue(graph.router.code.length > 0, "router");
        assertTrue(graph.minter.code.length > 0, "minter");
        assertTrue(graph.protocolGovernor.code.length > 0, "protocolGovernor");
        assertTrue(graph.epochGovernor.code.length > 0, "epochGovernor");
        assertTrue(graph.clFactory.code.length > 0, "clFactory");
        assertTrue(graph.customSwapFeeModule.code.length > 0, "swapFeeModule");
        assertTrue(graph.customUnstakedFeeModule.code.length > 0, "unstakedFeeModule");
        assertTrue(graph.samplePool != address(0) && graph.samplePool.code.length > 0, "samplePool");

        assertEq(Voter(graph.voter).governor(), graph.protocolGovernor, "governor wired");
        assertEq(Voter(graph.voter).epochGovernor(), graph.epochGovernor, "epochGovernor wired");
        assertEq(CLFactory(graph.clFactory).swapFeeModule(), graph.customSwapFeeModule, "swap module");
        assertEq(
            CLFactory(graph.clFactory).unstakedFeeModule(), graph.customUnstakedFeeModule, "unstaked module"
        );

        console2.log("aero", graph.aero);
        console2.log("protocolGovernor", graph.protocolGovernor);
        console2.log("epochGovernor", graph.epochGovernor);
        console2.log("samplePool", graph.samplePool);
    }

    function test_hermetic_createPool_volatile_smoke() public view {
        // deployHermetic already created a volatile pool via PoolFactory.createPool
        assertTrue(graph.samplePool.code.length > 0, "volatile pool code");
    }
}
