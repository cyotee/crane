---
last_reviewed: 2026-08-09
git_sha: 4f9a1412
scope: crane
method: cartographer+survey
---
# Crane Agent Navigation Index

Lean task → skill / path router for Crane. Full structure: [`docs/CODEBASE_MAP.md`](../CODEBASE_MAP.md). Capabilities: [`CRANE_CAPABILITY_INVENTORY.md`](./CRANE_CAPABILITY_INVENTORY.md). Always-on: root `AGENTS.md`.

| Task | Skill / agent | Path |
|------|---------------|------|
| CREATE3 / DFPkg / FactoryService | `crane-deployment` | `contracts/factories/` |
| Diamond FTR / storage / DFPkg shape | `crane-architecture` | facets/targets/repos patterns |
| Access control / reentrancy | `crane-access` | `contracts/access/` |
| Tests / TestBases / Behaviors | `crane-testing` | `contracts/test/`, `test/foundry/` |
| Adversarial suites | `crane-adversarial-testing` | skill catalogs |
| Port a protocol | `crane-porter` + `crane-porting` + `crane-porting-verification` | `contracts/external/`, `contracts/protocols/` |
| Morpho | `crane-morpho`, `morpho-*` | `contracts/protocols/lending/morpho/` |
| Olympus | `crane-olympus`, `olympus-*` | `contracts/protocols/tokens/stable/olympus/` |
| Uniswap integration | `crane-uniswap`, `uniswap-v*` | `contracts/protocols/dexes/uniswap/` |
| Balancer integration | `crane-balancer`, `balancer-v3-*` | protocols + external |
| Token DFPkgs | `crane-tokens` | `contracts/tokens/` |
| Utilities / math | `crane-utilities` | `contracts/utils/` |
| Docs → skills | `docs-skill-scribe` + `docs-to-skills` | `.claude/skills/` |
| Code style / NatSpec | `crane-code-style`, `crane-natspec` | conventions |
| Protocol maturity | — | `docs/protocols/status.md` |
| Code graph | cartographer (consumer installer) | `.cartographer/` |

## Profiles

| Profile | Use |
|---------|-----|
| default | Hermetic core |
| `ci` | Lightweight CI (skips heavy ports) |
| `morpho_port` / `olympus_port` | Port-focused (see skills) |
| fork-related | See Foundry config / testing docs |

`via_ir` forbidden in IndexedEx consumers; follow Crane `foundry.toml` for Crane-native work.
