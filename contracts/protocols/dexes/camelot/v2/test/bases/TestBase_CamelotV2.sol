// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ICamelotFactory} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotV2Router} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {CamelotFactory} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol";
import {CamelotRouter} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotRouter.sol";
import {TestBase_Weth9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/TestBase_Weth9.sol";

abstract contract TestBase_CamelotV2 is TestBase_Weth9 {

    address camelotV2FeeToSetter;

    ICamelotFactory internal camelotV2Factory;
    ICamelotV2Router internal camelotV2Router;

    function setUp() public virtual override {
        camelotV2FeeToSetter = makeAddr("camelotV2FeeToSetter");
        TestBase_Weth9.setUp();
        if (address(camelotV2Factory) == address(0)) {
            camelotV2Factory = new CamelotFactory(camelotV2FeeToSetter);
        }

        if (address(camelotV2Router) == address(0)) {
            camelotV2Router = new CamelotRouter(
                address(camelotV2Factory),
                address(weth)
            );
        }
    }
}