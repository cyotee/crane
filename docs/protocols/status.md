# Protocol & core maturity status

Honest maturity labels for public consumers. **Core factories, access, tokens, and registries** are the primary supported product surface. Protocol trees vary widely.

| Label | Meaning |
|-------|---------|
| **stable** | Crane-native patterns in active use; TestBase/Behavior coverage expected for public APIs |
| **experimental** | Usable for integration/learning; APIs or ports may change; not a production guarantee |
| **vendored** | Upstream sources under `contracts/external` or protocol trees; fidelity to upstream, Crane wrappers partial |
| **WIP** | Incomplete port or scaffolding; do not rely on for mainnet |

## Core framework

| Area | Path | Maturity |
|------|------|----------|
| CREATE3 factory + DFPkg | `contracts/factories/` | **stable** |
| Diamond package factory | `contracts/factories/diamondPkg/` | **stable** |
| Access (Operable, ERC8023 MultiStepOwnable, reentrancy) | `contracts/access/` | **stable** |
| Tokens (ERC20/2612/4626 + DFPkgs) | `contracts/tokens/` | **stable** |
| Registries | `contracts/registries/` | **stable** |
| Introspection (ERC165/2535 helpers) | `contracts/introspection/` | **stable** |
| Utils (math, sets, crypto) | `contracts/utils/` | **stable** (some TODOs remain) |
| InitDev / InitBc services | `contracts/Init*.sol` | **stable** |
| Bounties DFPkg | `contracts/bounties/` | **experimental** (product-adjacent) |

## DEX / AMM ports

| Protocol | Maturity | Notes |
|----------|----------|-------|
| Uniswap V2/V3/V4 services & wrappers | **experimental** – **vendored** | Skills + partial Crane services; verify TestBases per path |
| Balancer V3 | **experimental** – **vendored** | Vault/pool integration skills; port depth varies |
| Aerodrome + Slipstream | **experimental** – **vendored** | Base-focused; gauge/CL surfaces |
| Camelot | **experimental** | Service wrappers present |

## Lending / CDP / other

| Protocol | Maturity | Notes |
|----------|----------|-------|
| Aave V3 | **vendored** / **experimental** wrappers | Large vendor tree |
| Aave V4 Hub/Spoke | **WIP** – **experimental** | Port in progress; not production-complete |
| Euler EVC/EVK | **vendored** / **experimental** | |
| Compound Comet | **vendored** / **experimental** | Skills available |
| Resupply | **experimental** | |
| Reliquary | **experimental** | |
| Pendle / Frax / Liquity / Sky | **vendored** / **WIP** | Large trees; use status carefully |
| Reactive Network demos | **experimental** | Messaging demos |

## CI vs full monorepo

GitHub Actions uses `FOUNDRY_PROFILE=ci`, which **skips** `contracts/external/**`, `contracts/protocols/**`, and heavy fork/protocol tests to avoid OOM. A green CI run proves **framework core**, not every protocol port.

See [CONTRIBUTING.md](../../CONTRIBUTING.md) and `foundry.toml` `[profile.ci]`.
