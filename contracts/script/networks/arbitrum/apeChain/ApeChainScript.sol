// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    ArbOSScript
} from "../ArbOSScript.sol";

contract ApeChainScript
is
ArbOSScript
{

    function initialize() public virtual
    override(
        ArbOSScript
    ) {
    }
    
}