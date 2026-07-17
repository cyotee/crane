# Summary

* [Introduction](README.md)
* [Getting Started](getting-started.md)

## For AI Agents & Framework Users

* [Using Crane as an Agent Framework](getting-started.md#using-crane-as-an-ai-agent-framework)
* [Building Custom Modules](concepts/building-with-crane.md)
* [Agent Reusability Value (LR-4)](getting-started.md)

## Concepts

* [Facet-Target-Repo](concepts/facet-target-repo.md)
* [Storage Slots](concepts/storage-slots.md)
* [Guard Functions and Modifiers](concepts/guard-functions.md)
* [DFPkg Pattern & Reusable Packages](concepts/dfpkg.md)
* [Registries](CODEBASE_MAP.md)
* [Utilities: Sets, Math & Collections](CODEBASE_MAP.md)

## Development

* [Code Style](development/code-style.md)
* [NatSpec and Documentation](development/natspec.md)
* [Testing Patterns](development/testing.md)

## Deployment

* [CREATE3 Factory & New Chain Setup (Create3FactoryDFPkg)](deployment/create3.md)
* [Diamond Factory Packages (DFPkg)](deployment/dfpkg.md)
* [Factory Services](deployment/factory-services.md)
* [BattleChain Security Gate](deployment/battlechain.md)

## Access Control

* [Multi-Step Ownable (ERC8023)](access/multi-step-ownable.md)
* [Operable](access/operable.md)

## Tokens

* [ERC20 + Permit + DFPkg](tokens/erc20.md)

## Protocol Ports (for Agents)

* [DEX Integrations](protocols/dexes.md)
* [Lending Protocols](protocols/lending.md)
* [TestBases, Behavior Libraries & Protocol Test Patterns](development/testing.md)

## Registries (LR-2 GitBook)

* [Facet Registry, Package Registry, CallTarget Registry](CODEBASE_MAP.md)
* [Purpose, Population via Create3 + canonical* Usage](getting-started.md)
* [Registries + DiamondPackageCallBackFactory Reuse](deployment/create3.md)

## Utilities (LR-2 GitBook)

* [Sets (AddressSet, Bytes32Set, etc.) + *SetRepo Patterns](CODEBASE_MAP.md)
* [ConstProdUtils & Math Utilities](CODEBASE_MAP.md)
* [Collections, Cryptography & Helpers](development/testing.md)
* [Protocol Utilities (used with TestBases)](protocols/dexes.md)

## Reference & Skills

* [Key Interfaces](reference/interfaces.md)
* [AI Agent Skills](reference/agent-skills.md)

## Funding the Framework

* [BankrBot Token Launch](BANKR_LAUNCH.md)

---

## LR-2 GitBook Required Content Areas

This `docs/SUMMARY.md` drives GitBook navigation to expanded coverage in `getting-started.md`, `deployment/create3.md`, `deployment/dfpkg.md`, `CODEBASE_MAP.md`, `protocols/dexes.md`, `protocols/lending.md`, `development/testing.md`, and `concepts/*`.

### Setting Up a Chain Presence via CREATE3 Package
Use the CREATE3 Package (`Create3FactoryDFPkg` / related, implementing `IDiamondFactoryPackage`) to deploy your own `Create3Factory` for a new chain.

See dedicated guide: [CREATE3 Factory & New Chain Setup (Create3FactoryDFPkg)](deployment/create3.md)

`PkgInit` / `PkgArgs` are defined on the interface. Central NatSpec values (use **ONLY** these):

```solidity
// From CENTRALLY_COMPUTED_NATSPEC_VALUES.md only
/// @custom:signature packageName()
/// @custom:selector 0xabc8b346
function packageName() external pure returns (string memory);

/// @custom:signature facetCuts()
/// @custom:selector 0xa4b3ad35
function facetCuts() external view returns (IDiamond.FacetCut[] memory);
```

Bootstrap uses `InitDevService` / `CraneTest` and canonical facets. See `deployment/create3.md`, AGENTS.md, and crane-deployment skill.

### DiamondPackageCallBackFactory Reuse (No Per-Chain Redeploy)
**Explicit LR-2 requirement**: The `DiamondPackageCallBackFactory` (implementing `IDiamondPackageCallBackFactory`) does **not** need to be redeployed per chain — it is safe and intended for public reuse across deployments.

```solidity
/// @custom:interfaceid 0x949da331
interface IDiamondPackageCallBackFactory {
    // ...
    /// @custom:signature diamondPackageFactory()
    /// @custom:selector 0x0fe96d13
    function diamondPackageFactory() external view returns (IDiamondPackageCallBackFactory);
    /// @custom:signature deploy(address,bytes)
    /// @custom:selector 0xe97fac05
    function deploy(address pkg, bytes memory pkgArgs) external returns (address);
}
```

Obtain via `create3Factory.diamondPackageFactory()`. Use `diamondFactory.deploy(pkg, ...)` for proxies on any chain. This is the reusable callback factory (interfaceId `0x949da331` from central values only). See `deployment/create3.md` and `getting-started.md`.

### Registries (Purpose, Population via Create3, Usage with canonical*)
Detailed explanation:

- **FacetRegistry**: Tracks `IFacet` impls. Enables lookup by name/interfaces/funcs. Provides `canonicalFacet(interfaceId)`.
- **Package Registry (DiamondFactoryPackageRegistry)**: Tracks DFPkgs. `canonicalPackage(interfaceId)`.
- **CallTargetRegistry**: Dynamic call target config (split query/management).

**Population**: Auto-populated via `Create3Factory` `deployFacet*` / `deployPackage*` (after CREATE3, calls `facet.facetMetadata()` / `package.packageMetadata()` using `IFacet` selectors below, then `_register*`). Also manual `register*` + `setCanonical*`.

**Consumer usage**: `IFacetRegistry(address(factory)).canonicalFacet(type(IDiamondCut).interfaceId)` etc. Post-deploy assert via `Behavior_*`. Enables "deploy once, attach everywhere".

Central values used (ONLY from CENTRALLY_COMPUTED_NATSPEC_VALUES.md):

```solidity
// IFacet (0x5b6f4d01 etc)
/// @custom:signature facetName()
/// @custom:selector 0x5b6f4d01
function facetName() external view returns (string memory name);
/// @custom:signature facetInterfaces()
/// @custom:selector 0x2ea80826
function facetInterfaces() external view returns (bytes4[] memory interfaces);
/// @custom:signature facetFuncs()
/// @custom:selector 0x574a4cff
function facetFuncs() external view returns (bytes4[] memory funcs);
/// @custom:signature facetMetadata()
/// @custom:selector 0xf10d7a75
function facetMetadata() external view returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions);
```

See [Registries](CODEBASE_MAP.md), [Purpose, Population via Create3 + canonical* Usage](getting-started.md), [deployment/create3.md].

### Ported Protocols + TestBase/Behavior Patterns
All major DEX and lending ports (Uniswap V2/V3/V4, Camelot V2, Aerodrome V1+Slipstream, Balancer V3, Aave v3/v4, Euler, etc.) include:

- `AwareRepo` for DI (router/vault/factory)
- `*Service` libs (business logic, often using ConstProdUtils)
- stubs for mocks
- `test/bases/TestBase_*.sol` (inheritance chains e.g. `TestBase_CamelotV2 is TestBase_Weth9`)
- `Behavior_*` libs + `TestBase_I*` for interface compliance (mandatory `Behavior_IFacet` declaration tests using central selectors)

Usage in tests: inherit `CraneTest` → protocol TestBase → attach handler, use `diamondFactory.deploy(...)` (0xe97fac05). See:

- [DEX Integrations](protocols/dexes.md)
- [Lending Protocols](protocols/lending.md)
- [TestBases, Behavior Libraries & Protocol Test Patterns](development/testing.md)
- AGENTS.md (full TestBase/Behavior/handler examples)

### Utilities (Sets/AddressSetRepo + ConstProdUtils + Math/Collections)
**General utilities** (contracts/utils/):

- **Sets**: `AddressSet`, `Bytes32Set`, `Bytes4Set`, etc. + `*SetRepo` (1-indexed storage, `_add`, `_addAsc`, `_remove`, `_contains`, `_values`, `_range`, `_index`, `_length`). Used in `FacetRegistryRepo`, `ERC2535Repo`, handlers, comparators.
- **Math**: `ConstProdUtils` (reserve sorting, `getPurchaseQuote`, LP mint/withdraw, quote parity for AMMs). `using ConstProdUtils for uint256;`
- Other: collections, Better* hash/arrays, cryptography, SafeERC20, TransientSlot, rate providers.

Protocol-specific utils live with ports (e.g. in services for Camelot/Aerodrome/Balancer).

See [Utilities: Sets, Math & Collections](CODEBASE_MAP.md), [ConstProdUtils usage in tests](development/testing.md), [DEX ports](protocols/dexes.md), AGENTS.md.

These + registries enable reuse of verified code across projects/chains.

### Agent Value Proposition (LR-4 Verbatim)
Documentation, skills, and examples must clearly and accurately communicate the following **specific rationale**:

**Security benefit**:
The primary security advantage is the ability to **reuse already deployed and verified code**. When code is known to be good, reusing it (via facets attached through DFPkgs) eliminates the risk of introducing new bugs through inadvertent changes. This risk is especially high when development or deployment work is delegated to an AI agent. Reusing battle-tested, already-audited deployed logic removes that class of error.

**Reduced deployment cost benefit**:
Because you can reuse already deployed facets and packages, you do not need to deploy that code yourself on every project or chain instance. This directly saves gas by simply not needing to deploy as much bytecode.

All claims grounded in this reuse-based reasoning. Concrete examples highlight **"deploy once, attach everywhere"** and **"agent-proof reuse"** (e.g. bootstrap Create3FactoryDFPkg per chain using central values only, then reuse the public `DiamondPackageCallBackFactory` (interfaceId `0x949da331`) + DFPkgs + registries via `canonical*` for all proxies without re-deploying logic facets).

See [Agent Reusability Value (LR-4)](getting-started.md), PRD.md (LR-2/LR-4), AGENTS.md, `deployment/create3.md`.

Use ONLY values from `CENTRALLY_COMPUTED_NATSPEC_VALUES.md` for any `@custom:selector` / `@custom:interfaceid` in code/docs.
