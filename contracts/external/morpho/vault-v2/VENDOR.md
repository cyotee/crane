# vault-v2 vendor

| Item | Value |
|------|-------|
| Upstream | morpho-org/vault-v2 |
| Pin | `9d4ec6578d16b8ed787850cbc3c8aac5798dda79` (main @ clone 2026-07-27) |
| Solidity files (this tree) | 27 |
| Copy date | 2026-07-27 |
| License | **GPL-2.0** |
| Import policy | Morpho Blue/IRM/MetaMorpho remapped to `@crane/contracts/external/morpho/...` |

## Adaptations

- Exact pragmas → `^0.8.35`.
- `imports/` (compile helpers only) excluded.
- Adapter depends on `AdaptiveCurveIrmLib` periphery (vendored under `blue-irm/adaptive-curve-irm/libraries/periphery/` from IRM commit used by vault-v2 submodule; core AdaptiveCurveIrm remains v1.0.0 pin).
