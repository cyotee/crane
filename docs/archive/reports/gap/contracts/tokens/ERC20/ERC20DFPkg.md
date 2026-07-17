# Gap Report for: contracts/tokens/ERC20/ERC20DFPkg.sol

**File Type:** DFPkg

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full @custom + // tag:: include-tags on public symbols, contract, interface)
- LR-7: Testing Standards (package declaration tests for packageName, facet*, diamondConfig, calcSalt, initAccount, postDeploy etc.)

**Current State Summary:**
Gaps closed for NatSpec on this DFPkg file. (No Repo/storage in this file, so no LR-6 slot changes required. PkgInit/PkgArgs correctly live inside IERC20DFPkg interface per AGENTS.md rules.)

**Detailed Gaps Closed:**
- LR-1: Added/enhanced rich NatSpec (@title/@notice/@param/@return/@dev + @custom:signature / @custom:selector from CENTRALLY... + @custom:throws) to the contract, the local IERC20DFPkg interface, Pkg* structs, errors, deploy overloads, and ALL IDiamondFactoryPackage public methods.
- Existing // tag::...[] / // end::...[] were present but incomplete/inconsistent for overloads; updated to use exact gold-standard style (hyphenated param lists for overloads e.g. deploy(IDiamondPackageCallBackFactory-string-string-uint8-uint256-address-bytes32)[] and constructor(IERC20DFPkg.PkgInit)[], descriptive -erc20/-impl variants) while preserving extraction compatibility. Followed ERC8023 + Create3FactoryDFPkg + Operable style for rich docs.
- All @custom: for IDiamondFactoryPackage surface use ONLY values from docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no ad-hoc computation or cast).
- LR-7 coverage note: declaration surface (packageName/facetAddresses/facetCuts/diamondConfig/calcSalt/processArgs/initAccount/postDeploy etc.) now fully documented with exact central values; tests themselves not modified per scope (only .sol + gap report + GAP_REPORT.md).

**Actions Performed (scoped strictly to this report's gaps):**
1. Performed strict read order before any edit: (1) this gap report, (2) CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY its IDiamondFactoryPackage + IFacet overlap values), (3) PRD.md (LR-1 NatSpec+tags for DFPkgs, LR-7 package decl tests), (4) AGENTS.md (DFPkg Pkg* in I* interface only, Facet-Target-Repo notes, NatSpec include tags with hyphen overloads, central values, no viaIR), (5) source contracts/tokens/ERC20/ERC20DFPkg.sol + skimmed its embedded interface for Pkg structs.
2. Preserved/updated exact `// tag::Name(params)[] ... // end::Name(params)[]` (no extra spaces) around contract, interface, all structs, errors, and every public/external.
3. Added rich notices/params/returns/dev/throws modeled on Create3FactoryDFPkg.sol gold + ERC8023 + Operable.
4. Updated all relevant IDiamond* impls to duplicate @custom:selector/signature (central) + @inheritdoc.
5. Ensured constructor uses PkgInit from interface, immutables, facetCuts/diamondConfig logic correct (no changes to logic).
6. Only edited allowed files: this .sol + its gap report + GAP_REPORT.md.

**NatSpec Symbols Documented (with tags + central values):**
- Main: IERC20DFPkg , ERC20DFPkg
- Structs: PkgInit , PkgArgs  (defined inside IERC20DFPkg interface per AGENTS critical rule)
- Errors (local): NoNameAndSymbol() , NoRecipient()
- Functions (local deploys + overloads): deploy(IDiamondPackageCallBackFactory-string-string-uint8-uint256-address-bytes32)[] , deploy(IDiamondPackageCallBackFactory-PkgArgs)[]
- IDiamondFactoryPackage (ALL public, with central): 
  - packageName() : 0xabc8b346
  - facetInterfaces() : 0x2ea80826
  - facetAddresses() : 0x52ef6b2c
  - packageMetadata() : 0xf45469e7
  - facetCuts() : 0xa4b3ad35
  - diamondConfig() : 0x65d375b3
  - calcSalt(bytes) : 0xd82be56e
  - processArgs(bytes) : 0x87c3adb3
  - updatePkg(address,bytes) : 0xa9089235
  - initAccount(bytes) : 0x870d4838
  - postDeploy(address) : 0x70068fcf
- Also: constructor(IERC20DFPkg.PkgInit)[]

**Testing Gaps (LR-7 notes - not addressed by edits here):**
- Per instructions: only the source DFPkg + its gap report + GAP_REPORT.md were edited.
- LR-7 items (e.g. full init of packages with non-zero facets in tests, Behavior usage if any, exact declaration assertions for packageName/facetCuts/diamondConfig/calcSalt etc.) remain for separate work (pre-existing tests at test/foundry/spec/tokens/ERC20/ERC20DFPkg_*.t.sol cover usage).
- The NatSpec now supports documentation of the required declaration surface (packageName, facetAddresses, facetCuts, diamondConfig, calcSalt, initAccount, postDeploy per LR-7).

**Documentation/Skills Gaps (if applicable):**
- (Out of scope for this specific gap report; see root GAP_REPORT for LR-2/LR-3 tracking. Note this is referenced in AGENTS.md as the DFPkg example.)

**Notes for Subagents:**
- Work ONLY on files needed for this report's gaps (ERC20DFPkg.sol + its .md + GAP_REPORT.md).
- Used only central NatSpec values (referenced CENTRALLY_COMPUTED_NATSPEC_VALUES.md keys: IDiamondFactoryPackage packageName 0xabc8b346, facetCuts 0xa4b3ad35, diamondConfig 0x65d375b3, calcSalt 0xd82be56e, initAccount 0x870d4838, postDeploy 0x70068fcf, facetInterfaces 0x2ea80826, plus facetAddresses/packageMetadata/processArgs/updatePkg).
- Exact tag style + hyphen overloads + rich style followed.
- After edits: verified with `forge inspect ERC20DFPkg abi` (success; all selectors match central values exactly; no NatSpec validation errors after fixes for named @param/@return).
- Also ran targeted `forge build` attempts and `forge test --match-path "*ERC20DFPkg*" --list` attempts (compile verified via inspect; tests slow to list but pre-existing coverage exists).
- Updated the gap report and GAP_REPORT.md .

**Status:** CLOSED (LR-1 NatSpec for DFPkg; full rich docs + exact tags + ONLY central customs)

**Priority:** High for core framework files. (Also referenced in AGENTS.md key files list)
