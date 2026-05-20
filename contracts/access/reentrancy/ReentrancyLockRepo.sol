// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {TransientSlot} from "@crane/contracts/utils/TransientSlot.sol";

// tag::ReentrancyLockRepo[]
/**
 * @title ReentrancyLockRepo - A library for managing a simple reentrancy lock state using a transient storage slot.
 * @author cyotee doge <not_cyotee@proton.me>
 */
library ReentrancyLockRepo {
    using TransientSlot for *;

    // tag::STORAGE_SLOT[]
    /**
     * @dev Standardized storage slot for the reentrancy lock state.
     */
    bytes32 private constant STORAGE_SLOT = keccak256(abi.encode("crane.access.reentrancy"));
    // end::STORAGE_SLOT[]

    // tag::_lock()[]
    /**
     * @dev Locks the reentrancy lock state.
     */
    function _lock() internal {
        STORAGE_SLOT.asBoolean().tstore(true);
    }
    // end::_lock()[]

    // tag::_unlock()[]
    /**
     * @dev Unlocks the reentrancy lock state.
     */
    function _unlock() internal {
        STORAGE_SLOT.asBoolean().tstore(false);
    }
    // end::_unlock()[]

    // tag::_isLocked()[]
    /**
     * @dev Checks if the reentrancy lock is currently active.
     * @return True if the lock is active, false otherwise.
     */
    function _isLocked() internal view returns (bool) {
        return STORAGE_SLOT.asBoolean().tload();
    }
    // end::_isLocked()[]

    // tag::_onlyUnlocked()[]
    /**
     * @dev Reverts if the reentrancy lock is currently active.
     */
    function _onlyUnlocked() internal view {
        if (_isLocked()) {
            revert IReentrancyLock.IsLocked();
        }
    }
    // end::_onlyUnlocked()[]
}
// end::ReentrancyLockRepo[]