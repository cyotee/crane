// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {ReentrancyLockRepo} from "@crane/contracts/access/reentrancy/ReentrancyLockRepo.sol";

// tag::ReentrancyLockModifiers[]
/**
 * @title ReentrancyLockModifiers - Modifiers for functions that require reentrancy protection.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Provides a `lock` modifier that can be applied to functions to prevent reentrancy attacks by utilizing the ReentrancyLockRepo for state management.
 */
abstract contract ReentrancyLockModifiers {
    // tag::lock[]
    /**
     * @notice Modifier to prevent reentrancy on functions. It checks if the contract is currently locked, locks it for the duration of the function execution, and then unlocks it afterward.
     */
    modifier lock() {
        // Check if the contract is currently locked. If it is, revert with the IsLocked error.
        ReentrancyLockRepo._onlyUnlocked();
        // Lock the contract to prevent reentrancy during the execution of the function.
        ReentrancyLockRepo._lock();
        // Execute the function body.
        _;
        // Unlock the contract after the function execution is complete to allow future calls.
        ReentrancyLockRepo._unlock();
    }
    // end::lock[]
}
// end::ReentrancyLockModifiers[]