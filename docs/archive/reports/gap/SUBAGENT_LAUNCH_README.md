# Launching Subagents for Gap Closure

**Status:** Central NatSpec computation pass complete. Per-file gap reports generated. Ready for subagent execution.

## How to Assign a Subagent
1. Choose a specific report from `docs/reports/gap/`
2. Spawn a subagent with a prompt like:
   ```
   You are an expert Solidity developer following Crane standards (see AGENTS.md and PRD.md).
   Your task is to close the gaps listed in this specific report: docs/reports/gap/contracts/factories/create3/Create3FactoryFacet.sol.md

   Key resources:
   - Read the full gap report above.
   - Read docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for all pre-computed @custom: values. Use ONLY these values.
   - Read PRD.md sections on LR-1 (NatSpec), LR-6 (slots), LR-7 (tests).
   - Read AGENTS.md for patterns (Facet-Target-Repo, include tags, no viaIR, etc.).
   - Read the actual source file referenced in the report.

   Rules:
   - Work on ONLY this one file (and its corresponding test if the gap requires it).
   - Do not compute any selectors/hashes yourself — use the central values file.
   - Add exact // tag::Name[] ... // end::Name[] wrappers.
   - Implement all listed required changes.
   - After edits, run `forge build` and relevant tests for this file.
   - If successful, update the report and main GAP_REPORT.md with [x] for this item.
   - Output a summary of changes.

   Begin by reading the gap report and the source file.
   ```
3. Monitor the subagent output.
4. For parallel work, spawn multiple with non-overlapping files (e.g., different directories).

## Priority Order Suggestion (from GAP_REPORT.md)
1. Core factories (create3/, diamondPkg/) - NatSpec + DFPkg tests
2. Registries - LR-6 slot fixes + NatSpec
3. Access (operable, reentrancy) - NatSpec + tests
4. Introspection - full coverage
5. Tokens/ERC20 - DFPkg and facet
6. Core tests (especially declaration and Behavior tests)
7. Docs and skills updates (LR-2, LR-3)

## Tracking
- Main tracker: GAP_REPORT.md (use checkboxes)
- This directory has one report per file.
- Use `docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md` for all NatSpec values.

## Notes
- The generator created reports for a very large number of files (including ports and fork tests). Focus first on non-ported core Crane framework files for highest impact.
- Central values were computed from source using `cast sig` / `cast keccak` in a single pass.
- Subagents must not re-compute values.

Launch subagents using the spawn mechanism with the prompt template above, customized per report.
