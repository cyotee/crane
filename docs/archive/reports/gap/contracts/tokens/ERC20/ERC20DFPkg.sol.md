# Gap Report for: contracts/tokens/ERC20/ERC20DFPkg.sol

**File Type:** DFPkg (ERC20 token factory package - key for token reusability)

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full NatSpec + // tag:: / // end:: + @custom:selector/signature for contract, interface, structs, all public methods using central values only).
- LR-7: Testing Standards (noted for related test; this file scoped to source NatSpec).

**Current State Summary:**
LR-1 gaps closed for source. Performed strict read order (gap report, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD LR-1, AGENTS.md, source). ONLY edited: source + this gap report + GAP_REPORT.md. Added full rich NatSpec + exact gold-standard hyphenated // tag:: / // end:: (e.g. ERC20DFPkg[], IERC20DFPkg[], PkgInit[], PkgArgs[], constructor(IERC20DFPkg.PkgInit)[], deploy overloads, all IDiamondFactoryPackage methods like packageName-erc20, facet*-erc20, diamondConfig-erc20, calcSalt-erc20, processArgs-erc20, updatePkg-erc20, initAccount-erc20, postDeploy-erc20). Used ONLY central values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md for all IDiamondFactoryPackage customs (packageName 0xabc8b346, facetCuts 0xa4b3ad35, diamondConfig 0x65d375b3, calcSalt 0xd82be56e, initAccount 0x870d4838, postDeploy 0x70068fcf, facetInterfaces 0x2ea80826, facetAddresses 0x52ef6b2c, packageMetadata 0xf45469e7, processArgs 0x87c3adb3, updatePkg 0xa9089235). Added rich @notice/@param/@return/@dev/@custom:throws (NoNameAndSymbol, NoRecipient) + @inheritdoc following gold (Create3FactoryDFPkg + ERC8023 + Operable). Pkg structs correctly on interface (per AGENTS). Strict process. Verification: `forge inspect ERC20DFPkg abi` + `methodIdentifiers` (selectors exact match central); targeted build clean. (Note: no storage slots in this DFPkg.)

**Detailed Gaps (addressed):**
- LR-1: Incomplete/missing NatSpec + tags on contract, interface (IERC20DFPkg), PkgInit/PkgArgs, constructor, deploy methods, all IDiamondFactoryPackage methods. Now full with hyphenated tags for overloads, central customs only.
- (LR-7 scoping: declaration tests covered in related test file; source NatSpec only here.)

**Specific Actions Taken to Close Gaps:**
1. Strict read order executed before edits.
2. Wrapped all documented symbols with exact gold-standard // tag::Name(params)[] ... // end:: (hyphenated for overloads e.g. deploy-..., packageName-erc20).
3. Added rich NatSpec (@notice/@param/@return/@dev/@custom:throws/@inheritdoc) + @custom:selector/@custom:signature using ONLY central values (no ad-hoc computation).
4. Ensured PkgInit/PkgArgs on interface (AGENTS rule).
5. Updated per-file gap report + main GAP_REPORT.md.
6. Verified with targeted forge inspect (abi + methodIdentifiers match central exactly); build --quiet clean.

**NatSpec Symbols Tagged (exact, using ONLY central from CENTRALLY_COMPUTED_NATSPEC_VALUES.md):**
- IERC20DFPkg (interface)
- PkgInit[]
- PkgArgs[]
- NoNameAndSymbol() (error, selector 0x62277d23)
- NoRecipient() (error, selector 0x65a4920b)
- deploy(IDiamondPackageCallBackFactory-string-...) 
- deploy(IDiamondPackageCallBackFactory-PkgArgs)
- ERC20DFPkg (contract)
- constructor(IERC20DFPkg.PkgInit)
- deploy convenience + pkgargs impl
- packageName-erc20 (0xabc8b346)
- facetInterfaces-erc20 (0x2ea80826)
- facetAddresses-erc20 (0x52ef6b2c)
- packageMetadata-erc20 (0xf45469e7)
- facetCuts-erc20 (0xa4b3ad35)
- diamondConfig-erc20 (0x65d375b3)
- calcSalt-erc20 (0xd82be56e)
- processArgs-erc20 (0x87c3adb3)
- updatePkg-erc20 (0xa9089235)
- initAccount-erc20 (0x870d4838)
- postDeploy-erc20 (0x70068fcf)

**Testing Gaps (LR-7 specific if applicable - scoped):**
- Source NatSpec now supports declaration tests (full surfaces) in related test (ERC20DFPkg_IERC20.t.sol). Full init/exact/Behavior covered there.

**Documentation/Skills Gaps (LR-2/LR-3 - addressed for this file):**
- Rich NatSpec + tags enable GitBook extraction. Ties to crane-tokens skill, deployment/dfpkg, AGENTS (Pkg structs on interface, no viaIR). Cross-refs to central process.

**Notes for Subagents:**
- Implemented only fixes for this file's LR-1 gaps.
- Used ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md (strict read order: gap, central, PRD LR-1, AGENTS, source). No new values computed.
- Pkg structs on interface (per rules).
- Post-edit: `forge inspect ERC20DFPkg abi` + `methodIdentifiers` exact central match; `forge build --quiet` clean.
- Updated this gap + main GAP_REPORT.md.

**Status:** LR-1 CLOSED for ERC20DFPkg.sol.
**Priority:** High (key DFPkg for ERC20 token reusability)
