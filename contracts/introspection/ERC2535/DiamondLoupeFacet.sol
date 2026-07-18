// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {DiamondLoupeTarget} from "@crane/contracts/introspection/ERC2535/DiamondLoupeTarget.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// tag::DiamondLoupeFacet[]
/**
 * @title DiamondLoupeFacet - Reusable Diamond facet implementing IDiamondLoupe (diamond introspection/loupe) per Facet-Target-Repo.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Extends DiamondLoupeTarget for business logic (delegates to ERC2535Repo). Implements IFacet to declare
 *      supported interfaces and functions for use with Diamond loupes, DFPkgs, registries, and composition.
 *      The facet surface exposes IDiamondLoupe (facets, facetFunctionSelectors, facetAddresses, facetAddress) plus the IFacet declaration methods.
 * @custom:contractlistipfs
 */
contract DiamondLoupeFacet is DiamondLoupeTarget, IFacet {
    /* -------------------------------------------------------------------------- */
    /*                                   IFacet                                   */
    /* -------------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares a canonical nonunique name for the exposing facet.
     * @return name The name of the facet.
     * @custom:selector 0x5b6f4d01
     * @custom:signature facetName()
     */
    function facetName() public pure returns (string memory name) {
        return type(DiamondLoupeFacet).name;
    }

    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the interfaces implemented by the exposing facet for use in a composing proxy.
     * @return interfaces The interface IDs implemented by the facet.
     * @custom:selector 0x2ea80826
     * @custom:signature facetInterfaces()
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);

        interfaces[0] = type(IDiamondLoupe).interfaceId;
    }

    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the function selectors implemented by the exposing facet for use in a composing proxy.
     * @return funcs The function selectors implemented by the facet.
     * @custom:selector 0x574a4cff
     * @custom:signature facetFuncs()
     */
    function facetFuncs()
        public
        pure
        virtual
        returns (
            // override
            bytes4[] memory funcs
        )
    {
        funcs = new bytes4[](4);

        funcs[0] = IDiamondLoupe.facets.selector;
        funcs[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        funcs[2] = IDiamondLoupe.facetAddresses.selector;
        funcs[3] = IDiamondLoupe.facetAddress.selector;
    }

    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares comprehensive metadata about the exposing facet.
     * @dev Exposed to allow for single call retrieval of all facet metadata.
     * @return name The name of the facet.
     * @return interfaces The interface IDs implemented by the facet.
     * @return functions The function selectors implemented by the facet.
     * @custom:selector 0xf10d7a75
     * @custom:signature facetMetadata()
     */
    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    // end::facetMetadata()[]
}
// end::DiamondLoupeFacet[]
