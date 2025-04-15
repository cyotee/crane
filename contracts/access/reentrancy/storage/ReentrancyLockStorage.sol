// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    ReentrancyLockLayout,
    ReentrancyLockRepo
} from "../../../access/reentrancy/libs/ReentrancyLockRepo.sol";

import {
    IReentrancyLock
} from"../../../access/reentrancy/interfaces/IReentrancyLock.sol";

contract ReentrancyLockStorage {

    using ReentrancyLockRepo for bytes32;

    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(ReentrancyLockRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        = type(IReentrancyLock).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    function _reentrant()
    internal pure virtual returns(ReentrancyLockLayout storage) {
        return STORAGE_SLOT._layout();
    }

    function _isLocked()
    internal view virtual returns(bool) {
        return _reentrant().isLocked;
    }

    function _lock()
    internal virtual {
        _reentrant().isLocked = true;
    }

    function _unlock()
    internal virtual {
        delete _reentrant().isLocked;
    }
    

}
