# bundler3 vendor

| Item | Value |
|------|-------|
| Upstream | morpho-org/bundler3 |
| Pin | `9afc2f4ea32c9dbeba2205a485731b8a98f7ae4c` (main @ clone 2026-07-27) |
| Solidity files (this tree) | 24 |
| Copy date | 2026-07-27 |
| License | **GPL-2.0** |
| Import policy | Morpho Blue + OZ remapped to `@crane/...`; Permit2 → `@crane/contracts/protocols/utils/permit2/` |

## Adaptations

- Exact pragmas → `^0.8.35`.
- Excluded: `imports/`, `adapters/migration/`, `mocks/` (migration adapters optional; smoke uses core Bundler3 + GeneralAdapter1).
- Permit2 library paths adjusted to Crane's flat `protocols/utils/permit2/` layout (no nested `libraries/`).
