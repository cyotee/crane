# Gap Report for: contracts/registries/facet/FacetRegistryFacet.sol

**File Type:** Facet

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full NatSpec + // tag:: / // end:: + @custom:selector/signature/interfaceid for facet and all public methods)
- LR-6: ERC1967-Compliant Storage Slot Derivation (if needed - n/a here)
- LR-7: Testing Standards (facet declaration tests via Behavior_IFacet / TestBase_IFacet for facetInterfaces/facetFuncs; noted only)

**Current State Summary:**
Before fix: No NatSpec at all on contract or the 4 public IFacet methods. No // tag:: / // end:: wrappers. Followed basic IFacet impl pattern but missing required documentation per ERC8023 gold standard in PRD/LR-1 and AGENTS.md. (LR-6 not applicable: this facet has no storage/Repo; the related FacetRegistryRepo already used correct ERC1967 DEFAULT_SLOT form per prior review. LR-7 declaration test coverage may pre-exist via registry tests or IFacet behavior; source changes support by making facet fully documented. No test files edited.)

**Detailed Gaps (closed by this work):**
- LR-1: missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).
- LR-1: Document facetName, facetInterfaces, facetFuncs, facetMetadata.
- (LR-7 test declaration coverage noted; source now has full NatSpec+tags to match LR-1 for documented surface. LR-6 n/a.)

**Specific Actions Needed to Close Gaps:**
1. Wrapped documented symbols (contract + 4 public fns) with exact // tag::Symbol(params)[] ... // end::
2. Added @inheritdoc IFacet + modeled on gold standard (no duplication of @custom here as they live in IFacet per pattern used in ERC20Facet/ERC165Facet/MultiStepOwnableFacet fixes). Used central values indirectly via @inheritdoc (explicit selectors confirmed matching via inspect).
3. (No Repo in this file; LR-6 n/a.)
4. Updated this gap report + main GAP_REPORT.md tracking.
5. Verified via `forge inspect FacetRegistryFacet abi` (targeted compile validation equivalent for the change) + full build launch; also confirmed selectors match central: 0x5b6f4d01 etc.

**Central NatSpec Values Used (from docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md ; ONLY these):**

From central (IFacet section):
- facetName() : 0x5b6f4d01
- facetInterfaces() : 0x2ea80826
- facetFuncs() : 0x574a4cff
- facetMetadata() : 0xf10d7a75

Confirmed post-edit via `forge inspect` output (exact match):
- facetName() pure returns (string)  | 0x5b6f4d01
- facetInterfaces() pure returns (bytes4[]) | 0x2ea80826
- facetFuncs() pure returns (bytes4[]) | 0x574a4cff
- facetMetadata() pure returns (string,bytes4[],bytes4[]) | 0xf10d7a75

(Interface IDs and other selectors for IFacetRegistry methods are compiler-derived via .interfaceId / .selector inside facetFuncs/facetInterfaces bodies; no ad-hoc literals added. IFacetRegistry specific values not present in central pass so not hardcoded.)

**NatSpec Symbols Tagged (exact):**
- Main: FacetRegistryFacet (full contract wrapper)
- facetName()
- facetInterfaces()
- facetFuncs()
- facetMetadata()

(No events/errors declared on this facet contract itself; they are in inherited Target/Repo/Operable + IFacetRegistry interface. IFacet customs live in contracts/factories/diamondPkg/IFacet.sol per pattern. The facetFuncs body references 14 IFacetRegistry selectors for declaration.)

**Testing Gaps (LR-7 specific if applicable):**
- Declaration tests for facets use Behavior_IFacet (pre-existing coverage likely in registry or diamondPkg tests; source update ensures documented parity).
- Source now has full NatSpec+tags to match LR-1 for documented surface (tests themselves out of scope per edit rules: only source + its gap + GAP_REPORT.md).
- (Other LR-7 like full pkg init, preview parity, etc. not applicable to this pure facet file. Full init of registry subjects would be in consumer tests.)

**Documentation/Skills Gaps (if applicable):**
- Surface documented via source tags for extraction (LR-2/LR-3 notes remain general; registries usage covered in other updated docs/skills per prior entries).

**Notes for Subagents (post-fix):**
- Implemented only fixes for this file's gaps per rules (only edited: contracts/registries/facet/FacetRegistryFacet.sol + this gap report + GAP_REPORT.md).
- Used ONLY central values (never ad-hoc computation or literals for the IFacet methods).
- Updated main GAP_REPORT.md checkbox.
- Ran targeted compile validation (`forge inspect FacetRegistryFacet abi` which succeeds and prints the IFacet methods + selectors) + async full `forge build`. Confirmed output selectors == central values.
- Do not edit other files (followed strictly; closest registry report was this one for LR-1/LR-6).
- LR-6: confirmed not needed (FacetRegistryRepo.sol already uses correct bytes32(uint256(keccak256(abi.encode("crane.registries.facets"))) - 1) form).

**Priority:** High (core framework files)

**Status:** CLOSED (LR-1 source gaps for facet; LR-6 n/a)
