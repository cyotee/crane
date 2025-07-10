// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {
    AddressSet,
    AddressSetRepo
} from "../../utils/collections/sets/AddressSetRepo.sol";
import {
    Bytes4Set,
    Bytes4SetRepo
} from "../../utils/collections/sets/Bytes4SetRepo.sol";
import { Test_Crane } from "../../test/Test_Crane.sol";
import { IFacet } from "../../interfaces/IFacet.sol";
import { IDiamondLoupe } from "../../interfaces/IDiamondLoupe.sol";
import { Behavior_IDiamondLoupe } from "../../test/behaviors/Behavior_IDiamondLoupe.sol";

abstract contract TestBase_IDiamondLoupe is Test_Crane, Behavior_IDiamondLoupe {

    function setUp() public virtual override {
        IDiamondLoupe.Facet[] memory expectedFacets_ = expected_IDiamondLoupe_facets();
        expect_IDiamondLoupe(
            diamondLoupe_subject(),
            expectedFacets_
        );
        // expect_IDiamondLoupe_facets(
        //     diamondLoupe_subject(),
        //     expectedFacets_
        // );
        // for ( uint256 facetsCursor = 0; facetsCursor < expectedFacets_.length; facetsCursor++ ) {
        //     for ( uint256 funcsCursor = 0; funcsCursor < expectedFacets_[facetsCursor].functionSelectors.length; funcsCursor++ ) {
        //         expect_IDiamondLoupe_facetAddress(
        //             diamondLoupe_subject(),
        //             expectedFacets_[facetsCursor].functionSelectors[funcsCursor],
        //             expectedFacets_[facetsCursor].facetAddress
        //         );
        //     }
        //     expect_IDiamondLoupe_facetAddresses(
        //         diamondLoupe_subject(),
        //         expectedFacets_[facetsCursor].facetAddress
        //     );
        //     expect_IDiamondLoupe_facetFunctionSelectors(
        //         diamondLoupe_subject(),
        //         expectedFacets_[facetsCursor].facetAddress,
        //         expectedFacets_[facetsCursor].functionSelectors
        //     );
        // }
    }

    function diamondLoupe_subject() public virtual returns(IDiamondLoupe subject_);

    function expected_IDiamondLoupe_facets() public virtual returns(IDiamondLoupe.Facet[] memory expectedFacets_);

    function test_IDiamondLoupe_facets() public virtual {
        hasValid_IDiamondLoupe_facets(diamondLoupe_subject());
    }

    function test_IDiamondLoupe_facetAddresses() public virtual {
        hasValid_IDiamondLoupe_facetAddresses(diamondLoupe_subject());
    }

    function test_IDiamondLoupe_facetAddress() public virtual {
        hasValid_IDiamondLoupe_facetAddress(diamondLoupe_subject());
    }

    function test_IDiamondLoupe_facetFunctionSelectors() public virtual {

        IDiamondLoupe.Facet[] memory expectedFacets_ = expected_IDiamondLoupe_facets();
        for ( uint256 facetsCursor = 0; facetsCursor < expectedFacets_.length; facetsCursor++ ) {
            hasValid_IDiamondLoupe_facetFunctionSelectors(
                diamondLoupe_subject(),
                expectedFacets_[facetsCursor].facetAddress
            );
        }
    }

}