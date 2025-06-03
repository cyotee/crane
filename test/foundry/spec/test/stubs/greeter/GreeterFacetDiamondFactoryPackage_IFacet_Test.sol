// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { CraneTest } from "../../../../../../contracts/test/CraneTest.sol";
import { IFacet } from "../../../../../../contracts/interfaces/IFacet.sol";
import { IGreeter } from "../../../../../../contracts/test/stubs/greeter/IGreeter.sol";
import { GreeterFacetDiamondFactoryPackage } from "../../../../../../contracts/test/stubs/greeter/GreeterFacetDiamondFactoryPackage.sol";

contract GreeterFacetDiamondFactoryPackage_IFacet_Test is CraneTest {

    function test_IFacet_facetInterfaces_GreeterFacetDiamondFactoryPackage() public {
        bytes4[] memory expectedInterfaces = new bytes4[](1);
        expectedInterfaces[0] = type(IGreeter).interfaceId;

        expect_IFacet_facetInterfaces(
            IFacet(address(greeterFacetDFPkg())),
            expectedInterfaces
        );

        assertTrue(
            hasValid_IFacet_facetInterfaces(
                IFacet(address(greeterFacetDFPkg()))
            ),
            "GreeterFacetDiamondFactoryPackage should expose correct interface IDs"
        );
    }

    function test_IFacet_facetFuncs_GreeterFacetDiamondFactoryPackage() public {
        bytes4[] memory expectedFuncs = new bytes4[](2);
        expectedFuncs[0] = IGreeter.getMessage.selector;
        expectedFuncs[1] = IGreeter.setMessage.selector;

        expect_IFacet_facetFuncs(
            IFacet(address(greeterFacetDFPkg())),
            expectedFuncs
        );

        assertTrue(
            hasValid_IFacet_facetFuncs(
                IFacet(address(greeterFacetDFPkg()))
            ),
            "GreeterFacetDiamondFactoryPackage should expose correct function selectors"
        );
    }
} 