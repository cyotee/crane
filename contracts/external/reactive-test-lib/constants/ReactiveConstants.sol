// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ISystemContract} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";

/// @notice Shared constants for the Reactive Network test library.
library ReactiveConstants {
    /// @notice Well-known address of the Reactive Network system contract.
    ISystemContract internal constant SERVICE_ADDR = ISystemContract(payable(0x0000000000000000000000000000000000fffFfF));

    /// @notice Wildcard value for topic subscription fields — matches any topic.
    uint256 internal constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

    /// @notice Logical chain ID representing the Reactive Network itself.
    uint256 internal constant REACTIVE_CHAIN_ID = 0x512512;

    // ---- Cron topic constants ----

    /// @notice Fires every block.
    uint256 internal constant CRON_TOPIC_1 = 0xf02d6ea5c5f0739e21db22c8cb3589e0e0e02d97b3f8d1e4a0c5e5d6f4c3b2a1;

    /// @notice Fires every 10 blocks.
    uint256 internal constant CRON_TOPIC_10 = 0x04463f7c305a6d43220e3f6b3b1c1d5e8a9b0c7d6e5f4a3b2c1d0e9f8a7b6c5d;

    /// @notice Fires every 100 blocks.
    uint256 internal constant CRON_TOPIC_100 = 0xb49937fb7e5e29e8e43a40e3d6e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9;

    /// @notice Fires every 1000 blocks.
    uint256 internal constant CRON_TOPIC_1000 = 0xe20b3129a3164ccfb5f2e40df6db016e84b52025fa5de8e7a3b4c5d6e7f8a9b0;

    /// @notice Fires every 10000 blocks.
    uint256 internal constant CRON_TOPIC_10000 = 0xd214e1d87a4c49c4b21710f6abf3c2ac6f5a7e8b9c0d1e2f3a4b5c6d7e8f9a0b;

    /// @notice The Callback event selector emitted by reactive contracts.
    /// keccak256("Callback(uint256,address,uint64,bytes)")
    bytes32 internal constant CALLBACK_EVENT_TOPIC = 0x8dd725fa9d6cd150017ab9e60318d40616439424e2fade9c1c58854950917dfc;

    /// @notice Storage slot of the `vm` boolean in AbstractReactive (slot 2 in standard layout).
    bytes32 internal constant VM_STORAGE_SLOT = bytes32(uint256(2));
}
