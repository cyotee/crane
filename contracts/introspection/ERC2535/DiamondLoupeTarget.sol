// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";

// tag::DiamondLoupeTarget[]
/**
 * @title DiamondLoupeTarget - Exposes IDiamondLoupe functions.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Provides diamond loupe (introspection) view functions.
 * @dev Follows Facet-Target-Repo pattern. Delegates entirely to ERC2535Repo for storage-backed loupe queries.
 *      Inherited by DiamondLoupeFacet (which adds IFacet metadata declarations).
 */
contract DiamondLoupeTarget is IDiamondLoupe {
    /* -------------------------------------------------------------------------- */
    /*                                IDiamondLoupe                               */
    /* -------------------------------------------------------------------------- */

    // tag::facets()[]
    /**
     * @inheritdoc IDiamondLoupe
     * @notice Gets all facet addresses and their four byte function selectors.
     * @return facets_ Array of Facet structs (each with facetAddress and its functionSelectors).
     * @dev Delegates to ERC2535Repo._facets().
     */
    function facets() external view returns (Facet[] memory facets_) {
        facets_ = ERC2535Repo._facets();
    }
    // end::facets()[]

    // tag::facetFunctionSelectors(address)[]
    /**
     * @inheritdoc IDiamondLoupe
     * @notice Gets all the function selectors supported by a specific facet.
     * @param _facet The facet address.
     * @return facetFunctionSelectors_ The function selectors registered for the facet.
     * @dev Delegates to ERC2535Repo._facetFunctionSelectors(_facet).
     */
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {
        facetFunctionSelectors_ = ERC2535Repo._facetFunctionSelectors(_facet);
    }
    // end::facetFunctionSelectors(address)[]

    // tag::facetAddresses()[]
    /**
     * @inheritdoc IDiamondLoupe
     * @notice Get all the facet addresses used by a diamond.
     * @return facetAddresses_ All facet addresses currently registered in the diamond.
     * @dev Delegates to ERC2535Repo._facetAddresses().
     * @custom:selector 0x52ef6b2c
     * @custom:signature facetAddresses()
     */
    function facetAddresses() external view returns (address[] memory facetAddresses_) {
        facetAddresses_ = ERC2535Repo._facetAddresses();
    }
    // end::facetAddresses()[]

    // tag::facetAddress(bytes4)[]
    /**
     * @inheritdoc IDiamondLoupe
     * @notice Gets the facet that supports the given selector.
     * @dev If facet is not found return address(0).
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address supporting it, or address(0).
     * @dev Delegates to ERC2535Repo._facetAddress(_functionSelector).
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {
        facetAddress_ = ERC2535Repo._facetAddress(_functionSelector);
    }
    // end::facetAddress(bytes4)[]
}
// end::DiamondLoupeTarget[]
