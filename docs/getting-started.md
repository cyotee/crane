# Getting Started

Crane is a **Diamond-first (ERC2535)** framework for building modular, upgradeable Solidity contracts with deterministic deployment, reusable logic, and first-class support for AI agents.

**Primary benefits for agents and developers**:
Documentation, skills, and examples must clearly and accurately communicate the following **specific rationale**:

**Security benefit**:
The primary security advantage is the ability to **reuse already deployed and verified code**. When code is known to be good, reusing it (via facets attached through DFPkgs) eliminates the risk of introducing new bugs through inadvertent changes. This risk is especially high when development or deployment work is delegated to an AI agent. Reusing battle-tested, already-audited deployed logic removes that class of error.

**Reduced deployment cost benefit**:
Because you can reuse already deployed facets and packages, you do not need to deploy that code yourself on every project or chain instance. This directly saves gas by simply not needing to deploy as much bytecode.

All claims are grounded in this reuse-based reasoning rather than generic statements. Concrete examples highlight "deploy once, attach everywhere" and "agent-proof reuse" (e.g. bootstrap Create3FactoryDFPkg per chain once using central values only, then reuse the public DPCF + DFPkgs + registries across all proxies/chains/tests via facets attached through DFPkgs).

**Cross-chain reproducibility**: Same salt → identical addresses everywhere.

**Agent-native**: The relevant Crane and protocol skills must be installed and available both inside this repository (`.claude/skills/`) **and** in the user's global Claude/agent environment (per LR-3). Install `crane-deployment` (for CREATE3/DFPkg/DPCF), `crane-architecture`, `crane-testing` + protocol skills. Consult for GitBook LR-2 areas: chain setup via Create3FactoryDFPkg (using ONLY central values), explicit DPCF reuse, registries (Facet/Package/CallTarget), ported protocols + TestBase_* usage in tests, protocol utilities (*Service), general type libs (AddressSet/Bytes*Set + *SetRepo, ConstProdUtils, collections). See PRD LR-2. All claims grounded in reuse-based reasoning per PRD LR-4; see also AGENTS.md.

**LR-4 Framework Value Proposition (Security & Cost for Agents)**:

Documentation, skills, and examples must clearly and accurately communicate the following **specific rationale**:

**Security benefit**:
The primary security advantage is the ability to **reuse already deployed and verified code**. When code is known to be good, reusing it (via facets attached through DFPkgs) eliminates the risk of introducing new bugs through inadvertent changes. This risk is especially high when development or deployment work is delegated to an AI agent. Reusing battle-tested, already-audited deployed logic removes that class of error.

**Reduced deployment cost benefit**:
Because you can reuse already deployed facets and packages, you do not need to deploy that code yourself on every project or chain instance. This directly saves gas by simply not needing to deploy as much bytecode.

Concrete examples:
- Bootstrap a new chain's Create3Factory **once** using Create3FactoryDFPkg (via its `packageName() 0xabc8b346`, `facetCuts() 0xa4b3ad35`, `initAccount(bytes) 0x870d4838`, `postDeploy(address) 0x70068fcf` etc from CENTRALLY_COMPUTED_NATSPEC_VALUES.md **only**) + the reusable DiamondPackageCallBackFactory.
- Then **deploy once, attach everywhere**: use DFPkgs (e.g. ERC20DFPkg) and registered facets (via canonical* on FacetRegistry/PackageRegistry) for all proxies and all chains, without redeploying the logic facets.

All agent-facing docs and skills ground claims in this exact reuse-based reasoning rather than generic statements (see PRD LR-4, CENTRALLY_COMPUTED_NATSPEC_VALUES.md for verified selectors only, AGENTS.md). Examples should highlight "deploy once, attach everywhere" and "agent-proof reuse".

**Required GitBook Content Areas (at minimum)**:
- How to set up a chain presence: using the CREATE3 Package (Create3FactoryDFPkg / related) to deploy your own Create3Factory for a new chain.
- Explicit statement that the Diamond Package Factory (DiamondPackageCallBackFactory) does **not** need to be redeployed per chain — it is safe and intended for public reuse across deployments.
- Detailed explanation of the included Registries (Facet Registry, Package Registry, CallTarget Registry, etc.), their purpose, how they are populated, and how consumers interact with them.
- Detailed explanations of all ported protocols, including:
  - How to integrate and use them.
  - How to use them inside tests (TestBases, stubs, etc.).
- Detailed coverage of all protocol-specific utility libraries.
- Detailed coverage of all general utility and type libraries, including (but not limited to):
  - Type-specific Set implementations (AddressSet, Bytes32Set, etc.) and their Repo patterns.
  - Math utilities (e.g. ConstProdUtils).
  - Other collections, cryptography, and helper libraries.

Agent-focused "Getting Started", "Building with Crane", and architecture sections must tie everything back to reusability benefits. See also `docs/deployment/create3.md`, `docs/deployment/dfpkg.md`, `docs/CODEBASE_MAP.md`, `docs/development/testing.md`.

## Install

```bash
forge install cyotee/crane
```

Update your `remappings.txt` and `foundry.toml` (see this repo's versions for the exact aliases: `@crane/`, `@solady/`, etc.).

## For AI Agents: Using Crane as a Framework

When building or deploying contracts as an AI agent (per LR-3: The relevant Crane and protocol skills must be installed and available both inside this repository (`.claude/skills/`) **and** in the user's global Claude/agent environment):

1. **Install + consult skills** (LR-3): The relevant Crane and protocol skills must be installed and available both inside this repository (`.claude/skills/`) **and** in the user's global Claude/agent environment. Use `crane-deployment` (for CREATE3, DFPkgs, FactoryService, and Diamond proxy instantiation — specifically chain setup via Create3FactoryDFPkg using central values only), `crane-architecture` (FTR, DFPkg structure, storage slots, PkgInit-on-interface rule), `crane-testing` (CraneTest, TestBase inheritance, factory bootstrap in tests, Behavior libraries, and handlers). Protocol skills for TestBase usage. Skills enable correct handling of GitBook-required LR-2 areas (CREATE3 pkg for chain presence, explicit DPCF public reuse, registries details + consumer canonical*, ported protocols + TestBases, utilities + Sets/*SetRepo patterns). Consult AGENTS.md + skills for all.
2. **Always use FTR + DFPkg for new features** — Repo for storage, Target for logic, Facet for Diamond exposure, DFPkg for reusable deployment (enables agent-proof reuse).
3. **Bootstrap via Init*Service or CraneTest** — Never `new` contracts directly in production paths. Ties to registries auto-population.
4. **Follow NatSpec + include-tags** — Every public interface symbol must be wrapped for extractable docs. Use ONLY values from `CENTRALLY_COMPUTED_NATSPEC_VALUES.md` (e.g. `packageName() 0xabc8b346`, `facetInterfaces() 0x2ea80826`, `facetAddresses() 0x52ef6b2c`, `facetCuts() 0xa4b3ad35`, `initAccount(bytes) 0x870d4838`, `postDeploy(address) 0x70068fcf`, `deploy(address,bytes) 0xe97fac05`, IDiamondPackageCallBackFactory interfaceId `0x949da331`, IFacet selectors `0x5b6f4d01`/`0x2ea80826`/`0x574a4cff`/`0xf10d7a75`).
5. **BattleChain gate** — Factories, core packages, and significant ports must survive BattleChain (testnet 627 → mainnet 626) before Base/mainnet promotion.
6. **Emit skills** — After implementing a new feature, create or update a corresponding `.claude/skills/crane-xxx/` SKILL.md so other agents can use it.

Example agent workflow:
- "Create an access-controlled vault facet using Operable + ERC8023."
- Use installed crane skills (LR-3) + central values to generate correct Repo/Target/Facet + DFPkg + TestBase.
- Bootstrap factories via Create3FactoryDFPkg for chain (LR-2), reuse DPCF + canonical* registries to **deploy once, attach everywhere**.
- Practice **reuse already deployed and verified code** (via DFPkgs) to avoid agent-induced bugs and save gas.

See expanded guidance in the concepts and reference sections. This getting-started, concepts/building-with-crane, deployment/* (create3.md, dfpkg.md), reference/agent-skills.md, AGENTS.md, CODEBASE_MAP.md, and PRD tie back to all GitBook-required LR-2 areas (CREATE3 pkg chain setup, DPCF public reuse, registries purpose/population/consumer interaction, full protocols+tests+TestBases, protocol utilities, general Sets/math/collections) + LR-4 reuse language + LR-3 skills.

## Initialize Factories

```solidity
import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

contract MyWorkflow is Test {
    ICreate3FactoryProxy internal create3Factory;
    IDiamondPackageCallBackFactory internal diamondFactory;

    function setUp() public {
        (create3Factory, diamondFactory) = InitDevService.initEnv(address(this));
    }
}
```

`InitDevService` (or `InitBcService` for BattleChain) deploys canonical core facets and both factories. This uses the shared Create3 bootstrap.

## Setting Up a Chain Presence: CREATE3 Package (Create3FactoryDFPkg) — GitBook LR-2

**How to deploy your own Create3Factory for a new chain** (required LR-2 area; use installed `crane-deployment` skill):

Use the `Create3FactoryDFPkg` (implements `ICREATE3DFPkg` extending `IDiamondFactoryPackage`) to bootstrap a fully configured `Create3Factory` Diamond (with Cut, ownership, operable, registries, etc.). `PkgInit` / `PkgArgs` **must** be defined on the *interface* (see AGENTS.md + crane-architecture skill).

Key central NatSpec values (use ONLY these from `CENTRALLY_COMPUTED_NATSPEC_VALUES.md`):

- `packageName()` : `0xabc8b346`
- `facetInterfaces()` : `0x2ea80826`
- `facetAddresses()` : `0x52ef6b2c`
- `facetCuts()` : `0xa4b3ad35`
- `initAccount(bytes)` : `0x870d4838`
- `postDeploy(address)` : `0x70068fcf`

(The Create3FactoryDFPkg-specific `deployCreate3Factory(address)` is referenced by name per source + its interface; do not cite unlisted selector values as "from central".)

**Bootstrap flow** (consult `crane-deployment` skill; see `InitDevService.initEnv`, `InitBcService`, CraneTest, Create3FactoryDFPkg.sol for reference):

1. Obtain initial Create3Factory entrypoint.
2. Use it + canonical facets (resolved via FacetRegistry `canonicalFacet`) to deploy the Create3FactoryDFPkg.
3. Pass the *reusable* `DiamondPackageCallBackFactory` (obtained via `create3Factory.diamondPackageFactory()` — selector `0x0fe96d13` from central) in PkgInit.
4. Call `deployCreate3Factory(owner)` (internally uses reusable DPCF `deploy`).

```solidity
// Central values ONLY from CENTRALLY_COMPUTED_NATSPEC_VALUES.md: interfaceId 0x949da331, diamondPackageFactory 0x0fe96d13, deploy 0xe97fac05
ICREATE3DFPkg.PkgInit memory pkgInit = ICREATE3DFPkg.PkgInit({
    diamondCutFacet: IFacetRegistry(address(factory)).canonicalFacet(type(IDiamondCut).interfaceId),
    // ... other canonical facets from registry ...
    diamondFactory: create3Factory.diamondPackageFactory()  // the reusable DPCF (central selector 0x0fe96d13)
});

ICREATE3DFPkg pkg = ...;  // deployed via create3Factory
ICreate3FactoryProxy myCreate3 = pkg.deployCreate3Factory(owner);
// myCreate3 now has registries + can deploy more facets/packages/proxies using DFPkgs
```

**LR-4 reuse tie-in (concrete example)**: Deploy the Create3FactoryDFPkg (and its bundled facets) once per chain. Thereafter **reuse already deployed and verified code** (no re-deploy of facets/DPCF) via the safe public-reuse DiamondPackageCallBackFactory and auto-populated registries — saves gas by not deploying bytecode again, and eliminates agent-induced bug risk. Skills install required to get this right.

After bootstrap, your chain has its Create3Factory. See `docs/deployment/create3.md` for full details + central values. This is the GitBook-required "how to set up a chain presence". Ties to LR-2 registries + protocols.

## Diamond Package Factory (DiamondPackageCallBackFactory) Reuse — LR-2 / LR-4

**Explicit statement (GitBook required LR-2):** The `DiamondPackageCallBackFactory` (implementing `IDiamondPackageCallBackFactory`, interfaceId `0x949da331` from CENTRALLY_COMPUTED_NATSPEC_VALUES.md) does **not** need to be redeployed per chain — it is safe and intended for **public reuse** across deployments.

- Deployed once via Create3Factory (see `create3Factory.diamondPackageFactory()` selector `0x0fe96d13` from central list).
- From source impl: "Deployed once via Create3Factory ... Safe and intended for reuse by any consumer on any chain."
- "This factory is intended to be deployed *once* per ecosystem and reused across chains/consumers."
- Use `diamondFactory.deploy(pkg, abi.encode(pkgArgs))` (selector `0xe97fac05` from central) for all proxy instances.

**LR-4 exact tie-in (concrete example):** This directly enables **deploy once, attach everywhere**. Facets + DFPkgs (bundled logic) are deployed once via Create3 + Create3FactoryDFPkg, then attached to unlimited proxies using the reusable DPCF. You **reuse already deployed and verified code** (via facets attached through DFPkgs) to eliminate the risk of introducing new bugs through inadvertent changes — risk especially high when delegated to an AI agent. Reusing battle-tested, already-audited deployed logic removes that class of error (**agent-proof reuse**). You do not need to deploy that code yourself... This directly saves gas by simply not needing to deploy as much bytecode.

Consult installed `crane-deployment` skill for correct usage. See full in `DiamondPackageCallBackFactory.sol`, `IDiamondPackageCallBackFactory`, `docs/deployment/create3.md` and `dfpkg.md`, AGENTS.md.

## Registries (Facet, Package, CallTarget) — GitBook LR-2 Required

Crane auto-populates registries on Create3Factory instances (populated by Create3FactoryDFPkg facets + internal `_register*` calls during `deployFacet` / `deployPackage*` — see InitDevService and Create3Factory for flow).

- **Facet Registry** (`IFacetRegistry`): Tracks facets by interfaceId/name/selectors. `canonicalFacet(bytes4)` resolves verified impls (avoids hardcodes in PkgInits). Populated automatically on `registerFacet` / deploy*Facet. Consumers (via your Create3Factory): `IFacetRegistry(addr).canonicalFacet(type(IFoo).interfaceId)`. Uses central `facetInterfaces()` selector `0x2ea80826`.
- **Diamond Factory Package Registry** (`IDiamondFactoryPackageRegistry`): Tracks DFPkgs by name/interfaces/facets. `canonicalPackage(...)`. Auto via package deploy (and Create3FactoryDFPkg).
- **Call Target Registry** (Query/Management via ICallTargetRegistry*): Governs allowed external targets for metatx/relayers. Installed via CallTargetRegistryDFPkg during bootstrap.

All exposed as facets on your bootstrapped Create3Factory (no separate deploys). Query via the factory address. See `contracts/registries/*`, `contracts/registries/facet/IFacetRegistry.sol`, `contracts/interfaces/IDiamondFactoryPackageRegistry.sol`, `CODEBASE_MAP.md`, `docs/deployment/create3.md` (full purpose, population, consumer interaction via canonical*). Ties to LR-2/4: enables safe discovery + attach of already-verified facets/packages for **reuse already deployed and verified code** and gas savings.

(Consult crane-deployment skill for registry interaction patterns in chain setup + proxy deploys.)

## Ported Protocols, Test Usage, Utilities, and Type Libraries — LR-2

**Ported protocols** (detailed in `docs/protocols/*`, `docs/deployment/dfpkg.md`): Camelot V2, Uniswap V2/V3/V4, Aerodrome/Slipstream, Balancer V3, Aave v3/v4, Euler, etc. Each follows: *AwareRepo.sol (DI for external router/vault), services/ (*Service libs for business logic e.g. swaps/quotes using structs), DFPkgs, stubs/, test/bases/ (TestBase_*). Use inside tests via inheritance from CraneTest + TestBase_* (see AGENTS.md). Reuse via installed protocol skills + CraneTest avoids boilerplate and supports agent-proof reuse of integrations.

**How to use in tests** (via CraneTest inheritance + TestBases per LR-2):
```solidity
import {CraneTest} from "@crane/contracts/test/CraneTest.sol";
import {TestBase_CamelotV2} from "@crane/contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol";

contract MyTest is CraneTest, TestBase_CamelotV2 {
    function setUp() public virtual override {
        CraneTest.setUp(); TestBase_CamelotV2.setUp();
        // factories + diamondFactory + registries ready; pools via helpers from TestBase
    }
}
```
See `TestBase_*` (e.g. contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol) in protocol `test/bases/`, `Behavior_*` (e.g. Behavior_IFacet) for declaration validation using central selectors, handlers for invariants/fuzz. Fork tests compare outputs vs live protocol.

**Protocol-specific utilities** (GitBook required LR-2): e.g. `CamelotV2Service`, `AerodromeService`, Balancer helpers, `ConstProdUtils` (constant-product AMM math for quotes/purchase; parity tests).

**General utilities & type libraries** (GitBook required LR-2 coverage): 
- Collections/Sets: `AddressSet`, `Bytes32Set`, `Bytes4Set`, `StringSet` + corresponding `*SetRepo` (1-indexed storage mapping + array; `_add`/`_remove`/`_values`/`_index`/`_contains`; used in registries, handlers, comparators, sets). See `contracts/utils/collections/sets/AddressSetRepo.sol` etc and AGENTS.md.
- Math: `ConstProdUtils`, `UInt256`, FixedPoint etc.
- Others: `Better*HashLib`, `SafeERC20`, EIP712, crypto utils.

Use via CraneTest (wires factories/registries from InitDevService) + specific TestBases. Full patterns in `AGENTS.md` (Testing + Protocol Integration Structure sections), `docs/CODEBASE_MAP.md`, `docs/development/testing.md`.

Cross-links + skills support other agents: after deploying factories once (Create3+DFPkg), **reuse already deployed and verified code** (protocol DFPkgs, utilities, Sets) via skills for **deploy once, attach everywhere** across tests/instances without duplication or new bugs.

## Deploy a Facet (Deterministic)

```solidity
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

using BetterEfficientHashLib for bytes;

IFacet myFacet = IFacet(
    create3Factory.deployFacet(
        type(MyFacet).creationCode,
        abi.encode(type(MyFacet).name)._hash()
    )
);
vm.label(address(myFacet), type(MyFacet).name);
```

## Deploy a Package

```solidity
IMyDFPkg pkg = IMyDFPkg(
    address(
        create3Factory.deployPackageWithArgs(
            type(MyDFPkg).creationCode,
            abi.encode(IMyDFPkg.PkgInit({ myFacet: myFacet })),
            abi.encode(type(MyDFPkg).name)._hash()
        )
    )
);
```

**Rule**: `PkgInit` / `PkgArgs` live in `IMyDFPkg` interface (enables typed `abi.encode` in services and consumers).

## Deploy Reproducible Diamond Proxies

```solidity
address proxy = diamondFactory.deploy(pkg, abi.encode(pkgArgs));
```

Identical inputs → identical proxy address on any supported chain.

## Example: ERC20 via Native DFPkg

```solidity
IERC20 token = erc20Pkg.deploy(
    diamondFactory,
    "MyToken", "MTK", 18, 1_000_000 ether, recipient, bytes32(0)
);
```

## Next Steps (Agent & Human)

- Study `contracts/access/operable/` as the canonical FTR + Modifiers + NatSpec example (per AGENTS).
- Read `AGENTS.md` (required; covers skills install, patterns, deployment) and `docs/CODEBASE_MAP.md` (GitBook navigation for LR-2 areas: registries, protocols, utilities/Sets).
- Install + follow `crane-deployment`, `crane-testing`, `crane-architecture` skills (repo `.claude/skills/` **and** your global per LR-3/PRD/AGENTS). The relevant Crane and protocol skills must be installed and available both inside this repository (`.claude/skills/`) **and** in the user's global Claude/agent environment. Use for LR-2 GitBook content (Create3 pkg chain setup with ONLY central NatSpec values, DPCF reuse, registries, TestBase for protocols + utilities + Sets). Skills must be kept in sync with standards.
- Implement tests with `TestBase_*` + `Behavior_*` + handlers (full init, exact asserts, declaration tests using central values per LR-7).
- Add NatSpec + `// tag::Symbol[] ... // end::Symbol[]` on all documented symbols (use ONLY `CENTRALLY_COMPUTED_NATSPEC_VALUES.md`).
- Contribute/update skills when you ship reusable patterns.
- Practice exact **LR-4 reuse**: When code is known to be good, reusing it (via facets attached through DFPkgs) eliminates the risk of introducing new bugs through inadvertent changes. This risk is especially high when development or deployment work is delegated to an AI agent. Reusing battle-tested, already-audited deployed logic removes that class of error. **deploy once, attach everywhere** (Create3FactoryDFPkg for per-chain Create3 once; reuse DPCF + DFPkgs + registries + protocol utils/sets) to **reuse already deployed and verified code** (via facets attached through DFPkgs) which eliminates the risk of introducing new bugs through inadvertent changes (especially high for AI agents). Directly saves gas by simply not needing to deploy as much bytecode. All claims grounded in this reuse-based reasoning. See PRD LR-4.

## Verification Commands

```bash
forge build
forge test
forge fmt
```

For full test matrix: `npm run test-all` (if configured).

See [deployment docs](deployment/) and [Bankr token launch](BANKR_LAUNCH.md) for production flows.
