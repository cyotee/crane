# rocketpool vendor (D2-FULL)

| Item | Value |
|------|-------|
| Upstream | rocket-pool/rocketpool |
| Pin | `fef41a4f7cf99d7d66313c0ba04deb8ba2dabf88` |
| Solidity files (this tree) | 180 |
| Copy date | 2026-07-21 |
| Import policy | Shared OZ/Solady remapped to `@crane/contracts/external/...`; unique transitives under `contracts/external/<dep>/` |

## Adaptations
- Imports rewritten from upstream remappings to `@crane/...` paths (no new Foundry alias paths).
- Exact `pragma solidity =X.Y.Z` relaxed to ranges where needed for Foundry multi-version compile (`VENDOR.md` note).
- Full contracts/ tree including minipool, megapool, network, DAO
- SafeMath → openzeppelin-contracts-v4/utils/math/SafeMath.sol
- Multi-pragma 0.7.6 / 0.8.30 relaxed for Foundry

## Inventory
See `{SCRATCH}/inventory-rocketpool.txt` / combined domain-vendor-inventory.txt.
