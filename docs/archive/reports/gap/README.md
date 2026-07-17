# Per-File Gap Reports - Crane Launch Readiness

**Location:** docs/reports/gap/

**Overview:** See ../GAP_REPORT.md (root) for high-level summary of all LR gaps.

## Purpose
- One report per source file (contracts, tests, docs, skills).
- Enables targeted subagent work: assign one report per task.
- Tracks exact changes needed per PRD requirements (LR-1 NatSpec, LR-6 Slots, LR-7 Testing, LR-2 Docs, LR-3 Skills).

## Directory Structure
- `contracts/...` → Per-file for all non-external .sol
- `test/...` → Test files
- `docs/...` → Documentation files
- `.claude/skills/...` → Skills

## How Reports Are Structured
Each report includes:
- File type and affected LR(s)
- Detailed gaps (with references to PRD)
- Specific actionable changes
- Section: "NatSpec Symbols Requiring Central Value Computation" (placeholders for now)
- Subagent notes: "Do not compute selectors yourself"

## NatSpec Central Computation Pass
To avoid parallel conflicts on `cast sig` / keccak for `@custom:selector`, `@custom:topiczero`, `@custom:interfaceid`:

1. This pass (started) extracts symbols from reports.
2. Computes using Foundry cast / scripts.
3. Populates back into the relevant gap reports AND will be used to patch source.

**Sample computed values (from initial central pass):**
- ICreate3Factory.diamondPackageFactory(): 0x0fe96d13
- ICreate3Factory.create3(bytes,bytes32): 0xa7b62a7f
- IDiamondFactoryPackage.packageName(): 0xabc8b346
- IFacet.facetInterfaces(): 0x2ea80826
- etc.

Full population will be done in coordinated review step after all reports are reviewed.

## Usage for Subagents / Tasks
1. Pick a report file.
2. Implement the "Specific Actions Needed".
3. For NatSpec: wait for central values or use the populated report.
4. Mark in main GAP_REPORT.md when complete for that file.

**Total reports:** (run `find . -name "*.md" | wc -l` in this dir)

**Next:** Review populated reports → Detailed plan referencing specific reports → Coordinated execution.
