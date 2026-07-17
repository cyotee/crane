# Registries

Crane registries provide on-chain discovery, canonical resolution, and configuration for facets, packages, and call targets. They are core to **agent-proof reuse**: deploy once via CREATE3, register, then resolve with `canonical*` instead of hardcoding addresses or redeploying bytecode.

This enables “deploy once, attach everywhere” (see [Getting Started](../getting-started.md) for the security and gas rationale).

## Chain setup note

To stand up a chain presence, deploy your own `Create3Factory` with the CREATE3 package (`Create3FactoryDFPkg`). The **Diamond Package Factory** (`DiamondPackageCallBackFactory`, interface id `0x949da331`) does **not** need to be redeployed per chain — it is safe and intended for **public reuse** across deployments. See [CREATE3 & New Chain Setup](../deployment/create3.md).

## Facet Registry

**Location:** `contracts/registries/facet/`

**Purpose:** Track deployed `IFacet` implementations. Lookup by name, interface id, or function selector. Resolve preferred implementations with `canonicalFacet(bytes4 interfaceId)`.

**Population:** Auto-populated on successful `deployFacet*` through `Create3Factory` (after CREATE3, factory calls `facet.facetMetadata()` and registers). Manual `registerFacet` / `setCanonicalFacet` also exist.

**Consumer usage:**

```solidity
IFacet cut = IFacetRegistry(address(factory)).canonicalFacet(type(IDiamondCut).interfaceId);
```

Also: `allFacets()`, `facetsOfName`, `facetsOfInterface`, `facetsOfFunction`, metadata getters.

`IFacet` metadata selectors (documented elsewhere in Crane): `facetName` `0x5b6f4d01`, `facetInterfaces` `0x2ea80826`, `facetFuncs` `0x574a4cff`, `facetMetadata` `0xf10d7a75`.

## Package Registry

**Location:** `contracts/registries/package/` (DiamondFactoryPackageRegistry)

**Purpose:** Track `IDiamondFactoryPackage` deployments. Canonical package per interface for deterministic proxy construction.

**Population:** Auto on `deployPackage*` via Create3Factory (`package.packageMetadata()` then register). Also `registerPackage` / `setCanonicalPackage`.

**Consumer usage:** `canonicalPackage(interfaceId)`, `allPackages()`, lookups by name/interface/facet.

Used in bootstrap (`InitDevService`) when deploying Create3 DFPkg, CallTarget DFPkg, BountyBoard DFPkg, etc.

## Call Target Registry

**Location:** `contracts/registries/target/` (query + management facets; `CallTargetRegistryDFPkg`)

**Purpose:** Dynamic configuration oracle for call targets — default or per-caller target for an interface id. Lets routers/proxies resolve “who do I call?” without baking addresses into bytecode.

**Population:** Explicit via management (`setDefaultCallTargetForID`, per-caller setters). Not auto-filled on facet deploy.

**Usage:** `defaultCallTargetForID`, `callTargetForIDForCaller` (query interface).

## How registries attach to Create3Factory

Registry facets are deployed with Create3 (salts from type names) and attached to the Create3Factory diamond during bootstrap. After factory/package deploys, tests should assert expected registry entries (production-first; see [Testing Patterns](../development/testing.md)).

## Agent workflow

1. Bootstrap factories (`CraneTest` / `InitDevService`).
2. Deploy facets/packages through Create3 helpers (auto-register).
3. Resolve with `canonicalFacet` / `canonicalPackage` in DFPkg constructors and init paths.
4. Assert registry state in tests with Behavior libraries where available.

Skills: `crane-deployment`, `crane-architecture`. Repo guide: `AGENTS.md`.

## See also

- [CREATE3 & New Chain Setup](../deployment/create3.md)
- [DFPkg Pattern](dfpkg.md)
- [Diamond Factory Packages](../deployment/dfpkg.md)
- [Codebase Map](../CODEBASE_MAP.md)
- [Testing Patterns](../development/testing.md)
