// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import { TransientSlot } from "@openzeppelin/contracts/utils/TransientSlot.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {
//     ReentrancyLockLayout,
//     ReentrancyLockRepo
// } from "./ReentrancyLockRepo.sol";

import {
    IReentrancyLock
} from "contracts/interfaces/IReentrancyLock.sol";

contract ReentrancyLockStorage {

    // using ReentrancyLockRepo for bytes32;
    using TransientSlot for *;

    // bytes32 private constant LAYOUT_ID
    //     = keccak256(abi.encode(type(ReentrancyLockRepo).name));
    // bytes32 private constant STORAGE_RANGE_OFFSET
    //     = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        = type(IReentrancyLock).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE));

    // function _reentrant()
    // internal pure virtual returns(ReentrancyLockLayout storage) {
    //     return STORAGE_SLOT._layout();
    // }

    function _reentrant()
    internal pure virtual returns(bytes32) {
        return STORAGE_SLOT;
    }

    function _isLocked()
    internal view virtual returns(bool) {
        // return _reentrant().isLocked;
        return STORAGE_SLOT.asBoolean().tload();
    }

    function _lock()
    internal virtual {
        // _reentrant().isLocked = true;
        _reentrant().asBoolean().tstore(true);
    }

    function _unlock()
    internal virtual {
        // delete _reentrant().isLocked;
        _reentrant().asBoolean().tstore(false);
    }
    

}
