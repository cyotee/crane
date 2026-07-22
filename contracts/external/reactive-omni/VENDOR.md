# reactive-omni vendor

| Item | Value |
|------|-------|
| Upstream | Reactive-Network/reactive-lib-omni |
| Pin | `3ade0dcf1d27e67e5783ef807e73a1b9e0c0cce8` |
| Solidity files (this tree) | 8 |
| Copy date | 2026-07-22 |
| License | Upstream SPDX `UNLICENSED`; vendored under Fair Use / research clause |
| Import policy | Internal imports rewritten to `@crane/contracts/external/reactive-omni/...` |

## Relationship to classic `reactive-lib`

This is a **separate API** from `contracts/external/reactive/` (classic reactive-lib). Do not mix:

| | Classic (`external/reactive`) | Omni (`external/reactive-omni`) |
|--|------------------------------|--------------------------------|
| Upstream | reactive-lib | reactive-lib-omni |
| System address | `0x…fffFfF` (`SERVICE_ADDR`) | `0x888…888` (`SYSTEM`) |
| LogRecord fields | snake_case (`chain_id`, `topic_0`) | camelCase (`chainId`, `topic0`) |
| Callbacks | emit `Callback` event | prefer `requestCallback` / `requestCallbackV_1_0` |
| Pragma | `>=0.8.0` | `^0.8.29` |

## Inventory

| Path | Role |
|------|------|
| `base/AbstractReactive.sol` | Reactive contract base (system = `0x888…`) |
| `base/AbstractCallback.sol` | Destination callback base (`onlyCallbackSender`) |
| `base/AbstractPayer.sol` | Payment / service-provider ACL |
| `interfaces/IReactive.sol` | `react(LogRecord)` + deprecated `Callback` event |
| `interfaces/ISystemContract.sol` | subscribe + `requestCallback*` |
| `interfaces/ISubscriptionService.sol` | subscribe / unsubscribe |
| `interfaces/IPayable.sol` | debt / receive |
| `interfaces/IPayer.sol` | pay |

## Adaptations

- Imports rewritten from relative `../interfaces` / `./` to `@crane/contracts/external/reactive-omni/...`.
- Layout: upstream `src/{base,interfaces}` → package root (no `src/` prefix).
- No logic changes.
