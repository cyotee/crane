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
- No logic changes intended in domain contracts.
- Upstream builds with `via_ir = true` and low optimizer runs for `UniversalRouter.sol`. IndexedEx default profile has `via_ir = false`; use FOUNDRY profile that enables `via_ir` when compiling/deploying this package (see monorepo `foundry.toml` profile `universal_router` if present).

## Inventory (production)

- `UniversalRouter.sol`, `SwapProxy.sol`
- `base/` Dispatcher, Lock, RouteSigner
- `modules/` Payments, Permit2Payments, ChainedActions, Migrator, V2/V3/V4 swap routers
- `libraries/` Commands, Constants, Locker, MaxInputAmount
- `interfaces/`, `types/RouterParameters.sol`

## Excluded

- Upstream `contracts/test/`, `contracts/deploy/`
- Node/Hardhat artifacts, docs
