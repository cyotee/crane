// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { CraneTest } from "../../../../../contracts/test/CraneTest.sol";
import { IFacet } from "../../../../../contracts/interfaces/IFacet.sol";
import { IOwnable } from "../../../../../contracts/interfaces/IOwnable.sol";
import { OwnableFacet } from "../../../../../contracts/access/ownable/OwnableFacet.sol";

contract OwnableFacet_IFacet_Test is CraneTest {
    
    function setUp() public override {
        // Initialize test state
    }

    function test_IFacet_facetInterfaces_OwnableFacet() public {
        bytes4[] memory expectedInterfaces = new bytes4[](1);
        expectedInterfaces[0] = type(IOwnable).interfaceId;
        
        expect_IFacet_facetInterfaces(
            IFacet(address(ownableFacet())),
            expectedInterfaces
        );

        assertTrue(
            hasValid_IFacet_facetInterfaces(
                IFacet(address(ownableFacet()))
            ),
            "OwnableFacet should expose correct interface IDs"
        );
    }

    function test_IFacet_facetFuncs_OwnableFacet() public {
        bytes4[] memory expectedFuncs = new bytes4[](5);
        expectedFuncs[0] = IOwnable.owner.selector;
        expectedFuncs[1] = IOwnable.proposedOwner.selector;
        expectedFuncs[2] = IOwnable.transferOwnership.selector;
        expectedFuncs[3] = IOwnable.acceptOwnership.selector;
        expectedFuncs[4] = IOwnable.renounceOwnership.selector;

        expect_IFacet_facetFuncs(
            IFacet(address(ownableFacet())),
            expectedFuncs
        );

        assertTrue(
            hasValid_IFacet_facetFuncs(
                IFacet(address(ownableFacet()))
            ),
            "OwnableFacet should expose correct function selectors"
        );
    }
} 