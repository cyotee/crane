# ponsFamily (pons) vendor

| Item | Value |
|------|-------|
| Upstream | https://github.com/ponsdotdev/ponsfamily |
| Pin | `60fcd76499a8d84caa09a1b252b0b1ae46a7bd86` (`main` as of 2026-07-28) |
| Solidity domain files | 5 (`PonsLaunchFactory`, `PonsLauncherToken`, `ILaunchpad`, `PonsLiquidityMath`, `PonsTickMath`) |
| Copy date | 2026-07-28 |
| License | MIT (factory, token, interfaces, liquidity math); **GPL-2.0-or-later** (`PonsTickMath`) |
| Import policy | OpenZeppelin **v5** only via `@crane/contracts/external/openzeppelin-contracts-v5/...`. **Do not** nest OZ/Solady under `ponsFamily/`. **Do not** use default project `openzeppelin-contracts` 4.9.6 tree for this port. |

## Live active addresses (Robinhood Chain 4663)

| Role | Address | Notes |
|------|---------|--------|
| Active factory | `0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB` | Start block **8991118** |
| Active locker | `0x736D76699C26D0d966744cAe304C000d471f7F35` | |
| V3 factory / PM / router / WETH | See `ROBINHOOD_MAIN` | Shared Uni V3 stack |

Live `getLaunchConfig(0)` (verified 2026-07-28 via public RH RPC):

| Field | Value |
|-------|--------|
| pairToken | WETH `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73` |
| graduationThreshold | `4.2 ether` |
| initialTick | `-204200` |
| supply | `1_000_000_000 ether` (1e9 * 1e18) |
| maxWalletBps / maxTxBps | `500` / `550` |
| restrictionBlocks | `2` |
| routerRequiresDeadline | `false` on live (SwapRouter02-style) |
| launchFee | `0.0005 ether` |

Hermetic tests set **`routerRequiresDeadline = true`** and wire Crane classic `SwapRouter`.

## Adaptations (no business-logic edits)

- Pragma `^0.8.30` → `^0.8.35` (Crane project solc).
- `@openzeppelin/contracts/...` → `@crane/contracts/external/openzeppelin-contracts-v5/...`.
- Relative imports within `pons/` preserved.
- **Stack depth (no viaIR):** pure upstream fails legacy-codegen stack-too-deep without viaIR.
  Crane keeps `via_ir = false` and applies compile-only structural adaptations that preserve
  external launch/restriction/graduation behavior:
  - `PonsLauncherToken` constructor takes a single `Init` struct (same fields as upstream flat args).
  - `PonsLaunchFactory.launchToken` split into `_prepareLaunch` / `_seedPoolAndPosition` /
    `_recordLockAndEmit` with a `LaunchCtx` memory struct.
- Profile `pons_port` uses `optimizer_runs = 300` (matches upstream `contract-meta.json`) and
  `evm_version = "cancun"`.

## Explicit non-ports

- Upstream `contracts/lib/openzeppelin-contracts/**` — **not** copied (shared external).
- Product **v2** bonding-curve docs — **not** in this GitHub repo; do not invent.
- Locker implementation — **not** upstream open source; hermetic uses `stubs/PonsLaunchLockerStub.sol` implementing `IPonsLaunchLocker`.
- Service / Aware / Behavior wrappers — follow-up (PF4).

## Inventory

```
ponsFamily/
├── VENDOR.md
├── pons/
│   ├── PonsLaunchFactory.sol
│   ├── PonsLauncherToken.sol
│   ├── interfaces/ILaunchpad.sol
│   └── libraries/{PonsLiquidityMath,PonsTickMath}.sol
├── stubs/PonsLaunchLockerStub.sol
└── test/bases/{TestBase_PonsFamily,TestBase_PonsFamily_Fork}.sol
```

## Fork profile

```bash
FOUNDRY_PROFILE=pons_port forge test \
  --match-path 'test/foundry/spec/protocols/launchpads/ponsFamily/fork/**' -vv
```
