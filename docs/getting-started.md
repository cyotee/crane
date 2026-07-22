# Getting Started

Crane is a **Diamond-first (ERC-2535)** framework for building modular, upgradeable Solidity contracts with deterministic deployment, reusable logic, and first-class support for AI agents.

## Why reuse matters

**Security.** Prefer attaching already deployed and verified facets (via DFPkgs) instead of redeploying large surfaces of new bytecode—especially when an AI agent writes the change.

**Cost.** Facets and packages deployed once can be reused by many proxies and projects, so you do not pay full deployment cost for the same logic every time.

**Cross-chain reproducibility.** CREATE3 salts yield the same addresses when configuration matches.

## Documentation map

| Topic | Page |
|-------|------|
| CREATE3 / new chain / factory reuse | [CREATE3 & New Chain Setup](deployment/create3.md) |
| DFPkg operations | [Diamond Factory Packages](deployment/dfpkg.md) · [DFPkg Pattern](concepts/dfpkg.md) |
| Registries | [Registries](concepts/registries.md) |
| Testing / TestBases | [Testing Patterns](development/testing.md) |
| DEX / lending ports | [DEX Integrations](protocols/dexes.md) · [Lending](protocols/lending.md) |
| Sets / ConstProdUtils | [Utilities Overview](utilities/overview.md) · [Sets](utilities/sets.md) · [Math](utilities/math-const-prod.md) |
| Building modules | [Building with Crane](concepts/building-with-crane.md) |
| Architecture map | [Codebase Map](CODEBASE_MAP.md) |
| AI agent skills | [Agent Skills](reference/agent-skills.md) |

## Install

```bash
git clone --recurse-submodules https://github.com/cyotee/crane.git
cd crane
forge build

# Core path (matches CI)
FOUNDRY_PROFILE=ci forge build
FOUNDRY_PROFILE=ci forge test
```

As a Foundry dependency:

```bash
forge install cyotee/crane
```

Update your `remappings.txt` and `foundry.toml` (see this repo for aliases such as `@crane/`).

Bootstrap factories in tests:

```solidity
import {InitDevService} from "@crane/contracts/InitDevService.sol";

(ICreate3FactoryProxy create3Factory, IDiamondPackageCallBackFactory diamondFactory) =
    InitDevService.initEnv(address(this));
```

## For AI agents

1. **Load skills** — Prefer in-repo `.claude/skills/` and/or install marketplaces:
   - Developer: [cyotee/cyotee-claude-plugins](https://github.com/cyotee/cyotee-claude-plugins) → `crane@cyotee`
   - Ops: [cyotee/defi-agent-skills](https://github.com/cyotee/defi-agent-skills) (on-chain runbooks; not architecture dumps)
2. **Start with** `crane-architecture`, `crane-deployment`, and `crane-testing`.
3. **Use Facet-Target-Repo + DFPkg** for new features — Repo for storage, Target for logic, Facet for Diamond exposure.
4. **Bootstrap via `Init*Service` or Crane test bases** — avoid ad-hoc `new` for production deployment paths.
5. **Follow NatSpec conventions** in [AGENTS.md](../AGENTS.md) and [NatSpec docs](development/natspec.md).
6. **Optional BattleChain gate** — significant factories/packages may be exercised on BattleChain before mainnet promotion; see [BattleChain](deployment/battlechain.md).

## Next steps

- Read [Building with Crane](concepts/building-with-crane.md)
- Skim [Facet-Target-Repo](concepts/facet-target-repo.md)
- Try [CREATE3 setup](deployment/create3.md) and [DFPkg](deployment/dfpkg.md)
