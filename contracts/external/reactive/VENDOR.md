# reactive vendor

| Item | Value |
|------|-------|
| Upstream | Reactive-Network/reactive-lib |
| Pin | `f6990ce3526928d039fec78855b2004ff8d65c9f` |
| Solidity files (this tree) | 10 |
| Copy date | 2026-07-22 |
| License | Upstream SPDX `UNLICENSED`; vendored under Fair Use / research clause (see workspace porting policy) |
| Import policy | Internal imports rewritten to `@crane/contracts/external/reactive/...`. No private OZ/forge-std trees. |

## Adaptations

- Imports rewritten from relative paths under `src/` to `@crane/contracts/external/reactive/{abstract-base,interfaces,libraries}/...`.
- Layout flattened from upstream `src/{abstract-base,interfaces,libraries}` into this package root (same three subtrees, no `src/` prefix).
- No logic changes.

## Inventory

| Path | Role |
|------|------|
| `abstract-base/AbstractReactive.sol` | Base for Reactive Network contracts (system contract, RVM detect) |
| `abstract-base/AbstractPausableReactive.sol` | Pause/resume subscriptions |
| `abstract-base/AbstractCallback.sol` | Destination-chain callback base |
| `abstract-base/AbstractPayer.sol` | Payment / authorized-sender ACL |
| `interfaces/IReactive.sol` | `react(LogRecord)` + `Callback` event |
| `interfaces/ISystemContract.sol` | System contract (payable + subscription) |
| `interfaces/ISubscriptionService.sol` | subscribe / unsubscribe |
| `interfaces/IPayable.sol` | debt / receive |
| `interfaces/IPayer.sol` | pay |
| `libraries/SystemLib.sol` | `getSystemContractImpl()` helper |

## Demos

Example contracts that consume this SDK live at:

`contracts/protocols/messaging/reactive/demos/`

(from Reactive-Network/reactive-smart-contract-demos @ `f1f85ab2a0a8f917b9b37a57c00be2ffc8ad5ad4`).

## Related packages

| Package | Path |
|---------|------|
| Omni (next-gen API) | `contracts/external/reactive-omni/` |
| Foundry test harness | `contracts/external/reactive-test-lib/` |
| Demos | `contracts/protocols/messaging/reactive/demos/` |

| System contracts | `contracts/external/reactive-system/` |
