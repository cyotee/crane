// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IApprovedMessageSenderRegistry} from '@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol';
import {FacetBase} from '@crane/contracts/factories/diamondPkg/FacetBase.sol';
import {ApprovedMessageSenderRegistryTarget} from '@crane/contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryTarget.sol';

contract ApprovedMessageSenderRegistryFacet is ApprovedMessageSenderRegistryTarget, FacetBase {
    // tag::facetName[]
    function facetName() public pure override returns (string memory name) {
        return "ApprovedMessageSenderRegistryFacet";
    }
    // end::facetName[]

    // tag::facetInterfaces[]
    function facetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IApprovedMessageSenderRegistry).interfaceId;
        return interfaces;
    }
    // end::facetInterfaces[]

    // tag::facetFuncs[]
    function facetFuncs() public pure override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = IApprovedMessageSenderRegistry.isApprovedSender.selector;
        funcs[1] = IApprovedMessageSenderRegistry.allApprovedSenders.selector;
        funcs[2] = IApprovedMessageSenderRegistry.approveSender.selector;
        return funcs;
    }
    // end::facetFuncs[]
}