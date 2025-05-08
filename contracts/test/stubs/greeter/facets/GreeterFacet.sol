// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    IGreeter
} from "../interfaces/IGreeter.sol";
import {
    GreeterTarget
} from "../targets/GreeterTarget.sol";
import {
    IFacet
} from "../../../../factories/create2/callback/diamondPkg/IFacet.sol";

contract GreeterFacet
is
GreeterTarget,
IFacet
{

    function facetInterfaces()
    public view virtual
    returns(bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IGreeter).interfaceId;
    }

    function facetFuncs()
    public pure virtual
    returns(bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IGreeter.getMessage.selector;
        funcs[1] = IGreeter.setMessage.selector;
    }

}