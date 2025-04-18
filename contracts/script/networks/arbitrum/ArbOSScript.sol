// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    CraneScript
} from "../../CraneScript.sol";
import {
    ArbOSFixture
} from "../../../networks/arbitrum/fixtures/ArbOSFixture.sol";

contract ArbOSScript
is
CraneScript,
ArbOSFixture
{

    function initialize() public virtual
    override(
        CraneScript,
        ArbOSFixture
    ) {

    }

    // function owner()
    // public view virtual override returns(address) {
    //     // return address(this);
    //     // return ownerWallet().addr;
    //     revert("ArbOSScript: Fix owner().");
    // }

}