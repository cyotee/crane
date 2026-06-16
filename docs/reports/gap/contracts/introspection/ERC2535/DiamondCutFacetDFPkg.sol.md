# Gap Report for: contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol

**File Type:** DFPkg

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include-tags standard)

**Current State Summary:**
LR-1 closed. Previously 0 rich NatSpec + 0 // tag:: wrappers on this core DFPkg. PkgInit/PkgArgs correctly located on the I* interface (no change needed). All code/logic/comments preserved exactly. No LR-6/7 work performed (LR-7 noted only in report). Rich NatSpec + @custom + exact tags added modeled directly on closed golds (CallTargetRegistryDFPkg, BountyBoardDFPkg, Create3FactoryDFPkg, ERC20DFPkg).

**Detailed Gaps (pre-closure):**
- LR-1: missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).
- LR-7: (not addressed in this scope; declaration tests exist via other infra like DevEnvSmokeTest + Behavior paths).

**Symbols Wrapped with // tag:: / // end:: (16+):**
- IDiamondCutFacetDFPkg (interface + rich @title/@author/@notice/@dev)
- PkgInit[]
- PkgArgs[]
- DiamondCutFacetDFPkg (contract + @title/@author/@notice/@dev)
- constructor(IDiamondCutFacetDFPkg.PkgInit)[]
- packageName-diamondcutfacetdfpkg[]
- packageMetadata-diamondcutfacetdfpkg[]
- facetAddresses-diamondcutfacetdfpkg[]
- facetInterfaces-diamondcutfacetdfpkg[]
- facetCuts-diamondcutfacetdfpkg[]
- diamondConfig-diamondcutfacetdfpkg[]
- calcSalt-diamondcutfacetdfpkg[]
- processArgs-diamondcutfacetdfpkg[]
- updatePkg-diamondcutfacetdfpkg[]
- initAccount-diamondcutfacetdfpkg[]
- postDeploy-diamondcutfacetdfpkg[]

**Centrally Computed NatSpec Values Used (ONLY from CENTRALLY_COMPUTED_NATSPEC_VALUES.md):**
- All IDiamondFactoryPackage: packageName() 0xabc8b346, facetInterfaces() 0x2ea80826, facetAddresses() 0x52ef6b2c, packageMetadata() 0xf45469e7, facetCuts() 0xa4b3ad35, diamondConfig() 0x65d375b3, calcSalt(bytes) 0xd82be56e, processArgs(bytes) 0x87c3adb3, updatePkg(address,bytes) 0xa9089235, initAccount(bytes) 0x870d4838, postDeploy(address) 0x70068fcf
- Cross-ref IFacet where facets delegate: facetName 0x5b6f4d01, facetInterfaces 0x2ea80826, facetFuncs 0x574a4cff, facetMetadata 0xf10d7a75 (no direct use on pkg surface, for context only)
- @custom:signature + @custom:selector inserted only for the 11 IDiamondFactoryPackage methods on the impl (no ad-hoc computation).
**NatSpec Added (modeled exactly on golds):**
- @title/@author/@dev on interface + contract
- @notice/@param/@return/@custom:signature/@custom:selector/@inheritdoc IDiamondFactoryPackage on all surfaces
- @dev for structs + @notice for constructor/init hooks
- Hyphen-disambiguated tags for DFPkg surfaces (following task spec + Bounty/CallTarget/Create3/ERC20 pattern): -diamondcutfacetdfpkg suffix
- No changes to Pkg* struct placement (already correct per AGENTS.md)

**Process Recap (Strict Order Followed BEFORE any edit):**
1. docs/reports/gap/contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol.md (this per-file gap)
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (only source for all @custom:* ; referenced IDiamond* + IFacet values)
3. PRD.md (LR-1 section: full rich NatSpec, AsciiDoc tags required for all public, @custom:selector/signature mandatory from verified, Pkg* on I*DFPkg)
4. AGENTS.md (full relevant: DFPkg pattern "PkgInit and PkgArgs structs MUST be defined inside the I*DFPkg interface", NatSpec+AsciiDoc // tag::Name[] / // end:: standard, hyphenated tags for overload/surface disambig e.g. packageName-diamondcutfacetdfpkg[], rich @notice/@param/@return/@dev/@custom:*, gold examples: Create3FactoryDFPkg, CallTargetRegistryDFPkg (18 tags), BountyBoardDFPkg (18 tags), no logic changes, relative paths, targeted verif only)
5. contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol (source)
- Additional reference reads (pre-edit, no edits to them): gold DFPkgs for exact tag/NatSpec patterns (CallTargetRegistryDFPkg.sol, BountyBoardDFPkg.sol, Create3FactoryDFPkg.sol, ERC20DFPkg.sol) + IDiamondFactoryPackage.sol (for @inheritdoc modeling)
- ONLY edited the 3 allowed files (relative paths): contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol + this per-file gap .md + GAP_REPORT.md
- No viaIR. No logic/comments altered. Targeted verification only after.

**Targeted Verification Performed (post-edit only):**
- `forge inspect contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol:DiamondCutFacetDFPkg (abi|methodIdentifiers)` (selectors for packageName etc matched centrals 0xabc8b346 etc.)
- `forge build contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol --skip test --quiet` (BUILD_EXIT=0)
- `forge test --list --match-path '*DiamondCut*' ` and `'*DFPkg*'` (narrow smoke)
- All matched centrals; build clean.

**Notes:**
- LR-7 gaps remain for follow-up (pre-existing coverage via DiamondPackageCallBackFactory/InitDev + Behavior paths; no test file touched per scope).
- Supports LR-1 for introspection DFPkgs + core factory bootstrap.
- See main GAP_REPORT.md for [x] entry.

**Priority:** High (core framework files) - CLOSED for LR-1
