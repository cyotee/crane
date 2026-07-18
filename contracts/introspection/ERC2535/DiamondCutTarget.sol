// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";

// import { IOwnable } from "@crane/contracts/crane/interfaces/IOwnable.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// tag::DiamondCutTarget[]
/**
 * @title DiamondCutTarget - Target implementation for the IDiamondCut diamond upgrade interface.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Provides the diamondCut function restricted to owner.
 * @dev Delegates diamondCut logic to ERC2535Repo._diamondCut. Inherits MultiStepOwnableModifiers for onlyOwner guard.
 *      This Target is extended by DiamondCutFacet which adds the IFacet metadata surface.
 */
contract DiamondCutTarget is MultiStepOwnableModifiers, IDiamond, IDiamondCut {
    /* -------------------------------------------------------------------------- */
    /*                                    LOGIC                                   */
    /* -------------------------------------------------------------------------- */

    // tag::diamondCut(IDiamond.FacetCut[],address,bytes)[]
    /**
     * @inheritdoc IDiamondCut
     * @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall.
     * @dev Delegates to ERC2535Repo._diamondCut . Restricted via onlyOwner modifier (from MultiStepOwnable).
     * @param diamondCut_ Contains the facet addresses and function selectors.
     * @param initTarget The address of the contract or facet to execute initCalldata.
     * @param initCalldata A function call, including function selector and arguments. _calldata is executed with delegatecall on initTarget.
     * @custom:emits DiamondCut
     * @custom:selector 0x1f931c1c
     * @custom:signature diamondCut(IDiamond.FacetCut[],address,bytes)
     */
    function diamondCut(IDiamond.FacetCut[] memory diamondCut_, address initTarget, bytes memory initCalldata)
        public
        virtual
        onlyOwner
    {
        ERC2535Repo._diamondCut(diamondCut_, initTarget, initCalldata);
    }
    // end::diamondCut(IDiamond.FacetCut[],address,bytes)[]

    // end::DiamondCutTarget[]
}
