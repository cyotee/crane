// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { CraneScript } from "../../../script/CraneScript.sol";
import { CamelotV2Script } from "../../../script/protocols/CamelotV2Script.sol";
import { CraneTest } from "../../CraneTest.sol";
import { ArbOSTest } from "../networks/ArbOSTest.sol";
import { ApeChainTest } from "../networks/ApeChainTest.sol";

contract CamelotV2BaseTest is CamelotV2Script, ApeChainTest {


    function initialize()
    public virtual
    override(
        CamelotV2Script,
        ApeChainTest
    ) {

    }

    function setUp() public virtual
    override(
        CraneScript,
        ArbOSTest
    ) {
        // initialize();
        CraneTest.setUp();
        // initPrecompiles_ArbOS();
    }

}