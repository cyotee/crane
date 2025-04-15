// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { Test_Crane } from "../../../../../../contracts/test/Test_Crane.sol";
import { IFacet } from "../../../../../../contracts/interfaces/IFacet.sol";
import { IOwnable } from "../../../../../../contracts/interfaces/IOwnable.sol";
import { IDiamondCut } from "../../../../../../contracts/interfaces/IDiamondCut.sol";
// import { DiamondCutFacetDFPkg } from "../../../../../contracts/introspection/erc2535/dfPkgs/DiamondCutFacetDFPkg.sol";
import { TestBase_IFacet } from "../../../../../../contracts/test/bases/TestBase_IFacet.sol";

contract DiamondCutFacetDFPkg_IFacet_Test is TestBase_IFacet {

    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(diamondCutFacetDFPkg()));
    }

    function controlFacetInterfaces() 
    public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](2);
        controlInterfaces[0] = type(IOwnable).interfaceId;
        controlInterfaces[1] = type(IDiamondCut).interfaceId;
    }

    function controlFacetFuncs() 
    public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](1);
        controlFuncs[0] = IDiamondCut.diamondCut.selector;
    }

    // function test_IFacet_facetInterfaces_DiamondCutFacetDFPkg() public {
    //     bytes4[] memory expectedInterfaces = new bytes4[](2);
    //     expectedInterfaces[0] = type(IOwnable).interfaceId;
    //     expectedInterfaces[1] = type(IDiamondCut).interfaceId;

    //     expect_IFacet_facetInterfaces(
    //         IFacet(address(diamondCutFacetDFPkg())),
    //         expectedInterfaces
    //     );

    //     assertTrue(
    //         hasValid_IFacet_facetInterfaces(
    //             IFacet(address(diamondCutFacetDFPkg()))
    //         ),
    //         "DiamondCutFacetDFPkg should expose correct interface IDs"
    //     );
    // }

    // function test_IFacet_facetFuncs_DiamondCutFacetDFPkg() public {
    //     bytes4[] memory expectedFuncs = new bytes4[](1);
    //     expectedFuncs[0] = IDiamondCut.diamondCut.selector;

    //     expect_IFacet_facetFuncs(
    //         IFacet(address(diamondCutFacetDFPkg())),
    //         expectedFuncs
    //     );

    //     assertTrue(
    //         hasValid_IFacet_facetFuncs(
    //             IFacet(address(diamondCutFacetDFPkg()))
    //         ),
    //         "DiamondCutFacetDFPkg should expose correct function selectors"
    //     );
    // }
} 