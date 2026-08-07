# Uniswap Universal Router vendor

| Item | Value |
|------|-------|
| Upstream | [Uniswap/universal-router](https://github.com/Uniswap/universal-router) |
| Pin | tag **2.1.1** (`999d561c3ad58fb5cab91b602911f3c75591a9c7`) |
| Solidity files (this tree) | 26 (production; tests/deploy excluded) |
| Copy date | 2026-08-04 |
| License | GPL-3.0-or-later |
| Import policy | Shared OZ / Solmate / Permit2 / Uni V2–V4 remapped to `@crane/contracts/...` |

## Why 2.1.1

- Includes **V4** (`V4_SWAP` via `V4SwapRouter` → `V4Router`).
- Does **not** require PermissionedV4Router / permissions adapter factory (introduced later on main / 2.2+).
- Aligns with Crane’s existing Uniswap V4 port under `protocols/dexes/uniswap/v4/`.

## Adaptations

- Imports rewritten from upstream remappings (`@uniswap/v4-*`, `permit2/`, `solmate/`, `@openzeppelin/`) to `@crane/...` paths.
- **Stack-safe for `via_ir = false`** (Crane/IndexedEx project law — never enable viaIR):
  - `modules/ChainedActions.sol` — Across `depositV3` via low-level encode+call (12-arg stack).
  - `modules/uniswap/v3/V3SwapRouter.sol` — packed `V3PoolSwapArgs` / callback structs / exact-in loop frame.
  - `modules/uniswap/v2/V2SwapRouter.sol` — `V2HopState` + per-hop helper.
- Behavioral intent matches Uniswap universal-router **2.1.1**; only stack frames / call encoding differ.
- Compile with monorepo `FOUNDRY_PROFILE=universal_router` (or any profile with `via_ir = false`).

## Inventory (production)

- `UniversalRouter.sol`, `SwapProxy.sol`
- `base/` Dispatcher, Lock, RouteSigner
- `modules/` Payments, Permit2Payments, ChainedActions, Migrator, V2/V3/V4 swap routers
- `libraries/` Commands, Constants, Locker, MaxInputAmount
- `interfaces/`, `types/RouterParameters.sol`

## Excluded

- Upstream `contracts/test/`, `contracts/deploy/`
- Node/Hardhat artifacts, docs
