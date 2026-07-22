// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/// @notice Minimal cron-based reactive contract for testing.
contract SampleCronContract {
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
    uint256 public lastCronBlock;
    bool public paused;

    constructor(
        address _systemContract,
        uint256 _cronTopic,
        uint256 _destChainId,
        address _callbackTarget
    ) {
        callbackTarget = _callbackTarget;
        destChainId = _destChainId;

        // Subscribe to cron events on the reactive chain
        (bool ok,) = _systemContract.call(
            abi.encodeWithSignature(
                "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
                uint256(0x512512), // REACTIVE_CHAIN_ID
                address(0),       // wildcard contract
                _cronTopic,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            )
        );
        require(ok, "subscribe failed");
    }

    function react(LogRecord calldata log) external {
        if (paused) return;

        lastCronBlock = log.block_number;

        bytes memory payload = abi.encodeWithSignature(
            "onCronCallback(address,uint256)",
            address(0), // RVM ID placeholder
            log.block_number
        );
        emit Callback(destChainId, callbackTarget, 100000, payload);
    }

    function pause() external {
        paused = true;
    }

    function resume() external {
        paused = false;
    }
}
