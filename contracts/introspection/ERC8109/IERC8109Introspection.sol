// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IERC8109Introspection {
    /** @notice Gets the facet that handles the given selector.
     *
     *  @dev If facet is not found return address(0).
     *  @param _functionSelector The function selector.
     *  @return The facet address associated with the function selector.
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address);

    struct FunctionFacetPair {
        bytes4 selector;
        address facet;
    }

    /**
     * @notice Returns an array of all function selectors and their 
     *         corresponding facet addresses.
     *
     * @dev    Iterates through the diamond's stored selectors and pairs
     *         each with its facet.
     * @return pairs An array of `FunctionFacetPair` structs, each containing
     *         a selector and its facet address.
     */
    function functionFacetPairs() external view returns(FunctionFacetPair[] memory pairs);

}