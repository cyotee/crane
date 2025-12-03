// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IReentrancyLock} from "contracts/interfaces/IReentrancyLock.sol";
import {ReentrancyLockRepo} from "contracts/access/reentrancy/ReentrancyLockRepo.sol";

contract ReentrancyLockTarget is IReentrancyLock {
    function isLocked() external view returns (bool) {
        return ReentrancyLockRepo._isLocked();
    }
}
