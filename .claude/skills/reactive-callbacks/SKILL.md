---
name: reactive-callbacks
description: >
  Guides Reactive Network callback integration: requestCallback / requestCallbackV_1_0,
  CallbackConfiguration_V_1_0, first-argument RVM ID overwrite, AbstractCallback and
  onlyCallbackSender, Callback Proxy validation, minimum gas limits, and destination contract
  patterns. Use when the user asks about "callback", "requestCallback", "AbstractCallback",
  "onlyCallbackSender", "Callback Proxy", "destination contract", or "cross-chain callback payload".
license: MIT
---

# Reactive Callbacks & Destination Contracts

After `react()` decides to act, the RC asks the **system contract** to deliver a **callback transaction** to a **destination** contract (same or other chain). Destination code must **authorize** the network entry point and the originating RC identity.

Sources: [Events & Callbacks](https://dev.reactive.network/events-&-callbacks), [Reactive Library](https://dev.reactive.network/reactive-library), [Debugging](https://dev.reactive.network/legacy/debugging), [Origins](https://dev.reactive.network/legacy/origins-and-destinations).

## Preferred API (omni)

```solidity
function requestCallbackV_1_0(CallbackConfiguration_V_1_0 memory config_) external;

struct CallbackConfiguration_V_1_0 {
    uint256 chainId;   // destination
    address recipient; // target contract
    uint64 gasLimit;   // execution gas
    bytes payload;     // ABI-encoded call
}
```

Also available: generic `requestCallback(CallbackVersion version_, bytes config_)`.

Both emit the same internal `CallbackRequest` path; network then submits the destination tx.

**Deprecated:** emitting `IReactive.Callback` directly — still common in demos; new code should use system methods.

## First argument is identity (mandatory)

> Reactive overwrites the **first 160 bits** of the callback payload with the reactive/RVM identity. The first Solidity argument is always an `address`, regardless of its name. Destination contracts using `AbstractCallback` verify via `onlyCallbackSender`.

Rules:

1. Encode **at least one** argument; first slot is for identity.
2. Pass `address(0)` as placeholder in the payload.
3. Omitting the first slot → callback fails.

```solidity
bytes memory payload = abi.encodeWithSignature(
    "onAction(address,uint256)",
    address(0), // overwritten
    amount
);
// Omni:
// SYSTEM.requestCallbackV_1_0(CallbackConfiguration_V_1_0({
//     chainId: destChainId,
//     recipient: destContract,
//     gasLimit: 1_000_000,
//     payload: payload
// }));
// Legacy demos:
// emit Callback(destChainId, destContract, GAS_LIMIT, payload);
```

## Destination contract pattern

```solidity
contract MyDestination is AbstractCallback {
    constructor(IPayable callbackProxy_, address expectedReactive_)
        AbstractCallback(callbackProxy_, expectedReactive_)
    {}

    function onAction(address /* rvmOrSender */, uint256 amount)
        external
        onlyCallbackSender(/* see library: may take expected sender */)
    {
        // effect
    }
}
```

Docs show:

```solidity
modifier onlyCallbackSender(address callbackSender_) {
    _onlyCallbackSender(callbackSender_);
    _;
}
// reverts CallbackNotAuthorized if mismatch
```

Constructor sets `_CALLBACK_SENDER` to the authorized reactive contract and wires payer to the **callback proxy**.

Validate:

1. Call comes through **Callback Proxy** (library/proxy pattern).
2. Embedded identity matches expected RC.

Proxy addresses: `skill:reactive-architecture` → origins table, or `skill:reactive-deployment`.

## Gas limits

| Rule | Value |
|------|-------|
| Minimum callback gas limit | **100_000** (below → ignored) |
| Demo basic GAS_LIMIT | often `1_000_000` |
| RVM tx max gas (economy) | 900_000 |

## Payment model (destination)

Callbacks use the same **execute first, account later** model. Destination callback contracts need balance / reserves or they go **inactive**.

- Fund: `cast send $CALLBACK_ADDR --value ...`
- Settle: `coverDebt()` or inherit `AbstractPayer` so proxy can call `pay()`
- Or `callbackProxy.depositTo(callbackAddr)`

See `skill:reactive-deployment` economy section.

## Hyperlane transport

If a chain has no Callback Proxy yet, use **Hyperlane mailboxes** as alternate transport. Reactive still listens and decides; only delivery path changes. Demo: `src/demos/hyperlane`. Mailbox addresses: `skill:reactive-deployment`.

## Read by task

| Need | Open |
|------|------|
| Payload + authorization detail | [references/payload-and-auth.md](references/payload-and-auth.md) |
| Full architecture flow | `skill:reactive-architecture` |
| Funding inactive contracts | `skill:reactive-deployment` |

## Gotchas

- First arg always reserved — design ABI with leading `address`.
- `onlyCallbackSender` / proxy checks are security-critical; never leave callback functions public without auth.
- Self-callbacks (destination = Reactive Network / self) appear in bridges; test-lib routes them via `SERVICE_ADDR`.
- Legacy field names (`topic_3`, `vmOnly`) differ from omni — match imported interfaces.

## See also

- `skill:reactive-contracts` — `react()` and subscriptions  
- `skill:reactive-integrations` — Basic Demo origin/RC/callback trio  
- `skill:reactive-deployment` — proxies, Hyperlane, funding  
