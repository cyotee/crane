// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::IDiamondLoupe[]
/**
 * A loupe is a small magnifying glass used to look at diamonds.
 * These functions look at diamonds
 * @title IDiamondLoupe - Diamond Loupe interface (ERC2535) for inspecting facets and selectors on a Diamond.
 * @author Nick Mudge (@mudgen)
 * @notice A loupe is a small magnifying glass used to look at diamonds.
 *         These functions look at diamonds.
 * @dev Original TODO comments preserved exactly per requirements. Provides read-only inspection of the facets
 *      and supported function selectors installed on a Diamond proxy.
 * @custom:interfaceid 0x48e2b093
 */
// TODO Write NatSpec comments.
// TODO Complete unit testing for all functions.
// TODO Implement and test external versions of all functions.
interface IDiamondLoupe {
    /* -------------------------------------------------------------------------- */
    /*                                    Types                                   */
    /* -------------------------------------------------------------------------- */

    // tag::Facet[]
    /**
     * @notice Represents a facet address paired with the function selectors it implements.
     * @dev Used as return type from facets(). Mirrors the struct defined in the Diamond standard.
     */
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }
    // end::Facet[]

    /* -------------------------------------------------------------------------- */
    /*                                   Errors                                   */
    /* -------------------------------------------------------------------------- */

    // tag::FunctionAlreadyPresent(bytes4)[]
    error FunctionAlreadyPresent(bytes4 functionSelector);
    // end::FunctionAlreadyPresent(bytes4)[]

    // tag::FacetAlreadyPresent(address)[]
    error FacetAlreadyPresent(address facet);
    // end::FacetAlreadyPresent(address)[]

    // tag::FunctionNotPresent(bytes4)[]
    error FunctionNotPresent(bytes4 functionSelector);
    // end::FunctionNotPresent(bytes4)[]

    // tag::FacetNotPresent(address)[]
    error FacetNotPresent(address facet);
    // end::FacetNotPresent(address)[]

    // tag::SelectorFacetMismatch(bytes4-address-address)[]
    /// @notice Thrown when attempting to remove a selector that belongs to a different facet
    error SelectorFacetMismatch(bytes4 functionSelector, address expectedFacet, address actualFacet);
    // end::SelectorFacetMismatch(bytes4-address-address)[]

    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::facets()[]
    /**
     * @notice Gets all facet addresses and their four byte function selectors.
     * @return facets_ Facet
     * @custom:signature facets()
     * @custom:selector 0x7a0ed627
     */
    function facets() external view returns (Facet[] memory facets_);
    // end::facets()[]

    // tag::facetFunctionSelectors(address)[]
    /**
     * @notice Gets all the function selectors supported by a specific facet.
     * @param _facet The facet address.
     * @return facetFunctionSelectors_
     * @custom:signature facetFunctionSelectors(address)
     * @custom:selector 0xadfca15e
     */
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);
    // end::facetFunctionSelectors(address)[]

    // tag::facetAddresses()[]
    /**
     * @notice Get all the facet addresses used by a diamond.
     * @return facetAddresses_
     * @custom:signature facetAddresses()
     * @custom:selector 0x52ef6b2c
     */
    function facetAddresses() external view returns (address[] memory facetAddresses_);
    // end::facetAddresses()[]

    // tag::facetAddress(bytes4)[]
    /**
     * @notice Gets the facet that supports the given selector.
     * @dev If facet is not found return address(0).
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address.
     * @custom:signature facetAddress(bytes4)
     * @custom:selector 0xcdffacc6
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
    // end::facetAddress(bytes4)[]
}
// end::IDiamondLoupe[]
