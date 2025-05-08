// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {CraneTest} from "contracts/test/CraneTest.sol";
import {IFacet} from "../../../../../contracts/factories/create2/callback/diamondPkg/IFacet.sol";
import {IOperable} from "../../../../../contracts/access/operable/IOperable.sol";
import {OperableFacet} from "../../../../../contracts/access/operable/OperableFacet.sol";

contract OperableFacet_IFacet_Test is CraneTest {
    function test_IFacet_facetInterfaces_OperableFacet() public {
        bytes4[] memory expectedInterfaces = new bytes4[](1);
        expectedInterfaces[0] = type(IOperable).interfaceId;

        expect_IFacet_facetInterfaces(
            IFacet(address(operableFacet())),
            expectedInterfaces
        );

        assertTrue(
            hasValid_IFacet_facetInterfaces(
                IFacet(address(operableFacet()))
            ),
            "OperableFacet should expose correct interface IDs"
        );
    }

    function test_IFacet_facetFuncs_OperableFacet() public {
        bytes4[] memory expectedFuncs = new bytes4[](4);
        expectedFuncs[0] = IOperable.isOperator.selector;
        expectedFuncs[1] = IOperable.isOperatorFor.selector;
        expectedFuncs[2] = IOperable.setOperator.selector;
        expectedFuncs[3] = IOperable.setOperatorFor.selector;

        expect_IFacet_facetFuncs(
            IFacet(address(operableFacet())),
            expectedFuncs
        );

        assertTrue(
            hasValid_IFacet_facetFuncs(
                IFacet(address(operableFacet()))
            ),
            "OperableFacet should expose correct function selectors"
        );
    }
} 