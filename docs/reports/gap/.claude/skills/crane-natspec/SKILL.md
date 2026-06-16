# Gap Report: .claude/skills/crane-natspec/SKILL.md

**File Type:** Agent Skill

**Primary LR Violations:** LR-3 (Up-to-date skills), LR-1 (NatSpec process/scope)

## Current State
Skill exists and covers related topic. Now fully aligned (see below).

## Specific Gaps (Closed)
- [x] Drifted from finalized PRD standards: now explicitly covers NatSpec process with Foundry Script/central (dedicated `scripts/foundry/ComputeNatSpecValues.s.sol`; `forge script ... --sig "run()" -vvv`; CENTRALLY_COMPUTED... as exclusive source; "use ONLY"), ERC1967 (slot form in documented Repos), full LR-7 (test NatSpec on TestBases/Behaviors/Handlers/*.t.sol, Behavior declaration tests validate tagged surfaces).
- [x] Missing explicit coverage of verification script and scope: added "Verification Script and Central Values Process (Mandatory per LR-1)" + "Full Scope (incl. Tests) and Verification Script" + "NatSpec on Test Code (LR-1 + LR-7)" sections with exact run cmd, central date, subagent rules, LR-7 test surface requirements, declaration test ties.
- [x] Examples may use old/incomplete: replaced examples + added complete ones using ONLY values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (e.g. IOperable interfaceId 0xa7f11160 + its selector 0x6d70f7ae / error 0x76c6c93a / topic0 0x26ba2805..., IFacet 0x2ea80826 etc.); updated tag formats to gold (hyphenated e.g. NewGlobalOperatorStatus(address-bool)[]); added ERC1967 slot NatSpec example.
- [x] Ties to LR-2 GitBook required content: added upfront critical block + LR Ties section covering (via verified NatSpec) Create3FactoryDFPkg chain setup, reusable DiamondPackageCallBackFactory (0x949da331), registries, ported protocol TestBases+Behaviors+utilities, general Sets/etc. (enables extraction).
- [x] References central process, AGENTS.md, PRD LR-1/3/7, docs/development/natspec.md, other crane-* skills, strict read order reminder, "Update this skill..." note.
- [x] Behavior / test init / correct usage: explicit in scope + test NatSpec + LR Ties (Behavior libs use the documented central-tagged surfaces; full init implied via declaration tests).

## Changes Made (using only allowed inputs)
1. Updated skill content (added critical alignment block at top, new dedicated Verification Script + Central section, Full Scope + Test NatSpec sections, ERC1967 note, LR Ties, expanded validation + resources) to match current standards from reads.
2. All custom tag examples use **ONLY** values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no fabrication; cross-checked against listed IOperable, IFacet, IDiamondPackageCallBackFactory etc.).
3. Added explicit content on verification script (run command, script purpose using type().interfaceId + keccak, helper vs primary, regeneration) and scope (incl. tests).
4. Aligned with PRD LR-3 + updated docs; added cross-refs for GitBook/LR-2 areas, crane-testing (Behaviors), crane-deployment (factories), reuse value (LR-4).
5. Strict read order followed exactly: 1. target gap report, 2. CENTRALLY..., 3. PRD (LR-1/LR-3/LR-7 focus), 4. AGENTS.md (NatSpec section + patterns), 5. source files (the skill itself + references/natspec-examples.md + docs/development/natspec.md + scripts/... .s.sol + .sh for process details).
6. Only edited: the skill + this gap report + GAP_REPORT.md. No source .sol or other docs edited.

**Priority:** High for core crane-* skills; Medium for protocol ones.

**Subagent Notes:** Gaps closed per task. Skill now enables correct agent behavior for NatSpec per current standards (Foundry Script central process, ERC1967, full test scope + test NatSpec, verification script). Follows "use ONLY" central values rule. Only edited skill + this gap report + GAP_REPORT.md. All content derived strictly from gap report (original) + CENTRALLY_COMPUTED_NATSPEC_VALUES.md + PRD.md (relevant LR) + AGENTS.md + the skill file + referenced natspec sources (no invention).
