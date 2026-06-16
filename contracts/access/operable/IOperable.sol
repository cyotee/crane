// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

// tag::IOperable[]
/**
 * @title IOperable - Simple function caller authorization interface.
 * @author cyotee doge <doge.cyotee>
 * @notice Interface for global and per-function operator based access control.
 *         Used to authorize callers for protected functions without full ownership.
 * @custom:interfaceid 0xa7f11160
 */
interface IOperable {
    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    // tag::NewGlobalOperatorStatus(address-bool)[]
    /**
     * @notice Emitted when a global operator approval status changes.
     * @param operator The operator whose approval status has changed.
     * @param status The operator's new approval status.
     * @custom:topic-signature NewGlobalOperatorStatus(address,bool)
     * @custom:topiczero 0x26ba28058a3c072a70c8fd315037fe9b3957237cef5c61a9652a8da41c673daa
     */
    event NewGlobalOperatorStatus(address operator, bool status);
    // end::NewGlobalOperatorStatus(address-bool)[]

    // tag::NewFunctionOperatorStatus(address-bytes4-bool)[]
    /**
     * @notice Emitted when function level operator approval status changes.
     * @param operator The operator whose approval status has changed.
     * @param func The function for which the operator's approval status has changed.
     * @param status The operator's new approval status.
     * @custom:topic-signature NewFunctionOperatorStatus(address,bytes4,bool)
     * @custom:topiczero 0xf071216dc06459e77b915d1883909d92f41239172000b60261dfdc0351889569
     */
    event NewFunctionOperatorStatus(address operator, bytes4 func, bool status);
    // end::NewFunctionOperatorStatus(address-bytes4-bool)[]

    /* -------------------------------------------------------------------------- */
    /*                                   Errors                                   */
    /* -------------------------------------------------------------------------- */

    // tag::NotOperator(address)[]
    /**
     * @notice Thrown when a caller that is not an authorized operator attempts a restricted action.
     * @param caller Caller that failed Operator status validation.
     * @custom:signature NotOperator(address)
     * @custom:selector 0x76c6c93a
     */
    error NotOperator(address caller);
    // end::NotOperator(address)[]

    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::isOperator(address)[]
    /**
     * @notice Returns whether `query` is authorized as a global operator (for all functions).
     * @param query Address for which to query authorization as an operator.
     * @return True if the address is authorized as an operator.
     * @custom:signature isOperator(address)
     * @custom:selector 0x6d70f7ae
     */
    function isOperator(address query) external view returns (bool);
    // end::isOperator(address)[]

    // tag::isOperatorFor(bytes4-address)[]
    /**
     * @notice Returns whether `query` is authorized to call the specific function `func`.
     * @param func Function selector for which to query operator authorization.
     * @param query Account for which to query authorization to call `func`.
     * @return True if the account is authorized for the given function selector.
     * @custom:signature isOperatorFor(bytes4,address)
     * @custom:selector 0xea562a25
     */
    function isOperatorFor(bytes4 func, address query) external view returns (bool);
    // end::isOperatorFor(bytes4-address)[]

    // tag::setOperator(address-bool)[]
    /**
     * @notice Sets (or revokes) global operator status for an address.
     * @param newOperator Address for which to change authorization.
     * @param approval Authorization status to set for newOperator.
     * @return True on success (gas-saving return value).
     * @custom:signature setOperator(address,bool)
     * @custom:selector 0x558a7297
     * @custom:emits NewGlobalOperatorStatus(address,bool)
     * @custom:throws NotOperator(address)
     */
    function setOperator(address newOperator, bool approval) external returns (bool);
    // end::setOperator(address-bool)[]

    // tag::setOperatorFor(bytes4-address-bool)[]
    /**
     * @notice Sets (or revokes) per-function operator status for an address on a specific selector.
     * @param func Function selector for which to update authorization of `newOperator`.
     * @param newOperator Account for which to update authorization to call `func`.
     * @param approval Call authorization change.
     * @return True on success (gas-saving return value).
     * @custom:signature setOperatorFor(bytes4,address,bool)
     * @custom:selector 0x755dbe7c
     * @custom:emits NewFunctionOperatorStatus(address,bytes4,bool)
     * @custom:throws NotOperator(address)
     */
    function setOperatorFor(bytes4 func, address newOperator, bool approval) external returns (bool);
    // end::setOperatorFor(bytes4-address-bool)[]
}
// end::IOperable[]
