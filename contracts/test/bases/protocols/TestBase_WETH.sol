// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {
    CommonBase,
    ScriptBase,
    TestBase
} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {
    StdCheatsSafe,
    StdCheats
} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import { Script } from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { BetterScript } from "contracts/script/BetterScript.sol";
import { ScriptBase_Crane_Factories } from "contracts/script/ScriptBase_Crane_Factories.sol";
import { Script_WETH } from "contracts/script/protocols/Script_WETH.sol";
import { BetterTest } from "contracts/test/BetterTest.sol";
import { Test_Crane } from "contracts/test/Test_Crane.sol";
import { ScriptBase_Crane_ERC20 } from "contracts/script/ScriptBase_Crane_ERC20.sol";
import { ScriptBase_Crane_ERC4626 } from "contracts/script/ScriptBase_Crane_ERC4626.sol";

contract TestBase_WETH
is
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
    
    Test,
    BetterTest,
    Test_Crane
{

    function run() public virtual
    override(
        ScriptBase_Crane_Factories,
        ScriptBase_Crane_ERC20,
        ScriptBase_Crane_ERC4626,
        Script_WETH,
        Test_Crane
    ) {
        super.run();
    }
}