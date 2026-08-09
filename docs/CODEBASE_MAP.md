---
last_reviewed: 2026-08-09
git_sha: 4f9a1412
scope: crane
method: cartographer+survey
---
# Crane Codebase Map

Primary structure map for the Crane Diamond framework. Capability checklist: [`docs/agent/CRANE_CAPABILITY_INVENTORY.md`](agent/CRANE_CAPABILITY_INVENTORY.md). Task router: [`docs/agent/AGENT_NAVIGATION_INDEX.md`](agent/AGENT_NAVIGATION_INDEX.md). Maturity: [`docs/protocols/status.md`](protocols/status.md).

## Overview

Crane is a **Diamond-first (ERC-2535)** Solidity framework: Facet–Target–Repo, `*Service` libraries, **DFPkg** diamond factory packages, **CREATE3** deterministic deploy, production-first **TestBase/Behavior/handler** testing, and **faithful protocol ports** with shared remapped dependencies under `contracts/external/`.

**Stack:** Solidity **0.8.35** (see `foundry.toml`), Foundry, CREATE3, ERC-2535.

```
crane/
├── AGENTS.md · CLAUDE.md
├── contracts/
│   ├── access/ · factories/ · proxies/ · proxy/ · introspection/
│   ├── tokens/ · utils/ · interfaces/ · registries/ · bounties/
│   ├── protocols/          # Crane wrappers + ports by domain
│   ├── external/           # Vendored upstream + shared OZ/Solady
│   └── test/               # CraneTest + protocol TestBases
├── test/foundry/           # Specs mirroring contracts
├── docs/                   # Product docs + agent/ maps
├── .claude/skills/         # Canonical skills SoT
└── .cartographer/          # Committed code graph
```

## Core packages

| Area | Path | Purpose |
|------|------|---------|
| Factories | `contracts/factories/` | CREATE3, diamond package factories, FactoryService |
| Access | `contracts/access/` | Operable, multi-step ownable, reentrancy locks |
| Proxies | `contracts/proxies/`, `contracts/proxy/` | Diamond proxy infrastructure |
| Tokens | `contracts/tokens/` | ERC20/permit/4626 packages |
| Utils | `contracts/utils/` | Math (ConstProd), sets, crypto, pagination |
| Introspection | `contracts/introspection/` | ERC165/2535 helpers |
| Registries | `contracts/registries/` | On-chain registries |
| Interfaces | `contracts/interfaces/` | Shared interfaces |
| Init services | `contracts/InitDevService.sol`, `InitBcService.sol` | Dev/bootstrap helpers |

## Protocols layout

```
contracts/protocols/
├── lending/     # morpho, aave, euler, …
├── dexes/       # uniswap, aerodrome, …
├── tokens/      # stable/olympus, wrappers, …
├── cdps/        # sky, liquity, …
├── launchpads/  # ponsFamily, uniswap CCA, …
├── l2s/         # superchain
├── oracles/     # chainlink
├── utils/       # permit2, gsn
├── messaging/ · perps/ · wallets/ · staking/
```

**External:** `contracts/external/**` — vendor sources with `VENDOR.md`; expand shared deps first; remap imports to `@crane/contracts/external/...`.

## High-value ports for agents

| Port | Path | Skills |
|------|------|--------|
| Morpho Blue / MetaMorpho / Vault V2 / Bundler | `contracts/protocols/lending/morpho/` | `crane-morpho`, `morpho-*` |
| Olympus V3 / Default Framework | `contracts/protocols/tokens/stable/olympus/` | `crane-olympus`, `olympus-*` |
| Uniswap stack | `contracts/protocols/dexes/uniswap/` | `crane-uniswap`, `uniswap-v*` |
| Balancer V3 | protocols + external | `crane-balancer`, `balancer-v3-*` |
| Aerodrome / Slipstream | `contracts/protocols/dexes/aerodrome/` | `crane-aerodrome`, `slipstream-*` |

## Testing map

| Piece | Location |
|-------|----------|
| CraneTest | `contracts/test/CraneTest.sol` |
| Specs | `test/foundry/spec/` (mirrors contracts tree) |
| Port tests | under protocol trees + `test/foundry/spec/protocols/**` |
| Skills | `crane-testing`, `crane-adversarial-testing` |

## Docs map

| Doc | Role |
|-----|------|
| `docs/SUMMARY.md` | Doc index |
| `docs/deployment/`, `docs/development/` | Deploy + testing guides |
| `docs/protocols/status.md` | Maturity labels |
| `docs/agent/*` | Agent inventory / navigation (this program) |
| `docs/archive/` | Historical plans (not active trackers) |

## Skills & agents

Canonical skills: `.claude/skills/`. Key framework skills: `crane-deployment`, `crane-architecture`, `crane-testing`, `crane-adversarial-testing`, `crane-porting`, `crane-porting-verification`, `crane-access`, `crane-code-style`, `crane-natspec`, `crane-utilities`, `crane-tokens`.

Agents: `.claude/agents/crane-porter.md`, `docs-skill-scribe.md`.

## Cartographer

Committed under `.cartographer/` (no Git LFS). Install CLI via consumer repo installer or Claude marketplace + Bun. Re-index with `--force`; require `verify --fresh`.

## Consumers

IndexedEx (and others) should:

1. Point harnesses at this map + capability inventory  
2. Pin submodule gitlink to a **pushed** Crane SHA that includes these docs  
3. Sync skills with consumer sync scripts when needed  
