# Third-party notices

## Crane-native code

Unless otherwise noted, original Crane framework code in this repository is licensed under the **GNU Affero General Public License v3.0** (see `LICENSE`).

## Vendored and submodule dependencies

This repository vendors or submodules third-party code that remains under **its own license**. Do not assume AGPL applies to upstream protocol sources.

| Area | Typical origins | Notes |
|------|-----------------|--------|
| `lib/forge-std` | Foundry | MIT |
| `lib/openzeppelin-contracts` | OpenZeppelin | MIT |
| `lib/chainlink-local` | Chainlink | See upstream |
| `lib/battlechain-lib` | Cyfrin / BattleChain | See upstream |
| `contracts/external/**` | Various (OZ variants, Solady, Balancer, Lido, etc.) | Prefer upstream SPDX headers; see per-tree `VENDOR.md` where present |
| `contracts/protocols/**` | Upstream ports + Crane wrappers | Upstream trees keep original terms; Crane wrappers are AGPL unless marked otherwise |
| `licenses/` | Apache-2.0, MIT, BSL-1.1, GPL texts | Reference copies for common dependency licenses |

When redistributing or deploying, review:

1. Root `LICENSE` (AGPL-3.0) for Crane-native composition.
2. SPDX headers and `VENDOR.md` files next to vendored trees.
3. Upstream project licenses for any protocol you ship in production.

## Skills and documentation

Agent skills under `.claude/skills/` that describe third-party protocols are educational material. They are **not** official products of Aave, Uniswap, Balancer, or other protocol teams unless explicitly stated.
