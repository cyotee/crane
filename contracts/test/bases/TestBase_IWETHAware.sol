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

import { IWETHAware } from "../../interfaces/IWETHAware.sol";
import { BetterScript } from "../../script/BetterScript.sol";
import { ScriptBase_Crane_Factories } from "../../script/ScriptBase_Crane_Factories.sol";
import { Script_WETH } from "../../script/protocols/Script_WETH.sol";
import { TestBase_WETH } from "../../test/bases/protocols/TestBase_WETH.sol";

abstract contract TestBase_IWETHAware
is
    CommonBase,
    ScriptBase,

    TestBase,
    StdAssertions,

    StdChains,
    StdCheatsSafe,
    StdCheats,

    StdUtils,

    Script,
    BetterScript,

    ScriptBase_Crane_Factories,
    // ScriptBase_Crane_ERC20,
    // ScriptBase_Crane_ERC4626,

    Script_WETH,
    TestBase_WETH
{

    function run() public
    override(
        ScriptBase_Crane_Factories,
        Script_WETH,
        TestBase_WETH
    ) {
        // super.run();
    }

    function wethAwareTestSubject() public virtual returns (IWETHAware);

    function test_IWETHAware() public {
        assertEq(
            address(wethAwareTestSubject().weth()),
            address(weth9())
        );
    }

}