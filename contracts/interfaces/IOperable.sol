// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/**
 * @title IOperable - Simple function caller authorization interface.
 * @author cyotee doge <doge.cyotee>
 */
interface IOperable {
    /**
     * @param caller Caller that failed Operator status validation.
     */
    error NotOperator(address caller);

    event NewGlobalOperatorStatus(address newOperator, bool status);
    event NewFunctionOperatorStatus(address newOperator, bytes4 func, bool status);

    /**
     * @param query Address for which to query authorization as an operator.
     * @return Boolean indicating if query is authorized as an operator
     * @custom:func-sig isOperator(address)
     * @custom:func-sig-hash 6d70f7ae
     * @custom:selector 0x6d70f7ae
     *
     */
    function isOperator(address query) external view returns (bool);

    /**
     * @param func Function selector for which to query operator authorization.
     * @param query Account for which to query authorization to call `func`.
     * @custom:selector 0xea562a25
     */
    function isOperatorFor(bytes4 func, address query) external view returns (bool);

    /**
     * @param newOperator Address for which to change authorization.
     * @param approval Authorization status to set for newOperator.
     * @return Gas saving boolean indicating success.
     * @custom:func-sig setOperator(address,bool)
     * @custom:func-sig-hash 558a7297
     * @custom:selector 0x558a7297
     */
    function setOperator(address newOperator, bool approval) external returns (bool);

    /**
     * @param func Function selector for which to update authorization of `newOperator`.
     * @param newOperator Account for which to update authorization to call `func`.
     * @param approval Call authorization change.
     * @return Gas saving boolean indicating success.
     * @custom:selector 0x755dbe7c
     */
    function setOperatorFor(bytes4 func, address newOperator, bool approval) external returns (bool);
}
