// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.29;

import { ISystemContract } from "@crane/contracts/external/reactive-omni/interfaces/ISystemContract.sol";
import { IReactive } from "@crane/contracts/external/reactive-omni/interfaces/IReactive.sol";
import { AbstractPayer } from "@crane/contracts/external/reactive-omni/base/AbstractPayer.sol";

/**
 * @title Abstract base contract for reactive contracts.
 */
abstract contract AbstractReactive is AbstractPayer, IReactive {
    /// @notice Address of the system contract in the reactive network.
    ISystemContract internal constant SYSTEM = ISystemContract(payable(0x8888888888888888888888888888888888888888));

    /// @notice Predefined wildcard topic value for event subscriptions.
    uint256 internal constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

    constructor() AbstractPayer(SYSTEM) {
    }

    /// @notice A modifier for guarding methods that should only be called by the system contract (e.g., `react()`).
    modifier onlySystem() {
        _onlyServiceProvider();
        _;
    }
}
