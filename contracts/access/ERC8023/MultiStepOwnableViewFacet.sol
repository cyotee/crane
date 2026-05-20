// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Imports                                  */
/* -------------------------------------------------------------------------- */

/* --------------------------- Imported Interfaces -------------------------- */

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IMultiStepOwnableView} from "@crane/contracts/access/ERC8023/IMultiStepOwnableView.sol";

/* --------------------------- Imported Libraries --------------------------- */

import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

/* --------------------------- Imported Contracts --------------------------- */

import {MultiStepOwnableViewTarget} from "@crane/contracts/access/ERC8023/MultiStepOwnableViewTarget.sol";

// tag::MultiStepOwnableViewFacet[]
/**
 * @title MultiStepOwnableFacet - Reusable facet for ERC8023 compliant multi-step ownership views of state.
 * @author cyotee doge <not_cyotee@proton.me>
 * @custom:contractlistipfs
 */
contract MultiStepOwnableViewFacet is MultiStepOwnableViewTarget, IFacet {
    /* -------------------------------------------------------------------------- */
    /*                                   IFacet                                   */
    /* -------------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     */
    function facetName() public pure returns (string memory name) {
        return type(MultiStepOwnableViewFacet).name;
    }
    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IMultiStepOwnableView).interfaceId;
    }

    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     */
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](4);
        funcs[0] = IMultiStepOwnableView.owner.selector;
        funcs[1] = IMultiStepOwnableView.pendingOwner.selector;
        funcs[2] = IMultiStepOwnableView.preConfirmedOwner.selector;
        funcs[3] = IMultiStepOwnableView.getOwnershipTransferBuffer.selector;
    }

    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     */
    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    // end::facetMetadata()[]
}
// end::MultiStepOwnableViewFacet[]
