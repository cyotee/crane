# reactive-test-lib vendor

| Item | Value |
|------|-------|
| Upstream | Reactive-Network/reactive-test-lib |
| Pin | `2ff9b2a68ca9956306ec943c10d1c757c1dd1956` |
| Solidity files (library) | 11 |
| Copy date | 2026-07-22 |
| License | MIT (upstream SPDX) |
| Compatible with | Classic `reactive-lib` / `contracts/external/reactive` (snake_case LogRecord, `SERVICE_ADDR` `0x…fffFfF`) |
| Import policy | Package-internal imports → `@crane/contracts/external/reactive-test-lib/...`; `forge-std` via project remapping |

## Purpose

Foundry hermetic simulation of Reactive Network: subscriptions, `react()`, cross-chain callbacks, self-callbacks, cron, multi-step protocols — without live RN deployment.

## Layout

```
contracts/external/reactive-test-lib/
├── ReactiveTest.sol          # re-export entry
├── base/                     # ReactiveTest, ReactiveFixtures
├── constants/                # SERVICE_ADDR, chain IDs, event topics
├── interfaces/               # minimal ABI-compatible IReactive surfaces
├── mock/                     # MockSystemContract, MockCallbackProxy
└── simulator/                # ReactiveSimulator, CronSimulator

test/foundry/spec/protocols/messaging/reactive/test-lib/
├── *.t.sol                   # upstream package tests (ported)
└── mocks/                    # sample contracts used by those tests
```

## Adaptations

- Internal imports remapped to `@crane/contracts/external/reactive-test-lib/...`.
- `forge-std/Test.sol` / `Vm.sol` unchanged (Crane `forge-std/=lib/forge-std/src/`).
- Upstream package tests relocated under Crane `test/foundry/spec/...` with remapped library imports.
- Self-contained interfaces (does **not** import classic `external/reactive`); ABI-compatible for testing classic-style demos.

## See also

- Classic SDK: `contracts/external/reactive/`
- Omni SDK: `contracts/external/reactive-omni/`
- Demos: `contracts/protocols/messaging/reactive/demos/`

| System contracts | `contracts/external/reactive-system/` |
