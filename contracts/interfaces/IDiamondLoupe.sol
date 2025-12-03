// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * A loupe is a small magnifying glass used to look at diamonds.
 * These functions look at diamonds
 */
// TODO Write NatSpec comments.
// TODO Complete unit testing for all functions.
// TODO Implement and test external versions of all functions.
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    error FunctionAlreadyPresent(bytes4 functionSelector);
    error FacetAlreadyPresent(address facet);
    error FunctionNotPresent(bytes4 functionSelector);
    error FacetNotPresent(address facet);

    /**
     * @notice Gets all facet addresses and their four byte function selectors.
     * @return facets_ Facet
     * @custom:selector 0x7a0ed627
     */
    function facets() external view returns (Facet[] memory facets_);

    /**
     * @notice Gets all the function selectors supported by a specific facet.
     * @param _facet The facet address.
     * @return facetFunctionSelectors_
     * @custom:selector 0xadfca15e
     */
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /**
     * @notice Get all the facet addresses used by a diamond.
     * @return facetAddresses_
     * @custom:selector 0x52ef6b2c
     */
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /**
     * @notice Gets the facet that supports the given selector.
     * @dev If facet is not found return address(0).
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address.
     * @custom:selector 0xcdffacc6
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
