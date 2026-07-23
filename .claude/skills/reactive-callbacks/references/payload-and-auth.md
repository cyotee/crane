# Callback Payload and Authorization

Sources:
- https://dev.reactive.network/events-&-callbacks
- https://dev.reactive.network/reactive-library
- https://dev.reactive.network/legacy/debugging
- https://dev.reactive.network/legacy/reactvm

## System entry points

```solidity
function requestCallback(CallbackVersion version_, bytes memory config_) external;
function requestCallbackV_1_0(CallbackConfiguration_V_1_0 memory config_) external;

struct CallbackConfiguration_V_1_0 {
    uint256 chainId;
    address recipient;
    uint64 gasLimit;
    bytes payload;
}
```

Prefer `requestCallbackV_1_0` — typed, no manual version encoding.

## Authorization model

### Network side

Reactive injects identity into the **first 160 bits** of the payload before destination execution. Contracts cannot forge a different RVM/RC identity by choosing another first arg — the network overwrites it.

### Destination side

Two complementary checks:

1. **msg.sender is Callback Proxy** (or authorized service address for same-chain).
2. **Injected address equals expected Reactive contract / RVM ID**.

`AbstractCallback`:

- Stores `_CALLBACK_SENDER`
- `onlyCallbackSender` reverts `CallbackNotAuthorized(actual, expected)`

Constructor pattern from docs:

```solidity
constructor(IPayable callbackProxy_, address callbackSender_)
    AbstractPayer(callbackProxy_)
{
    _CALLBACK_SENDER = callbackSender_;
}
```

## Encoding checklist

- [ ] Function signature includes leading `address` parameter
- [ ] Encode `address(0)` (or any placeholder) in that slot
- [ ] `gasLimit >= 100_000`
- [ ] `recipient` is the destination contract that implements the function
- [ ] `chainId` is destination network (mainnet↔mainnet or testnet↔testnet only)

## Legacy emit Callback

Still used in demos:

```solidity
emit Callback(destinationChainId, callback, GAS_LIMIT, payload);
```

Marked **deprecated** on `IReactive` in omni docs. Behavior equivalent for network pickup when system is configured for event-based callbacks.

## Debugging failed callbacks

From debugging docs:

- Missing first arg → hard fail
- Inactive contract (underfunded) → no execution
- Wrong proxy address on destination constructor → auth reverts
- MetaMask Smart Transactions can break faucet/bridge flows on Reactive (disable Smart Transactions)

## Example from Uniswap stop-order demo

```solidity
bytes memory payload = abi.encodeWithSignature(
    "stop(address,address,address,bool,uint256,uint256)",
    address(0),
    pair,
    client,
    token0,
    coefficient,
    threshold
);
emit Callback(chain_id, stop_order, CALLBACK_GAS_LIMIT, payload);
```

Repo: https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/uniswap-v2-stop-order/
