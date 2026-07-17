# Gap Report: .claude/skills/crane-testing/SKILL.md

**File Type:** Agent Skill

**Primary LR Violations:** LR-3 (Up-to-date skills), LR-7 (testing standards)

## Current State
Skill exists and covers related topic. Now fully aligned (see below).

## Specific Gaps (Closed)
- [x] Drifted from PRD standards: now explicitly documents LR-7 testing rules (full init of SUTs/DFPkgs with no address(0), exact value assertions + deltas, preview parity, Facet declaration tests + Package declaration tests, mandatory Behavior_* usage for IFacet/IDiamondFactoryPackage/etc. instead of ad-hoc, correct CraneTest/TestBase_* setUp order + parent calls, NatSpec on test code incl. TestBases/Behaviors/Handlers per LR-1).
- [x] Ties to central NatSpec process: added upfront requirements block requiring exclusive use of CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY those values); references dedicated Foundry Script verification (not ad-hoc cast); lists example central IFacet values (facetName(): 0x5b6f4d01, facetInterfaces(): 0x2ea80826, facetFuncs(): 0x574a4cff, facetMetadata(): 0xf10d7a75, supportsInterface: 0x01ffc9a7 from CENTRALLY...); cross-refs crane-natspec skill + docs/development/natspec.md.
- [x] ERC1967: added requirement that testers respect ERC1967 slot derivation (DEFAULT_SLOT form with -1) in storage-related tests; cross-ref to crane-architecture skill + LR-6.
- [x] Missing explicit coverage for Behaviors/Handlers/TestBases: expanded all sections with LR-7 mandates, added detailed "LR-7 Testing Standards (Mandatory)" section with full enumerated list excerpted from PRD, explicit "Facet Declaration Tests" + "Package Declaration Tests" guidance + examples using Behavior, "Correct CraneTest / TestBase Inheritance and Initialization Order (LR-7)" subsection.
- [x] GitBook LR-2 content references: added calls to `docs/development/testing.md` throughout, notes on required LR-2 coverage (registry population assertions in tests, TestBases/stubs for ported protocols, utility libs e.g. Sets + ConstProdUtils in integration tests). Links to deployment + protocols GitBook areas.
- [x] Examples updated for accuracy: now use length pre-checks + Behavior calls (matching current TestBase_IFacet/Behavior_IFacet), full expect/isValid/hasValid patterns with logging from sources, exact vm.expect* usage, invariant examples with assertEq + comments for preview parity etc. References correct inheritance + no 'new' for Crane items (via crane-deployment).
- [x] Test NatSpec + central ties + other LR-7: added Key Conventions item + dedicated NatSpec on test code bullet; full DFPkg lifecycle, CREATE3 determinism, registry pop, storage isolation, error selector matching (central), fork parity, access/reentrancy matrix all called out.
- [x] References to AGENTS.md, PRD LR sections, other crane-* skills, and "Update this skill when standards evolve (LR-3)".

## Changes Made (using only allowed inputs)
1. Updated skill content (multiple targeted section expansions) to match current patterns from reads of CraneTest.sol, TestBase_IFacet.sol, Behavior_IFacet.sol, TestBase_IERC165.sol, Behavior_IERC165.sol, TestBase_ERC20 patterns, AGENTS.md testing sections, PRD LR-3/LR-7, CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY), natspec.md, development/testing.md, plus original skill + its gap report.
2. Added explicit LR-7 compliance section + initialization/declaration/Behavior mandates.
3. Referenced central NatSpec computation process (use ONLY central values), ERC1967, GitBook LR-2 (testing.md + required registry/protocol/utility test coverage).
4. All new prescriptive text + examples are accurate to the read sources; no invented code or values.
5. Aligns with LR-4 reuse messaging indirectly via declared/tested facets for safe reuse.

**Priority:** High for core crane-* skills; Medium for protocol ones.

**Subagent Notes:** Gaps closed per task (LR-3/LR-7 focus for crane-testing). Skill now enables correct agent behavior for testing per current standards (full init, Behaviors exact, declaration tests, CraneTest order, test NatSpec, central process). Only edited skill + this gap report + GAP_REPORT.md. No source files (.sol) or other docs edited. All content derived strictly from gap report (original) + CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IFacet selectors only) + PRD.md (LR sections) + AGENTS.md + the skill file itself + referenced test infrastructure patterns + docs/development/testing.md + natspec.md.
