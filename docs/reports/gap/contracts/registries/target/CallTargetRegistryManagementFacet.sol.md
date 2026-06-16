# Gap Report for: contracts/registries/target/CallTargetRegistryManagementFacet.sol

**File Type:** Facet

**Primary Affected Requirements (from PRD):**
- LR-1 (NatSpec + include-tags for facet + public methods; full @custom using central values)

**Current State Summary:**
LR-1 gaps closed (NatSpec + tags added using ONLY central values). Other items (e.g. LR-7) noted but untouched per "Edit ONLY" rules.

**Detailed Gaps (pre-edit):**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).
- LR-7: Add test asserting facetInterfaces() and facetFuncs() match expected (use Behavior_IFacet).
- LR-1: Document facetName, facetInterfaces, facetFuncs, facetMetadata.

**Actions Taken to Close Gaps (LR-1 focus only):**
1. Wrapped documented symbols with exact // tag::CallTargetRegistryManagementFacet[] ... // end::CallTargetRegistryManagementFacet[] (and per-method).
2. Added full NatSpec to facet + public methods (facetName, facetInterfaces, facetFuncs, facetMetadata) using ONLY central values.
3. Inserted @custom:selector / @custom:signature from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (0x5b6f4d01 etc).
4. (No Repos/slots edited here; LR-6 not applicable to this Facet file.)

**NatSpec Symbols Tagged (using ONLY central values):**
- CallTargetRegistryManagementFacet (contract)
- facetName() [selector 0x5b6f4d01, signature from central]
- facetInterfaces() [selector 0x2ea80826]
- facetFuncs() [selector 0x574a4cff]
- facetMetadata() [selector 0xf10d7a75]

**Testing Gaps (LR-7 etc - unchanged per edit scope):**
- Full initialization, Behavior_IFacet use, declaration tests etc. remain for LR-7 work (e.g. in test/foundry/DevEnvSmokeTest.t.sol); only LR-1 addressed.
- Per rules, did not edit tests or other files.

**Documentation/Skills Gaps (LR-2/LR-3 - unchanged per scope):**
- GitBook/skills coverage may still reference; edits limited to LR-1 NatSpec on this file only.

**Notes for Subagents:**
- Implemented *only* fixes for this file's LR-1 gaps.
- All NatSpec custom values taken exclusively from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no independent computation).
- Updated the main GAP_REPORT.md checkbox (in next step).
- Edited ONLY: source + this report + GAP_REPORT.md .

**Status:** LR-1 CLOSED for CallTargetRegistryManagementFacet.sol .

**Priority:** High (core framework files)

**Post-edit Verification Steps (per task):**
- Run `forge build`
- Run targeted tests: `forge test --match-path test/foundry/DevEnvSmokeTest.t.sol -vv`
- Confirm no other files were modified.
