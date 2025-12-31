// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

// import { Script } from "forge-std/Script.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import { BetterScript } from "contracts/crane/script/BetterScript.sol";
// import { Script_Crane } from "contracts/crane/script/Script_Crane.sol";
// import { Script_ArbOS } from "contracts/crane/script/networks/Script_ArbOS.sol";
import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
import {TestBase_ArbOS} from "contracts/crane/test/bases/networks/TestBase_ArbOS.sol";

abstract contract TestBase_Curtis is

    // Script,
    // BetterScript,
    // Script_ArbOS,
    // Test_Crane,
    TestBase_ArbOS
{
    function setUp()
        public
        virtual
        override(
            // Test_Crane,
            TestBase_ArbOS
        )
    {
        // initialize();
        Test_Crane.setUp();
        // initPrecompiles_ArbOS();
    }

    function run()
        public
        virtual
        override(
            // Test_Crane,
            TestBase_ArbOS
        )
    {
        Test_Crane.run();
    }
}
