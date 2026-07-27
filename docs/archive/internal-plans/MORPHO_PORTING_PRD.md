# PRD: Port Morpho into Crane

**Canonical PRD (v1.0):**  
[`docs/superpowers/specs/2026-07-27-morpho-port-prd.md`](../../superpowers/specs/2026-07-27-morpho-port-prd.md)

**Implementation plan (tasks, upstream tests, fork parity):**  
[`docs/superpowers/plans/2026-07-27-morpho-port.md`](../../superpowers/plans/2026-07-27-morpho-port.md)

This file is retained under `docs/archive/internal-plans/` so it sits next to [`DEFI_PORTING_PRD.md`](./DEFI_PORTING_PRD.md) (Morpho Phase 1 items C.3–C.4) and [`DEFI_RESEARCH.md`](./DEFI_RESEARCH.md) §2.1.

**Do not edit this stub for requirements** — update the superpowers specs PRD instead.

## Summary

Port Morpho Blue, AdaptiveCurve IRM, Chainlink oracle factory, MetaMorpho V1.1, Public Allocator, then Vault V2 / Bundler3, into Crane as a faithful domain port with shared deps remapped to `@crane/contracts/external/...`.

| Priority | Upstream | Role |
|----------|----------|------|
| P0 | morpho-org/morpho-blue | Core markets |
| P0 | morpho-org/morpho-blue-irm | AdaptiveCurve IRM |
| P0 | morpho-org/morpho-blue-oracles | ChainlinkOracleV2 factory |
| P0 | morpho-org/metamorpho-v1.1 | Curator vaults V1.1 |
| P0 | morpho-org/public-allocator | Vault liquidity reallocation |
| P1 | morpho-org/vault-v2 | Vault V2 + adapters |
| P1 | morpho-org/bundler3 | Batch executor |
| P2 | URD / token / legacy MetaMorpho V1.0 | Optional |

**Minimum mergeable port = P0** (Blue + MetaMorpho + constants + Service/Aware/TestBase + hermetic + ETH/Base forks).

**Gate:** BUSL license clearance before vendoring Blue / MetaMorpho sources.
