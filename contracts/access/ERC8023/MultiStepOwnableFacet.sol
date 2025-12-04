// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {MultiStepOwnableTarget} from "@crane/contracts/access/ERC8023/MultiStepOwnableTarget.sol";

contract MultiStepOwnableFacet is MultiStepOwnableTarget, IFacet {
    /* -------------------------------------------------------------------------- */
    /*                              IFacet Functions                              */
    /* -------------------------------------------------------------------------- */

    function facetName() public pure returns (string memory name) {
        return type(MultiStepOwnableFacet).name;
    }

    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IMultiStepOwnable).interfaceId;
    }

    /**
     * @inheritdoc IFacet
     */
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](8);
        funcs[0] = IMultiStepOwnable.initiateOwnershipTransfer.selector;
        funcs[1] = IMultiStepOwnable.confirmOwnershipTransfer.selector;
        funcs[2] = IMultiStepOwnable.cancelPendingOwnershipTransfer.selector;
        funcs[3] = IMultiStepOwnable.acceptOwnershipTransfer.selector;
        funcs[4] = IMultiStepOwnable.owner.selector;
        funcs[5] = IMultiStepOwnable.pendingOwner.selector;
        funcs[6] = IMultiStepOwnable.preConfirmedOwner.selector;
        funcs[7] = IMultiStepOwnable.getOwnershipTransferBuffer.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
