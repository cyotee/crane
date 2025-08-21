// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    IReentrancyLock
} from "contracts/interfaces/IReentrancyLock.sol";
import {
    ReentrancyLockStorage
} from "contracts/access/reentrancy/utils/ReentrancyLockStorage.sol";

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