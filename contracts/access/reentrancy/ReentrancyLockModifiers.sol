// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IReentrancyLock} from "contracts/interfaces/IReentrancyLock.sol";
import {ReentrancyLockRepo} from "contracts/access/reentrancy/ReentrancyLockRepo.sol";

contract ReentrancyLockModifiers {
    modifier lock() {
        ReentrancyLockRepo._onlyUnlocked();
        ReentrancyLockRepo._lock();
        _;
        ReentrancyLockRepo._unlock();
    }
}
