// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {TransientSlot} from "@crane/contracts/utils/TransientSlot.sol";

// tag::ReentrancyLockRepo[]
/**
 * @title ReentrancyLockRepo - Library for managing reentrancy lock using transient storage.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Storage (transient) library implementing simple reentrancy guard state per IReentrancyLock.
 * @dev Uses transient storage via TransientSlot (tstore/tload) for per-tx lock flag. No persistent Storage struct.
 *      Provides _lock/_unlock/_isLocked/_onlyUnlocked. Follows Repo convention with ERC1967 slot key + dual _layoutStruct (returning the transient slot key bytes32).
 *      Used by ReentrancyLockTarget, ReentrancyLockFacet, and ReentrancyLockModifiers.nonReentrant.
 * @dev Guard logic in _onlyUnlocked; modeled on OperableRepo / MultiStepOwnableRepo / ERC2535Repo gold standards for NatSpec, tags, slot form.
 */
library ReentrancyLockRepo {
    using TransientSlot for *;

    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant transient storage slot key.
     *      Exact form: bytes32(uint256(keccak256(abi.encode("crane.access.reentrancy.lock"))) - 1).
     *      Follows LR-6 and gold standards (e.g. OperableRepo "crane.access.operable").
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.access.reentrancy.lock"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Parameterized version of _layoutStruct to support custom transient slot key.
     * @param slot_ The transient slot key (bytes32) to use.
     * @return layoutStruct The slot key (for use with TransientSlot.as*).
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (bytes32 layoutStruct) {
        return slot_;
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard STORAGE_SLOT.
     * @return layoutStruct The canonical transient slot key.
     */
    function _layoutStruct() internal pure returns (bytes32 layoutStruct) {
        return STORAGE_SLOT;
    }

    // end::_layoutStruct()[]

    // tag::_lock()[]
    /**
     * @dev Locks the reentrancy lock state (transient).
     */
    function _lock() internal {
        _layoutStruct().asBoolean().tstore(true);
    }

    // end::_lock()[]

    // tag::_unlock()[]
    /**
     * @dev Unlocks the reentrancy lock state (transient).
     */
    function _unlock() internal {
        _layoutStruct().asBoolean().tstore(false);
    }

    // end::_unlock()[]

    // tag::_isLocked()[]
    /**
     * @dev Checks if the reentrancy lock is currently active.
     * @return True if the lock is active, false otherwise.
     */
    function _isLocked() internal view returns (bool) {
        return _layoutStruct().asBoolean().tload();
    }

    // end::_isLocked()[]

    // tag::_onlyUnlocked()[]
    /**
     * @dev Guard that reverts if the reentrancy lock is currently active.
     *      Used by the `lock` modifier to enforce non-reentrant execution.
     * @custom:throws IReentrancyLock.IsLocked when the lock is active.
     */
    function _onlyUnlocked() internal view {
        if (_isLocked()) {
            revert IReentrancyLock.IsLocked();
        }
    }
    // end::_onlyUnlocked()[]
}
// end::ReentrancyLockRepo[]
