// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TODO Write NatSpec comments. Copy from standard
/**
 * @title IDiamond - ERC2535 structs and events.
 * @author Nick Mudge (@mudgen)
 */
interface IDiamond {
    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    // Bad data normalization. Facets should be grouped by FacetCutAction. Should reuse Facet struct.
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}
