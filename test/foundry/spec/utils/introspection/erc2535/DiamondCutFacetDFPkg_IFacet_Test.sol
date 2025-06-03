// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { CraneTest } from "../../../../../../contracts/test/CraneTest.sol";
import { IFacet } from "../../../../../../contracts/interfaces/IFacet.sol";
import { IOwnable } from "../../../../../../contracts/interfaces/IOwnable.sol";
import { IDiamondCut } from "../../../../../../contracts/interfaces/IDiamondCut.sol";
// import { DiamondCutFacetDFPkg } from "../../../../../contracts/introspection/erc2535/dfPkgs/DiamondCutFacetDFPkg.sol";

contract DiamondCutFacetDFPkg_IFacet_Test is CraneTest {

    function test_IFacet_facetInterfaces_DiamondCutFacetDFPkg() public {
        bytes4[] memory expectedInterfaces = new bytes4[](2);
        expectedInterfaces[0] = type(IOwnable).interfaceId;
        expectedInterfaces[1] = type(IDiamondCut).interfaceId;

        expect_IFacet_facetInterfaces(
            IFacet(address(diamondCutFacetDFPkg())),
            expectedInterfaces
        );

        assertTrue(
            hasValid_IFacet_facetInterfaces(
                IFacet(address(diamondCutFacetDFPkg()))
            ),
            "DiamondCutFacetDFPkg should expose correct interface IDs"
        );
    }

    function test_IFacet_facetFuncs_DiamondCutFacetDFPkg() public {
        bytes4[] memory expectedFuncs = new bytes4[](1);
        expectedFuncs[0] = IDiamondCut.diamondCut.selector;

        expect_IFacet_facetFuncs(
            IFacet(address(diamondCutFacetDFPkg())),
            expectedFuncs
        );

        assertTrue(
            hasValid_IFacet_facetFuncs(
                IFacet(address(diamondCutFacetDFPkg()))
            ),
            "DiamondCutFacetDFPkg should expose correct function selectors"
        );
    }
} 