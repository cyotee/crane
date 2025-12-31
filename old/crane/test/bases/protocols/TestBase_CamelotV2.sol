// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase, TestBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {Script_Crane} from "contracts/crane/script/Script_Crane.sol";
import {ScriptBase_Crane_ERC20} from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {ScriptBase_Crane_ERC4626} from "contracts/crane/script/ScriptBase_Crane_ERC4626.sol";
import {Script_WETH} from "contracts/crane/script/protocols/Script_WETH.sol";
import {Script_ArbOS} from "contracts/crane/script/networks/Script_ArbOS.sol";
import {Script_ApeChain} from "contracts/crane/script/networks/Script_ApeChain.sol";
import {TestBase_Curtis} from "contracts/crane/test/bases/networks/TestBase_Curtis.sol";
import {Script_CamelotV2} from "contracts/crane/script/protocols/Script_CamelotV2.sol";
import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
import {TestBase_ArbOS} from "contracts/crane/test/bases/networks/TestBase_ArbOS.sol";
import {TestBase_ApeChain} from "contracts/crane/test/bases/networks/TestBase_ApeChain.sol";
import {ScriptBase_Crane_Factories} from "contracts/crane/script/ScriptBase_Crane_Factories.sol";
import {Script_Crane_Stubs} from "contracts/crane/script/Script_Crane_Stubs.sol";
import {BetterTest} from "contracts/crane/test/BetterTest.sol";
import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";

abstract contract TestBase_CamelotV2 is
    CommonBase,
    ScriptBase,
    TestBase,
    StdAssertions,
    StdChains,
    StdCheatsSafe,
    StdCheats,
    StdInvariant,
    StdUtils,
    Script,
    BetterScript,
    ScriptBase_Crane_Factories,
    ScriptBase_Crane_ERC20,
    ScriptBase_Crane_ERC4626,
    Script_WETH,
    Script_ArbOS,
    Script_ApeChain,
    Script_CamelotV2,
    Script_Crane,
    Script_Crane_Stubs,
    Test,
    BetterTest,
    Test_Crane,
    TestBase_ArbOS,
    TestBase_ApeChain,
    TestBase_Curtis
{
    function setUp() public virtual override(Test_Crane, TestBase_ArbOS, TestBase_ApeChain, TestBase_Curtis) {
        // initialize();
        Test_Crane.setUp();
        // initPrecompiles_ArbOS();
    }

    function run()
        public
        virtual
        override(
            ScriptBase_Crane_Factories,
            ScriptBase_Crane_ERC20,
            ScriptBase_Crane_ERC4626,
            Script_WETH,
            Script_CamelotV2,
            Script_Crane,
            Script_Crane_Stubs,
            Test_Crane,
            TestBase_ArbOS,
            TestBase_ApeChain,
            TestBase_Curtis
        )
    {
        // super.run();
        // _initializePools();
    }
}
