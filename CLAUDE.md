Read AGENTS.md in this repo.

## Codebase Overview

Crane is a Diamond-first (ERC2535) Solidity development framework for modular, upgradeable smart contracts. It provides structured Facet-Target-Repo + *Service + DFPkg patterns, deterministic CREATE3 + callback Diamond factory infrastructure, rigorous TestBase/Behavior/handler testing, and deep faithful ports of major DeFi protocols (with shared dependencies remapped to Crane equivalents).

**Stack**: Solidity 0.8.30, Foundry, CREATE3, Diamond (ERC2535)
**Structure**: See `contracts/` (core + protocols), `test/foundry/spec/`, `scripts/`, extensive `.claude/skills/`, and `docs/`.

For detailed architecture, module guide, patterns, navigation, and current state of protocol integrations, see [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md).

Recent focus areas include Aave v4 Hub/Spoke port, dependency deduplication to `external/`, BattleChain deployment pilots, and the DeFi porting program (Ethena, Lido, Morpho, Ajna, etc. — see DEFI_* PRDs).

## Protocol porting (mandatory skills)

When vendoring or porting external protocol code into Crane:

1. Load **`crane-porting`** — `contracts/external` vs `contracts/protocols`, shared dep remaps, `VENDOR.md`, expand→remap→delete.
2. Load **`crane-porting-verification`** — hermetic TestBases, Behaviors, fork parity, DoD checklist. A port without tests is incomplete.
3. Prefer agent **`crane-porter`** (`.claude/agents/crane-porter.md`) for end-to-end port sessions.
4. Supporting: `crane-architecture`, `crane-code-style`, `crane-testing`, `writing-skills` (post-port protocol skill).

Canonical skill paths: `.claude/skills/crane-porting/`, `.claude/skills/crane-porting-verification/`.

## Documentation → skills

When turning a docs site (or full doc tree) into agent skills:

1. Load **`docs-to-skills`** — full inventory, fetch every page, cluster into a skill family, coverage gates.
2. Load **`skill-authoring`** — progressive disclosure, description triggers, `references/` compartmentalization (&lt;500 line SKILL.md bodies).
3. Prefer agent **`docs-skill-scribe`** (`.claude/agents/docs-skill-scribe.md`).
4. Do not cherry-pick the homepage; emit multi-skill families with lean SKILL.md + on-demand references.