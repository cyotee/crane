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
import { ScriptBase_Crane_Factories } from "../../../script/ScriptBase_Crane_Factories.sol";
import { ScriptBase_Crane_ERC20 } from "../../../script/ScriptBase_Crane_ERC20.sol";
import { ScriptBase_Crane_ERC4626 } from "../../../script/ScriptBase_Crane_ERC4626.sol";
import { Script_Crane } from "../../../script/Script_Crane.sol";
import { Script_Crane_Stubs } from "../../../script/Script_Crane_Stubs.sol";
import { BetterTest } from "../../../test/BetterTest.sol";
import { Test_Crane } from "../../../test/Test_Crane.sol";
import { Script_Permit2 } from "../../../script/protocols/Script_Permit2.sol";

contract TestBase_Permit2
is
    Script,
    BetterScript,
    ScriptBase_Crane_Factories,
    ScriptBase_Crane_ERC20,
    ScriptBase_Crane_ERC4626,
    Script_Permit2,
    Script_Crane,
    Script_Crane_Stubs,
    BetterTest,
    Test_Crane
{

    function setUp() public virtual
    override(
        // Script_Crane,
        Test_Crane
        // Fixture_Crane,
        // Fixture_CamelotV2,
        // Fixture
    ) {
        Test_Crane.setUp();
    }


    function run() public virtual
    override (
        Script_Permit2,
        ScriptBase_Crane_Factories,
        ScriptBase_Crane_ERC20,
        ScriptBase_Crane_ERC4626,
        Script_Crane,
        Script_Crane_Stubs,
        Test_Crane
    ){
        Script_Permit2.run();
        Script_Crane_Stubs.run();
    }

}