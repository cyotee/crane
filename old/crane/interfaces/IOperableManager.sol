// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "./IOperable.sol";

/**
 * @title IOperatableManager - Interface for managing operator authorization of contracts owned by contracts.
 * @author cyotee doge <doge.cyotee>
 * @notice Manager interfaces minimize potential risk from allowing Owner/Operators to forward arbitrary calls.
 */
interface IOperableManager {
    /**
     * @param subject Subject of ownership for which to change the authorization status of `newOperator`.
     * @param newOperator Address to authorize for function calls.
     * @param approval Operator approval change.
     */
    function setOperator(IOperable subject, address newOperator, bool approval) external returns (bool);

    /**
     * @param subject Subject of ownership for which to change the authorization status of `newOperator`.
     * @param func Function selector for which to update authorization of `newOperator`.
     * @param newOperator Account for which to update authorization to call `func`.
     * @param approval Call authorization change.
     * @return Gas saving boolean indicating success.
     */
    function setOperatorFor(IOperable subject, bytes4 func, address newOperator, bool approval) external returns (bool);
}
