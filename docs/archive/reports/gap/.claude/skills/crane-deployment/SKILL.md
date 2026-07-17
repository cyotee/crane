# Gap Report: .claude/skills/crane-deployment/SKILL.md

**File Type:** Agent Skill

**Primary LR Violations:** LR-3 (Up-to-date skills), LR-2 (content)

## Current State
Skill exists and covers related topic. Now fully aligned (see below).

## Specific Gaps (Closed)
- [x] Drifted from PRD standards: now references NatSpec verification via Foundry Script + CENTRALLY_COMPUTED_NATSPEC_VALUES.md (only central values used in examples); references ERC1967; incorporates LR-7 testing rules (full init, Behaviors, exact asserts, declaration tests, registry pop, salt checks); GitBook topics covered.
- [x] Missing explicit coverage:
  - Added full section: "Reusability of DiamondPackageCallBackFactory" (quotes source NatSpec: "Safe and intended for reuse...", "deployed once", obtain via diamondPackageFactory(), interfaceId 0x949da331 from central).
  - Added full section: "Chain Bootstrap with Create3FactoryDFPkg" (step-by-step from InitDev + DFPkg.deployCreate3Factory; Pkg* on interface; links to docs; using diamond factory for new chain Create3 instance).
  - Added full section: "Registries Explanation" (FacetRegistry, PackageRegistry, CallTarget; auto-pop via Create3 _register*; canonical queries; purpose for consumers).
  - Updated test sections with LR-7 (no addr(0), Behavior_IFacet + Behavior_IDiamondFactoryPackage, full DFPkg/package decl tests, exacts, CraneTest order, registry/salt checks).
  - Examples updated with central NatSpec values (selectors e.g. 0xe97fac05, 0xabc8b346, 0x2ea80826, interface 0x949da331); NatSpec process (Foundry script, tags) called out.
  - No slot examples added (avoids old format); anti-patterns now lists ERC1967 requirement + other LR-7.
- [x] Links to docs added throughout (deployment/create3.md, dfpkg.md, concepts etc.) + GitBook/LR-2 notes.
- Utility libs note de-scoped (not core to deployment skill; covered in crane-utilities).

## Changes Made (using only allowed inputs)
1. Updated skill content to match current code (from reads of Create3Factory.sol, DiamondPackageCallBackFactory.sol, Create3FactoryDFPkg.sol, IDiamond* interfaces, InitDevService.sol, registries IFacet*, CraneTest.sol, PRD LR-2/LR-3/LR-7, AGENTS, central values, gap report).
2. Added required explicit sections on reusability, chain bootstrap w/ Create3FactoryDFPkg, registries.
3. References central NatSpec + verification process, updated testing to LR-7, GitBook topics.
4. All examples use central values; accurate to source NatSpec, flow diagrams, registration logic, init flows.
5. Updated consumer/agents sections for reuse story (LR-4).

**Priority:** High for core crane-* skills; Medium for protocol ones.

**Subagent Notes:** Gaps closed per task. Skill now enables correct agent behavior for deployment per current standards. Only edited skill + this gap report + GAP_REPORT.md. No source files edited. All content derived strictly from gap report + CENTRALLY... + PRD + AGENTS + referenced .sol + deployment docs snippets.
