# PRD: Port pons (ponsfamily) into Crane

**Canonical PRD (v1.0):**  
[`docs/superpowers/specs/2026-07-28-pons-port-prd.md`](../../superpowers/specs/2026-07-28-pons-port-prd.md)

This file is retained under `docs/archive/internal-plans/` so it sits next to
[`DEFI_PORTING_PRD.md`](./DEFI_PORTING_PRD.md) and other protocol port plans.

**Do not edit this stub for requirements** — update the superpowers specs PRD instead.

## Summary

Port the **pons** v1 token launchpad from
[ponsdotdev/ponsfamily](https://github.com/ponsdotdev/ponsfamily) into Crane under:

```text
contracts/protocols/launchpads/ponsFamily/
```

as a faithful domain port: `PonsLaunchFactory`, `PonsLauncherToken`, libraries, and
thin interfaces; OpenZeppelin remapped to Crane `openzeppelin-contracts-v5`; Uniswap V3
via existing Crane ports; hermetic locker stub (locker source not published upstream);
Robinhood fork constants for active/legacy factory + locker.

| Priority | Upstream / deliverable | Role |
|----------|------------------------|------|
| P0 | `PonsLaunchFactory` + token + math + interfaces | Core launch path |
| P0 | OZ v5 remap (no nested OZ tree) | Shared deps |
| P0 | `PonsLaunchLockerStub` + `TestBase_PonsFamily` | Hermetic deploy |
| P0 | `ROBINHOOD_MAIN` pons addresses + fork suite | Live bind |
| P0 | `PonsLaunchService` + `PonsLaunchAwareRepo` + Behaviors | Crane surface |
| P1 | Diamond / DFPkg / adversarial | Optional |
| Out | pons v2 (curve → V4) | Separate PRD when source ships |

**Minimum mergeable port = vendor + hermetic launch + Robinhood fork bind.**

**Gate:** compile without viaIR; production-first tests (no SUT mocks); SPDX MIT + GPL TickMath preserved.
