// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {
//     AddressSet
//     // AddressSetRepo
// } from "@crane/src/utils/collections/sets/AddressSetRepo.sol";
// import {Bytes4Set} from
// // Bytes4SetRepo
// "@crane/src/utils/collections/sets/Bytes4SetRepo.sol";
// import {Test_Crane} from "@crane/contracts/crane/test/Test_Crane.sol";
// import { IFacet } from "@crane/contracts/crane/interfaces/IFacet.sol";
import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {Behavior_IDiamondLoupe} from "@crane/contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol";

abstract contract TestBase_IDiamondLoupe is Test {
    IDiamondLoupe _diamondLoupeSubject;

    function setUp() public virtual {
        _diamondLoupeSubject = diamondLoupe_subject();
        // IDiamondLoupe.Facet[] memory expectedFacets_ = expected_IDiamondLoupe_facets();
        Behavior_IDiamondLoupe.expect_IDiamondLoupe(_diamondLoupeSubject, expected_IDiamondLoupe_facets());
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function diamondLoupe_subject() public virtual returns (IDiamondLoupe subject_);

    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_IDiamondLoupe_facets() public virtual returns (IDiamondLoupe.Facet[] memory expectedFacets_);

    function test_IDiamondLoupe_facets() public virtual {
        assert(Behavior_IDiamondLoupe.hasValid_IDiamondLoupe_facets(_diamondLoupeSubject));
    }

    function test_IDiamondLoupe_facetAddresses() public virtual {
        assertTrue(Behavior_IDiamondLoupe.hasValid_IDiamondLoupe_facetAddresses(_diamondLoupeSubject));
    }

    function test_IDiamondLoupe_facetAddress() public virtual {
        assertTrue(Behavior_IDiamondLoupe.hasValid_IDiamondLoupe_facetAddress(_diamondLoupeSubject));
    }

    function test_IDiamondLoupe_facetFunctionSelectors() public virtual {
        IDiamondLoupe.Facet[] memory expectedFacets_ = expected_IDiamondLoupe_facets();
        for (uint256 facetsCursor = 0; facetsCursor < expectedFacets_.length; facetsCursor++) {
            assertTrue(
                Behavior_IDiamondLoupe.hasValid_IDiamondLoupe_facetFunctionSelectors(
                    _diamondLoupeSubject, expectedFacets_[facetsCursor].facetAddress
                )
            );
        }
    }

    function erc165Funcs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);

        funcs[0] = IERC165.supportsInterface.selector;
    }

    function diamondLoupeFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](4);

        funcs[0] = IDiamondLoupe.facets.selector;
        funcs[1] = IDiamondLoupe.facetAddresses.selector;
        funcs[2] = IDiamondLoupe.facetAddress.selector;
        funcs[3] = IDiamondLoupe.facetFunctionSelectors.selector;
    }
}
