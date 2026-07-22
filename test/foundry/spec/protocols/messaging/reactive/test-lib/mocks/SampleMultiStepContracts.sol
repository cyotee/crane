// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/// @notice Simulates a simplified bridge protocol with multiple reactive hops:
///   1. User calls MiniOrigin.deposit() → emits Deposit event
///   2. MiniReactive.react() matches Deposit → emits Callback to MiniBridge.receiveDeposit()
///   3. MiniBridge.receiveDeposit() → emits Confirmation event
///   4. MiniReactive.react() matches Confirmation → emits self-Callback to MiniReactive.deliver()
///   5. MiniReactive.deliver() stores result

// ---- Origin (L1 deposit contract) ----

contract MiniOrigin {
    event Deposit(address indexed sender, uint256 indexed amount);

    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}

// ---- Bridge (L1 bridge contract that confirms deposits) ----

contract MiniBridge {
    event Confirmation(
        uint256 indexed depositId,
        address indexed sender,
        uint256 indexed amount
    );

    address public authorizedSender;

    uint256 public lastDepositId;
    uint256 public confirmationCount;

    constructor(address _callbackSender) {
        authorizedSender = _callbackSender;
    }

    function receiveDeposit(address /* rvmId */, uint256 depositId, address sender, uint256 amount) external {
        // In a real scenario, would check authorizedSender
        lastDepositId = depositId;
        confirmationCount++;
        emit Confirmation(depositId, sender, amount);
    }
}

// ---- Reactive Contract (subscribes to both chains, performs multi-step protocol) ----

contract MiniReactive {
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

    uint256 public originChainId;
    uint256 public destChainId;
    uint256 public rnChainId;
    address public bridgeAddr;

    // Delivery tracking
    uint256 public deliveredAmount;
    address public deliveredSender;
    uint256 public deliveryCount;

    // Auth
    mapping(address => bool) public authorizedSenders;

    uint256 private constant DEPOSIT_TOPIC = 0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c;
    uint256 private constant CONFIRMATION_TOPIC = 0xa37a53be3e077363939b60e1f4e37f25f2367f12dc6e7d4f6ad47a66c5948983;

    constructor(
        address _systemContract,
        uint256 _originChainId,
        uint256 _destChainId,
        uint256 _rnChainId,
        address _originContract,
        address _bridgeAddr
    ) {
        originChainId = _originChainId;
        destChainId = _destChainId;
        rnChainId = _rnChainId;
        bridgeAddr = _bridgeAddr;
        authorizedSenders[_systemContract] = true;

        // Subscribe to Deposit events from origin
        uint256 depositTopic = uint256(keccak256("Deposit(address,uint256)"));
        (bool ok,) = _systemContract.call(
            abi.encodeWithSignature(
                "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
                _originChainId, _originContract, depositTopic, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
            )
        );
        require(ok, "subscribe deposit failed");

        // Subscribe to Confirmation events from bridge
        uint256 confirmTopic = uint256(keccak256("Confirmation(uint256,address,uint256)"));
        (ok,) = _systemContract.call(
            abi.encodeWithSignature(
                "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
                _destChainId, _bridgeAddr, confirmTopic, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
            )
        );
        require(ok, "subscribe confirmation failed");
    }

    function react(LogRecord calldata log) external {
        uint256 depositTopic = uint256(keccak256("Deposit(address,uint256)"));
        uint256 confirmTopic = uint256(keccak256("Confirmation(uint256,address,uint256)"));

        if (log.topic_0 == depositTopic) {
            // Step 1: Deposit detected → send callback to bridge
            address sender = address(uint160(log.topic_1));
            uint256 amount = log.topic_2;
            uint256 depositId = uint256(keccak256(abi.encode(sender, amount, block.number)));

            bytes memory payload = abi.encodeWithSignature(
                "receiveDeposit(address,uint256,address,uint256)",
                address(0), // RVM ID placeholder
                depositId,
                sender,
                amount
            );
            emit Callback(destChainId, bridgeAddr, 500000, payload);

        } else if (log.topic_0 == confirmTopic) {
            // Step 2: Confirmation received → self-callback to deliver
            uint256 amount = log.topic_3;
            address sender = address(uint160(log.topic_2));

            bytes memory payload = abi.encodeWithSignature(
                "deliver(address,address,uint256)",
                address(0), // RVM ID placeholder
                sender,
                amount
            );
            emit Callback(rnChainId, address(this), 500000, payload);
        }
    }

    /// @notice Self-callback: final delivery step.
    function deliver(address /* rvmId */, address sender, uint256 amount) external {
        require(authorizedSenders[msg.sender], "Authorized sender only");
        deliveredSender = sender;
        deliveredAmount = amount;
        deliveryCount++;
    }
}
