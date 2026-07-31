# PRD: Port Olympus V3 (Bophades) into Crane

**Canonical PRD (v1.0):**  
[`docs/superpowers/specs/2026-07-29-olympus-v3-port-prd.md`](../../superpowers/specs/2026-07-29-olympus-v3-port-prd.md)

**Implementation plan (tasks, phases, checkboxes):**  
[`docs/superpowers/plans/2026-07-29-olympus-v3-port.md`](../../superpowers/plans/2026-07-29-olympus-v3-port.md)

This file is retained under `docs/archive/internal-plans/` so it sits next to [`DEFI_PORTING_PRD.md`](./DEFI_PORTING_PRD.md) and other port program docs.

**Do not edit this stub for requirements** — update the superpowers specs PRD instead.

## Summary

Port [OlympusDAO/olympus-v3](https://github.com/OlympusDAO/olympus-v3) into:

```text
contracts/protocols/tokens/stable/olympus/v3/
```

as a faithful Default Framework domain port with shared deps remapped to `@crane/contracts/external/...`.

| Decision | Value |
|----------|-------|
| **v2 tree** | Keep for research/testing (`olympus/v2` + `FOUNDRY_PROFILE=olympus_port`) |
| **v3 tree** | Forward port + Service / Aware / TestBase |
| **Skills** | Archive v2 skills under `docs/archive/skills/olympus-v2/`; write new v3 skills |
| **Minimum merge** | Match current v2 completeness + wrappers + skill migration |
| **Pin** | Execution-time upstream commit (not forced to v2’s `0af8d56`) |
| **License** | AGPL-3.0-only |

**Minimum mergeable port = Phases 0–4** in the canonical PRD (vendor + hermetic suite + wrappers + skills).
