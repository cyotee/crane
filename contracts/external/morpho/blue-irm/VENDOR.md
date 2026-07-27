# morpho-blue-irm vendor

| Item | Value |
|------|-------|
| Upstream | morpho-org/morpho-blue-irm |
| Pin | `v1.0.0` (`a7d9cce3451b4a106bfd40933ac57a785b5228f3`) |
| Solidity files (this tree) | 7 |
| Copy date | 2026-07-27 |
| License | **MIT** (upstream LICENSE) |
| Import policy | Morpho Blue interfaces/libs remapped to `@crane/contracts/external/morpho/blue/...`. No private OZ. |

## Live bytecode reference (AdaptiveCurveIRM)

| Chain | Address | `keccak256(code)` (Alchemy, 2026-07-27) |
|-------|---------|------------------------------------------|
| Ethereum | `0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC` | `0x73b578a0cd95d0d6e77f85a3945a670a9b8679670f8fc190ca97e89a1f07f6cd` |
| Base | `0x46415998764C29aB2a25CbeA6254146D50D22687` | `0x9978b522abfe0f3b8279800375d833b9d9660ae4f6321a2efb1f1f98850a0cbe` |

## Adaptations

- `pragma solidity 0.8.19` → `^0.8.35` on `AdaptiveCurveIrm.sol`.
- `lib/morpho-blue/src/...` → `@crane/contracts/external/morpho/blue/...`.
- Crane recompile may not match live codehash (immutables + optimizer/viaIR differences).

## Inventory

```
AdaptiveCurveIrm.sol
interfaces/IAdaptiveCurveIrm.sol
libraries/{ErrorsLib,MathLib,UtilsLib}.sol
libraries/adaptive-curve/{ConstantsLib,ExpLib}.sol
```
