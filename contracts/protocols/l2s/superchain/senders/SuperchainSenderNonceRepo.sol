// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library SuperchainSenderNonceRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.protocols.l2s.superchain.senders.nonce");

    error InvalidSenderNonce(address sender, uint256 targetChainId, uint256 currentNonce, uint256 providedNonce);

    struct Storage {
        mapping(address sender => mapping(uint256 targetChainId => uint256 nextNonce)) nextNonce;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _nextNonce(Storage storage layoutStruct, address sender, uint256 targetChainId)
        internal
        view
        returns (uint256 nonce)
    {
        return layoutStruct.nextNonce[sender][targetChainId];
    }

    function _nextNonce(address sender, uint256 targetChainId) internal view returns (uint256 nonce) {
        return _nextNonce(_layoutStruct(), sender, targetChainId);
    }

    function _useNonce(Storage storage layoutStruct, address sender, uint256 targetChainId)
        internal
        returns (uint256 nonce)
    {
        nonce = layoutStruct.nextNonce[sender][targetChainId];
        layoutStruct.nextNonce[sender][targetChainId] = nonce + 1;
    }

    function _useNonce(address sender, uint256 targetChainId) internal returns (uint256 nonce) {
        return _useNonce(_layoutStruct(), sender, targetChainId);
    }

    function _useCheckedNonce(Storage storage layoutStruct, address sender, uint256 targetChainId, uint256 providedNonce)
        internal
        returns (uint256 currentNonce)
    {
        currentNonce = layoutStruct.nextNonce[sender][targetChainId];
        if (currentNonce != providedNonce) {
            revert InvalidSenderNonce(sender, targetChainId, currentNonce, providedNonce);
        }
        layoutStruct.nextNonce[sender][targetChainId] = currentNonce + 1;
    }

    function _useCheckedNonce(address sender, uint256 targetChainId, uint256 providedNonce)
        internal
        returns (uint256 currentNonce)
    {
        return _useCheckedNonce(_layoutStruct(), sender, targetChainId, providedNonce);
    }
}