// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";

import {BASE_MAIN} from "@crane/contracts/constants/networks/BASE_MAIN.sol";
import {IMorpho} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";

// tag::TestBase_MorphoBlueFork_Base[]
/**
 * @title TestBase_MorphoBlueFork (Base)
 * @notice Base mainnet fork base: binds live Morpho Blue + AdaptiveCurveIRM + oracle factory.
 */
abstract contract TestBase_MorphoBlueFork is Test {
    IMorpho internal liveMorpho;
    address internal liveIrm;
    address internal liveOracleFactory;

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl("base_mainnet_alchemy"), BASE_MAIN.DEFAULT_FORK_BLOCK);

        liveMorpho = IMorpho(BASE_MAIN.MORPHO);
        liveIrm = BASE_MAIN.MORPHO_ADAPTIVE_CURVE_IRM;
        liveOracleFactory = BASE_MAIN.MORPHO_CHAINLINK_ORACLE_V2_FACTORY;

        assertGt(address(liveMorpho).code.length, 0, "live Morpho code");
        assertGt(liveIrm.code.length, 0, "live IRM code");
        assertGt(liveOracleFactory.code.length, 0, "live oracle factory code");

        vm.label(address(liveMorpho), "LiveMorpho");
        vm.label(liveIrm, "LiveAdaptiveCurveIrm");
        vm.label(liveOracleFactory, "LiveChainlinkOracleV2Factory");
    }
}
// end::TestBase_MorphoBlueFork_Base[]
