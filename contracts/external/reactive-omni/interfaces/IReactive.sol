// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.29;

import { IPayer } from "@crane/contracts/external/reactive-omni/interfaces/IPayer.sol";

/**
 * @title Interface for reactive contracts.
 * @notice Reactive contracts receive notifications about new events matching the criteria of their event subscriptions.
 */
interface IReactive is IPayer {
    /// @notice A standard representation of log records from EVM-style networks.
    struct LogRecord {
        uint256 chainId;
        address contractAddress;
        uint256 topic0;
        uint256 topic1;
        uint256 topic2;
        uint256 topic3;
        bytes data;
        uint256 blockNumber;
        uint256 opCode;
        uint256 blockHash;
        uint256 txHash;
        uint256 logIndex;
    }

    /// @notice This event can be emitted to request an old-style callback to a destination network.
    /// @dev Deprecated and should not be used for new development. Use the system contract's `requestCallback()` and `requestCallback_V_*_*()` methods.
    /// @param chainId_ Chain ID of the destination chain.
    /// @param contract_ Contract address to be called.
    /// @param gasLimit_ Gas limit for the transaction.
    /// @param payload_ ABI-encoded transaction payload for the callback.
    /// @dev Make sure the `payload_` reserves its first argument as an `address` where the address of the calling contract will be injected for authentication purposes.
    event Callback(
        uint256 indexed chainId_,
        address indexed contract_,
        uint64 indexed gasLimit_,
        bytes payload_
    );

    /// @notice Entry point for handling new event notifications.
    /// @param log_ Data structure containing the information about the intercepted log record.
    /// @dev Will be called by the network's system contract, make sure to authenticate calls.
    function react(LogRecord calldata log_) external;
}
