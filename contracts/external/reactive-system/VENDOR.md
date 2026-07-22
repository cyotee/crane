# reactive-system vendor

| Item | Value |
|------|-------|
| Upstream | Reactive-Network/system-smart-contracts |
| Pin | `315e7350acb97b8425d3cfbd2eb6a93a7bf599b7` |
| Solidity files (this tree) | 7 domain + 3 demo |
| Copy date | 2026-07-22 |
| License | Upstream SPDX `UNLICENSED` / demo GPL-2.0-or-later; Fair Use / research clause |
| Depends on | Classic `contracts/external/reactive` (reactive-lib interfaces + abstract bases + SystemLib) |
| Import policy | Shared SDK via `@crane/contracts/external/reactive/...`; local files via `@crane/contracts/external/reactive-system/...` |

## Role

On-network **system contracts** for Reactive Network:

| Contract | Purpose |
|----------|---------|
| `SystemContract` | Subscription service + callback proxy + cron + payment/charge |
| `CallbackProxy` | Callback execution, reserves/debts, gas charging |
| `AbstractSubscriptionService` | Recursive topic filter subscription tree |
| `DelegateProxy` | Delegates to system impl via `SystemLib.getSystemContractImpl()` |

## Layout

```
contracts/external/reactive-system/
├── SystemContract.sol
├── CallbackProxy.sol
├── AbstractSubscriptionService.sol
├── DelegateProxy.sol
├── demos/basic/          # test helpers (variant of basic demos)
└── VENDOR.md

test/foundry/spec/protocols/messaging/reactive/system/
├── ViewTest.sol
├── DynamicViewTest.sol
└── AdvancedDynamicViewTest.sol
```

## Adaptations

- Imports rewritten from `lib/reactive-lib/...` to `@crane/contracts/external/reactive/...`.
- Intra-package imports rewritten to `@crane/contracts/external/reactive-system/...`.
- No domain logic changes.
- Empty Foundry script stub from upstream not ported.

## Related

| Package | Path |
|---------|------|
| Classic SDK | `contracts/external/reactive/` |
| Omni SDK | `contracts/external/reactive-omni/` |
| Test harness | `contracts/external/reactive-test-lib/` |
| App demos | `contracts/protocols/messaging/reactive/demos/` |
