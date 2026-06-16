// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {ReentrancyLockRepo} from "@crane/contracts/access/reentrancy/ReentrancyLockRepo.sol";

// tag::ReentrancyLockModifiers[]
/**
 * @title ReentrancyLockModifiers - Modifiers for functions that require reentrancy protection.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Provides a `nonReentrant` modifier that can be applied to functions to prevent reentrancy attacks by utilizing the ReentrancyLockRepo for state management.
 * @dev Declared abstract to indicate this should be inherited, not deployed directly.
 *      Compiler will inline the modifiers used in the inheriting contract.
 *      Thin wrapper that delegates to ReentrancyLockRepo guard functions (_onlyUnlocked, _lock, _unlock) per AGENTS.md Modifiers pattern (see OperableModifiers, MultiStepOwnableModifiers).
 */
abstract contract ReentrancyLockModifiers {
    // tag::nonReentrant[]
    /**
     * @notice Modifier to prevent reentrancy on functions.
     */
    modifier nonReentrant() {
        // Check if the contract is currently locked. If it is, revert with the IsLocked error.
        ReentrancyLockRepo._onlyUnlocked();
        // Lock the contract to prevent reentrancy during the execution of the function.
        ReentrancyLockRepo._lock();
        // Execute the function body.
        _;
        // Unlock the contract after the function execution is complete to allow future calls.
        ReentrancyLockRepo._unlock();
    }
    // end::nonReentrant[]
}
// end::ReentrancyLockModifiers[]
