// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/// @notice Reactive contract that emits a self-callback (targets itself on the reactive chain).
///         Mimics the ReactiveBridge pattern where react() emits Callback(reactive_chain_id, address(this), ...).
contract SampleSelfCallbackContract {
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

    uint256 public reactiveChainId;
    uint256 public deliveredAmount;
    address public deliveredRvmId;
    uint256 public deliveryCount;

    /// @notice Authorized sender (SERVICE_ADDR for same-chain callbacks).
    mapping(address => bool) public authorizedSenders;

    constructor(
        address _systemContract,
        uint256 _reactiveChainId,
        uint256 _originChainId,
        address _originContract,
        uint256 _topic0
    ) {
        reactiveChainId = _reactiveChainId;

        // Authorize SERVICE_ADDR as callback sender (same as ReactiveBridge does)
        authorizedSenders[_systemContract] = true;

        // Subscribe to origin events
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

    /// @notice react() emits a self-callback targeting this contract on the reactive chain.
    function react(LogRecord calldata log) external {
        uint256 amount = abi.decode(log.data, (uint256));

        // Self-callback: target is address(this), chain is reactiveChainId
        bytes memory payload = abi.encodeWithSignature(
            "deliver(address,uint256)",
            address(0), // RVM ID placeholder
            amount
        );
        emit Callback(reactiveChainId, address(this), 500000, payload);
    }

    /// @notice Callback entry point — called via SERVICE_ADDR for same-chain delivery.
    function deliver(address _rvmId, uint256 amount) external {
        require(authorizedSenders[msg.sender], "Authorized sender only");
        deliveredRvmId = _rvmId;
        deliveredAmount = amount;
        deliveryCount++;
    }
}
