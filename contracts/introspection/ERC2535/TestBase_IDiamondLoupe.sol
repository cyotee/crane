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

// tag::TestBase_IDiamondLoupe[]
/**
 * @title TestBase_IDiamondLoupe
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Abstract Behavior TestBase for declaration and loupe config tests of IDiamondLoupe subjects (diamonds).
 * @dev LR-7 compliant: requires full realistic non-zero subject (via CraneTest/TestBase+InitDevService+real DFPkg facets, never 0); uses exact assertTrue; mandates Behavior_IDiamondLoupe.expect_ + hasValid_* / areValid_*; includes facet decl tests for loupe surface.
 *      LR-1: rich NatSpec + exact // tag:: / end:: on contract + all public (TestBase_IDiamondLoupe[], setUp[], diamondLoupe_subject()[], expected_..., test_*[], erc165Funcs[], diamondLoupeFuncs[]).
 *      Modeled on gold: TestBase_IERC165.sol + TestBase_IFacet.sol + Behavior_IDiamondLoupe (just closed), AGENTS.md, PRD LR-1/LR-7.
 *      Inheritors perform full init then rely on or call this setUp. Uses Behavior for facets config.
 */
abstract contract TestBase_IDiamondLoupe is Test {
    // tag::diamondLoupeTestSubject[]
    /// @notice The IDiamondLoupe subject under test (diamond). Populated via virtual after full non-0 init.
    IDiamondLoupe _diamondLoupeSubject;
    // end::diamondLoupeTestSubject[]

    // tag::setUp[]
    /**
     * @notice Virtual setUp that obtains real subject and primes Behavior_IDiamondLoupe expectations.
     * @dev LR-7: asserts non-zero subject (enforces full init via CraneTest/TestBase chaining + InitDev + real DFPkg before); registers via expect_ for hasValid_ validation of loupe surface.
     */
    function setUp() public virtual {
        _diamondLoupeSubject = diamondLoupe_subject();
        // LR-7: full realistic non-0 init required (no address(0) subjects)
        assertTrue(
            address(_diamondLoupeSubject) != address(0),
            "LR-7: _diamondLoupeSubject must be real non-zero (CraneTest/TestBase + InitDev + DFPkg deploy)"
        );
        // IDiamondLoupe.Facet[] memory expectedFacets_ = expected_IDiamondLoupe_facets();
        Behavior_IDiamondLoupe.expect_IDiamondLoupe(_diamondLoupeSubject, expected_IDiamondLoupe_facets());
    }
    // end::setUp[]

    // tag::diamondLoupe_subject()[]
    /// @notice Virtual hook returning the test subject (IDiamondLoupe). Must yield non-zero after full init.
    /// @return subject_ The initialized diamond loupe subject.
    /// forge-lint: disable-next-line(mixed-case-function)
    function diamondLoupe_subject() public virtual returns (IDiamondLoupe subject_);
    // end::diamondLoupe_subject()[]

    // tag::expected_IDiamondLoupe_facets()[]
    /// @notice Virtual hook for expected Facet[] config (address + its selectors per loupe decl test).
    /// @return expectedFacets_ The control facets data for validation.
    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_IDiamondLoupe_facets() public virtual returns (IDiamondLoupe.Facet[] memory expectedFacets_);
    // end::expected_IDiamondLoupe_facets()[]

    // tag::test_IDiamondLoupe_facets()[]
    /**
     * @notice Tests facets() decl via Behavior (exact config match).
     * @dev LR-7: uses Behavior hasValid; upgraded to assertTrue with msg for exactness.
     */
    function test_IDiamondLoupe_facets() public virtual {
        assertTrue(
            Behavior_IDiamondLoupe.hasValid_IDiamondLoupe_facets(_diamondLoupeSubject),
            "IDiamondLoupe facets config must be valid via Behavior_IDiamondLoupe.hasValid_IDiamondLoupe_facets"
        );
    }
    // end::test_IDiamondLoupe_facets()[]

    // tag::test_IDiamondLoupe_facetAddresses()[]
    function test_IDiamondLoupe_facetAddresses() public virtual {
        assertTrue(
            Behavior_IDiamondLoupe.hasValid_IDiamondLoupe_facetAddresses(_diamondLoupeSubject),
            "IDiamondLoupe facetAddresses must be valid via Behavior_IDiamondLoupe"
        );
    }
    // end::test_IDiamondLoupe_facetAddresses()[]

    // tag::test_IDiamondLoupe_facetAddress()[]
    function test_IDiamondLoupe_facetAddress() public virtual {
        assertTrue(
            Behavior_IDiamondLoupe.hasValid_IDiamondLoupe_facetAddress(_diamondLoupeSubject),
            "IDiamondLoupe facetAddress mappings must be valid via Behavior_IDiamondLoupe"
        );
    }
    // end::test_IDiamondLoupe_facetAddress()[]

    // tag::test_IDiamondLoupe_facetFunctionSelectors()[]
    function test_IDiamondLoupe_facetFunctionSelectors() public virtual {
        IDiamondLoupe.Facet[] memory expectedFacets_ = expected_IDiamondLoupe_facets();
        for (uint256 facetsCursor = 0; facetsCursor < expectedFacets_.length; facetsCursor++) {
            assertTrue(
                Behavior_IDiamondLoupe.hasValid_IDiamondLoupe_facetFunctionSelectors(
                    _diamondLoupeSubject, expectedFacets_[facetsCursor].facetAddress
                ),
                "IDiamondLoupe facetFunctionSelectors must match for each facet via Behavior"
            );
        }
    }
    // end::test_IDiamondLoupe_facetFunctionSelectors()[]

    // tag::erc165Funcs()[]
    function erc165Funcs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);

        funcs[0] = IERC165.supportsInterface.selector;
    }
    // end::erc165Funcs()[]

    // tag::diamondLoupeFuncs()[]
    function diamondLoupeFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](4);

        funcs[0] = IDiamondLoupe.facets.selector;
        funcs[1] = IDiamondLoupe.facetAddresses.selector;
        funcs[2] = IDiamondLoupe.facetAddress.selector;
        funcs[3] = IDiamondLoupe.facetFunctionSelectors.selector;
    }
    // end::diamondLoupeFuncs()[]
}
// end::TestBase_IDiamondLoupe[]
