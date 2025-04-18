// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPowerCalculatorAware} from "../interfaces/IPowerCalculatorAware.sol";

import {PowerCalculatorAwareTarget} from "../targets/PowerCalculatorAwareTarget.sol";

import {IFacet} from "../../../../factories/create2/callback/diamondPkg/interfaces/IFacet.sol";

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