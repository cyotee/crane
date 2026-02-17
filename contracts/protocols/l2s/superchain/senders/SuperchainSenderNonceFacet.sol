// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {FacetBase} from '@crane/contracts/factories/diamondPkg/FacetBase.sol';
import {ISuperchainSenderNonce} from '@crane/contracts/interfaces/ISuperchainSenderNonce.sol';
import {SuperchainSenderNonceTarget} from '@crane/contracts/protocols/l2s/superchain/senders/SuperchainSenderNonceTarget.sol';

contract SuperchainSenderNonceFacet is SuperchainSenderNonceTarget, FacetBase {
    function facetName() public pure override returns (string memory name) {
        return type(SuperchainSenderNonceFacet).name;
    }

    function facetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ISuperchainSenderNonce).interfaceId;
        return interfaces;
    }

    function facetFuncs() public pure override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = ISuperchainSenderNonce.nextNonce.selector;
        return funcs;
    }
}