// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.29;

/**
 * @title Interface for event subscription service.
 * @notice Reactive contracts receive notifications about new events matching the criteria of their event subscriptions.
 */
interface ISubscriptionService {
    /// @notice Subscribes the calling contract to receive events matching the criteria specified.
    /// @param chainId_ EIP155 source chain ID for the event (as a `uint256`), or `0` for all chains.
    /// @param contract_ Contract address to monitor, or `0` for all contracts.
    /// @param topic0_ Topic 0 to monitor, or `REACTIVE_IGNORE` for all topics.
    /// @param topic1_ Topic 1 to monitor, or `REACTIVE_IGNORE` for all topics.
    /// @param topic2_ Topic 2 to monitor, or `REACTIVE_IGNORE` for all topics.
    /// @param topic3_ Topic 3 to monitor, or `REACTIVE_IGNORE` for all topics.
    function subscribe(
        uint256 chainId_,
        address contract_,
        uint256 topic0_,
        uint256 topic1_,
        uint256 topic2_,
        uint256 topic3_
    ) external;

    /// @notice Removes active subscription of the calling contract, matching the criteria specified, if one exists.
    /// @param chainId_ Chain ID criterion of the original subscription.
    /// @param contract_ Contract address criterion of the original subscription.
    /// @param topic0_ Topic 0 criterion of the original subscription.
    /// @param topic1_ Topic 0 criterion of the original subscription.
    /// @param topic2_ Topic 0 criterion of the original subscription.
    /// @param topic3_ Topic 0 criterion of the original subscription.
    function unsubscribe(
        uint256 chainId_,
        address contract_,
        uint256 topic0_,
        uint256 topic1_,
        uint256 topic2_,
        uint256 topic3_
    ) external;
}
