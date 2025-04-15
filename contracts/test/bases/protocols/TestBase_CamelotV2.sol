// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import { Script } from "forge-std/Script.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { BetterScript } from "../../../script/BetterScript.sol";
import { Script_Crane } from "../../../script/Script_Crane.sol";
import { Script_WETH } from "../../../script/protocols/Script_WETH.sol";
import { Script_ArbOS } from "../../../script/networks/Script_ArbOS.sol";
import { Script_ApeChain } from "../../../script/networks/Script_ApeChain.sol";
import { TestBase_Curtis } from "../networks/TestBase_Curtis.sol";
import { Script_CamelotV2 } from "../../../script/protocols/Script_CamelotV2.sol";
import { Test_Crane } from "../../Test_Crane.sol";
import { TestBase_ArbOS } from "../networks/TestBase_ArbOS.sol";
import { TestBase_ApeChain } from "../networks/TestBase_ApeChain.sol";

contract TestBase_CamelotV2
is
    Script,
    BetterScript,
    Script_WETH,
    Script_ArbOS,
    Script_ApeChain,
    Script_CamelotV2,
    TestBase_ApeChain,
    TestBase_Curtis
{


    function setUp() public virtual
    override(
        TestBase_ApeChain,
        TestBase_Curtis
    ) {
        // initialize();
        Test_Crane.setUp();
        // initPrecompiles_ArbOS();
    }

    function run() public virtual
    override(
        Script_WETH,
        Script_CamelotV2,
        Test_Crane
    ) {
        // super.run();
        // _initializePools();
    }

}