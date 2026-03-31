// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ITokenTransferRelayer} from '@crane/contracts/interfaces/ITokenTransferRelayer.sol';
import {IMultiStepOwnable} from '@crane/contracts/interfaces/IMultiStepOwnable.sol';
import {TokenTransferRelayerTarget} from '@crane/contracts/protocols/l2s/superchain/relayers/token/TokenTransferRelayerTarget.sol';
import {FacetBase} from '@crane/contracts/factories/diamondPkg/FacetBase.sol';

contract TokenTransferRelayerFacet is TokenTransferRelayerTarget, FacetBase {
    // tag::facetName[]
    function facetName() public pure override returns (string memory name) {
        return "TokenTransferRelayerFacet";
    }
    // end::facetName[]

    // tag::facetInterfaces[]
    function facetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(ITokenTransferRelayer).interfaceId;
        interfaces[1] = type(IMultiStepOwnable).interfaceId;
        return interfaces;
    }
    // end::facetInterfaces[]

    // tag::facetFuncs[]
    function facetFuncs() public pure override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = ITokenTransferRelayer.nextNonce.selector;
        funcs[1] = ITokenTransferRelayer.relayTokenTransfer.selector;
        funcs[2] = ITokenTransferRelayer.recoverToken.selector;
        return funcs;
    }
    // end::facetFuncs[]
}