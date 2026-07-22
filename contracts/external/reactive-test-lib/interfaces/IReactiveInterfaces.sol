// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/// @notice Minimal IPayable interface (ABI-compatible with reactive-lib).
interface IPayable {
    receive() external payable;
    function debt(address _contract) external view returns (uint256);
}

/// @notice Minimal ISubscriptionService interface (ABI-compatible with reactive-lib).
interface ISubscriptionService is IPayable {
    function subscribe(
        uint256 chain_id,
        address _contract,
        uint256 topic_0,
        uint256 topic_1,
        uint256 topic_2,
        uint256 topic_3
    ) external;

    function unsubscribe(
        uint256 chain_id,
        address _contract,
        uint256 topic_0,
        uint256 topic_1,
        uint256 topic_2,
        uint256 topic_3
    ) external;
}

/// @notice Minimal ISystemContract interface (ABI-compatible with reactive-lib).
interface ISystemContract is IPayable, ISubscriptionService {}

/// @notice Minimal IPayer interface (ABI-compatible with reactive-lib).
interface IPayer {
    function pay(uint256 amount) external;
    receive() external payable;
}

/// @notice LogRecord struct matching reactive-lib's IReactive.LogRecord.
struct LogRecord {
    uint256 chain_id;
    address _contract;
    uint256 topic_0;
    uint256 topic_1;
    uint256 topic_2;
    uint256 topic_3;
    bytes data;
    uint256 block_number;
    uint256 op_code;
    uint256 block_hash;
    uint256 tx_hash;
    uint256 log_index;
}

/// @notice Interface for calling react() on reactive contracts.
interface IReactive {
    function react(LogRecord calldata log) external;
}

/// @notice Result of a callback execution.
struct CallbackResult {
    uint256 chainId;
    address target;
    uint64 gasLimit;
    bytes payload;
    bool success;
    bytes returnData;
}

/// @notice Cron event trigger frequencies.
enum CronType {
    Cron1,
    Cron10,
    Cron100,
    Cron1000,
    Cron10000
}

/// @notice Interface for the chain registry used by the simulator for auto chain ID detection.
interface IChainRegistry {
    /// @notice Returns the chain ID for a given contract address, or 0 if not registered.
    function getChainId(address contractAddr) external view returns (uint256);
}
