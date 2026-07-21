# stakewise vendor (D2-FULL)

| Item | Value |
|------|-------|
| Upstream | stakewise/v3-core |
| Pin | `fc70cbe1b3d41bc5f78434830d837aa270ca33bc` |
| Solidity files (this tree) | 172 |
| Copy date | 2026-07-21 |
| Import policy | Shared OZ/Solady remapped to `@crane/contracts/external/...`; unique transitives under `contracts/external/<dep>/` |

## Adaptations
- Imports rewritten from upstream remappings to `@crane/...` paths (no new Foundry alias paths).
- Exact `pragma solidity =X.Y.Z` relaxed to ranges where needed for Foundry multi-version compile (`VENDOR.md` note).
- OZ 5.x via openzeppelin-contracts-v5 / openzeppelin-upgradeable-v5
- Full contracts/ tree (vaults, tokens, factories, interfaces, mocks)

## Inventory
See `{SCRATCH}/inventory-stakewise.txt` / combined domain-vendor-inventory.txt.
