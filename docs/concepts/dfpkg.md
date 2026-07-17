# DFPkg Pattern

A **Diamond Factory Package (DFPkg)** is a contract that implements `IDiamondFactoryPackage`. It packages facet references and the logic needed to initialize a new Diamond proxy instance.

Packages are how Crane turns reusable facets into **deployable products**: one package definition produces consistent proxies at predictable addresses when given the same arguments.

## Why packages exist

- **Composition**: A package lists which facets (and selectors) a proxy needs.
- **Initialization**: `initAccount` runs via delegatecall on the new proxy to set storage.
- **Determinism**: `calcSalt` + CREATE3-style factory flows yield stable addresses.
- **Reuse**: Facets are deployed once; packages only *reference* them. That is the security and gas story: **reuse already deployed and verified code** via facets attached through DFPkgs (“deploy once, attach everywhere”).

## Interface-owned structs (critical rule)

`PkgInit` and `PkgArgs` **must** be defined on the **interface** (`I*DFPkg`), never only on the implementing contract. That enables typed `IMyDFPkg.PkgInit` usage in FactoryServices and `abi.encode` call sites.

```solidity
interface IERC20DFPkg {
    struct PkgInit { /* facet addresses for constructor */ }
    struct PkgArgs { /* per-instance deploy args */ }
}

contract ERC20DFPkg is IERC20DFPkg, IDiamondFactoryPackage {
    // constructor(PkgInit memory pkgInit) { ... }
}
```

## Core package surface

Typical DFPkg responsibilities:

| Function | Role |
|----------|------|
| `packageName()` | Human/registry name |
| `facetCuts()` | `IDiamond.FacetCut[]` for the proxy |
| `diamondConfig()` | Diamond configuration blob |
| `calcSalt(bytes)` | Deterministic salt from package args |
| `initAccount(bytes)` | Delegatecalled on the new proxy |
| `postDeploy(address)` | Hook after proxy exists |

Central NatSpec selectors (examples already used in deployment docs):

- `packageName()` — `0xabc8b346`
- `facetCuts()` — `0xa4b3ad35`
- `initAccount(bytes)` — `0x870d4838`
- `postDeploy(address)` — `0x70068fcf`

## Conceptual vs operational docs

| Doc | Focus |
|-----|--------|
| **This page** | What a DFPkg is, struct rules, package lifecycle concepts |
| [Diamond Factory Packages](../deployment/dfpkg.md) | Operational package construction and deploy steps |
| [CREATE3 & New Chain Setup](../deployment/create3.md) | Factories, chain bootstrap, DPCF reuse |
| [Registries](registries.md) | How packages/facets are discovered after deploy |

## Lifecycle (high level)

1. Deploy **facets** once with Create3Factory (registered automatically when using factory deploy helpers).
2. Deploy a **package** whose constructor stores immutable facet addresses (`PkgInit`).
3. Deploy **proxies** via `DiamondPackageCallBackFactory.deploy(pkg, pkgArgs)` — the package supplies cuts + init.
4. Consumers resolve packages later via Package Registry `canonicalPackage(interfaceId)` when available.

## See also

- [Diamond Factory Packages (deployment)](../deployment/dfpkg.md)
- [CREATE3 & New Chain Setup](../deployment/create3.md)
- [Building with Crane](building-with-crane.md)
- [Getting Started](../getting-started.md)
- [Tokens: ERC20 DFPkg](../tokens/erc20.md)
