# Reactive Smart Contract Demos Catalog

Primary repo: https://github.com/Reactive-Network/reactive-smart-contract-demos  
Docs: https://dev.reactive.network/legacy/demos  
README summary fetched 2026-07-22.

## Basic Demo

- **Path:** `src/demos/basic`
- **Flow:** L1 origin emits event → Reactive detects → callback to destination.
- **Contracts:** `BasicDemoL1Contract`, `BasicDemoReactiveContract`, `BasicDemoL1Callback`.
- **Use:** onboarding / smoke integration.

## Cron Demo

- **Path:** `src/demos/cron`
- **Flow:** Subscribe to system Cron events; run scheduled logic without off-chain keepers.
- **Use:** periodic health checks, reward drips, scheduled updates.

## Uniswap V2 Stop Order

- **Path:** `src/demos/uniswap-v2-stop-order`
- **Flow:** Subscribe to pair `Sync`; when rate crosses threshold, callback executes Router swap and returns proceeds.
- **Topic0 Sync:** `0x1c411e9a96e071241c2f21f7726b17ae89e3cab4c78be50e062b03a9fffbbad1` (also used in subscriptions docs).

## Uniswap V2 Stop-Loss & Take-Profit

- **Path:** `src/demos/uniswap-v2-stop-take-profit-order`
- **Flow:** Personal RC per user; multi-order lifecycle; dynamic pair subscriptions.

## Approval Magic

- **Path:** `src/demos/approval-magic`
- **Flow:** `ApprovalListener` RC watches ERC-20 approvals + registry; triggers exchange or Uniswap swap when approval targets a subscribed contract.

## Hyperlane

- **Path:** `src/demos/hyperlane`
- **Flow:** Base ↔ Reactive two-way messaging via Hyperlane mailboxes (no centralized relayer dependency for that path).
- **Contracts:** `HyperlaneOrigin.sol`, `HyperlaneReactive.sol`.

## Aave Liquidation Protection

- **Path:** `src/demos/aave-liquidation-protection`
- **Flow:** Personal RC on CRON; health-factor checks; destination deposits collateral and/or repays debt.

## Leverage Loop

- **Path:** `src/demos/leverage-loop`
- **Flow:** User deposits into personal account; RC detects deposit; loops supply/borrow until target HF or max iterations.

## Automated Prediction Market

- **Path:** `src/demos/automated-prediction-market`
- **Flow:** On `PredictionResolved`, RC triggers batch distribution of winnings.

## Gasless Cross-Chain Atomic Swap

- **Path:** `src/demos/gasless-cross-chain-atomic-swap`
- **Flow:** Initiate/ack on two chains; RC syncs deposits and completes or fails atomically; users pay gas only on their chain.

## Shared tooling

- Foundry: `forge install`, `forge compile`, `forge test -vv`
- Env: `ORIGIN_*`, `DESTINATION_*`, `REACTIVE_*`, `SYSTEM_CONTRACT_ADDR`, `CALLBACK_PROXY_ADDR` (see repo README)

Always open the demo’s own README before deploying — constructor args and chain wiring differ.
