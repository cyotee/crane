// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import { Test_Crane } from "contracts/crane/test/Test_Crane.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IOwnable} from "contracts/crane/interfaces/IOwnable.sol";
// import { OwnableFacet } from "contracts/crane/access/ownable/OwnableFacet.sol";
import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";

contract OwnableFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return ownableFacet();
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IOwnable).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](5);
        controlFuncs[0] = IOwnable.owner.selector;
        controlFuncs[1] = IOwnable.proposedOwner.selector;
        controlFuncs[2] = IOwnable.transferOwnership.selector;
        controlFuncs[3] = IOwnable.acceptOwnership.selector;
        controlFuncs[4] = IOwnable.renounceOwnership.selector;
    }

    // function test_IFacet_facetInterfaces_OwnableFacet() public {
    //     bytes4[] memory expectedInterfaces = new bytes4[](1);
    //     expectedInterfaces[0] = type(IOwnable).interfaceId;

    //     expect_IFacet_facetInterfaces(
    //         IFacet(address(ownableFacet())),
    //         expectedInterfaces
    //     );

    //     assertTrue(
    //         hasValid_IFacet_facetInterfaces(
    //             IFacet(address(ownableFacet()))
    //         ),
    //         "OwnableFacet should expose correct interface IDs"
    //     );
    // }

    // function test_IFacet_facetFuncs_OwnableFacet() public {
    //     bytes4[] memory expectedFuncs = new bytes4[](5);
    //     expectedFuncs[0] = IOwnable.owner.selector;
    //     expectedFuncs[1] = IOwnable.proposedOwner.selector;
    //     expectedFuncs[2] = IOwnable.transferOwnership.selector;
    //     expectedFuncs[3] = IOwnable.acceptOwnership.selector;
    //     expectedFuncs[4] = IOwnable.renounceOwnership.selector;

    //     expect_IFacet_facetFuncs(
    //         IFacet(address(ownableFacet())),
    //         expectedFuncs
    //     );

    //     assertTrue(
    //         hasValid_IFacet_facetFuncs(
    //             IFacet(address(ownableFacet()))
    //         ),
    //         "OwnableFacet should expose correct function selectors"
    //     );
    // }
}
