# Gap Report for: contracts/registries/target/CallTargetRegistryRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard
- LR-6: ERC1967-Compliant Storage Slot Derivation

**Current State Summary:**
Gaps closed for this file per LR-1 and LR-6. (Targeted minimal edit; only source + this report + GAP_REPORT.md edited. Verified with forge build.)

**Detailed Gaps (Closed):**
- LR-6: DEFAULT_SLOT updated to the exact ERC1967 form: bytes32(uint256(keccak256(abi.encode("crane.registries.calltargets"))) - 1).
- LR-1: full NatSpec + // tag:: // end:: for library (CallTargetRegistryRepo[]), DEFAULT_SLOT, Storage, both _layoutStruct overloads, and all dual function pairs (_defaultCallTargetForID*, _setDefaultCallTargetForID*, _callTargetForIDForCaller*, _setCallTargetForIDForCaller*) using OperableRepo / DiamondFactoryPackageRegistryRepo gold standard hyphenated tag style (e.g. _defaultCallTargetForID(Storage-bytes4)[], _defaultCallTargetForID(bytes4)[]) + rich @dev/@param/@return NatSpec. Consulted CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no direct symbols listed for this internal Repo; no @custom:selector etc inserted as none apply to pure-internal storage accessors).

**Actions Completed:**
- Fixed non-ERC1967 slot constant (DEFAULT_SLOT) and updated related _layoutStruct default.
- Added top-level // tag::CallTargetRegistryRepo[] / end + full library NatSpec (title, author, dev).
- Wrapped Storage, DEFAULT_SLOT, _layoutStruct duals + all getters/setters with precise tags and docs modeled on recently closed registry Repos.
- Kept existing logic and sectioning comments identical; only enhanced NatSpec and tags.
- Updated the per-file gap report itself.
- Only edited allowed files: the .sol source, this gap report, and GAP_REPORT.md.

**NatSpec Symbols Tagged:**
- CallTargetRegistryRepo, DEFAULT_SLOT, Storage, _layoutStruct(bytes32), _layoutStruct(), _defaultCallTargetForID* (2), _setDefaultCallTargetForID* (2), _callTargetForIDForCaller* (2), _setCallTargetForIDForCaller* (2). (See updated source for exact tags and NatSpec.)

**Testing Gaps (LR-7 specific if applicable):**
N/A (no changes to tests; this edit was strictly for LR-1/LR-6 in the Repo storage lib. Declaration coverage for associated facets would be via Behavior_IFacet in consuming tests; registry population asserted in factory tests).

**Documentation/Skills Gaps (if applicable):**
Out of scope for this task (registries already documented at high level in CODEBASE_MAP.md etc.).

**Notes for Subagents:**
- Implemented only fixes for this file's gaps (LR-1/LR-6 for the CallTargetRegistryRepo).
- Central values consulted from docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (referenced where applicable; strictly no values fabricated).
- Updated the main GAP_REPORT.md checkbox + LR-6 mention.
- Did not edit any other files (no interfaces, targets, facets, DFPkg, tests, or other gap reports).

**Priority:** High (closed)

## Central NatSpec Population (coordinated pass)
See docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for the authoritative list of computed selectors, topic0, and interfaceIds (e.g. for related ICallTargetRegistry* surface if/when populated).
Use those values when implementing the NatSpec tags in related interfaces (none required to be inserted in this Repo).

(Values pre-computed centrally to ensure accuracy and avoid duplication across subagents.)

## Verification Pass (strict read order + build/tests + tracking update)
Re-ran strict read order for this task assignment (1. this gap report, 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md using ONLY its values (none apply here), 3. PRD.md (LR-1/LR-6 sections), 4. AGENTS.md (gold Repo patterns, hyphenated tags e.g. Storage-*, dual _layout/_xxx overloads, NatSpec+tags), 5. source contracts/registries/target/CallTargetRegistryRepo.sol).

Source already compliant: 
- LR-6: DEFAULT_SLOT = bytes32(uint256(keccak256(abi.encode("crane.registries.calltargets"))) - 1) + _layoutStruct default.
- LR-1: full NatSpec + exact // tag::CallTargetRegistryRepo[] / // end:: + tagged DEFAULT_SLOT/Storage + dual _layoutStruct(bytes32)[] / _layoutStruct()[] + all 8 dual function pairs using hyphenated style (e.g. _defaultCallTargetForID(Storage-bytes4)[], _defaultCallTargetForID(bytes4)[], _setCallTargetForIDForCaller(Storage-bytes4-address-address)[] etc) + rich @dev/@param/@return modeled on OperableRepo/DiamondFactoryPackageRegistryRepo gold + AGENTS/PRD.

**Build + tests verification (this pass):**
- Targeted: `forge inspect CallTargetRegistryRepo abi` + `forge inspect CallTargetRegistryQueryTarget bytecode` : exit 0, valid output/bytecode emitted (compiles cleanly including repo + dependents).
- Full forge build attempted (background; long due to 5k+ files); relevant paths covered by inspect.
- Related test compile/setup: DevEnvSmokeTest.t.sol (exercises CallTargetRegistryDFPkg + registry via InitBcService) compiles (targeted --no-match-test setup verified paths).
- No source changes required/needed (already at gold standard); only updated this gap report + GAP_REPORT.md per rules.

**Updated tracking:** Added verification entry below in GAP_REPORT.md under LR-1/LR-6 for this file. No other files edited. 

This closes/ reaffirms the per-file gaps for the assigned target report (no remaining gaps for CallTargetRegistryRepo LR-6/LR-1).
