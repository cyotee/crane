# Crane

**Diamond-first (ERC-2535) Solidity framework for modular, upgradeable smart contracts.**

Crane separates storage (**Repo**), business logic (**Target**), and Diamond exposure (**Facet**) into clear layers. CREATE3 factories and Diamond packages deploy once at deterministic addresses; proxies compose instances cheaply across EVM chains. The same structure is designed for **humans and AI agents**: reuse verified facets instead of redeploying risk.

- **Docs (GitHub Pages):** https://cyotee.github.io/crane/
- **Repository:** https://github.com/cyotee/crane
- **Agent marketplaces:** [cyotee-claude-plugins](https://github.com/cyotee/cyotee-claude-plugins) (build) · [defi-agent-skills](https://github.com/cyotee/defi-agent-skills) (operate)

## Why Crane

| Capability | What you get |
|------------|----------------|
| **Deterministic factories** | CREATE3 + Diamond package factory for reproducible cross-chain deploys |
| **Deploy once, attach often** | Facets and packages reused via DFPkgs instead of redeploying bytecode every project |
| **Facet-Target-Repo** | Storage slots, thin targets, metadata-rich facets — easier to audit and agent-generate |
| **Foundry-native tests** | `TestBase_*`, `Behavior_*`, handlers, and fork patterns alongside the code |
| **Agent-native** | Skills under `.claude/skills/` plus installable marketplaces |

Primary security advantage for agent-driven work: **reuse already deployed and verified logic**. New Diamonds attach existing facets rather than regenerating large surfaces of unaudited bytecode.

## Quick start

```bash
git clone --recurse-submodules https://github.com/cyotee/crane.git
cd crane
forge build

# Core path used by CI (recommended for most work)
FOUNDRY_PROFILE=ci forge build
FOUNDRY_PROFILE=ci forge test
```

Bootstrap factories in tests:

```solidity
import {InitDevService} from "@crane/contracts/InitDevService.sol";

(ICreate3FactoryProxy create3Factory, IDiamondPackageCallBackFactory diamondFactory) =
    InitDevService.initEnv(address(this));
```

See [docs/getting-started.md](docs/getting-started.md) and [docs/SUMMARY.md](docs/SUMMARY.md).

## Documentation

| Resource | Link |
|----------|------|
| Published docs | https://cyotee.github.io/crane/ |
| Getting started | [docs/getting-started.md](docs/getting-started.md) |
| Building with Crane | [docs/concepts/building-with-crane.md](docs/concepts/building-with-crane.md) |
| CREATE3 / DFPkg | [docs/deployment/](docs/deployment/) |
| Testing | [docs/development/testing.md](docs/development/testing.md) |
| Contributor guide | [AGENTS.md](AGENTS.md) · [CONTRIBUTING.md](CONTRIBUTING.md) |

Local docs preview (requires [mdBook](https://rust-lang.github.io/mdBook/)):

```bash
bash scripts/build_docs_pages.sh
mdbook serve --open
```

## AI agents

Crane is intended for AI-assisted Solidity development:

1. **In-repo skills** — `.claude/skills/` (`crane-architecture`, `crane-deployment`, `crane-testing`, protocol deep-dives, etc.). See [docs/reference/agent-skills.md](docs/reference/agent-skills.md).
2. **Developer marketplace** — architecture, Crane commands, Foundry, protocol skills:

   ```bash
   /plugin marketplace add cyotee/cyotee-claude-plugins
   /plugin install crane@cyotee
   ```

3. **Ops marketplace** — on-chain cast/Bankr runbooks (product operations, not architecture dumps):

   ```bash
   /plugin marketplace add cyotee/defi-agent-skills
   /plugin install foundry-agent@defi-agent-skills
   ```

Also works with Codex, Grok Build, and OpenCode (see each marketplace README).

## Architecture (short)

- **Facet-Target-Repo** — assembly-bound storage libraries, thin Targets, Facets implementing `IFacet`
- **DFPkg** — bundled facet cuts + init for repeatable Diamonds
- **CREATE3** — salt from type-name hashes for deterministic addresses
- **Registries** — facet / package / call-target discovery as factories run

Details: [docs/concepts/](docs/concepts/) and [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md).

## Protocol ports & maturity

Crane vendors and wraps many DeFi protocols (Uniswap, Balancer, Aerodrome, Aave, Euler, and others) under `contracts/protocols/` and `contracts/external/`.

**Core factories, access control, tokens, and registries** are the primary supported product surface. Individual protocol ports vary from production-oriented wrappers to vendored-upstream / experimental. Prefer docs and skills for a given port, and do not assume every tree is battle-tested for mainnet.

## Build & test commands

```bash
forge build
FOUNDRY_PROFILE=ci forge test
forge test --match-path test/foundry/spec/... -vvv
forge fmt
```

Full monorepo compile (including large protocol trees) can require significant memory; use the **ci** profile for a reliable core gate.

## Security

Please report vulnerabilities privately via GitHub Security Advisories:

→ **[SECURITY.md](SECURITY.md)**

BattleChain may be used as an optional adversarial deployment gate for factories; it is not a substitute for responsible disclosure or a formal audit of every port.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md) for style, NatSpec, testing, and PR expectations.

## License

Crane-native code is licensed under the **GNU Affero General Public License v3.0** — see [LICENSE](LICENSE).

Vendored dependencies and protocol sources retain **their original licenses**. See [NOTICE.md](NOTICE.md) and the `licenses/` directory.
