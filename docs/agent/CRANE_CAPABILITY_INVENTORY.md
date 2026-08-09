---
last_reviewed: 2026-08-09
git_sha: 4f9a1412
scope: crane
method: cartographer+survey
---
# Crane Capability Inventory

Canonical inventory of what Crane provides. Consumers (e.g. IndexedEx) **pin a gitlink** to a pushed Crane commit that includes this file + `docs/CODEBASE_MAP.md` + `.cartographer/`.

Related: [`docs/CODEBASE_MAP.md`](../CODEBASE_MAP.md) · [`docs/agent/AGENT_NAVIGATION_INDEX.md`](./AGENT_NAVIGATION_INDEX.md) · [`docs/protocols/status.md`](../protocols/status.md) · skills under `.claude/skills/`.

Cartographer (2026-08-09): Crane graph under `.cartographer/` (~13032 files / 17125 nodes when indexed from consumer path).

## Framework core (stable product surface)

| Capability | Path | Skill(s) | Maturity |
|------------|------|----------|----------|
| CREATE3 + DFPkg factories | `contracts/factories/` | `crane-deployment` | stable |
| Diamond package callback factory | `contracts/factories/diamondPkg/` (and related) | `crane-deployment`, `crane-architecture` | stable |
| Access (operable, MultiStepOwnable/ERC8023, reentrancy) | `contracts/access/` | `crane-access` | stable |
| Proxies / diamond proxy | `contracts/proxies/`, `contracts/proxy/` | `crane-architecture` | stable |
| Introspection | `contracts/introspection/` | `crane-architecture` | stable |
| Tokens (ERC20/2612/4626 + DFPkgs) | `contracts/tokens/` | `crane-tokens` | stable |
| Utils (math, sets, crypto, ConstProd) | `contracts/utils/` | `crane-utilities` | stable |
| Interfaces | `contracts/interfaces/` | — | stable |
| Registries | `contracts/registries/` | — | stable |
| InitDev / InitBc services | `contracts/Init*.sol` | — | stable |
| Bounties | `contracts/bounties/` | — | experimental |

## Testing

| Capability | Path | Skill(s) |
|------------|------|----------|
| CraneTest | `contracts/test/CraneTest.sol` | `crane-testing` |
| TestBases / Behaviors / handlers | `contracts/test/**`, `test/foundry/` | `crane-testing`, `forge-fuzz-testing` |
| Adversarial catalogs | skill-driven | `crane-adversarial-testing` |
| CI profile | `foundry.toml` `[profile.ci]` | Skips heavy `contracts/external/**` + many protocol tests |

## Protocol ports (high-signal)

See also [`docs/protocols/status.md`](../protocols/status.md) for maturity labels.

| Protocol | Primary path | Skill family | Notes |
|----------|--------------|--------------|-------|
| Morpho | `contracts/protocols/lending/morpho/` (`blue`, `metamorpho`, `vault-v2`, `bundler`) | `crane-morpho`, `morpho-architecture`, `morpho-blue-operations`, `morpho-vaults` | Port + Service/TestBase; `FOUNDRY_PROFILE=morpho_port` |
| Olympus | `contracts/protocols/tokens/stable/olympus/` | `crane-olympus`, `olympus-architecture`, `olympus-operations` | Kernel/Default Framework port; `FOUNDRY_PROFILE=olympus_port` |
| Aave V3 / V4 | `contracts/protocols/lending/aave/` | `aave-v3-*`, `aave-v4-*` | Large vendor trees; V4 WIP |
| Euler | `contracts/protocols/lending/euler/` | `euler-*` / `evk-*` skills | EVC/EVK |
| Uniswap V2/V3/V4 | `contracts/protocols/dexes/uniswap/` | `crane-uniswap`, `uniswap-v3-*`, `uniswap-v4-*` | Services + vendored |
| Balancer V3 | under dexes + external | `crane-balancer`, `balancer-v3-*` | Vault/pool integration |
| Aerodrome + Slipstream | `contracts/protocols/dexes/aerodrome/` | `crane-aerodrome`, `aerodrome-*`, `slipstream-*` | Base-focused |
| Camelot | under dexes | `crane-camelot` | Fee-on-transfer aware |
| Permit2 | `contracts/protocols/utils/permit2/` | `permit2-*` | Allowance + signature transfer |
| Pons launchpad | `contracts/protocols/launchpads/ponsFamily/` | `pons-*` | Robinhood Chain launchpad |
| Superchain L2 | `contracts/protocols/l2s/superchain/` | — | messaging/registries |
| External vendors | `contracts/external/**` | `crane-porting` | Shared OZ/Solady trees; `VENDOR.md` per package |

## Porting workflow

1. `crane-porting` — vendor into `contracts/external` + wrappers in `contracts/protocols`; remap shared deps  
2. `crane-porting-verification` — hermetic + fork gates  
3. Prefer agent `crane-porter` for end-to-end sessions  

## Skills SoT

- Path: `.claude/skills/<name>/` (this repo)  
- Consumers may sync mirrors (IndexedEx: `./scripts/sync-crane-skills.sh`)  
- Authoring: `skill-authoring`, `docs-to-skills`  
- **Not** Bankr/Godot catalogs  

## Agent harnesses (Crane)

| File | Role |
|------|------|
| `AGENTS.md` | Primary Crane agent law + skill routing |
| `CLAUDE.md` | Points at AGENTS + map/inventory |
| `docs/CODEBASE_MAP.md` | Deep structure |
| This file | Capability inventory |
| `docs/agent/AGENT_NAVIGATION_INDEX.md` | Task → skill/path |

## Cartographer

Installed via **consuming repo** (IndexedEx `scripts/install-cartographer.sh`) or marketplace path. No separate Crane installer.

```bash
# from IndexedEx root with cartographer on PATH:
cartographer index --root lib/crane --out lib/crane/.cartographer --force
cartographer verify --root lib/crane --out lib/crane/.cartographer --fresh
```

Or inside Crane checkout with absolute `--root`/`--out`.
