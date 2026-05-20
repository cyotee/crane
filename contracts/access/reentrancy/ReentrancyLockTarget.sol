// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {ReentrancyLockRepo} from "@crane/contracts/access/reentrancy/ReentrancyLockRepo.sol";

// tag::ReentrancyLockTarget[]
/**
 * @title ReentrancyLockTarget - A simple contract that implements the IReentrancyLock interface by utilizing the ReentrancyLockRepo for state management.
 * @author cyotee doge <not_cyotee@proton.me>
 */
contract ReentrancyLockTarget is IReentrancyLock {
    // tag::isLocked()[]
    /**
     * @inheritdoc IReentrancyLock
     */
    function isLocked() external view returns (bool) {
        return ReentrancyLockRepo._isLocked();
    }
    // end::isLocked()[]
}
// end::ReentrancyLockTarget[]