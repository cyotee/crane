// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.29;

import { IPayable } from "@crane/contracts/external/reactive-omni/interfaces/IPayable.sol";
import { AbstractPayer } from "@crane/contracts/external/reactive-omni/base/AbstractPayer.sol";

/**
 * @title Abstract base contract for contracts receiving the Reactive Network callbacks.
 */
abstract contract AbstractCallback is AbstractPayer {
    /// @notice Indicates that the callback sender is not authorized to perform the requested action.
    /// @param sender_ Address of the callback sender.
    /// @param expectedSender_ Expected callback sender.
    error CallbackNotAuthorized(address sender_, address expectedSender_);

    /// @notice Address of the reactive contract allowed to send callbacks.
    address public immutable _CALLBACK_SENDER;

    /// @param callbackProxy_ Address of the authorized callback proxy.
    /// @param callbackSender_ Address of the reactive contract allowed to send callbacks to this contract.
    constructor(IPayable callbackProxy_, address callbackSender_) AbstractPayer(callbackProxy_) {
        _CALLBACK_SENDER = callbackSender_;
    }

    /// @notice A modifier for guarding callback functions.
    /// @param callbackSender_ Address of the callback sender received from the callback proxy in the callback payload.
    modifier onlyCallbackSender(address callbackSender_) {
        _onlyCallbackSender(callbackSender_);
        _;
    }

    /// @notice The implementation of the `onlyCallbackSender` modifier.
    /// @param callbackSender_ Address of the callback sender received from the callback proxy in the callback payload.
    function _onlyCallbackSender(address callbackSender_) internal view {
        if (callbackSender_ != _CALLBACK_SENDER) {
            revert CallbackNotAuthorized(callbackSender_, _CALLBACK_SENDER);
        }
    }
}
