// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamond} from "./IDiamond.sol";
import {IDiamondLoupe} from "./IDiamondLoupe.sol";
import {DiamondStorage} from "./utils/DiamondStorage.sol";

contract DiamondLoupeTarget
is
DiamondStorage
,IDiamondLoupe 
{
    
    /**
     * @notice Gets all facet addresses and their four byte function selectors.
     * @return facets_ Facet
     */
    function facets()
    external view returns (Facet[] memory facets_) {
        facets_ = _facets();
    }

    /**
     * @notice Gets all the function selectors supported by a specific facet.
     * @param _facet The facet address.
     * @return facetFunctionSelectors_
     */
    function facetFunctionSelectors(address _facet)
    external view returns (bytes4[] memory facetFunctionSelectors_) {
        facetFunctionSelectors_ = _facetFunctionSelectors(_facet);
    }

    /**
     * @notice Get all the facet addresses used by a diamond.
     * @return facetAddresses_
     */
    function facetAddresses()
    external view returns (address[] memory facetAddresses_) {
        facetAddresses_ = _facetAddresses();
    }

    /**
     * @notice Gets the facet that supports the given selector.
     * @dev If facet is not found return address(0).
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address.
     */
    function facetAddress(bytes4 _functionSelector)
    external view returns (address facetAddress_) {
        facetAddress_ = _facetAddress(_functionSelector);
    }

}