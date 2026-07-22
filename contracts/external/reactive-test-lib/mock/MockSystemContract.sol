// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ISystemContract, LogRecord} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";
import {ReactiveConstants} from "@crane/contracts/external/reactive-test-lib/constants/ReactiveConstants.sol";

/// @title MockSystemContract
/// @notice Simulates the Reactive Network system contract for local Foundry testing.
///         Stores subscriptions and provides matching logic used by the simulator.
contract MockSystemContract {
    struct Subscription {
        uint256 chainId;
        address contractAddr;
        uint256 topic0;
        uint256 topic1;
        uint256 topic2;
        uint256 topic3;
        address subscriber;
    }

    Subscription[] public subscriptions;

    // ---- ISubscriptionService ----

    function subscribe(
        uint256 chain_id,
        address _contract,
        uint256 topic_0,
        uint256 topic_1,
        uint256 topic_2,
        uint256 topic_3
    ) external {
        subscriptions.push(Subscription({
            chainId: chain_id,
            contractAddr: _contract,
            topic0: topic_0,
            topic1: topic_1,
            topic2: topic_2,
            topic3: topic_3,
            subscriber: msg.sender
        }));
    }

    function unsubscribe(
        uint256 chain_id,
        address _contract,
        uint256 topic_0,
        uint256 topic_1,
        uint256 topic_2,
        uint256 topic_3
    ) external {
        uint256 len = subscriptions.length;
        for (uint256 i = 0; i < len; i++) {
            Subscription storage sub = subscriptions[i];
            if (
                sub.subscriber == msg.sender &&
                sub.chainId == chain_id &&
                sub.contractAddr == _contract &&
                sub.topic0 == topic_0 &&
                sub.topic1 == topic_1 &&
                sub.topic2 == topic_2 &&
                sub.topic3 == topic_3
            ) {
                // Swap with last and pop
                subscriptions[i] = subscriptions[len - 1];
                subscriptions.pop();
                return;
            }
        }
        revert("MockSystemContract: subscription not found");
    }

    // ---- IPayable (no-op stubs) ----

    function debt(address) external pure returns (uint256) {
        return 0;
    }

    receive() external payable {}

    // ---- Query helpers for the simulator ----

    /// @notice Returns all subscriber addresses whose subscriptions match the given event.
    function getMatchingSubscribers(
        uint256 chainId,
        address contractAddr,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3
    ) external view returns (address[] memory) {
        uint256 len = subscriptions.length;
        // First pass: count matches
        uint256 count = 0;
        for (uint256 i = 0; i < len; i++) {
            if (_matches(subscriptions[i], chainId, contractAddr, topic0, topic1, topic2, topic3)) {
                count++;
            }
        }
        // Second pass: collect
        address[] memory result = new address[](count);
        uint256 idx = 0;
        for (uint256 i = 0; i < len; i++) {
            if (_matches(subscriptions[i], chainId, contractAddr, topic0, topic1, topic2, topic3)) {
                result[idx++] = subscriptions[i].subscriber;
            }
        }
        return result;
    }

    /// @notice Returns total number of active subscriptions.
    function subscriptionCount() external view returns (uint256) {
        return subscriptions.length;
    }

    // ---- Internal matching logic ----

    function _matches(
        Subscription storage sub,
        uint256 chainId,
        address contractAddr,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3
    ) internal view returns (bool) {
        uint256 RI = ReactiveConstants.REACTIVE_IGNORE;

        // Chain ID: 0 = wildcard
        if (sub.chainId != 0 && sub.chainId != chainId) return false;

        // Contract address: address(0) = wildcard
        if (sub.contractAddr != address(0) && sub.contractAddr != contractAddr) return false;

        // Topics: REACTIVE_IGNORE = wildcard
        if (sub.topic0 != RI && sub.topic0 != topic0) return false;
        if (sub.topic1 != RI && sub.topic1 != topic1) return false;
        if (sub.topic2 != RI && sub.topic2 != topic2) return false;
        if (sub.topic3 != RI && sub.topic3 != topic3) return false;

        return true;
    }
}
