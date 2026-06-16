// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// tag::SuperchainSenderNonceRepo[]
/**
 * @title SuperchainSenderNonceRepo
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Storage library for per-sender nonces used in superchain cross-domain messaging (to prevent replays).
 * @dev Implements the Repo tier of the Facet-Target-Repo pattern for SuperchainSenderNonce.
 *      All functions have dual overloads: parameterized (explicit `Storage storage layoutStruct`) and default
 *      (using the internal ERC1967 STORAGE_SLOT). Follows gold standards from ERC20Repo, OperableRepo,
 *      MultiStepOwnableRepo, ERC2535Repo.
 * @dev This library is intended for internal use by the corresponding Target/Facet.
 *      The error is internal (used by checked nonce consumption).
 */
library SuperchainSenderNonceRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("crane.protocols.l2s.superchain.senders.nonce"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC20Repo, MultiStepOwnableRepo, ERC2535Repo,
     *      and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.protocols.l2s.superchain.senders.nonce"))) - 1);
    // end::STORAGE_SLOT[]

    /**
     * @dev Thrown when a provided nonce does not match the expected current nonce for a sender/chain pair.
     */
    error InvalidSenderNonce(address sender, uint256 targetChainId, uint256 currentNonce, uint256 providedNonce);

    // tag::Storage[]
    /**
     * @dev Storage layout for superchain sender nonces.
     *      nextNonce: tracks the next nonce to use per (sender, targetChainId) pair.
     */
    struct Storage {
        mapping(address sender => mapping(uint256 targetChainId => uint256 nextNonce)) nextNonce;
    }
    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Parameterized _layoutStruct allowing custom slot (for testing or special cases).
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    // tag::_nextNonce(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _nextNonce to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param sender The message sender address.
     * @param targetChainId The destination chain id.
     * @return nonce The current next nonce value (not yet consumed).
     */
    function _nextNonce(Storage storage layoutStruct, address sender, uint256 targetChainId)
        internal
        view
        returns (uint256 nonce)
    {
        return layoutStruct.nextNonce[sender][targetChainId];
    }
    // end::_nextNonce(Storage-address-uint256)[]

    // tag::_nextNonce(address-uint256)[]
    /**
     * @dev Default version of _nextNonce binding to the standard STORAGE_SLOT.
     * @param sender The message sender address.
     * @param targetChainId The destination chain id.
     * @return nonce The current next nonce value (not yet consumed).
     */
    function _nextNonce(address sender, uint256 targetChainId) internal view returns (uint256 nonce) {
        return _nextNonce(_layoutStruct(), sender, targetChainId);
    }
    // end::_nextNonce(address-uint256)[]

    // tag::_useNonce(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _useNonce to allow direct Storage access.
     *      Reads current and post-increments (returns the value used).
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param sender The message sender address.
     * @param targetChainId The destination chain id.
     * @return nonce The nonce value that was used for this call (pre-increment).
     */
    function _useNonce(Storage storage layoutStruct, address sender, uint256 targetChainId)
        internal
        returns (uint256 nonce)
    {
        nonce = layoutStruct.nextNonce[sender][targetChainId];
        layoutStruct.nextNonce[sender][targetChainId] = nonce + 1;
    }
    // end::_useNonce(Storage-address-uint256)[]

    // tag::_useNonce(address-uint256)[]
    /**
     * @dev Default version of _useNonce binding to the standard STORAGE_SLOT.
     * @param sender The message sender address.
     * @param targetChainId The destination chain id.
     * @return nonce The nonce value that was used for this call (pre-increment).
     */
    function _useNonce(address sender, uint256 targetChainId) internal returns (uint256 nonce) {
        return _useNonce(_layoutStruct(), sender, targetChainId);
    }
    // end::_useNonce(address-uint256)[]

    // tag::_useCheckedNonce(Storage-address-uint256-uint256)[]
    /**
     * @dev Argumented version of _useCheckedNonce to allow direct Storage access.
     *      Validates providedNonce matches current, then increments. Reverts on mismatch.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param sender The message sender address.
     * @param targetChainId The destination chain id.
     * @param providedNonce The nonce value the caller claims to be using.
     * @return currentNonce The nonce value that matched (and was consumed).
     */
    function _useCheckedNonce(
        Storage storage layoutStruct,
        address sender,
        uint256 targetChainId,
        uint256 providedNonce
    ) internal returns (uint256 currentNonce) {
        currentNonce = layoutStruct.nextNonce[sender][targetChainId];
        if (currentNonce != providedNonce) {
            revert InvalidSenderNonce(sender, targetChainId, currentNonce, providedNonce);
        }
        layoutStruct.nextNonce[sender][targetChainId] = currentNonce + 1;
    }
    // end::_useCheckedNonce(Storage-address-uint256-uint256)[]

    // tag::_useCheckedNonce(address-uint256-uint256)[]
    /**
     * @dev Default version of _useCheckedNonce binding to the standard STORAGE_SLOT.
     * @param sender The message sender address.
     * @param targetChainId The destination chain id.
     * @param providedNonce The nonce value the caller claims to be using.
     * @return currentNonce The nonce value that matched (and was consumed).
     */
    function _useCheckedNonce(address sender, uint256 targetChainId, uint256 providedNonce)
        internal
        returns (uint256 currentNonce)
    {
        return _useCheckedNonce(_layoutStruct(), sender, targetChainId, providedNonce);
    }
    // end::_useCheckedNonce(address-uint256-uint256)[]
}
// end::SuperchainSenderNonceRepo[]
