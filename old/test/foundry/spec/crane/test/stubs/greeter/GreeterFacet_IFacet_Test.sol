// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IGreeter} from "contracts/crane/test/stubs/greeter/IGreeter.sol";
import {GreeterFacet} from "contracts/crane/test/stubs/greeter/GreeterFacet.sol";

/**
 * @title GreeterFacet_Example_Test
 * @notice Example demonstrating TestBase_IFacet usage with existing greeter facet
 */
contract GreeterFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(new GreeterFacet()));
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory) {
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = type(IGreeter).interfaceId;
        return interfaces;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory) {
        bytes4[] memory funcs = new bytes4[](2);
        funcs[0] = IGreeter.getMessage.selector;
        funcs[1] = IGreeter.setMessage.selector;
        return funcs;
    }
}
