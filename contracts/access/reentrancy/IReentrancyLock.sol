// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

// tag::IReentrancyLock[]
/**
 * @title IReentrancyLock - Interface for a simple reentrancy lock mechanism.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Provides a standardized interface for checking if a contract is currently locked against reentrancy.
 */
interface IReentrancyLock {
    // tag::IsLocked[]
    /**
     * @notice Error thrown when a reentrancy lock is active.
     */
    error IsLocked();
    // end::IsLocked[]

    // tag::isLocked()[]
    /**
     * @notice Checks if the contract is currently locked against reentrancy.
     * @return True if the contract is locked, false otherwise.
     */
    function isLocked() external view returns (bool);
    // end::isLocked()[]
}
// end::IReentrancyLock[]