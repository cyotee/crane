// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BaseTest} from "@crane/contracts/protocols/dexes/balancer/v3/test/utils/BaseTest.sol";

abstract contract TestBase_BalancerV3 is BaseTest {

    function setUp() public virtual
    override(
        BaseTest
    ) {
        BaseTest.setUp();
    }

}
