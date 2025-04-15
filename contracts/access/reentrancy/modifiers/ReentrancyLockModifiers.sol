// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    IReentrancyLock
} from "../../../access/reentrancy/interfaces/IReentrancyLock.sol";

import {
    ReentrancyLockStorage
} from "../../../access/reentrancy/storage/ReentrancyLockStorage.sol";

contract ReentrancyLockModifiers
is
ReentrancyLockStorage
{

    modifier lock() {
        if(_isLocked()) {
            revert IReentrancyLock.IsLocked();
        }
        _lock();
        _;
        _unlock();
    }

}