// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";
import {TestBase_IFacet} from "@crane/contracts/factories/diamondPkg/TestBase_IFacet.sol";

/**
 * @title MultiStepOwnableFacet_IFacet_Test
 * @notice Tests IFacet compliance for MultiStepOwnableFacet.
 */
contract MultiStepOwnableFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return new MultiStepOwnableFacet();
    }

    function controlFacetName() public pure override returns (string memory facetName) {
        return "MultiStepOwnableFacet";
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IMultiStepOwnable).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](8);
        controlFuncs[0] = IMultiStepOwnable.initiateOwnershipTransfer.selector;
        controlFuncs[1] = IMultiStepOwnable.confirmOwnershipTransfer.selector;
        controlFuncs[2] = IMultiStepOwnable.cancelPendingOwnershipTransfer.selector;
        controlFuncs[3] = IMultiStepOwnable.acceptOwnershipTransfer.selector;
        controlFuncs[4] = IMultiStepOwnable.owner.selector;
        controlFuncs[5] = IMultiStepOwnable.pendingOwner.selector;
        controlFuncs[6] = IMultiStepOwnable.preConfirmedOwner.selector;
        controlFuncs[7] = IMultiStepOwnable.getOwnershipTransferBuffer.selector;
    }
}
