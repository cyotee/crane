// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::IFacet[]
/**
 * @title IFacet - Optional delcarative interface for Facet funtionality and metadata.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Optional for facets to implement for declarative metadata about the facet.
 */
interface IFacet {
    /**
     * @notice Declares a canonical nonunique name for the exposing facet.
     * @return name The name of the facet.
     * @custom:selector 0x5b6f4d01
     * @custom:signature facetName()
     */
    function facetName() external view returns (string memory name);

    /**
     * @notice Declares the interfaces implemented by the exposing facet for use in a composing proxy.
     * @return interfaces The interface IDs implemented by the facet.
     * @custom:selector 0x2ea80826
     * @custom:signature facetInterfaces()
     */
    function facetInterfaces() external view returns (bytes4[] memory interfaces);

    /**
     * @notice Declares the function selectors implemented by the exposing facet for use in a composing proxy.
     * @return funcs The function selectors implemented by the facet.
     * @custom:selector 0x574a4cff
     * @custom:signature facetFuncs()
     */
    function facetFuncs() external view returns (bytes4[] memory funcs);

    /**
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
        view
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions);
}
// end::IFacet[]