# ReactVM and Dual-State Environment

Sources:
- https://dev.reactive.network/legacy/reactvm
- https://dev.reactive.network/legacy/reactive-contracts

## What ReactVM is

**ReactVM** is a private execution environment where Reactive Contracts process events. Each deployed RC is assigned a ReactVM derived from the **deployer's address**. Contracts from the same EOA share a ReactVM and can share state; separating contracts across ReactVMs is generally recommended.

When a subscribed event matches, logs are delivered into the ReactVM; the contract runs Solidity logic and may request destination callbacks. ReactVMs execute independently (parallel across RVMs, deterministic within one RVM).

## Dual-state environment

| Instance | When state updates | Typical responsibilities |
|----------|--------------------|---------------------------|
| ReactVM state | Subscribed events | Vote tallies, automation counters, threshold logic |
| Reactive Network state | EOA / public calls | `pause()`, admin, subscription management |

Same bytecode; **states are not shared**. Detect environment via library flags (`vm`) or system-contract probes (demo pattern: system call reverts outside ReactVM).

## Subscriptions vs ReactVM

Calling `subscribe()` / `unsubscribe()` **inside ReactVM has no effect**. Manage filters on the **Reactive Network** instance. ReactVM logic should use callbacks (including self-callbacks) rather than assuming subscription APIs work in RVM.

## Callback identity (RVM ID)

When constructing a callback payload, **reserve the first argument** for identity:

- Developers pass `address(0)` as a placeholder.
- Reactive Network overwrites the first **160 bits** with the **RVM ID** (deployer-related address) before delivery.
- Omitting the first slot causes failure — the system needs a place to inject identity.
- Destination contracts use this first `address` to authorize the expected RC.

Legacy demo pattern (Uniswap stop order):

```solidity
bytes memory payload = abi.encodeWithSignature(
    "stop(address,address,address,bool,uint256,uint256)",
    address(0), // overwritten with RVM ID
    pair,
    client,
    token0,
    coefficient,
    threshold
);
emit Callback(chain_id, stop_order, CALLBACK_GAS_LIMIT, payload);
```

Omni docs describe the same first-argument overwrite when using `requestCallback` / `requestCallbackV_1_0`, with destination `AbstractCallback.onlyCallbackSender`.

## Reorg tracking

ReactVM blocks reference origin-chain block numbers and hashes so Reactive can track and handle origin reorganizations. Overall network state is the combination of ReactVM states.

## Limitations

Inside ReactVM, contracts **cannot** call external RPC endpoints or off-chain services. They receive logs from the network and may emit/request callbacks only.
