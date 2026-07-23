---
name: reactive-integrations
description: >
  Maps Reactive Network integration patterns from official demos and test lib: Basic origin→RC→callback,
  CRON, Uniswap stop/take-profit, Aave liquidation protection, leverage loop, prediction market payouts,
  gasless atomic swap, Approval Magic, Hyperlane, and Foundry reactive-test-lib. Use when the user asks
  for "Reactive demo", "stop-loss Reactive", "Aave protection Reactive", "reactive-test-lib",
  "triggerAndReact", or "how to integrate Reactive with Uniswap/Aave".
license: MIT
---

# Reactive Integrations & Demos

Official reference implementations:  
https://github.com/Reactive-Network/reactive-smart-contract-demos  

Docs index: https://dev.reactive.network/legacy/demos  
Local testing: https://dev.reactive.network/legacy/testing + https://github.com/Reactive-Network/reactive-test-lib

## Integration recipe (always)

1. **Origin** contract/event on supported chain (or use existing protocol events).  
2. **Reactive Contract** on Reactive (Mainnet `1597` / Lasna `5318007`) subscribes + implements `react`.  
3. **Destination** callback contract with proxy + RC authorization.  
4. Fund all sides; deploy; verify; trigger; observe Reactscan / `rnk_getFilters`.

Cross-link: `skill:reactive-architecture`, `skill:reactive-contracts`, `skill:reactive-callbacks`, `skill:reactive-deployment`.

## Demo catalog

| Demo | Pattern | Path |
|------|---------|------|
| **Basic** | Origin event → RC threshold → destination callback | `src/demos/basic` |
| **Cron** | Subscribe to system Cron topics; scheduled actions | `src/demos/cron` |
| **Uniswap V2 stop order** | `Sync` → price threshold → Router swap callback | `src/demos/uniswap-v2-stop-order` |
| **Stop-loss & take-profit** | Personal RC, multi-order, dynamic pair subs | `src/demos/uniswap-v2-stop-take-profit-order` |
| **Approval Magic** | ERC-20 `Approval` → auto exchange/swap | `src/demos/approval-magic` |
| **Hyperlane** | Alternate messaging Base ↔ Reactive | `src/demos/hyperlane` |
| **Aave liquidation protection** | CRON health checks → collateral/repay | `src/demos/aave-liquidation-protection` |
| **Leverage loop** | Deposit detected → iterative Aave loop | `src/demos/leverage-loop` |
| **Prediction market** | `PredictionResolved` → batch payouts | `src/demos/automated-prediction-market` |
| **Gasless atomic swap** | Two-chain deposit confirm → complete/abort | `src/demos/gasless-cross-chain-atomic-swap` |

Each folder has its own README with deploy steps. Prefer starting with **Basic**.

Detail: [references/demo-catalog.md](references/demo-catalog.md)

## Basic Demo anatomy (quote)

From `BasicDemoReactiveContract.sol` (legacy-style, illustrative):

```solidity
// constructor subscribes via service/system to origin contract + topic0
// react() checks log.topic_3 >= 0.001 ether then:
bytes memory payload = abi.encodeWithSignature("callback(address)", address(0));
emit Callback(destinationChainId, callback, GAS_LIMIT, payload);
```

Trio:

- `BasicDemoL1Contract.sol` — origin  
- `BasicDemoReactiveContract.sol` — RC  
- `BasicDemoL1Callback.sol` — destination  

## Foundry test lib

```bash
forge install Reactive-Network/reactive-test-lib
# remappings.txt:
# reactive-test-lib/=lib/reactive-test-lib/src/
```

Inherit `ReactiveTest`:

```solidity
function testCallbackFires() public {
    CallbackResult[] memory results = triggerAndReact(
        address(origin),
        abi.encodeWithSignature("receive()"),
        SEPOLIA_CHAIN_ID
    );
    assertCallbackCount(results, 1);
    assertCallbackSuccess(results, 0);
}
```

| Helper | Use |
|--------|-----|
| `triggerAndReact` / `WithValue` | One cycle: emit → match → react → callbacks |
| `triggerFullCycle` / `WithValue` | Multi-step bridges (max iterations) |
| `triggerCron` / `advanceAndTriggerCron` | CronType.Cron1..Cron10000 |
| `enableVmMode(rc)` | Required if `react` is `vmOnly` |
| `registerChain(addr, chainId)` | Auto origin chain resolution |

Mocks: `MockSystemContract` at `SERVICE_ADDR` `0x0000…fffFfF`, `MockCallbackProxy`, RVM ID injection.

Detail: [references/testing-with-foundry.md](references/testing-with-foundry.md)

## Choosing a pattern

| Goal | Start from |
|------|------------|
| Learn lifecycle | Basic |
| Time-based jobs | Cron (+ Aave protection) |
| DEX automation | Uniswap stop / SL-TP |
| Lending safety | Aave liquidation protection |
| Cross-chain messaging without proxy | Hyperlane |
| Trust-minimized swap UX | Gasless atomic swap |
| Approval-triggered UX | Approval Magic |

## API version warning

Demos may pin **legacy reactive-lib** (`emit Callback`, `vmOnly`, `service.subscribe`). New product code should follow **reactive-lib-omni** (`SYSTEM.subscribe`, `requestCallbackV_1_0`, `onlySystem`) per current docs, unless matching an existing demo’s dependency tree.

## See also

- Docs: https://dev.reactive.network/  
- Lib: https://github.com/Reactive-Network/reactive-lib-omni  
- Test lib: https://github.com/Reactive-Network/reactive-test-lib  
