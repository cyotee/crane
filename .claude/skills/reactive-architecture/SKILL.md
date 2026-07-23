---
name: reactive-architecture
description: >
  Explains Reactive Network architecture for event-driven cross-chain automation: origin vs destination
  chains, Reactive Contracts, ReactVM dual-state, system contract, callback proxies, and end-to-end
  event→react→callback flow. Use when the user asks about "Reactive Network", "Reactive Contracts",
  "ReactVM", "RVM", "origin and destination", "on-chain automation", "if-this-then-that smart contracts",
  or how Reactive differs from bots/relayers.
license: MIT
---

# Reactive Network Architecture

Reactive Network is an **EVM-compatible automation chain** built around **Reactive Contracts (RCs)** — event-driven contracts that subscribe to logs on origin EVM chains and automatically trigger **callback transactions** on destination chains.

Sources: [Getting Started](https://dev.reactive.network/), [docs index](https://dev.reactive.network/docs/), [Origins & Destinations](https://dev.reactive.network/legacy/origins-and-destinations), [ReactVM](https://dev.reactive.network/legacy/reactvm).

## Core idea

| Role | What it is |
|------|------------|
| **Origin** | Chain where events are emitted and read (event source) |
| **Reactive contract** | Deployed on Reactive Network; receives matching logs via `react()`; decides when to callback |
| **Destination** | Chain where Reactive delivers a callback transaction (state change) |
| **Callback Proxy** | On-destination entry point that makes callbacks verifiable |

A single RC can subscribe to **multiple origins** and send callbacks to **one or more destinations**. Origin and destination need not be the same chain. **Do not mix mainnet with testnet** endpoints in one flow.

## End-to-end flow

```text
1. Origin contract emits log (topic0..3 + data)
2. Reactive filter matches subscription (chainId, contract, topics)
3. System contract calls RC.react(LogRecord)
4. RC logic decides action → requestCallback / emit Callback
5. Network submits destination tx via Callback Proxy (or Hyperlane mailbox)
6. Destination contract runs authorized callback function
```

## Dual deployment model (legacy / ReactVM docs)

Legacy docs describe each RC existing in **two environments** with the **same bytecode, separate state**:

| Environment | Updated when | Typical use |
|-------------|--------------|-------------|
| **Reactive Network (RNK)** | EOAs call public functions | Subscriptions, admin, funding |
| **ReactVM (RVM)** | Subscribed events fire | Automation logic in `react()` |

- ReactVMs run in parallel per deployer-derived identity.
- Calling `subscribe()` / `unsubscribe()` **inside ReactVM has no effect** — manage subscriptions on the RNK instance.
- Newer **omni** docs emphasize a single system contract delivering logs to `react()`; still read dual-state guidance when working with demos that use `vm` / `vmOnly` flags.

Detail: [references/reactvm-and-state.md](references/reactvm-and-state.md)

## System addresses (quick)

| Concept | Address (common) | Notes |
|---------|------------------|-------|
| System / service (AbstractReactive `SYSTEM`) | `0x8888…8888` | Omni library constant for system contract |
| Legacy SERVICE_ADDR / system | `0x0000…fffFfF` | Economy, test-lib, some demos |
| Reactive Mainnet chain ID | `1597` | RPC `https://mainnet-rpc.rnk.dev/` |
| Lasna Testnet chain ID | `5318007` | Omni RPC `https://lasna-omni-rpc.rnk.dev/` |

**Doc contradiction:** economy/debugging pages use `0x0000…fffFfF`; omni `AbstractReactive` documents `0x8888…8888`. Prefer the library version pinned by your `reactive-lib` / `reactive-lib-omni` install, and verify on [Reactscan](https://reactscan.net/).

## Read by task

| Need | Open |
|------|------|
| Origin/destination roles + callback proxy purpose | [references/origins-destinations.md](references/origins-destinations.md) |
| ReactVM, dual state, RVM ID | [references/reactvm-and-state.md](references/reactvm-and-state.md) |
| Mental model vs bots | This page + `skill:reactive-integrations` demos |

## Constraints / gotchas

- RCs replace off-chain bots for **deterministic, on-chain** if-this-then-that automation.
- Callbacks are **async** relative to the origin tx; design destination handlers as reentrant-safe and idempotent where possible.
- Contracts must stay **funded** or they become `inactive` (see `skill:reactive-deployment`).
- Hyperlane is an **alternate callback transport** when a chain lacks a callback proxy — see `skill:reactive-deployment`.

## Key terms

- **RC** — Reactive Contract  
- **RVM / ReactVM** — private execution environment for event processing  
- **RNK** — Reactive Network public chain  
- **LogRecord** — struct delivered to `react()` (chain, address, topics, data, block metadata)  
- **Callback Proxy** — destination verifier/entry point for network-submitted callbacks  

## See also

- `skill:reactive-contracts` — write RCs, library, subscriptions  
- `skill:reactive-callbacks` — callback payload rules, destination contracts  
- `skill:reactive-deployment` — chain IDs, RPCs, faucets, funding  
- `skill:reactive-integrations` — demos and integration patterns  
- Docs: https://dev.reactive.network/  
- Demos: https://github.com/Reactive-Network/reactive-smart-contract-demos  
