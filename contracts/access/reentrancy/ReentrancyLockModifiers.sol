// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {ReentrancyLockRepo} from "@crane/contracts/access/reentrancy/ReentrancyLockRepo.sol";

abstract contract ReentrancyLockModifiers {
    modifier lock() {
        ReentrancyLockRepo._onlyUnlocked();
        ReentrancyLockRepo._lock();
        _;
        ReentrancyLockRepo._unlock();
    }
}
