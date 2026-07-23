---
name: reactive-contracts
description: >
  Guides writing Reactive Contracts with reactive-lib-omni: AbstractReactive, IReactive.react(LogRecord),
  SYSTEM.subscribe/unsubscribe, REACTIVE_IGNORE wildcards, onlySystem, payments via AbstractPayer, and
  CRON topics. Use when the user asks to "write a reactive contract", "subscribe to events", "implement
  react()", "AbstractReactive", "ISubscriptionService", "REACTIVE_IGNORE", "SYSTEM.subscribe", or build
  on-chain automation that listens to EVM logs.
license: MIT
---

# Writing Reactive Contracts

A **Reactive Contract** deploys on Reactive Network, **subscribes** to origin-chain logs, implements **`react(LogRecord)`**, and requests **destination callbacks** when conditions match.

Sources: [Reactive Contracts](https://dev.reactive.network/reactive-contracts), [Reactive Library](https://dev.reactive.network/reactive-library), [Subscriptions](https://dev.reactive.network/subscriptions), [Events & Callbacks](https://dev.reactive.network/events-&-callbacks).  
Lib: https://github.com/Reactive-Network/reactive-lib-omni

## Install

```bash
forge install Reactive-Network/reactive-lib-omni
```

## Minimal skeleton (omni API)

```solidity
import {AbstractReactive} from "reactive-lib-omni/.../AbstractReactive.sol";
// Adjust path to your remapping for AbstractReactive / ISystemContract

contract MyReactive is AbstractReactive {
    uint256 constant TOPIC0 = /* keccak256 of event sig as uint256 */;

    constructor(uint256 originChainId, address originContract) payable {
        SYSTEM.subscribe(
            originChainId,
            originContract,
            TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }

    function react(LogRecord calldata log_) external onlySystem {
        // decode log_.data / topics; optionally requestCallbackV_1_0(...)
    }
}
```

Docs example (PingPong-style self-subscription):

```solidity
SYSTEM.subscribe(
    block.chainid,
    address(this),
    PING_TOPIC_0,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE
);
```

## Quick facts

| Item | Value | Source |
|------|-------|--------|
| Entry point | `react(LogRecord)` | IReactive |
| Restrict caller | `onlySystem` (AbstractReactive) | library docs |
| System constant | `SYSTEM` = `0x8888…8888` | AbstractReactive docs |
| Topic wildcard | `REACTIVE_IGNORE` | subscriptions docs |
| Chain wildcard | `uint256(0)` | subscriptions docs |
| Contract wildcard | `address(0)` | subscriptions docs |
| Prefer callback API | `requestCallbackV_1_0` | events & callbacks |

## Subscription rules

- Criteria: **chainId**, **contract**, **topic0–topic3** (equality only).
- **At least one** parameter must be specific (no “subscribe to everything”).
- No range/`</>` filters; no OR inside one subscription — call `subscribe()` multiple times.
- Duplicates allowed but act as one; each call still costs gas.
- Subscribe in **constructor** and/or **dynamically** from RNK-side functions.
- `unsubscribe()` uses the **same** parameters as `subscribe()`.

Detail: [references/subscriptions.md](references/subscriptions.md)

## LogRecord (delivered to react)

```solidity
struct LogRecord {
    uint256 chainId;
    address contractAddress;
    uint256 topic0;
    uint256 topic1;
    uint256 topic2;
    uint256 topic3;
    bytes data;
    uint256 blockNumber;
    uint256 opCode;
    uint256 blockHash;
    uint256 txHash;
    uint256 logIndex;
}
```

Field names in older demos may use `topic_0` / snake_case — match the **library version** you import.

## Library map

| Type | Role |
|------|------|
| `AbstractReactive` | Base RC: `SYSTEM`, `REACTIVE_IGNORE`, `onlySystem`, payer wiring |
| `AbstractPayer` | `pay()`, `_coverDebt()`, `receive()` for funding |
| `AbstractCallback` | Destination authorization (`onlyCallbackSender`) — see callbacks skill |
| `ISystemContract` | `subscribe`/`unsubscribe` + `requestCallback*` |
| `IReactive` | `react` + deprecated `Callback` event |
| CRON system | Legacy cron emitter `0x0000…fffFfF` topics for scheduled react |

Detail: [references/library-surface.md](references/library-surface.md)

## Legacy demos note

Many GitHub demos still use **legacy reactive-lib** patterns:

- `service.subscribe(...)` instead of `SYSTEM.subscribe`
- `emit Callback(...)` instead of `requestCallbackV_1_0`
- `vmOnly` / `if (!vm)` dual-environment guards

Prefer **omni docs + reactive-lib-omni** for new work; when editing demos, follow the demo’s import tree. See `skill:reactive-integrations`.

## Deploy checklist

1. Fund constructor with REACT / lREACT (`payable` + `--value`).
2. Subscribe to intended origin events.
3. Implement `react` with `onlySystem`.
4. Request callbacks via system API (not raw unauthenticated destination calls).
5. Verify on Sourcify (`forge verify-contract --verifier sourcify --chain-id 1597|5318007`).
6. Confirm **active** status on Reactscan after funding.

## See also

- `skill:reactive-callbacks` — callback structs, destination side  
- `skill:reactive-architecture` — ReactVM dual-state  
- `skill:reactive-deployment` — RPCs, faucets  
- `skill:reactive-integrations` — demos  
