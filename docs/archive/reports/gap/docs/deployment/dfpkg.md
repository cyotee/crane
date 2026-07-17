# Gap Report: docs/deployment/dfpkg.md

**File Type:** Documentation

**Primary LR Violations:** LR-2 (GitBook content)

## Current State
The source `docs/deployment/dfpkg.md` (read as primary referenced doc source) provides high-level coverage of DFPkg value, interface (partial), typical structure (with critical PkgInit/PkgArgs-on-interface rule), deployment flow via DiamondPackageCallBackFactory, reuse characteristics, helper methods, post-deploy hooks, and consumer layers note. It includes the reuse statement that "The `DiamondPackageCallBackFactory` ... is deployed once and reused across chains and projects. You obtain it from your Create3Factory; you do not deploy a new callback factory for each chain or DFPkg use." The companion `docs/deployment/create3.md` (closest matching for dfpkg/create3 content) adds a critical LR-2 reuse note and basic registry integration text.

## Specific Gaps
- Missing detailed explanation of required LR-2 areas (CREATE3 Package for chain setup, Diamond Package Factory reuse, Registries, ported protocol test usage, protocol utilities, general type libraries like Sets).
- May lack links or sections tying to agent usage and value prop (LR-4).
- SUMMARY.md may need updates to surface new content.

## Required Changes
1. Add the specific missing content sections as per LR-2 in PRD.
2. Ensure cross-links from getting-started, concepts, deployment.
3. Update for NatSpec verification script, ERC1967, testing standards.

## Notes
- Content must support other agents deploying factories and reusing packages.
- After central NatSpec pass, any code examples in docs should match.

**Priority:** High

## Detailed Missing Content Additions (per PRD LR-2 - use ONLY from gap report, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD.md, AGENTS.md, dfpkg.md + create3.md sources)

Use exact central NatSpec values for any examples. The following sections supply the precise text and structure to close the LR-2 gaps in the target deployment docs (minimal additions focused on dfpkg/create3 scope; ported protocol details tie via DFPkg + TestBase factory bootstrap).

### Using the CREATE3 Package (Create3FactoryDFPkg / related) to Deploy Own Factory for New Chain (Chain Setup)

To set up a chain presence on a new EVM chain:

Deploy your own `Create3Factory` using the CREATE3 Package (Create3FactoryDFPkg and related DFPkgs). This is the bootstrap path for a new chain.

Once the Create3Factory is deployed on the chain, obtain the shared `DiamondPackageCallBackFactory` address from it (via `diamondPackageFactory()`).

From ICreate3Factory (central values):
```solidity
// tag::diamondPackageFactory()[]
function diamondPackageFactory() external view returns (IDiamondPackageCallBackFactory);
// end::diamondPackageFactory()[]
```
Selector (central): `0x0fe96d13`

See `InitDevService.initEnv(...)` (and CraneTest inheritance per AGENTS.md) for canonical bootstrap of facets + Create3Factory + registries under deterministic salts. Cross-chain scripts compute addresses in advance using salt = `abi.encode(type(X).name)._hash()` (from AGENTS FactoryService and create3 source).

This enables agents to stand up isolated but reusable infrastructure per PRD LR-2 / LR-4.

### Diamond Package Factory (DiamondPackageCallBackFactory) is Reusable / No Need to Redeploy

Explicit statement (required by PRD LR-2; already partially in dfpkg.md and create3.md sources; expand here):

**The `DiamondPackageCallBackFactory` does _not_ need to be redeployed per chain — it is safe and intended for public reuse across deployments and chains.**

From create3.md source (LR-2 note):
> The `DiamondPackageCallBackFactory` (the DPCF) is deployed **once** per ecosystem/setup. It does **not** need to be redeployed per chain or per consumer. It is safe and intended for public reuse across all deployments and chains. Consumers obtain its address from a Create3Factory (via `diamondPackageFactory()`). Deploying your own Create3Factory (via its DFPkg) is how you bootstrap a new chain presence; the callback factory is shared.

From dfpkg.md source:
> The `DiamondPackageCallBackFactory` that executes DFPkg deployments (via `pkg.deploy(diamondFactory, args)`) is deployed once and reused across chains and projects. You obtain it from your Create3Factory; you do not deploy a new callback factory for each chain or DFPkg use.

From AGENTS.md (factory hierarchy):
```
Create3Factory                    # Deploys facets, packages, and any contract
    └── DiamondPackageCallBackFactory   # Deploys Diamond proxy instances from packages
```

From central NatSpec (IDiamondPackageCallBackFactory):
- interfaceId: `0x949da331`
- `PROXY_INIT_HASH() : 0x1c8b7630`
- `deploy(address,bytes) : 0xe97fac05`
- etc.

Packages (DFPkg) declare via `facetCuts()`, `diamondConfig()`, `calcSalt(bytes)`, `initAccount(bytes)`, `postDeploy(address)`. Central selectors:
- `packageName() : 0xabc8b346`
- `facetCuts() : 0xa4b3ad35`
- `calcSalt(bytes) : 0xd82be56e`
- `initAccount(bytes) : 0x870d4838`
- `postDeploy(address) : 0x70068fcf`

DFPkg consumers call `diamondPackageFactory.deploy(pkg, pkgArgs)` (or pkg convenience wrappers). The callback factory is obtained once and reused; no per-project/per-chain redeploy of the proxy factory itself. This directly supports LR-4 reuse (security: verified code reuse; cost: avoid redeploying bytecode).

### Explanation of Included Registries

Crane includes registries for facets, packages, and call targets (populated during core factory initialization). Purpose (from PRD + create3 source + AGENTS + central IDiamondFactoryPackageRegistry / IFacetRegistry references):

- **Facet Registry**: Tracks canonical deployed facets by interface ID. Allows resolution of e.g. the single ERC165Facet or DiamondCutFacet instead of passing addresses in every PkgInit.
- **Package Registry** (DiamondFactoryPackageRegistry): Tracks deployed DFPkgs by name / interfaces / facets. Enables lookup of package for reuse and salt calc.
- **CallTarget Registry** (and related e.g. ICallTargetRegistry*): For approved targets in metatx / call contexts.
- Others: Superchain token registry, approved message sender etc. for protocol/L2 use.

How populated: `InitDevService` (and Create3Factory bootstrap) wires registries. `Create3Factory` "with facet/package registry". During `deployFacet` / `deployPackageWithArgs`, entries are recorded. (See central for related like `IDiamondFactoryPackageRegistry` implied via packageName/facet* selectors.)

How consumers interact (per AGENTS consumer layers note + create3 source):
```solidity
// Resolve canonical facet instead of hardcoding PkgInit addresses
// (example pattern; registries provide query by interface)
bytes4 erc165Id = type(IERC165).interfaceId;  // central IFacet supportsInterface: 0x01ffc9a7
IFacet facet = /* registry query by interfaceId */;
```
Packages/services use registries to avoid address passing. Consuming apps may layer additional rules on registries (but core Crane primitives do not enforce app-specific registration). After deployment, assert registry population (LR-7).

Registries + DFPkg + CREATE3 enable "deploy once, attach everywhere" for agents.

### Detailed Ported Protocols + Test Usage

From PRD (Feature 4 + LR-2):
Ported protocols (reusable utilities for DEX/lending):
- Uniswap: V2, V3, V4 (router wrappers, quote utilities)
- Camelot: V2 (router integration, fee handling)
- Aerodrome: V1 (Slipstream) (concentrated liquidity support)
- Balancer: V3 (vault integration, batch swaps)
(Additional from structure in AGENTS: protocols under dexes, cdps, lending, etc.)

How to integrate and use them (DFPkg + Aware pattern from AGENTS):
- Inject via `*AwareRepo` (e.g. `IBalancerV3VaultAware`, `IWETHAware`).
- Use protocol `services/` (e.g. `CamelotV2Service`).
- Deploy instances via DFPkgs + DiamondPackageCallBackFactory (above).

How to use them inside tests (TestBases, stubs, etc.) per AGENTS.md + PRD LR-2 / LR-7:
Two TestBase types:
1. Protocol Setup TestBase (inheritance chain for infra):
```solidity
// From AGENTS.md
abstract contract TestBase_CamelotV2 is TestBase_Weth9 {
    ICamelotFactory internal camelotV2Factory;
    ICamelotV2Router internal camelotV2Router;

    function setUp() public virtual override {
        TestBase_Weth9.setUp();  // Call parent setUp
        if (address(camelotV2Factory) == address(0)) {
            camelotV2Factory = new CamelotFactory(feeToSetter);
        }
        if (address(camelotV2Router) == address(0)) {
            camelotV2Router = new CamelotRouter(address(camelotV2Factory), address(weth));
        }
    }
}
```
Full chain example (AGENTS):
```
CraneTest                          # Factory setup (create3Factory, diamondFactory)
    └── TestBase_Weth9             # WETH deployment
        └── TestBase_CamelotV2     # Camelot factory + router
            └── TestBase_CamelotV2_Pools  # Pool creation helpers
                └── YourTest.t.sol  # Actual test contract
```
2. Behavior TestBase (for interface compliance, using Behavior_* libs):
- Use `Behavior_IFacet`, protocol Behaviors.
- `TestBase_*` live in `contracts/protocols/.../test/bases/` or `contracts/...`
- Actual specs in `test/foundry/spec/`

Stubs in `contracts/protocols/.../stubs/`. Use `CraneTest` for Create3 + Diamond factory bootstrap (ensures full init per LR-7; no address(0) facets).

Protocol tests assert CREATE3 determinism, registry population, exact DFPkg lifecycle (`calcSalt`, `initAccount` via delegatecall, `facetCuts` etc using central selectors).

See `forge test --match-path .../ConstProdUtils_*.t.sol` and protocol fork tests.

### Protocol-specific and General Utility Libraries (e.g. Sets)

Per PRD LR-2 and AGENTS:

**Protocol-specific:**
- E.g. DEX quote/swap services (CamelotV2Service, Balancer services, Uniswap utils).
- Use `ConstProdUtils` (constant product AMM math):
```solidity
// From AGENTS example
library CamelotV2Service {
    using ConstProdUtils for uint256;
    using SafeERC20 for IERC20;
    // ...
}
```
Key file (AGENTS): `/contracts/utils/math/ConstProdUtils.sol`

**General utility and type libraries (including Sets):**
- Type-specific Set implementations (AddressSet, Bytes32Set, etc.) and their Repo patterns (similar dual `_layoutStruct` + guard per AGENTS architecture).
- Math utilities (e.g. ConstProdUtils).
- Other collections (in `contracts/utils/collections/`), cryptography (e.g. ECDSA, EIP712 per central), helper libs (UInt256, Better* wrappers, SafeERC20 etc.).
- Follow Facet-Target-Repo + `*AwareRepo` for DI; use in DFPkg init and services.
- Storage slots use hierarchical (e.g. "protocols.dexes..."); post central pass, prefer ERC1967 form where applicable.

These reduce boilerplate for agents (LR-4) and are exercised in TestBases + handlers.

## Cross-References (minimal, from PRD/AGENTS)
- See AGENTS.md "Diamond Package Deployment Pattern", "Key Files" (Create3Factory, DiamondPackageCallBackFactory, ConstProdUtils, TestBase patterns).
- PRD LR-2, LR-4 (reuse security/cost: "reuse already deployed and verified code"; "do not need to deploy that code yourself").
- Central values for all @custom:* when expanding actual doc examples.
- Update GAP_REPORT.md and (if needed) SUMMARY.md per notes.

**Verification note:** After insertion into docs, run `forge build` and relevant `forge test` (e.g. factory/protocol tests). Use central values exclusively for NatSpec examples.

