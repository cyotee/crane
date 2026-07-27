// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";
import {FraxswapPair} from
    "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import {BAMM} from "@crane/contracts/protocols/tokens/stable/frax/BAMM/BAMM.sol";

import {BcFraxPhase13bDeploy} from "scripts/foundry/bc/BcFraxPhase13bDeploy.sol";

/// @notice Phase 13b hermetic smoke: FraxswapFactory + pair + full BAMM graph from BAMMTest list.
/// @dev No live BC broadcast. Drives real BcFraxPhase13bDeploy + real BAMM.mint.
contract BC_Phase13b_Frax_Hermetic_Test is Test {
    BcFraxPhase13bDeploy internal phase13b;
    BcFraxPhase13bDeploy.DeployResult internal graph;
    address internal owner;

    function setUp() public {
        owner = address(this);
        phase13b = new BcFraxPhase13bDeploy();
        graph = phase13b.deployHermetic(owner, 100e18);
    }

    function test_hermetic_factory_pair_bamm_graph_has_code() public view {
        assertTrue(graph.fraxswapFactory != address(0) && graph.fraxswapFactory.code.length > 0, "factory");
        assertTrue(graph.pair != address(0) && graph.pair.code.length > 0, "pair");
        assertTrue(graph.bamm != address(0) && graph.bamm.code.length > 0, "bamm");
        assertTrue(graph.bammHelper.code.length > 0, "bammHelper");
        assertTrue(graph.fraxswapOracle.code.length > 0, "oracle");
        assertTrue(graph.fraxswapDummyRouter != address(0) && graph.fraxswapDummyRouter.code.length > 0, "dummyRouter");
        assertTrue(graph.token0.code.length > 0 && graph.token1.code.length > 0, "tokens");

        FraxswapPair pair = FraxswapPair(graph.pair);
        assertEq(pair.token0(), graph.token0, "pair.token0");
        assertEq(pair.token1(), graph.token1, "pair.token1");
        assertTrue(pair.totalSupply() > 0, "pair seeded");

        console2.log("fraxswapFactory", graph.fraxswapFactory);
        console2.log("pair", graph.pair);
        console2.log("bamm", graph.bamm);
        console2.log("bammHelper", graph.bammHelper);
        console2.log("fraxswapOracle", graph.fraxswapOracle);
        console2.log("dummyRouter", graph.fraxswapDummyRouter);
    }

    function test_hermetic_bamm_mint_via_real_bamm() public {
        // Drive shipped BAMM.mint on the deploy graph (BAMMTest parity).
        FraxswapPair pair = FraxswapPair(graph.pair);
        BAMM bamm = BAMM(graph.bamm);

        uint256 lpBal = pair.balanceOf(owner);
        assertTrue(lpBal >= 1e18, "need LP");

        pair.approve(address(bamm), 1e18);
        uint256 bammOut = bamm.mint(owner, 1e18);
        assertTrue(bammOut > 0, "bamm minted");
        assertEq(bamm.balanceOf(owner), bammOut, "bamm bal");
        assertEq(pair.balanceOf(address(bamm)), 1e18, "LP held by BAMM");
    }

    function test_hermetic_contract_list_matches_bamm_testbase() public view {
        // Exact list from BAMMTest._deployBamm / gap report 13b.3
        assertTrue(graph.fraxswapFactory.code.length > 0, "1 FraxswapFactory");
        assertTrue(graph.pair.code.length > 0, "2 FraxswapPair");
        assertTrue(graph.fraxswapDummyRouter.code.length > 0, "3 FraxswapDummyRouter");
        assertTrue(graph.bammHelper.code.length > 0, "4 BAMMHelper");
        assertTrue(graph.fraxswapOracle.code.length > 0, "5 FraxswapOracle");
        assertTrue(graph.bamm.code.length > 0, "6 BAMM");
    }
}
