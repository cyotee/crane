# lido vendor (D2-FULL)

| Item | Value |
|------|-------|
| Upstream | lidofinance/core |
| Pin | `372b02e197df61fdf1a443de18acb514804b828d` |
| Solidity files (this tree) | 129 |
| Copy date | 2026-07-21 |
| Import policy | Shared OZ/Solady remapped to `@crane/contracts/external/...`; unique transitives under `contracts/external/<dep>/` |

## Adaptations
- Imports rewritten from upstream remappings to `@crane/...` paths (no new Foundry alias paths).
- Exact `pragma solidity =X.Y.Z` relaxed to ranges where needed for Foundry multi-version compile (`VENDOR.md` note).
- Full contracts/ multi-pragma tree (0.4–0.8)
- Aragon under external/aragon (os, apps, minime, id, apps-lido)
- Absolute contracts/ imports → @crane/contracts/external/lido/

## Inventory
See `{SCRATCH}/inventory-lido.txt` / combined domain-vendor-inventory.txt.
