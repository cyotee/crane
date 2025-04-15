// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    IReentrancyLock
} from "../../../access/reentrancy/interfaces/IReentrancyLock.sol";
import {
    ReentrancyLockStorage
} from "../../../access/reentrancy/storage/ReentrancyLockStorage.sol";

contract ReentrancyLockTarget
is
ReentrancyLockStorage,
IReentrancyLock
{

    function isLocked()
    external view returns(bool) {
        return _isLocked();
    }


}