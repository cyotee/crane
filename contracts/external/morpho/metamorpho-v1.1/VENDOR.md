# metamorpho-v1.1 vendor

| Item | Value |
|------|-------|
| Upstream | morpho-org/metamorpho-v1.1 |
| Pin | `bcc003108c0fbb9f715566207c52a1d3f279c5c3` (main @ 2026-07-27; no release tags) |
| Solidity files (this tree) | 13 |
| Copy date | 2026-07-27 |
| License | **GPL-2.0** |
| Import policy | Morpho Blue → `@crane/contracts/external/morpho/blue/...`; OZ → `@crane/contracts/external/openzeppelin-contracts/...` |

## Adaptations

- `pragma solidity 0.8.26` → `^0.8.35`.
- OZ multi-import from ERC4626.sol split into discrete imports (Crane OZ does not re-export).
- Compatibility alias `interfaces/IMetaMorpho.sol` → `IMetaMorphoV1_1` for Public Allocator.
- Upstream production uses `via-ir`; Crane compiles without viaIR.
- Mocks trimmed: dropped MorphoImport/ERC777Mock (not needed for domain compile).

## Inventory

```
MetaMorphoV1_1.sol, MetaMorphoV1_1Factory.sol
interfaces/{IMetaMorpho,IMetaMorphoV1_1,IMetaMorphoV1_1Factory}.sol
libraries/{ConstantsLib,ErrorsLib,EventsLib,PendingLib}.sol
mocks/{ERC20Mock,IrmMock,MetaMorphoMock,OracleMock}.sol
```
