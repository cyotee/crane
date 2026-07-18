// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";

// tag::ERC2612Repo[]
/**
 * @title ERC2612Repo - Storage library for ERC-2612 / EIP-2612 permit nonces.
 * @author cyotee doge <cyotee@syscoin.org>
 * @dev Storage library (Repo) for ERC2612 nonce state per IERC2612.
 * @dev Provides dual (parameterized + default) overloads for all storage accessors/mutators.
 * @dev Follows the gold standard from ERC20Repo, ERC721Repo, ERC4626Repo, OperableRepo, EIP712Repo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT).
 * @dev Used by ERC2612Target, ERC2612Facet, BetterBalancerV3PoolTokenFacet and permit consumers for Diamond storage binding of nonces.
 */
library ERC2612Repo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("eip.erc.2612"))) - 1).
     *      This follows the canonical pattern used by ERC20Repo (eip.erc.20), ERC721Repo (eip.erc.721), ERC4626Repo (eip.erc.4626), EIP712Repo (eip.eip.712),
     *      OperableRepo, MultiStepOwnableRepo, DeployedAddressesRepo, and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.2612"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for ERC-2612 nonces.
     *      nonces: Per-account nonces used for permit signatures (increment-only, never reset).
     */
    /// forge-lint: disable-next-line(pascal-case-struct)
    struct Storage {
        // Stores signature nonces per account.
        mapping(address account => uint256) nonces;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
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

    // tag::_useNonce(Storage-address)[]
    /**
     * @dev Argumented version of _useNonce to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner The account whose nonce to consume.
     * @return The nonce value before increment (the one used for the permit).
     */
    function _useNonce(Storage storage layoutStruct, address owner) internal returns (uint256) {
        // For each account, the nonce has an initial value of 0, can only be incremented by one, and cannot be
        // decremented or reset. This guarantees that the nonce never overflows.
        unchecked {
            // It is important to do x++ and not ++x here.
            return layoutStruct.nonces[owner]++;
        }
    }

    // end::_useNonce(Storage-address)[]

    // tag::_useNonce(address)[]
    /**
     * @dev Default version of _useNonce binding to the standard STORAGE_SLOT.
     * @param owner The account whose nonce to consume.
     * @return The nonce value before increment (the one used for the permit).
     */
    function _useNonce(address owner) internal returns (uint256) {
        return _useNonce(_layoutStruct(), owner);
    }

    // end::_useNonce(address)[]

    // tag::_useCheckedNonce(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _useCheckedNonce to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner The account.
     * @param nonce The nonce expected to be current (next valid).
     * @custom:throws IERC2612.InvalidAccountNonce if nonce does not match current.
     */
    function _useCheckedNonce(Storage storage layoutStruct, address owner, uint256 nonce) internal {
        uint256 current = _useNonce(layoutStruct, owner);
        if (nonce != current) {
            revert IERC2612.InvalidAccountNonce(owner, current);
        }
    }

    // end::_useCheckedNonce(Storage-address-uint256)[]

    // tag::_useCheckedNonce(address-uint256)[]
    /**
     * @dev Default version of _useCheckedNonce binding to the standard STORAGE_SLOT.
     * @param owner The account.
     * @param nonce The nonce expected to be current (next valid).
     * @custom:throws IERC2612.InvalidAccountNonce if nonce does not match current.
     */
    function _useCheckedNonce(address owner, uint256 nonce) internal {
        _useCheckedNonce(_layoutStruct(), owner, nonce);
    }

    // end::_useCheckedNonce(address-uint256)[]

    // tag::_nonces(Storage-address)[]
    /**
     * @dev Argumented version of _nonces to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner The account to query.
     * @return The current nonce for the owner.
     */
    function _nonces(Storage storage layoutStruct, address owner) internal view returns (uint256) {
        return layoutStruct.nonces[owner];
    }

    // end::_nonces(Storage-address)[]

    // tag::_nonces(address)[]
    /**
     * @dev Default version of _nonces binding to the standard STORAGE_SLOT.
     * @param owner The account to query.
     * @return The current nonce for the owner.
     */
    function _nonces(address owner) internal view returns (uint256) {
        return _nonces(_layoutStruct(), owner);
    }
    // end::_nonces(address)[]

    // end::ERC2612Repo[]
}
