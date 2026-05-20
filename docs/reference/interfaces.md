# Key Interfaces

## Core

- `IFacet` — `facetName`, `facetInterfaces`, `facetFuncs`, `facetMetadata`.
- `IDiamondFactoryPackage` — package metadata, `facetCuts`, `calcSalt`, `initAccount`, `postDeploy`.
- `IDiamond` / `IDiamondCut` / `IDiamondLoupe` — standard ERC2535 surfaces.
- `IMultiStepOwnable`
- `IOperable`

## Tokens

- `IERC20`, `IERC20Metadata`, `IERC20Permit`
- `IERC4626` (via packages)

## Introspection

- `IERC165`
- `IERC8109Introspection`

## Factories

- `ICreate3Factory`
- `IDiamondPackageCallBackFactory`

## Registries

- `IFacetRegistry`
- `IDiamondFactoryPackageRegistry`

Concrete implementations and their selectors are declared by the corresponding facets. Packages expose the subset of interfaces that are installed into proxies.
