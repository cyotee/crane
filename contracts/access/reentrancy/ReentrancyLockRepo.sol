// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IReentrancyLock} from "contracts/interfaces/IReentrancyLock.sol";

library ReentrancyLockRepo {
    using TransientSlot for *;

    bytes32 private constant STORAGE_SLOT = keccak256(abi.encode("crane.access.reentrancy"));

    function _lock() internal {
        STORAGE_SLOT.asBoolean().tstore(true);
    }

    function _unlock() internal {
        STORAGE_SLOT.asBoolean().tstore(false);
    }

    function _isLocked() internal view returns (bool) {
        return STORAGE_SLOT.asBoolean().tload();
    }

    function _onlyUnlocked() internal view {
        if (_isLocked()) {
            revert IReentrancyLock.IsLocked();
        }
    }
}
