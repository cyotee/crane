// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Test} from "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC8109Introspection} from "@crane/contracts/introspection/ERC8109/IERC8109Introspection.sol";
import {Behavior_IERC8109Introspection} from "@crane/contracts/introspection/ERC8109/Behavior_IERC8109Introspection.sol";

/**
 * @title TestBase_IERC8109Introspection
 * @notice Abstract test base for testing IERC8109Introspection behavior.
 * @dev Inheritors must implement:
 *      - `erc8109_subject()` - returns the subject under test
 *      - `expected_IERC8109Introspection_pairs()` - returns expected function-facet pairs
 */
abstract contract TestBase_IERC8109Introspection is Test {
    IERC8109Introspection internal erc8109TestSubject;

    function setUp() public virtual {
        erc8109TestSubject = erc8109_subject();
        Behavior_IERC8109Introspection.expect_IERC8109Introspection(
            erc8109TestSubject,
            expected_IERC8109Introspection_pairs()
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                            Virtual Functions                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Returns the subject under test.
    /// @dev Must be implemented by inheriting test contract.
    /// forge-lint: disable-next-line(mixed-case-function)
    function erc8109_subject() public virtual returns (IERC8109Introspection subject_);

    /// @notice Returns the expected function-facet pairs.
    /// @dev Must be implemented by inheriting test contract.
    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_IERC8109Introspection_pairs()
        public
        virtual
        returns (IERC8109Introspection.FunctionFacetPair[] memory expectedPairs_);

    /* -------------------------------------------------------------------------- */
    /*                               Test Functions                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Tests that facetAddress returns correct facet for each expected selector.
    /// forge-lint: disable-next-line(mixed-case-function)
    function test_IERC8109Introspection_facetAddress() public virtual {
        assertTrue(
            Behavior_IERC8109Introspection.hasValid_IERC8109Introspection_facetAddress(erc8109TestSubject),
            "facetAddress should return correct facet for all expected selectors"
        );
    }

    /// @notice Tests that functionFacetPairs returns all expected pairs.
    /// forge-lint: disable-next-line(mixed-case-function)
    function test_IERC8109Introspection_functionFacetPairs() public virtual {
        assertTrue(
            Behavior_IERC8109Introspection.hasValid_IERC8109Introspection_functionFacetPairs(erc8109TestSubject),
            "functionFacetPairs should return all expected pairs"
        );
    }

    /// @notice Tests the full IERC8109Introspection interface.
    /// forge-lint: disable-next-line(mixed-case-function)
    function test_IERC8109Introspection() public virtual {
        assertTrue(
            Behavior_IERC8109Introspection.hasValid_IERC8109Introspection(erc8109TestSubject),
            "IERC8109Introspection should be fully valid"
        );
    }

    /// @notice Tests that facetAddress returns address(0) for unknown selectors.
    /// forge-lint: disable-next-line(mixed-case-function)
    function test_IERC8109Introspection_facetAddress_unknownSelector() public virtual {
        bytes4 unknownSelector = bytes4(0xdeadbeef);
        address result = erc8109TestSubject.facetAddress(unknownSelector);
        assertEq(result, address(0), "facetAddress should return address(0) for unknown selector");
    }
}
