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
import { Script_ArbOS } from "../../../script/networks/Script_ArbOS.sol";
import { Test_Crane } from "../../Test_Crane.sol";
import { TestBase_ArbOS } from "./TestBase_ArbOS.sol";

contract TestBase_Curtis
is
    Script,
    BetterScript,
    Script_ArbOS,
    Test_Crane,
    TestBase_ArbOS
{

    function setUp() public virtual
    override(
        Test_Crane,
        TestBase_ArbOS
    ) {
        // initialize();
        Test_Crane.setUp();
        // initPrecompiles_ArbOS();
    }

}