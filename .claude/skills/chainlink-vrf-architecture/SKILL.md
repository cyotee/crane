---
name: chainlink-vrf-architecture
description: This skill should be used when the user asks about "Chainlink VRF", "VRF v2.5", "subscription method", "direct funding", "requestRandomWords", "fulfillRandomWords", "VRFCoordinator", "randomness oracle", or needs a high-level understanding of Chainlink VRF design and security.
license: MIT
---

# Chainlink VRF Architecture

Chainlink VRF provides onchain-verifiable randomness. A consumer contract requests randomness from a coordinator, and later receives a callback containing random words that are tied to a cryptographic proof.

## Request Models (VRF v2.5)

| Model | Funding | Best for | Tradeoff |
|-------|---------|----------|----------|
| Subscription | Shared subscription balance (LINK or native, network-dependent) | Frequent requests and multiple consumer contracts | Requires subscription lifecycle management |
| Direct funding | Consumer pays per request (LINK or native, network-dependent) | Infrequent one-off requests | Higher overhead and per-request funding logic |

## Core Lifecycle

1. Consumer submits randomness request to coordinator.
2. Coordinator emits request metadata (including request ID).
3. Chainlink oracle network produces proof and random words.
4. Coordinator verifies proof onchain.
5. Coordinator calls consumer callback with `requestId` and `randomWords`.
6. Consumer finalizes app state using those words.

## VRF v2.5 Request Shape

VRF v2.5 requests are passed as a request struct (via `requestRandomWords`) with fields such as:

- `keyHash`
- `subId` (subscription path)
- `requestConfirmations`
- `callbackGasLimit`
- `numWords`
- `extraArgs` (used for options like native payment where supported)

## Security Considerations

- Never use block variables (`block.timestamp`, `blockhash`) as your randomness source.
- Treat fulfillment as asynchronous: user action and random resolution occur in separate transactions.
- Do not allow arbitrary callers to execute fulfillment logic; only the coordinator should be authorized.
- Make fulfillment idempotent and store `requestId -> status` to prevent replay-like double-processing bugs.
- Keep callback gas bounded and avoid complex loops in fulfillment.
- Separate request initiation from effect execution when possible (store randomness, settle later).

## Integration Checklist

1. Pick a model: subscription vs direct funding.
2. Configure coordinator, key hash, confirmations, callback gas, and word count per network.
3. Implement request tracking (`pending`, `fulfilled`, `randomWords`).
4. Restrict fulfillment entry point to coordinator.
5. Add tests for request flow, authorization, stale/canceled request handling, and gas constraints.
6. Validate network-specific addresses and limits against Chainlink VRF supported networks docs.

## Useful Docs

- `https://docs.chain.link/vrf`
- `https://docs.chain.link/vrf/v2-5/getting-started`
- `https://docs.chain.link/vrf/v2-5/security`
- `https://docs.chain.link/vrf/v2-5/supported-networks`
- `https://docs.chain.link/vrf/llms-full.txt`

## See Also

- `skill:crane-chainlink-vrf` - Crane-specific Facet/Repo/DFPkg integration guidance
- `skill:crane-architecture` - Facet/Target/Repo design rules
- `skill:crane-deployment` - CREATE3 and Diamond package deployment patterns
- `skill:crane-testing` - testbase and behavior testing patterns
