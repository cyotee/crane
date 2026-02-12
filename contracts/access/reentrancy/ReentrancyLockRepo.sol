// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {TransientSlot} from "@crane/contracts/utils/TransientSlot.sol";

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
