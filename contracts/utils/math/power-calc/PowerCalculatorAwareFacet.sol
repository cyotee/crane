// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPowerCalculatorAware} from "./IPowerCalculatorAware.sol";

import {PowerCalculatorAwareTarget} from "./PowerCalculatorAwareTarget.sol";

import {IFacet} from "../../../factories/create2/callback/diamondPkg/IFacet.sol";

contract PowerCalculatorAwareFacet
is
PowerCalculatorAwareTarget,
IFacet
{

    function facetInterfaces()
    public pure virtual
    returns(bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);

        interfaces[0] = type(IPowerCalculatorAware).interfaceId;
        
    }

    function facetFuncs()
    public pure virtual
    returns(bytes4[] memory funcs) {
        funcs = new bytes4[](1);

        funcs[0] = IPowerCalculatorAware.powerCalculator.selector;

    }

}