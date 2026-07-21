# etherfi vendor (D2-FULL)

| Item | Value |
|------|-------|
| Upstream | etherfi-protocol/smart-contracts |
| Pin | `b4a0968087b178bc346cdf6bee6c0597bf4c42c7` |
| Solidity files (this tree) | 119 |
| Copy date | 2026-07-21 |
| Import policy | Shared OZ/Solady remapped to `@crane/contracts/external/...`; unique transitives under `contracts/external/<dep>/` |

## Adaptations
- Imports rewritten from upstream remappings to `@crane/...` paths (no new Foundry alias paths).
- Exact `pragma solidity =X.Y.Z` relaxed to ranges where needed for Foundry multi-version compile (`VENDOR.md` note).
- OZ 4.8 via openzeppelin-contracts-v4 / openzeppelin-upgradeable-v4
- Solady gap-fill (EnumerableRoles, LibCall, ReentrancyGuardTransient)
- EigenLayer vendored under external/eigenlayer (242 sol); interfaces under etherfi/interfaces/eigenlayer-interfaces

## Inventory
See `{SCRATCH}/inventory-etherfi.txt` / combined domain-vendor-inventory.txt.
