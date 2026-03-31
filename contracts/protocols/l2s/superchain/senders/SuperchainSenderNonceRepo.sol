// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library SuperchainSenderNonceRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.protocols.l2s.superchain.senders.nonce");

    error InvalidSenderNonce(address sender, uint256 targetChainId, uint256 currentNonce, uint256 providedNonce);

    struct Storage {
        mapping(address sender => mapping(uint256 targetChainId => uint256 nextNonce)) nextNonce;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    function _nextNonce(Storage storage layout, address sender, uint256 targetChainId)
        internal
        view
        returns (uint256 nonce)
    {
        return layout.nextNonce[sender][targetChainId];
    }

    function _nextNonce(address sender, uint256 targetChainId) internal view returns (uint256 nonce) {
        return _nextNonce(_layout(), sender, targetChainId);
    }

    function _useNonce(Storage storage layout, address sender, uint256 targetChainId)
        internal
        returns (uint256 nonce)
    {
        nonce = layout.nextNonce[sender][targetChainId];
        layout.nextNonce[sender][targetChainId] = nonce + 1;
    }

    function _useNonce(address sender, uint256 targetChainId) internal returns (uint256 nonce) {
        return _useNonce(_layout(), sender, targetChainId);
    }

    function _useCheckedNonce(Storage storage layout, address sender, uint256 targetChainId, uint256 providedNonce)
        internal
        returns (uint256 currentNonce)
    {
        currentNonce = layout.nextNonce[sender][targetChainId];
        if (currentNonce != providedNonce) {
            revert InvalidSenderNonce(sender, targetChainId, currentNonce, providedNonce);
        }
        layout.nextNonce[sender][targetChainId] = currentNonce + 1;
    }

    function _useCheckedNonce(address sender, uint256 targetChainId, uint256 providedNonce)
        internal
        returns (uint256 currentNonce)
    {
        return _useCheckedNonce(_layout(), sender, targetChainId, providedNonce);
    }
}