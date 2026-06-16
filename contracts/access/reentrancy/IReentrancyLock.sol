// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

// tag::IReentrancyLock[]
/**
 * @title IReentrancyLock
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Interface for a simple reentrancy lock mechanism.
 * @dev Declares the query (isLocked) and controls (lock, unlock). Used with ReentrancyLockRepo (transient) and ReentrancyLockModifiers.nonReentrant for protection.
 *      Follows Permit2Aware / ICallTarget* / IMultiStepOwnable gold for NatSpec + exact tags. 
 *      custom values (interfaceid/selector/signature) omitted: CENTRALLY_COMPUTED_NATSPEC_VALUES.md has no entries/prose for IReentrancyLock or IsLocked (do not fabricate).
 */
interface IReentrancyLock {
    /* -------------------------------------------------------------------------- */
    /*                                   Errors                                   */
    /* -------------------------------------------------------------------------- */

    // tag::IsLocked()[]
    /**
     * @notice Thrown when a reentrant call is attempted while the lock is held.
     */
    error IsLocked();
    // end::IsLocked()[]

    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::isLocked()[]
    /// @notice Returns whether reentrancy lock is currently active.
    /// @return locked_ True if locked (reentrancy will be blocked), false otherwise.
    function isLocked() external view returns (bool locked_);
    // end::isLocked()[]

    // tag::lock()[]
    /// @notice Acquires the lock (blocks reentrancy).
    /// @dev Reverts with IsLocked() if already held. Called by lock modifier before body.
    function lock() external;
    // end::lock()[]

    // tag::unlock()[]
    /// @notice Releases the lock (re-enables calls).
    /// @dev Called by lock modifier after body (or on revert for transient storage).
    function unlock() external;
    // end::unlock()[]
}
// end::IReentrancyLock[]
