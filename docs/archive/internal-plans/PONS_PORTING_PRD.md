# PRD: Port pons (ponsfamily) into Crane

**Canonical PRD (v1.1):**  
[`docs/superpowers/specs/2026-07-28-pons-port-prd.md`](../../superpowers/specs/2026-07-28-pons-port-prd.md)

**Implementation plan:**  
[`docs/superpowers/plans/2026-07-28-pons-port.md`](../../superpowers/plans/2026-07-28-pons-port.md)

This file is retained under `docs/archive/internal-plans/` so it sits next to
[`DEFI_PORTING_PRD.md`](./DEFI_PORTING_PRD.md) and other protocol port plans.

**Do not edit this stub for requirements** — update the superpowers specs PRD instead.

## Summary

Port open-source **pons** contracts from
[ponsdotdev/ponsfamily](https://github.com/ponsdotdev/ponsfamily) into Crane.

| Item | Decision (locked 2026-07-28) |
|------|------------------------------|
| Domain path | `contracts/protocols/launchpads/ponsFamily/pons/` (upstream `contracts/src`) |
| Shared deps | Reuse / expand `contracts/external` (OZ v5 semantics); no nested OZ |
| First merge | Vendor + compile + hermetic launch + active Robinhood fork bind |
| Fork CI | `FOUNDRY_PROFILE` + Robinhood RPC alias from `foundry.toml` |
| Locker | Minimal hermetic stub; live **active** locker on fork |
| Router | Real Uniswap V3 periphery only |
| Wrappers | Service / Aware follow-up (not required for first merge) |
| Diamond / DFPkg | Out of early scope |
| Product “v2” | **Not in this GitHub repo** — docs/skills only; not ported |
| Greenfield | Testnets only (follow-up) |
| Consumers | Hermetic testing + IndexedEx strategies |
