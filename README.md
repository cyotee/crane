# Crane

**Diamond-first (ERC2535) Solidity development framework for modular, upgradeable DeFi contracts.**

Crane separates storage (Repo), business logic (Target), and Diamond exposure (Facet) into distinct layers. Core factories and facets deploy once at deterministic CREATE3 addresses. Diamond proxies and packages compose instances cheaply and reproducibly across every EVM chain.

Production-grade implementation: 270+ tracked tasks, full factory system, extensive protocol integrations, and a native AI-agent skill library.

## Primary Value

- **Deterministic factories** — CREATE3 + DiamondPackageCallBackFactory for cross-chain reproducible deployments.
- **One-time logic cost** — Facets + packages deployed once; unlimited proxies reuse them (see "Reusability for Agents: Security and Cost (LR-4)" below for exact rationale and agent examples).
- **Structured architecture** — Facet-Target-Repo + AwareRepo + Service patterns keep code maintainable and auditable.
- **Battle-tested release process** — Every significant primitive **must** survive adversarial testing on BattleChain before Base/mainnet promotion.
- **Agent-native** — Pre-built skills for Claude Code / Bankr / other agents covering Balancer V3 (all pool types), Uniswap V3/V4, Aerodrome + Slipstream, Camelot, Aave, Euler, Compound Comet, Resupply, and more.

## Reusability for Agents: Security and Cost (LR-4)

The primary security advantage of Crane is the ability to **reuse already deployed and verified code**. When code is known to be good, reusing it (via facets attached through DFPkgs) eliminates the risk of introducing new bugs through inadvertent changes. This risk is especially high when development or deployment work is delegated to an AI agent. Reusing battle-tested, already-audited deployed logic removes that class of error.

Because you can reuse already deployed facets and packages, you do not need to deploy that code yourself on every project or chain instance. This directly saves gas by simply not needing to deploy as much bytecode.

Crane enables **agent-proof reuse** and **"deploy once, attach everywhere"**:

- Use the Create3FactoryDFPkg (via `packageName()` selector `0xabc8b346` and related from central values) to bootstrap your own Create3Factory once per new chain for deterministic deployments.
- The DiamondPackageCallBackFactory (interface ID `0x949da331` from `CENTRALLY_COMPUTED_NATSPEC_VALUES.md`; e.g. `deploy` at `0xe97fac05`) is safe for public reuse — it does **not** need to be redeployed per chain. Deploy proxies from packages without duplicating the factory logic.
- Registries (Facet, Package, CallTarget) are auto-populated during Create3Factory and DFPkg operations; query them via canonical getters for already-verified components.
- Attach facets from any DFPkg (e.g. `facetCuts()`, `initAccount()` at `0x870d4838`, `postDeploy()` at `0x70068fcf`) to compose Diamonds cheaply.
- For development, inherit protocol TestBases (e.g. `TestBase_CamelotV2`, `TestBase_BalancerV3Vault`) and use utilities such as `ConstProdUtils` and type Sets (AddressSet/Bytes4Set + *SetRepo patterns) to accelerate agent-driven implementation with shared, tested logic.

All claims are grounded in this reuse-based reasoning. See [docs/SUMMARY.md](docs/SUMMARY.md) (GitBook nav), [docs/getting-started.md](docs/getting-started.md), [docs/deployment/create3.md](docs/deployment/create3.md), [docs/deployment/dfpkg.md](docs/deployment/dfpkg.md), [docs/development/testing.md](docs/development/testing.md), and `.claude/skills/` (crane-deployment, crane-architecture, crane-testing) for usage. Cross-reference [AGENTS.md](AGENTS.md) for patterns and central NatSpec values (e.g. IFacet selectors `0x5b6f4d01`, `0x2ea80826`).

## The DAOSYS Token + Bounty Board

The DAOSYS token (name: DAOSYS, symbol: DAOSYS) represents the broader DAOSYS project (this workspace + Crane framework). It serves as the work token for an on-chain bounty board where AI agents (and humans) get paid to extend Crane, the DAOSYS examples, frontend tooling, and on-chain coordination features:

- Anyone deposits DAOSYS to post a feature request with milestone terms.
- Agents claim work, deliver PRs + tests + BattleChain survival (where applicable), and earn DAOSYS on approval.
- Agents sell earned DAOSYS for compute credits (via Bankr LLM Gateway).
- Trading fees on the DAOSYS token (launched via BankrBot on Base) help sustain ongoing development.

The token contracts, bounty board, and UI will be implemented in the DAOSYS repo (using Crane's Diamond factories, DFPkgs, and patterns).

Full model: see Crane's [GOVERNANCE.md](GOVERNANCE.md) and [BANKR_LAUNCH.md](BANKR_LAUNCH.md) (rebranded for the DAOSYS launch), plus future docs in the DAOSYS root.

**Token launch target:** Base (via BankrBot fair launch). Core components first battle-tested on BattleChain (627/626) as needed.

## BattleChain Security Gate (Required)

Before any mainnet deployment of Crane factories, packages, or ported protocol components:

1. Deploy to BattleChain testnet (627), then mainnet (626).
2. Create Safe Harbor agreement (scope the top-level Create3Factory with `ChildContractScope.All` for lineage coverage).
3. Request attack mode → survive whitehat testing.
4. Promote to PRODUCTION.
5. Only then ship identical bytecode to Base or other chains.

See the pilot in `scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol` + `contracts/InitBcService.sol`. Update AGENTS.md in consuming repos.

BattleChain docs (machine readable): https://docs.battlechain.com/llms-full.txt

## Core Patterns

- **Facet-Target-Repo** — Storage libraries with assembly slot binding, thin Targets, metadata-rich Facets implementing IFacet.
- **DFPkg + Diamond Factory** — Bundled facet cuts + init logic for repeatable Diamonds.
- **CREATE3 determinism** — Salt from type name hashes.
- **Test infrastructure** — `TestBase_*` + `Behavior_*` libraries + declarative invariant handlers live alongside the code.

See [AGENTS.md](AGENTS.md) and [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md) for details.

## Quick Start (Dev / Tests)

```bash
forge build
forge test
```

Bootstrap factories in tests:

```solidity
import {InitDevService} from "@crane/contracts/InitDevService.sol";

(contract ICreate3FactoryProxy create3Factory, IDiamondPackageCallBackFactory diamondFactory) =
    InitDevService.initEnv(address(this));
```

For BattleChain deploys use the parallel `InitBcService.initEnvBc(...)`.

## Documentation & Skills

- **Getting Started (incl. For AI Agents)**: [docs/getting-started.md](docs/getting-started.md)
- **Building Custom Modules**: [docs/concepts/building-with-crane.md](docs/concepts/building-with-crane.md)
- NatSpec + include-tag standard: [AGENTS.md](AGENTS.md) and [docs/development/natspec.md](docs/development/natspec.md)
- **AI Agent Skills**: `.claude/skills/` (crane-* core + 50+ protocol deep-dives for Aave, Balancer, Uniswap, Aerodrome/Slipstream, Euler, etc.). See [docs/reference/agent-skills.md](docs/reference/agent-skills.md).
- GitBook docs: `docs/SUMMARY.md` + organized guides under concepts/, deployment/, protocols/.

## Build & Test Commands

```bash
forge build
forge test
forge test --match-path test/foundry/spec/... -vvv
forge fmt
```

See full commands in [AGENTS.md](AGENTS.md).

## Professional Launch Readiness & Token

This repo is being prepared to professional standards so that other agents can confidently use Crane to build and deploy secure, low-cost modular contracts:

- Full NatSpec everywhere critical.
- Complete, GitBook-formatted docs (see [docs/SUMMARY.md](docs/SUMMARY.md) for GitBook navigation, including LR-2 required areas: CREATE3 Package chain setup, reusable DiamondPackageCallBackFactory (0x949da331), registries, ported protocol TestBases + utilities like ConstProdUtils/Sets).
- Up-to-date agent skills for the framework and ports.
- Emphasis on **reuse-based security and cost**: reusing already deployed and verified code (via facets attached through DFPkgs) eliminates the risk of introducing new bugs through inadvertent changes (especially high for AI-delegated work); reusing it directly saves gas by simply not needing to deploy as much bytecode. Supports "deploy once, attach everywhere" and "agent-proof reuse".

**Funding**: Trading fees from a BankrBot-launched token on Base will sustain development. See [BANKR_LAUNCH.md](BANKR_LAUNCH.md) for the process (requires Bankr Club subscription on an agent wallet + `bankr launch`).

Repository: https://github.com/cyotee/crane (public mirrors at launch).

## License

See LICENSE and licenses/ directory (mixed AGPL-3.0-or-later with vendored dependencies under their original terms).

## License

See LICENSE and licenses/ directory (mixed AGPL-3.0-or-later with vendored dependencies under their original terms).
