// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {ReentrancyLockRepo} from "@crane/contracts/access/reentrancy/ReentrancyLockRepo.sol";

// tag::ReentrancyLockTarget[]
/**
 * @title ReentrancyLockTarget - Target contract implementing IReentrancyLock.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Exposes reentrancy lock status query by delegating to ReentrancyLockRepo (transient storage).
 * @dev Follows Facet-Target-Repo. Does not define own storage (delegates entirely). Inherited by ReentrancyLockFacet.
 *      No custom tags (e.g. selector) per CENTRALLY_COMPUTED_NATSPEC_VALUES.md instruction - prose only.
 */
contract ReentrancyLockTarget is IReentrancyLock {
    // tag::isLocked()[]
    /**
     * @inheritdoc IReentrancyLock
     * @dev Delegates to ReentrancyLockRepo._isLocked() which uses the transient storage key from _layoutStruct().
     */
    function isLocked() external view returns (bool) {
        return ReentrancyLockRepo._isLocked();
    }

    // end::isLocked()[]

    // tag::lock()[]
    /**
     * @inheritdoc IReentrancyLock
     * @dev Delegates to ReentrancyLockRepo._lock(). Called via ReentrancyLockModifiers in protected functions (or directly if needed).
     */
    function lock() external {
        ReentrancyLockRepo._lock();
    }

    // end::lock()[]

    // tag::unlock()[]
    /**
     * @inheritdoc IReentrancyLock
     * @dev Delegates to ReentrancyLockRepo._unlock(). Called via ReentrancyLockModifiers in protected functions (or directly if needed).
     */
    function unlock() external {
        ReentrancyLockRepo._unlock();
    }
    // end::unlock()[]
}
// end::ReentrancyLockTarget[]
