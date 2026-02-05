// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { ISenderGuard } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ISenderGuard.sol";

import { StorageSlotExtension } from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/openzeppelin/StorageSlotExtension.sol";
import {
    TransientStorageHelpers
} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/TransientStorageHelpers.sol";

/**
 * @notice Abstract base contract for functions shared among all Routers.
 * @dev Common functionality includes access to the sender (which would normally be obscured, since msg.sender in the
 * Vault is the Router contract itself, not the account that invoked the Router), versioning, and the external
 * invocation functions (`permitBatchAndCall` and `multicall`).
 */
abstract contract SenderGuardCommon {
    using StorageSlotExtension for *;

    // NOTE: If you use a constant, then it is simply replaced everywhere when this constant is used by what is written
    // after =. If you use immutable, the value is first calculated and then replaced everywhere. That means that if a
    // constant has executable variables, they will be executed every time the constant is used.

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _SENDER_SLOT = TransientStorageHelpers.calculateSlot("SenderGuard", "sender");

    // Raw token balances are stored in half a slot, so the max is uint128. Moreover, given that amounts are usually
    // scaled inside the Vault, sending type(uint256).max would result in an overflow and revert.
    uint256 internal constant _MAX_AMOUNT = type(uint128).max;

    function _saveSender(address sender) internal returns (bool isExternalSender) {
        address savedSender = _getSenderSlot().tload();

        // NOTE: Only the most external sender will be saved by the Router.
        if (savedSender == address(0)) {
            _getSenderSlot().tstore(sender);
            isExternalSender = true;
        }
    }

    function _discardSenderIfRequired(bool isExternalSender) internal {
        // Only the external sender shall be cleaned up; if it's not an external sender it means that
        // the value was not saved in this modifier.
        if (isExternalSender) {
            _getSenderSlot().tstore(address(0));
        }
    }

    constructor() {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _getSenderSlot() internal view returns (StorageSlotExtension.AddressSlotType) {
        return _SENDER_SLOT.asAddress();
    }

    function _getSender() internal view returns (address) {
        return _getSenderSlot().tload();
    }
}
