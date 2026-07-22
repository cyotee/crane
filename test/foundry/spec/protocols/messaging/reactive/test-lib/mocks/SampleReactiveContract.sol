// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/// @notice Minimal reactive contract for testing — does NOT inherit from AbstractReactive
///         to avoid circular dependencies. Mimics the same interface.
contract SampleReactiveContract {
    uint256 internal constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

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

    event Callback(
        uint256 indexed chain_id,
        address indexed _contract,
        uint64 indexed gas_limit,
        bytes payload
    );

    address public callbackTarget;
    uint256 public destChainId;
    uint256 public threshold;
    uint256 public reactCallCount;

    constructor(
        address _systemContract,
        uint256 _originChainId,
        uint256 _destChainId,
        address _originContract,
        uint256 _topic0,
        address _callbackTarget
    ) {
        callbackTarget = _callbackTarget;
        destChainId = _destChainId;

        // Subscribe via the system contract
        (bool ok,) = _systemContract.call(
            abi.encodeWithSignature(
                "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
                _originChainId,
                _originContract,
                _topic0,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            )
        );
        require(ok, "subscribe failed");
    }

    function react(LogRecord calldata log) external {
        reactCallCount++;

        // Decode the amount from the event data
        uint256 amount = abi.decode(log.data, (uint256));

        // Only fire callback if amount > 0.001 ether
        if (amount > 0.001 ether) {
            bytes memory payload = abi.encodeWithSignature(
                "onCallback(address,uint256)",
                address(0), // placeholder — RVM ID will be injected here
                amount
            );
            emit Callback(destChainId, callbackTarget, 100000, payload);
        }
    }
}
