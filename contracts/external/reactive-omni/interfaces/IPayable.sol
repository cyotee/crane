// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.29;

/**
 * @title Common interface for the system contract and the callback proxy, allows contracts to check and pay their debts.
 */
interface IPayable {
    /// @notice Allows contracts to pay their debts and resume subscriptions.
    receive() external payable;

    /// @notice Allows reactive contracts to check their outstanding debt.
    /// @param contract_ Reactive contract's address.
    /// @return debt_ Reactive contract's current debt due to unpaid reactive transactions and/or callbacks.
    function debt(address contract_) external view returns (uint256 debt_);
}
