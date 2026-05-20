# Crane

Diamond-first (ERC2535) Solidity development framework.

Crane separates storage management, business logic, and Diamond exposure into distinct layers. Facets deploy once at deterministic addresses via CREATE3. Multiple proxies reuse the same facets on every chain.

## Primary Value

- Facets deployed once. Proxies composed from references to those facets.
- Deterministic addresses for facets and packages across all EVM chains.
- Storage isolated per proxy through library-based Diamond storage with namespaced slots.
- Packages (DFPkg) bundle facet cuts and initialization for repeatable Diamond instances.
- Reduced deployment cost: logic gas is paid once per facet, not per proxy.

## Core Patterns

- Facet-Target-Repo
- CREATE3 + DiamondPackageCallBackFactory
- IDiamondFactoryPackage (DFPkg)
- Structured TestBase + Behavior validation

## Documentation

Full documentation is maintained in `/docs` and published via GitBook.

## Build and Test

```bash
forge build
forge test
forge fmt
```

## Repository

https://github.com/cyotee/crane
