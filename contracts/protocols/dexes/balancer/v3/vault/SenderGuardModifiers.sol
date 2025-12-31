// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { ISenderGuard } from "@balancer-labs/v3-interfaces/contracts/vault/ISenderGuard.sol";

import { StorageSlotExtension } from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/StorageSlotExtension.sol";
import {
    TransientStorageHelpers
} from "@balancer-labs/v3-solidity-utils/contracts/helpers/TransientStorageHelpers.sol";
import {SenderGuardCommon} from "@crane/contracts/protocols/dexes/balancer/v3/vault/SenderGuardCommon.sol";

/**
 * @notice Abstract base contract for functions shared among all Routers.
 * @dev Common functionality includes access to the sender (which would normally be obscured, since msg.sender in the
 * Vault is the Router contract itself, not the account that invoked the Router), versioning, and the external
 * invocation functions (`permitBatchAndCall` and `multicall`).
 */
abstract contract SenderGuardModifiers is SenderGuardCommon {
    /**
     * @notice Saves the user or contract that initiated the current operation.
     * @dev It is possible to nest router calls (e.g., with reentrant hooks), but the sender returned by the Router's
     * `getSender` function will always be the "outermost" caller. Some transactions require the Router to identify
     * multiple senders. Consider the following example:
     *
     * - ContractA has a function that calls the Router, then calls ContractB with the output. ContractB in turn
     * calls back into the Router.
     * - Imagine further that ContractA is a pool with a "before" hook that also calls the Router.
     *
     * When the user calls the function on ContractA, there are three calls to the Router in the same transaction:
     * - 1st call: When ContractA calls the Router directly, to initiate an operation on the pool (say, a swap).
     *             (Sender is contractA, initiator of the operation.)
     *
     * - 2nd call: When the pool operation invokes a hook (say onBeforeSwap), which calls back into the Router.
     *             This is a "nested" call within the original pool operation. The nested call returns, then the
     *             before hook returns, the Router completes the operation, and finally returns back to ContractA
     *             with the result (e.g., a calculated amount of tokens).
     *             (Nested call; sender is still ContractA through all of this.)
     *
     * - 3rd call: When the first operation is complete, ContractA calls ContractB, which in turn calls the Router.
     *             (Not nested, as the original router call from contractA has returned. Sender is now ContractB.)
     */
    modifier saveSender(address sender) {
        bool isExternalSender = _saveSender(sender);
        _;
        _discardSenderIfRequired(isExternalSender);
    }

}
