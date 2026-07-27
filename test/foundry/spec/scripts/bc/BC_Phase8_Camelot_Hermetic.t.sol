// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {CamelotFactory} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol";
import {BcCamelotPhase8Deploy} from "scripts/foundry/bc/BcCamelotPhase8Deploy.sol";

/// @notice Phase 8 hermetic smoke: factory + router + createPair.
/// @dev Drives shipped BcCamelotPhase8Deploy. No live BC broadcast.
contract BC_Phase8_Camelot_Hermetic_Test is Test {
    BcCamelotPhase8Deploy internal phase8;
    BcCamelotPhase8Deploy.DeployResult internal graph;

    function setUp() public {
        phase8 = new BcCamelotPhase8Deploy();
        graph = phase8.deployHermetic(address(this));
    }

    function test_hermetic_factory_router_pair_have_code() public view {
        assertTrue(graph.camelotFactory.code.length > 0, "factory");
        assertTrue(graph.camelotRouter.code.length > 0, "router");
        assertTrue(graph.samplePair != address(0) && graph.samplePair.code.length > 0, "pair");
        assertEq(CamelotFactory(graph.camelotFactory).allPairsLength(), 1, "one pair");
        console2.log("camelotFactory", graph.camelotFactory);
        console2.log("camelotRouter", graph.camelotRouter);
        console2.log("samplePair", graph.samplePair);
    }
}
