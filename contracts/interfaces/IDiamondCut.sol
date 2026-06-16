// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";

// tag::IDiamondCut[]
/**
 * @title IDiamondCut - ERC2535 "Diamond Standard" cut interface.
 * @author Nick Mudge (@mudgen)
 * @notice Interface for adding/replacing/removing any number of functions on a Diamond proxy
 *         and optionally executing a function with delegatecall (for initialization).
 * @dev Reuses FacetCut and DiamondCut event from IDiamond. Core upgrade mechanism for ERC2535 diamonds.
 */
interface IDiamondCut {
    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::diamondCut(IDiamond.FacetCut[]-address-bytes)[]
    /**
     * @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall.
     * @param diamondCut_ Contains the facet addresses and function selectors.
     * @param initTarget The address of the contract or facet to execute initCalldata.
     * @param initCalldata A function call, including function selector and arguments.
     *                     _calldata is executed with delegatecall on initTarget.
     * @custom:signature diamondCut(IDiamond.FacetCut[],address,bytes)
     * @custom:selector 0x1f931c1c
     * @custom:emits DiamondCut
     */
    function diamondCut(IDiamond.FacetCut[] calldata diamondCut_, address initTarget, bytes calldata initCalldata)
        external;
    // end::diamondCut(IDiamond.FacetCut[]-address-bytes)[]
}
// end::IDiamondCut[]
