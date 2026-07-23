# Centrally computed NatSpec values

Canonical **function selectors** and **interface IDs** used in Crane NatSpec (`@custom:selector`, `@custom:interfaceid`, `@custom:signature`). Agents and docs must use these values instead of inventing hex strings.

Source of truth for many symbols: interfaces under `contracts/interfaces/` and implementations such as `contracts/factories/diamondPkg/DFPkgBase.sol` and CREATE3 factory interfaces.

## IDiamondFactoryPackage / DFPkg

| Symbol | Signature | Selector |
|--------|-----------|----------|
| `packageName` | `packageName()` | `0xabc8b346` |
| `facetInterfaces` | `facetInterfaces()` | `0x2ea80826` |
| `facetAddresses` | `facetAddresses()` | `0x52ef6b2c` |
| `packageMetadata` | `packageMetadata()` | `0xf45469e7` |
| `facetCuts` | `facetCuts()` | `0xa4b3ad35` |
| `diamondConfig` | `diamondConfig()` | `0x65d375b3` |
| `calcSalt` | `calcSalt(bytes)` | `0xd82be56e` |
| `processArgs` | `processArgs(bytes)` | `0x87c3adb3` |
| `updatePkg` | `updatePkg(address,bytes)` | `0xa9089235` |
| `initAccount` | `initAccount(bytes)` | `0x870d4838` |
| `postDeploy` | `postDeploy(address)` | `0x70068fcf` |

## IDiamondPackageCallBackFactory

| Item | Value |
|------|--------|
| Interface ID | `0x949da331` |
| Example `deploy` selector | `0xe97fac05` |

Confirm against `IDiamondPackageCallBackFactory` in `contracts/interfaces/` when adding new symbols.

## IFacet (common metadata surface)

| Symbol | Selector (typical) |
|--------|---------------------|
| Facet metadata helpers | `0x5b6f4d01`, `0x2ea80826`, `0x574a4cff`, `0xf10d7a75` |

See `Create3FactoryFacet` / `IFacet` for the authoritative list.

## ICreate3Factory (sample)

| Symbol | Signature | Selector |
|--------|-----------|----------|
| (see interface) | `ICreate3Factory` | `0x0fe96d13`, `0x1cdca5df`, `0xa7b62a7f`, `0x1f7fe4db` |

## Policy

1. Prefer values computed from source (`cast sig "fn()"` or NatSpec already on interfaces).
2. Do not invent interface IDs; XOR of declared selectors when documenting a new interface.
3. Historical copies under the external [crane-archive](https://github.com/cyotee/crane-archive) repo are not the public SoT.
