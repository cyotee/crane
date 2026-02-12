// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";

/**
 * @title ERC2612Repo - Diamond storage repository library.
 * @author cyotee doge <doge.cyotee>
 */
library ERC2612Repo {
    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode("eip.erc.2612"));

    struct Storage {
        // Stores signature nonces per account.
        mapping(address account => uint256) nonces;
    }

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(Storage storage layout, address owner) internal returns (uint256) {
        // For each account, the nonce has an initial value of 0, can only be incremented by one, and cannot be
        // decremented or reset. This guarantees that the nonce never overflows.
        unchecked {
            // It is important to do x++ and not ++x here.
            return layout.nonces[owner]++;
        }
    }

    function _useNonce(address owner) internal returns (uint256) {
        return _useNonce(_layout(), owner);
    }

    /**
     * @dev Same as {_useNonce} but checking that `nonce` is the next valid for `owner`.
     */
    function _useCheckedNonce(Storage storage layout, address owner, uint256 nonce) internal {
        uint256 current = _useNonce(layout, owner);
        if (nonce != current) {
            revert IERC2612.InvalidAccountNonce(owner, current);
        }
    }

    function _useCheckedNonce(address owner, uint256 nonce) internal {
        _useCheckedNonce(_layout(), owner, nonce);
    }

    function _nonces(Storage storage layout, address owner) internal view returns (uint256) {
        return layout.nonces[owner];
    }

    function _nonces(address owner) internal view returns (uint256) {
        return _nonces(_layout(), owner);
    }
}
