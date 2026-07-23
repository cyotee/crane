# AI Agent Skills for Crane

Crane ships with a rich library of skills under `.claude/skills/`. These enable Claude Code, Bankr agents, OpenClaw, Cursor, and other compatible tools to author correct, secure, gas-efficient Diamond contracts using Crane patterns.

Public skills live under `.claude/skills/`. The tree is curated for **Crane product + protocol architecture + Foundry + borderline TS tooling**. Personal/Bankr-ecosystem bazaar skills are not tracked in this repository.

## Core Crane Skills (Start Here)

- `crane-architecture` — Facet-Target-Repo, storage slots, guard functions, AwareRepo, Service, DFPkg rules.
- `crane-deployment` — CREATE3, DiamondPackageCallBackFactory, FactoryService, Init*Service, salt conventions.
- `crane-testing` — TestBase, Behavior libraries, handlers, invariants, comparators.
- `crane-adversarial-testing` — Abuse/attack catalogs for diamonds/vaults.
- `crane-code-style` — Headers, naming (`_layoutStruct`, `param_`), no viaIR, struct patterns for stack.
- `crane-natspec` — Full documentation requirements with include-tags and custom selectors. Values: [CENTRALLY_COMPUTED_NATSPEC_VALUES.md](CENTRALLY_COMPUTED_NATSPEC_VALUES.md).
- `crane-access` — Operable, ERC8023 MultiStepOwnable, reentrancy.
- `crane-tokens` — ERC20/2612/4626 native implementations + DFPkgs + Permit2 aware.
- `crane-utilities` — Math (ConstProdUtils), sets, EIP712, cryptography, pagination.
- `crane-porting` — How to vendor protocols into `contracts/external` + `contracts/protocols` with shared transitive deps (no private OZ clones).
- `crane-porting-verification` — Hermetic/fork tests, Behaviors, and definition-of-done gates for ports.
- `docs-to-skills` — Crawl full documentation sites/trees; inventory every page; emit multi-skill families with coverage reports.
- `skill-authoring` — Progressive disclosure, description triggers, compartmentalized `references/`, quality checklists for SKILL.md.

### Agent identities

- `crane-porter` (`.claude/agents/crane-porter.md`) — end-to-end protocol porting sessions (vendor, remap, wrap, verify).
- `docs-skill-scribe` (`.claude/agents/docs-skill-scribe.md`) — documentation scrape → progressive-disclosure skill families.

## Protocol Skills (Reusable Ports)

Extensive high-quality ports with dedicated skills:
- Balancer V3 (all pool types: weighted, stable, gyro, ReClamm, COW, hooks, vault ops)
- Uniswap V2 / V3 / V4 (pools, positions, swaps, hooks, flash accounting)
- Aerodrome + Slipstream (pools, gauges, CL math, rewards, voter)
- Aave v3 + v4 Hub/Spoke (full architecture, config, liquidation, tokens, position mgr)
- Euler (EVC, EVault, risk, oracles, periphery)
- And many more (Pendle, Frax ecosystem, Reliquary, Resupply, Comet, Permit2, Chainlink VRF, etc.)

Each protocol skill teaches both the external protocol *and* how Crane wraps it with services, aware repos, DFPkgs, and test infrastructure.

## How Agents Should Use Skills

1. When the user asks for a feature, call the relevant skill(s) first.
2. Generate code that follows the documented patterns exactly.
3. Add NatSpec + tags.
4. Write accompanying tests using the testing skill.
5. After delivery, consider contributing an updated or new skill so the knowledge persists for all agents.

## Maintaining Skills

Skills live in this repo under `.claude/skills/<name>/SKILL.md`.

- Keep them concise but example-rich.
- Include "references/" sub-files for long examples.
- Update when the underlying contracts or best practices evolve.
- Remove or archive stale "copy" directories.

See the root AGENTS.md for broader instructions.

## Installable marketplaces

For agents that load skills via Claude Code / Codex / Grok / OpenCode marketplaces:

| Marketplace | Audience | Install |
|-------------|----------|---------|
| [cyotee/cyotee-claude-plugins](https://github.com/cyotee/cyotee-claude-plugins) | Developers building on Crane and DeFi protocols | `/plugin marketplace add cyotee/cyotee-claude-plugins` then `/plugin install crane@cyotee` |
| [cyotee/defi-agent-skills](https://github.com/cyotee/defi-agent-skills) | Agents operating on-chain (cast/Bankr runbooks) | `/plugin marketplace add cyotee/defi-agent-skills` |

## Related tools

- Forge skills (`forge-testing`, `forge-fuzz-testing`, `forge-deployment`)
- Optional TS/JS agent tooling (tevm, voltaire-effect, wagmi) via the developer marketplace

Using these skills together gives agents a structured way to build and ship modular on-chain software with Crane patterns.
