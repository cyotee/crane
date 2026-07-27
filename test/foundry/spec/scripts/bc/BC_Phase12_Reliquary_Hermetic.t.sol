// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {ERC721Holder} from
    "@crane/contracts/external/openzeppelin-contracts/token/ERC721/utils/ERC721Holder.sol";

import {Reliquary} from "@crane/contracts/protocols/staking/reliquary/v1/Reliquary.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";
import {BcReliquaryPhase12Deploy} from "scripts/foundry/bc/BcReliquaryPhase12Deploy.sol";

/// @notice Phase 12 hermetic smoke: full curves + reward fund + createRelicAndDeposit.
/// @dev Drives shipped BcReliquaryPhase12Deploy. No live BC broadcast.
contract BC_Phase12_Reliquary_Hermetic_Test is Test, ERC721Holder {
    BcReliquaryPhase12Deploy internal phase12;
    BcReliquaryPhase12Deploy.DeployResult internal graph;

    function setUp() public {
        phase12 = new BcReliquaryPhase12Deploy();
        // Bootstrap Relic mints to this test (ERC721Holder), not the helper contract.
        graph = phase12.deployHermetic(address(this));
        // Pull pool tokens from helper for deposit smoke.
        uint256 bal = IERC20(graph.poolToken).balanceOf(address(phase12));
        if (bal > 1) {
            vm.prank(address(phase12));
            IERC20(graph.poolToken).transfer(address(this), bal - 1);
        }
        IERC20(graph.poolToken).approve(graph.reliquary, type(uint256).max);
    }

    function test_hermetic_curves_and_funding() public view {
        assertTrue(graph.reliquary.code.length > 0, "reliquary");
        assertTrue(graph.linearCurve.code.length > 0, "linear");
        assertTrue(graph.linearPlateauCurve.code.length > 0, "linearPlateau");
        assertTrue(graph.polynomialCurve.code.length > 0, "polynomial");
        assertTrue(graph.rewardFunded > 0, "rewards funded");
        assertEq(IERC20(graph.rewardToken).balanceOf(graph.reliquary), graph.rewardFunded, "reward bal");
        assertEq(Reliquary(graph.reliquary).poolLength(), 1, "one pool");

        console2.log("reliquary", graph.reliquary);
        console2.log("linearPlateau", graph.linearPlateauCurve);
        console2.log("polynomial", graph.polynomialCurve);
        console2.log("rewardFunded", graph.rewardFunded);
    }

    function test_hermetic_createRelicAndDeposit() public {
        uint256 amount = 100e18;
        uint256 relicId = Reliquary(graph.reliquary).createRelicAndDeposit(address(this), 0, amount);
        assertEq(Reliquary(graph.reliquary).ownerOf(relicId), address(this), "owner");
        console2.log("relicId", relicId);
    }
}
