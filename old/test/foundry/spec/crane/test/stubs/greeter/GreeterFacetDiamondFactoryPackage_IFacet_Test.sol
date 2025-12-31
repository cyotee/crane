// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import { Test_Crane } from "contracts/crane/test/Test_Crane.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IGreeter} from "contracts/crane/test/stubs/greeter/IGreeter.sol";
// import { GreeterFacetDiamondFactoryPackage } from "contracts/crane/test/stubs/greeter/GreeterFacetDiamondFactoryPackage.sol";
import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";

contract GreeterFacetDiamondFactoryPackage_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(greeterFacetDFPkg()));
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IGreeter).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](2);
        controlFuncs[0] = IGreeter.getMessage.selector;
        controlFuncs[1] = IGreeter.setMessage.selector;
    }

    // function test_IFacet_facetInterfaces_GreeterFacetDiamondFactoryPackage() public {
    //     bytes4[] memory expectedInterfaces = new bytes4[](1);
    //     expectedInterfaces[0] = type(IGreeter).interfaceId;

    //     expect_IFacet_facetInterfaces(
    //         IFacet(address(greeterFacetDFPkg())),
    //         expectedInterfaces
    //     );

    //     assertTrue(
    //         hasValid_IFacet_facetInterfaces(
    //             IFacet(address(greeterFacetDFPkg()))
    //         ),
    //         "GreeterFacetDiamondFactoryPackage should expose correct interface IDs"
    //     );
    // }

    // function test_IFacet_facetFuncs_GreeterFacetDiamondFactoryPackage() public {
    //     bytes4[] memory expectedFuncs = new bytes4[](2);
    //     expectedFuncs[0] = IGreeter.getMessage.selector;
    //     expectedFuncs[1] = IGreeter.setMessage.selector;

    //     expect_IFacet_facetFuncs(
    //         IFacet(address(greeterFacetDFPkg())),
    //         expectedFuncs
    //     );

    //     assertTrue(
    //         hasValid_IFacet_facetFuncs(
    //             IFacet(address(greeterFacetDFPkg()))
    //         ),
    //         "GreeterFacetDiamondFactoryPackage should expose correct function selectors"
    //     );
    // }
}
