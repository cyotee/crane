// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IOperableManager} from "contracts/crane/interfaces/IOperableManager.sol";
// import { OperableManagerFacet } from "contracts/crane/access/operable/OperableManagerFacet.sol";

contract OperableManagerFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(operableManagerFacet()));
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IOperableManager).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](2);
        controlFuncs[0] = IOperableManager.setOperator.selector;
        controlFuncs[1] = IOperableManager.setOperatorFor.selector;
    }
}
