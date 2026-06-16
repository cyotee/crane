// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::IDiamond[]
/**
 * @title IDiamond - ERC2535 "Diamond Standard" core data types and DiamondCut event.
 * @author Nick Mudge (@mudgen)
 * @notice Defines the FacetCutAction enum, FacetCut struct, and the canonical DiamondCut event.
 *         These are the shared types and event used across IDiamondCut (for diamondCut) and IDiamondLoupe.
 *         This is the canonical definition (re-exported at contracts/interfaces/IDiamond.sol for convenience).
 * @dev Original note preserved in NatSpec: bad data normalization in FacetCut (facets should be grouped by action).
 */
interface IDiamond {
    /* -------------------------------------------------------------------------- */
    /*                                    Types                                   */
    /* -------------------------------------------------------------------------- */

    // tag::FacetCutAction[]
    /**
     * @notice Enum for the action to perform on a set of function selectors for a given facet address.
     * @dev Values: Add=0, Replace=1, Remove=2. Stored as uint8 in ABI for FacetCut.action.
     */
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // end::FacetCutAction[]

    // tag::FacetCut[]
    /**
     * @notice Describes a facet modification to apply during diamondCut: target facet, action, and selectors.
     * @dev Note (preserved): "Bad data normalization. Facets should be grouped by FacetCutAction. Should reuse Facet struct."
     */
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
    // end::FacetCut[]

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    // tag::DiamondCut(FacetCut[]-address-bytes)[]
    /**
     * @notice Emitted when diamondCut is executed, indicating the cuts applied and optional initialization delegatecall.
     * @param _diamondCut Array of facet cuts applied in the operation.
     * @param _init Target address for the optional post-cut delegatecall (address(0) means no init).
     * @param _calldata Calldata (with selector) to execute via delegatecall on _init after applying cuts.
     * @custom:topic-signature DiamondCut(FacetCut[],address,bytes)
     * @custom:topiczero 0x8faa70878671ccd212d20771b795c50af8fd3ff6cf27f4bde57e5d4de0aeb673
     * @custom:emits DiamondCut(FacetCut[],address,bytes)
     */
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
    // end::DiamondCut(FacetCut[]-address-bytes)[]
}

// end::IDiamond[]
