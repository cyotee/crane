# Gap Report: .claude/skills/crane-architecture/SKILL.md

**File Type:** Agent Skill

**Primary LR Violations:** LR-3 (Up-to-date skills), LR-2 (GitBook content)

## Current State
Skill exists and covers related topic. Now fully aligned (see below).

## Specific Gaps (Closed)
- [x] Drifted from finalized PRD standards (NatSpec via Foundry Script + central, ERC1967 slots, LR-7 testing, GitBook required content): updated with explicit "LR-3 Alignment" block; all examples use ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IFacet 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75; IDiamondPackageCallBackFactory 0x949da331 + 0xe97fac05 etc; IDiamondFactoryPackage 0xabc8b346/0x870d4838/0x70068fcf/0xa4b3ad35/0x65d375b3/0xd82be56e; Create3 0x34cb11b5); storage examples now use ERC1967 `DEFAULT_SLOT = bytes32(uint256(keccak256(...)) - 1)`; added LR-7 full sections; referenced verification script + "use ONLY".
- [x] Missing explicit coverage:
  - Added "Reusability of DiamondPackageCallBackFactory" section (verbatim quotes from source NatSpec: "Safe and intended for reuse by any consumer on any chain.", "Deployed once"; interfaceId + key selectors from central ONLY; how to obtain via diamondPackageFactory(); LR-4 reuse benefits).
  - Added "Deploying Your Own Create3Factory via Package (Chain Bootstrap)" section (ICREATE3DFPkg / Create3FactoryDFPkg; PkgInit/PkgArgs rule on interface; deployCreate3Factory 0x34cb11b5 central; flow using canonicals from registry + InitDevService/CraneTest; cross to docs).
  - Added "Registries (Facet / Package / CallTarget)" detailed section (purpose for discovery/reuse/LR-4; auto population via Create3Factory _register* + _deploy*; consumer queries: canonicalFacet, facetsOf*, allFacets; examples from source repos/IFs; ties to TestBases).
  - Added "Utility Library Patterns (Sets, Math, Collections)" (AddressSet/Bytes4Set 1-indexed + *SetRepo ops; usage in registries/handlers/Behaviors; ConstProdUtils ref; crane-utilities tie-in; AGENTS + CODEBASE_MAP crosslinks).
  - Added "Testing: Correct Initialization + Behavior Usage (LR-7)" (CraneTest + InitDev full init rules; mandatory Behavior_IFacet + IDiamond* declaration tests using central selectors; no zero-addrs; exact asserts; test NatSpec; references crane-testing skill + AGENTS + docs/testing.md + protocol TestBases).
- [x] Examples may use old slot formats or incomplete NatSpec: all slot examples updated to ERC1967 + tags; IFacet/DFPkg examples use exact central @custom:selector values + tag style from gold standards (ERC8023/AGENTS); added central date/process refs.
- [x] Added ties to GitBook required areas (LR-2), PRD LR-1/2/3/4/6/7, AGENTS.md (patterns + testing), docs (deployment/create3/dfpkg/getting-started/CODEBASE_MAP), other crane-* skills; reuse/LR-4 language ("deploy once, attach everywhere", "reuse already-deployed verified code"); strict read order + allowed edits only.

## Changes Made (using only allowed inputs)
1. Updated skill content (new LR-3 alignment header block + dedicated LR-2 sections for reuse/factory bootstrap/registries/utilities/testing + updated existing storage/DFPkg/IFacet/decision guide) to current standards from reads.
2. All @custom/selector examples and references use **ONLY** values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no ad-hoc, no fabrication).
3. Explicitly added the 5 missing coverages listed in original gap; ERC1967 form + NatSpec Foundry Script/central process called out.
4. Aligned with PRD LR sections, AGENTS.md (Facet-Target-Repo, DFPkg rule, FactoryService, testing, registries, Sets, reuse), source files (DiamondPackageCallBackFactory.sol, Create3FactoryDFPkg.sol + ICREATE3DFPkg, Create3Factory.sol, FacetRegistryRepo.sol, IDiamondFactoryPackage.sol, CraneTest.sol, Behavior_IFacet.sol, AddressSetRepo.sol, ERC20DFPkg.sol, InitDevService.sol, IFacet.sol etc.).
5. Strict read order followed exactly: 1. target gap report, 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY those values), 3. PRD.md (LR-1/2/3/4/6/7 + required GitBook), 4. AGENTS.md (full patterns + NatSpec + testing + key files), 5. source file(s) referenced (the skill + its references/*.md + the .sol listed in Key Reference Files).
6. Only edited: the skill (.claude/skills/crane-architecture/SKILL.md) + this gap report + GAP_REPORT.md. No other files touched.

**Priority:** High for core crane-* skills; Medium for protocol ones.

**Subagent Notes:** Gaps closed per task. Skill now enables correct agent behavior for architecture per current standards (ERC1967, central NatSpec/Foundry Script, DFPkg rules, explicit factory reuse + Create3 pkg bootstrap + registries + Sets + LR-7 test init/Behaviors). Only edited skill + this gap report + GAP_REPORT.md. All content derived strictly from allowed reads (gap + central + PRD + AGENTS + sources). Follow "use ONLY" central rule for any NatSpec values.
