// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {TestBase_IFacet} from "@crane/contracts/factories/diamondPkg/TestBase_IFacet.sol";
import {Behavior_IFacet} from "@crane/contracts/factories/diamondPkg/Behavior_IFacet.sol";
import {ERC20Facet} from "@crane/contracts/tokens/ERC20/ERC20Facet.sol";

// tag::ERC20Facet_IFacet_Test[]
/**
 * @title ERC20Facet_IFacet_Test
 * @notice LR-7 / LR-1 declaration + behavior test for ERC20Facet.
 * @dev Inherits TestBase_IFacet (which uses Behavior_IFacet). Provides control values matching
 *      the facet's facetInterfaces/facetFuncs (IERC20 + IERC20Metadata + xor, plus 9 ERC20 funcs).
 *      Addresses LR-7: full initialization (explicit setUp + labels, no lazy/address(0)), exact asserts,
 *      use of Behavior libs (areValid via base + explicit expect/hasValid/areValid), facet declaration tests,
 *      proper TestBase usage, NatSpec on test code.
 *      References ONLY central values for IFacet (from CENTRALLY_COMPUTED_NATSPEC_VALUES.md).
 * @custom:signature ERC20Facet_IFacet_Test
 */
contract ERC20Facet_IFacet_Test is TestBase_IFacet {
    function setUp() public virtual override {
        // LR-7 full initialization: explicit deployment of real subject (no address(0) facets),
        // label for traces, call super which sets testFacet via facetTestInstance().
        // No pkgs here (pure facet decl test) but mirrors pattern from AGENTS.md crane-testing + closed LR-7 tests.
        TestBase_IFacet.setUp();
        vm.label(address(testFacet), "ERC20Facet");

        // LR-7: upfront Behavior expect on the initialized subject (per crane-testing + diamond/operable LR-7 examples)
        Behavior_IFacet.expect_IFacet_facetName(testFacet, controlFacetName());
        Behavior_IFacet.expect_IFacet_facetInterfaces(testFacet, controlFacetInterfaces());
        Behavior_IFacet.expect_IFacet_facetFuncs(testFacet, controlFacetFuncs());
    }

    // tag::facetTestInstance()[]
    /// @inheritdoc TestBase_IFacet
    function facetTestInstance() public virtual override returns (IFacet) {
        return new ERC20Facet();
    }

    // end::facetTestInstance()[]

    // tag::controlFacetName()[]
    /// @inheritdoc TestBase_IFacet
    function controlFacetName() public view virtual override returns (string memory facetName) {
        return type(ERC20Facet).name;
    }

    // end::controlFacetName()[]

    // tag::controlFacetInterfaces()[]
    /**
     * @notice Returns the expected interface IDs that the facet should support (IERC20, IERC20Metadata, and their XOR per ERC20Facet impl)
     * @dev Implemented to match ERC20Facet.facetInterfaces() exactly. Uses type().interfaceId (authoritative per PRD/LR-1).
     * @return controlInterfaces Array of 3 interface IDs
     * @custom:signature controlFacetInterfaces()
     * @custom:selector 0x890539e3
     */
    function controlFacetInterfaces() public view virtual override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](3);

        controlInterfaces[0] = type(IERC20).interfaceId;
        controlInterfaces[1] = type(IERC20Metadata).interfaceId;
        controlInterfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
    }

    // end::controlFacetInterfaces()[]

    // tag::controlFacetFuncs()[]
    /**
     * @notice Returns the expected function selectors that the facet should expose (9 ERC20+Metadata)
     * @dev Implemented to match ERC20Facet.facetFuncs() exactly.
     * @return controlFuncs Array of 9 selectors
     * @custom:signature controlFacetFuncs()
     * @custom:selector 0x5a5bc0c3
     */
    function controlFacetFuncs() public view virtual override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](9);

        controlFuncs[0] = IERC20Metadata.name.selector;
        controlFuncs[1] = IERC20Metadata.symbol.selector;
        controlFuncs[2] = IERC20Metadata.decimals.selector;
        controlFuncs[3] = IERC20.totalSupply.selector;
        controlFuncs[4] = IERC20.balanceOf.selector;
        controlFuncs[5] = IERC20.allowance.selector;
        controlFuncs[6] = IERC20.approve.selector;
        controlFuncs[7] = IERC20.transfer.selector;
        controlFuncs[8] = IERC20.transferFrom.selector;
    }

    // end::controlFacetFuncs()[]

    // tag::test_LR7_ERC20Facet_declaration_viaBehavior()[]
    /**
     * @notice LR-7 dedicated facet declaration test using Behavior_IFacet directly (expect + hasValid + areValid + consistency).
     * @dev Demonstrates full Behavior usage + exact value assertions for name/interfaces/funcs/metadata.
     *      Full init subject from setUp. References central IFacet selectors (0x5b6f4d01 etc).
     * @custom:signature test_LR7_ERC20Facet_declaration_viaBehavior()
     * @custom:selector 0x6ecb0193
     */
    function test_LR7_ERC20Facet_declaration_viaBehavior() public {
        IFacet facet = testFacet; // from full init setUp (expects already recorded in setUp)

        // Validate via hasValid (using setUp expects) + areValid (exact)
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetName(facet), "facetName via Behavior hasValid");
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetInterfaces(facet), "facetInterfaces via Behavior hasValid");
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetFuncs(facet), "facetFuncs via Behavior hasValid");

        // Metadata consistency exact
        assertTrue(
            Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(facet),
            "facetMetadata consistency must match individual getters exactly"
        );

        // Also direct areValid with subject (exact order expected/actual per examples + closed LR-7 tests)
        assertTrue(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(facet, controlFacetInterfaces(), facet.facetInterfaces())
        );
        assertTrue(Behavior_IFacet.areValid_IFacet_facetFuncs(facet, controlFacetFuncs(), facet.facetFuncs()));
    }
    // end::test_LR7_ERC20Facet_declaration_viaBehavior()[]
}
// end::ERC20Facet_IFacet_Test[]
