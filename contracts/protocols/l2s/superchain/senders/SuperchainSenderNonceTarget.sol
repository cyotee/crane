// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ISuperchainSenderNonce} from '@crane/contracts/interfaces/ISuperchainSenderNonce.sol';
import {SuperchainSenderNonceRepo} from '@crane/contracts/protocols/l2s/superchain/senders/SuperchainSenderNonceRepo.sol';

contract SuperchainSenderNonceTarget is ISuperchainSenderNonce {
    function nextNonce(uint256 targetChainId) external view returns (uint256 nonce) {
        return SuperchainSenderNonceRepo._nextNonce(address(this), targetChainId);
    }
}