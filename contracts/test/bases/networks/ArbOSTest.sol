// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { CraneScript } from "../../../script/CraneScript.sol";
import { ArbOSScript } from "../../../script/networks/ArbOSScript.sol";
import { CraneTest } from "../../CraneTest.sol";

contract ArbOSTest
is
CraneTest,
ArbOSScript
{

    function initialize() public virtual
    override(
        CraneTest,
        ArbOSScript
    ) {
        CraneTest.initialize();
    }

    // function owner()
    // public view virtual
    // override(
    //     CraneTest,
    //     ArbOSScript
    // ) returns(address) {
    //     // return address(this);
    //     // return ownerWallet().addr;
    //     revert("ArbOSScript: Fix owner().");
    // }

    function setUp() public virtual
    override(
        CraneTest,
        CraneScript
    ) {
        // initialize();
        CraneTest.setUp();
        // initPrecompiles_ArbOS();
    }

}