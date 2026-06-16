Read AGENTS.md in this repo.

## Codebase Overview

Crane is a Diamond-first (ERC2535) Solidity development framework for modular, upgradeable smart contracts. It provides structured Facet-Target-Repo + *Service + DFPkg patterns, deterministic CREATE3 + callback Diamond factory infrastructure, rigorous TestBase/Behavior/handler testing, and deep faithful ports of major DeFi protocols (with shared dependencies remapped to Crane equivalents).

**Stack**: Solidity 0.8.30, Foundry, CREATE3, Diamond (ERC2535)
**Structure**: See `contracts/` (core + protocols), `test/foundry/spec/`, `scripts/`, extensive `.claude/skills/`, and `docs/`.

For detailed architecture, module guide, patterns, navigation, and current state of protocol integrations, see [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md).

Recent focus areas include Aave v4 Hub/Spoke port, dependency deduplication to `external/`, BattleChain deployment pilots, and the DeFi porting program (Ethena, Lido, Morpho, Ajna, etc. — see DEFI_* PRDs).