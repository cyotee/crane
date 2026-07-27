// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {Vat} from "@crane/contracts/protocols/cdps/sky/core/Vat.sol";
import {Dai} from "@crane/contracts/protocols/cdps/sky/core/Dai.sol";
import {GemJoin, DaiJoin} from "@crane/contracts/protocols/cdps/sky/core/Join.sol";
import {
    BcSkyPhase10Deploy,
    BcSkyMockGem
} from "scripts/foundry/bc/BcSkyPhase10Deploy.sol";

/// @notice Phase 10 hermetic smoke: full DSS + flapper/flopper/pot/chainlog + openCdp.
/// @dev Drives shipped BcSkyPhase10Deploy. No live BC broadcast.
contract BC_Phase10_Sky_Hermetic_Test is Test {
    uint256 internal constant WAD = 10 ** 18;

    BcSkyPhase10Deploy internal phase10;
    BcSkyPhase10Deploy.DeployResult internal dss;
    address internal alice;

    function setUp() public {
        alice = makeAddr("skyAlice");
        phase10 = new BcSkyPhase10Deploy();
        dss = phase10.deployHermetic(block.chainid);
    }

    function test_hermetic_full_manifest_modules_have_code() public view {
        assertTrue(dss.vat.code.length > 0, "vat");
        assertTrue(dss.dai.code.length > 0, "dai");
        assertTrue(dss.daiJoin.code.length > 0, "daiJoin");
        assertTrue(dss.jug.code.length > 0, "jug");
        assertTrue(dss.pot.code.length > 0, "pot");
        assertTrue(dss.spotter.code.length > 0, "spotter");
        assertTrue(dss.vow.code.length > 0, "vow");
        assertTrue(dss.dog.code.length > 0, "dog");
        assertTrue(dss.flapper.code.length > 0, "flapper");
        assertTrue(dss.flopper.code.length > 0, "flopper");
        assertTrue(dss.end.code.length > 0, "end");
        assertTrue(dss.chainlog.code.length > 0, "chainlog");
        assertTrue(dss.gemJoin.code.length > 0, "gemJoin");
        assertTrue(dss.pip.code.length > 0, "pip");

        console2.log("vat", dss.vat);
        console2.log("flapper", dss.flapper);
        console2.log("flopper", dss.flopper);
        console2.log("pot", dss.pot);
        console2.log("chainlog", dss.chainlog);
    }

    function test_hermetic_openCdp_draw_dai() public {
        uint256 coll = 10 * WAD;
        uint256 daiAmt = 1000 * WAD; // $2000 gem * 10 coll / 1.5 mat >> 1000 DAI

        BcSkyMockGem(dss.gem).mint(alice, coll);
        vm.startPrank(alice);
        BcSkyMockGem(dss.gem).approve(dss.gemJoin, coll);
        GemJoin(dss.gemJoin).join(alice, coll);
        Vat(dss.vat).hope(address(this));
        vm.stopPrank();

        // frob from test (after hope) or from alice
        vm.prank(alice);
        Vat(dss.vat).frob(dss.ilk, alice, alice, alice, int256(coll), int256(daiAmt));

        vm.startPrank(alice);
        Vat(dss.vat).hope(dss.daiJoin);
        DaiJoin(dss.daiJoin).exit(alice, daiAmt);
        vm.stopPrank();

        assertEq(Dai(dss.dai).balanceOf(alice), daiAmt, "DAI drawn");
        console2.log("alice DAI", Dai(dss.dai).balanceOf(alice));
    }
}
