# Reactive Library Surface (omni)

Source: https://dev.reactive.network/reactive-library  
Repo: https://github.com/Reactive-Network/reactive-lib-omni

## Install

```bash
forge install Reactive-Network/reactive-lib-omni
```

## Abstract contracts

### AbstractReactive

Base for RCs:

- `SYSTEM` — system contract `0x8888888888888888888888888888888888888888`
- `REACTIVE_IGNORE` — topic wildcard
- `onlySystem` — restrict `react` (and similar) to system contract
- Constructor wires `AbstractPayer(SYSTEM)` for payments

### AbstractPayer

- `_SERVICE_PROVIDER` — system or callback proxy that may request payments
- `onlyServiceProvider` / `pay(uint256 amount_)`
- `_coverDebt()` — settle outstanding debt with provider
- `_pay` — balance check + call{value}; reverts `InsufficientFunds` / `TransferFailed`
- `receive() external payable`

### AbstractCallback

For **destination** contracts — see `skill:reactive-callbacks`.

- Constructor: `(IPayable callbackProxy_, address callbackSender_)`
- `onlyCallbackSender` — first-arg / sender authorization against `_CALLBACK_SENDER`

## Interfaces

### IPayable

```solidity
receive() external payable;
function debt(address contract_) external view returns (uint256 debt_);
```

### IPayer

```solidity
function pay(uint256 amount_) external;
receive() external payable;
```

### IReactive

```solidity
struct LogRecord { /* see SKILL.md */ }
function react(LogRecord calldata log_) external;

// Deprecated — use system requestCallback* instead
event Callback(
    uint256 indexed chainId_,
    address indexed contract_,
    uint64 indexed gasLimit_,
    bytes payload_
);
```

### ISubscriptionService

```solidity
function subscribe(uint256 chainId_, address contract_, uint256 topic0_, uint256 topic1_, uint256 topic2_, uint256 topic3_) external;
function unsubscribe(uint256 chainId_, address contract_, uint256 topic0_, uint256 topic1_, uint256 topic2_, uint256 topic3_) external;
```

### ISystemContract

Combines payable + subscription + callbacks:

```solidity
enum CallbackVersion { V_1_0 }

struct CallbackConfiguration_V_1_0 {
    uint256 chainId;
    address recipient;
    uint64 gasLimit;
    bytes payload;
}

function requestCallback(CallbackVersion version_, bytes memory config_) external;
function requestCallbackV_1_0(CallbackConfiguration_V_1_0 memory config_) external;
```

## CRON (time-based automation)

Legacy system contract `0x0000000000000000000000000000000000fffFfF` emits interval events. Subscribe by topic0:

| Event | Interval | Approx time | Topic 0 |
|-------|----------|-------------|---------|
| Cron1 | every block | ~7s | `0xf02d6ea5c22a71cffe930a4523fcb4f129be6c804db50e4202fb4e0b07ccb514` |
| Cron10 | 10 blocks | ~1 min | `0x04463f7c1651e6b9774d7f85c85bb94654e3c46ca79b0c16fb16d4183307b687` |
| Cron100 | 100 blocks | ~12 min | `0xb49937fb8970e19fd46d48f7e3fb00d659deac0347f79cd7cb542f0fc1503c70` |
| Cron1000 | 1000 blocks | ~2 h | `0xe20b31294d84c3661ddc8f423abb9c70310d0cf172aa2714ead78029b325e3f4` |
| Cron10000 | 10_000 blocks | ~28 h | `0xd214e1d84db704ed42d37f538ea9bf71e44ba28bc1cc088b2f5deca654677a56` |

Only authorized validator roots call `cron()`; each event carries current `number` (block).

Demo: https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/cron
