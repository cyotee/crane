# Gap Report: docs/development/natspec.md

**File Type:** Documentation

**Primary LR Violations:** LR-1 (stricter verification + full scope), LR-2 (GitBook ties), LR-3 (agent skills alignment)

**Status:** CLOSED (this update)

## Current State (pre-update)
(High-level or partial coverage of required topics; relied on outdated `cast` examples; lacked explicit Foundry Script mandate, central values process, full test scope, and agent/LR cross-refs.)

## Specific Gaps (addressed)
- [x] Missing detailed explanation / ties for LR-2 areas: now includes explicit sections + cross-links to CREATE3 Package for chain setup, DiamondPackageCallBackFactory reuse, Registries, ported protocol test usage (TestBases/Behavior), protocol utilities, general type libraries (Sets etc.). See new "Agent Use, LR-2 and LR-3 Alignment" and "See also" in the doc.
- [x] Lacked links or sections tying to agent usage and value prop (LR-4): added full "Agent Use..." section with reuse rationale ("deploy once, attach everywhere"), strict read order (gap report + CENTRALLY... + PRD + AGENTS + sources), crane-natspec, LR-4 language.
- [x] SUMMARY.md surface: doc already listed; content now richer for GitBook extraction.
- [x] No Foundry Script / verification requirement: added/expanded dedicated "Verification Script Requirement (Mandatory)" quoting PRD verbatim, critical accuracy rule, "MUST be calculated using a dedicated Foundry Script (not one-off terminal `cast`...)", plus new subsection "How to Use the Dedicated Verification Script" with exact `forge script scripts/foundry/ComputeNatSpecValues.s.sol --sig "run()" -vvv` command, explanation of type(I).interfaceId + Solidity keccak, notes that sh is helper only, script itself has NatSpec+tags, regeneration process. Created the .s.sol implementing it.
- [x] No central values process / use ONLY: added "Central Values Process (Single Source of Truth)" section mandating `CENTRALLY_COMPUTED_NATSPEC_VALUES.md`, step-by-step, "use ONLY", date, subagent rules.
- [x] Scope incomplete (no explicit tests): added "Full Scope (incl. Tests)" covering prod + all test files (`.t.sol`, TestBase_*, Behavior_*, handlers, stubs), LR-7 note on test NatSpec.
- [x] Out of sync with PRD gold standard + AGENTS: rewrote examples to use gold standard tag formats (e.g. `(address-address)`, `(bytes32)`, dual overload tags), required elements list from PRD LR-1 verbatim, Repos dual overloads, IFacet, @custom:topic-signature support, rich NatSpec. Updated Validation and Agent sections to reference AGENTS.md + PRD superseding older cast guidance. Added gold standard file list at top.
- [x] Ties to ERC1967 / testing standards: referenced in related (storage slots, testing.md), LR-7 declaration tests, Behavior usage.
- [x] Missing content for agent use: added comprehensive agent section, required read-order process, value prop, cross-refs to deployment/concepts for LR-2 required GitBook areas.

## Changes Made (only allowed files)
- Read in strict order: 1. this gap report, 2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used only its listed values conceptually for examples/alignment), 3. PRD.md (full LR-1 text + LR-2/3/7 context), 4. AGENTS.md (NatSpec section + overall), 5. referenced sources: docs/development/natspec.md, scripts/compute_natspec_values.sh, gold standard contracts/access/ERC8023/*.sol (IMultiStepOwnable etc for tag/overload/@custom patterns), contracts/factories/diamondPkg/IFacet.sol, ComputeNatSpec script references.
- Enhanced `docs/development/natspec.md`: expanded "Verification Script Requirement (Mandatory)" with detailed run instructions, reference to `scripts/foundry/ComputeNatSpecValues.s.sol` (new dedicated Foundry Script) + sh helper, emphasis on compiler (type().interfaceId) not ad-hoc cast, regeneration, full LR-1/scope/central process alignment, gold standard, "See also", and related files section. Also minor polish to central process notes.
- Created/updated allowed script: `scripts/foundry/ComputeNatSpecValues.s.sol` (primary dedicated LR-1 Foundry Script with NatSpec+tags itself, local minimal IFacet decls for fast ID calc via type(), keccak-based _log* helpers, run() usage documented; sh updated to launch/reference the .s.sol and note LR-1 precedence). This was called for by the focus on verification script + LR-1.
- This gap report updated (added details on script, read order, full LR-1 closure).
- `GAP_REPORT.md` tracking updated (see below; marked the pending "Create Foundry Script..." item complete).

## Required Changes (now complete)
1. [x] Added/expanded sections tying required LR-2 GitBook areas + cross-links (from getting-started, concepts, deployment, reference/agent-skills, protocols).
2. [x] Updated for NatSpec verification script (mandatory Foundry Script + full "How to Use" with script path), full scope (incl. tests), central values process (use ONLY), gold standard, ERC1967/testing refs. Created `scripts/foundry/ComputeNatSpecValues.s.sol` (and updated sh) as the committed dedicated script.
3. [x] Agent usage + LR-4 value prop integrated; SUMMARY already surfaces the doc.
4. [x] Full LR-1 alignment: script uses compiler for IDs/selectors (per PRD), scope covers tests, central process documented, AGENTS/PRD precedence noted, read-order enforced.

## Notes
- Content now supports other agents deploying factories and reusing packages (via accurate, verifiable, extractable NatSpec + explicit LR-2 ties + reuse language).
- Code examples in doc now match gold standard (post-central pass expectation noted).
- This doc update is the vehicle for LR-1/LR-2/LR-3 focus on natspec standard itself; deeper LR-2 content (e.g. full CREATE3 package guides) lives in sibling deployment docs per their gap reports.
- The dedicated script `scripts/foundry/ComputeNatSpecValues.s.sol` (with its own NatSpec/tags) + sh helper closes the "pure compiler Script using `type(I).interfaceId`" item.
- Always read in strict order per doc: 1. gap report, 2. CENTRALLY_COMPUTED..., 3. PRD (LRs), 4. AGENTS.md, 5. referenced sources.

**Priority:** High (closed)
