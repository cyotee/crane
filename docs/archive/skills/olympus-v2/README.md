# Archived Olympus skills (v2 research tree)

These skill bodies document the **research** Olympus port at:

| Item | Path / command |
|------|----------------|
| Domain | `contracts/protocols/tokens/stable/olympus/v2/` |
| Tests | `test/foundry/spec/protocols/tokens/stable/olympus/v2/` |
| Profile | `FOUNDRY_PROFILE=olympus_port` |
| Pin (VENDOR.md) | `0af8d56dbe78850d120f077b355dcecee56cb83f` (OlympusDAO/olympus-v3) |

## Forward work

Use the **active** skills under `.claude/skills/` / `.grok/skills/`:

- `olympus-architecture`
- `olympus-operations`
- `crane-olympus`

Those point at **`olympus/v3`** and `FOUNDRY_PROFILE=olympus_v3_port` (Service / Aware / TestBase included).

## Why dual tree

`olympus/v2` is retained for side-by-side research and regression. Do not delete these archived skills; developers working only on the research pin may load them from this archive.
