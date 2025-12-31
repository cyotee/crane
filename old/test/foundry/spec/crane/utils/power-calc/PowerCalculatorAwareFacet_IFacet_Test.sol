// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IPowerCalculatorAware} from "contracts/crane/interfaces/IPowerCalculatorAware.sol";
// import { PowerCalculatorAwareFacet } from "contracts/crane/utils/math/power-calc/PowerCalculatorAwareFacet.sol";

contract PowerCalculatorAwareFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(powerCalculatorAwareFacet()));
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IPowerCalculatorAware).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](1);
        controlFuncs[0] = IPowerCalculatorAware.powerCalculator.selector;
    }
}
