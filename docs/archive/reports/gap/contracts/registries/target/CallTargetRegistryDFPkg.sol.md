# Gap Report for: contracts/registries/target/CallTargetRegistryDFPkg.sol

**File Type:** DFPkg

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full @custom + // tag:: include-tags on public symbols)
- LR-7: Testing Standards (package declaration tests for packageName, facet*, diamondConfig, calcSalt, initAccount, postDeploy etc.)

**Current State Summary:**
Gaps closed for NatSpec on this DFPkg file. (No Repo/storage in this file, so no LR-6 slot changes required. PkgInit/PkgArgs correctly placed on the I* interface per AGENTS rule, verified before and after.)

**Detailed Gaps Closed:**
- LR-1: Added rich NatSpec (@notice, @param, @return) + @custom:signature / @custom:selector (sourced ONLY from CENTRALLY_COMPUTED_NATSPEC_VALUES.md for IDiamondFactoryPackage surfaces; local deploy from inspect) to all IDiamondFactoryPackage methods, the local deployCallTargetRegistry, interface, Pkg* structs, and constructor.
- Exact // tag::...[] / // end::...[] (gold style matching Create3FactoryDFPkg and ERC20DFPkg, no spaces inside []) around interface ICallTargetRegistryDFPkg, contract CallTargetRegistryDFPkg, PkgInit[], PkgArgs[], constructor, deployCallTargetRegistry (and -impl), packageName-calltarget, packageMetadata-calltarget, facet*-calltarget, diamondConfig-calltarget, calcSalt-calltarget, processArgs-calltarget, updatePkg-calltarget, initAccount-calltarget, postDeploy-calltarget.
- LR-7 coverage note: declaration surface (packageName, facetAddresses, facetCuts, diamondConfig, calcSalt, initAccount, postDeploy + deploy helper) now fully documented with central values; this supports declaration test coverage (tests themselves not modified per scope).

**Actions Performed (scoped strictly to this report's gaps):**
1. Strict read order executed: 1. docs/reports/gap/contracts/registries/target/CallTargetRegistryDFPkg.sol.md , 2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md , 3. PRD.md (LR-1, LR-7), 4. AGENTS.md (DFPkg critical: Pkg* on interface, NatSpec+tags gold, hyphen for overloads, model on closed ERC20DFPkg/Create3FactoryDFPkg), 5. source contracts/registries/target/CallTargetRegistryDFPkg.sol .
2. Preserved / added exact `// tag::Name[] ... // end::Name[]` (no extra spaces) for all symbols, using hyphenated suffixes for DFPkg-specific disambiguation (modeled on Create3FactoryDFPkg).
3. Added rich @notice/@param/@return + @custom:signature + @custom:selector to the DFPkg functions and deploy helper. Used ONLY values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md for IDiamondFactoryPackage: packageName 0xabc8b346, facetInterfaces 0x2ea80826, facetAddresses 0x52ef6b2c, packageMetadata 0xf45469e7, facetCuts 0xa4b3ad35, diamondConfig 0x65d375b3, calcSalt(bytes) 0xd82be56e, processArgs(bytes) 0x87c3adb3, updatePkg(address,bytes) 0xa9089235, initAccount(bytes) 0x870d4838, postDeploy(address) 0x70068fcf . Local deployCallTargetRegistry(address) selector 0x26d10134 obtained via pre-edit forge inspect for accuracy.
4. No Repo/slot work applicable. Pkg structs placement verified on interface (already correct; confirmed in reads + no change needed).
5. Added @inheritdoc and adapted rich descriptions modeled on closed Create3FactoryDFPkg.sol + ERC20DFPkg.sol .
6. Updated this per-file gap + GAP_REPORT.md only (3 files total). No other files touched.

**NatSpec Symbols Tagged (exact list):**
- Interface: ICallTargetRegistryDFPkg
- Structs (on interface per AGENTS): PkgInit[] , PkgArgs[]
- Deploy helper iface: deployCallTargetRegistry[]
- Contract: CallTargetRegistryDFPkg
- Constructor: constructor-calltargetdfpkg[]
- Deploy impl: deployCallTargetRegistry-impl[]
- packageName-calltarget (0xabc8b346)
- packageMetadata-calltarget (0xf45469e7)
- facetAddresses-calltarget (0x52ef6b2c)
- facetInterfaces-calltarget (0x2ea80826)
- facetCuts-calltarget (0xa4b3ad35)
- diamondConfig-calltarget (0x65d375b3)
- calcSalt-calltarget (0xd82be56e)
- processArgs-calltarget (0x87c3adb3)
- updatePkg-calltarget (0xa9089235)
- initAccount-calltarget (0x870d4838)
- postDeploy-calltarget (0x70068fcf)
- (No events or errors in this DFPkg)

**Testing Gaps (LR-7 specific if applicable - scoped):**
- Per instructions: only the source DFPkg + its gap report + GAP_REPORT.md were edited.
- LR-7 items (e.g. full init of packages with non-zero facets in tests, Behavior_IDiamondFactoryPackage usage, exact declaration assertions) remain for separate work.
- The NatSpec now documents the required declaration surface fully with centrals, closing the 0-tag core DFPkg for registries and supporting LR-7 declaration test coverage.

**Documentation/Skills Gaps (if applicable):**
- (Out of scope for this specific scoped subagent task; see root GAP_REPORT for LR-2/LR-3 tracking. This DFPkg enables CallTarget registry usage in deployment flows.)

**Notes for Subagents:**
- Work ONLY on the 3 allowed files for this report's gaps.
- Used only central NatSpec values (for shared IDiamond surfaces).
- Exact tag style from gold DFPkgs followed; overloads hyphenated where applicable.
- PkgInit/PkgArgs confirmed on ICallTargetRegistryDFPkg interface.
- After edits: verified ONLY with the mandated targeted commands (see Verification).
- This closes LR-1 for the CallTargetRegistryDFPkg (0-tag core registry DFPkg).

**Verification Performed:**
- Pre-edit (info gather, before any source change): `forge inspect contracts/registries/target/CallTargetRegistryDFPkg.sol:CallTargetRegistryDFPkg methodIdentifiers --json` → confirmed IDiamond selectors exactly match CENTRALLY (packageName:0xabc8b346, facetInterfaces:0x2ea80826, facetAddresses:0x52ef6b2c, packageMetadata:0xf45469e7, facetCuts:0xa4b3ad35, diamondConfig:0x65d375b3, calcSalt:0xd82be56e, processArgs:0x87c3adb3, updatePkg:0xa9089235, initAccount:0x870d4838, postDeploy:0x70068fcf) + local "deployCallTargetRegistry(address)": "0x26d10134".
- Post-edit targeted verif ONLY (as specified):
  - `forge inspect contracts/registries/target/CallTargetRegistryDFPkg.sol:CallTargetRegistryDFPkg (abi|methodIdentifiers)`
  - `forge build --skip test --quiet`
  - `forge test --list --match-path '*CallTarget*DFPkg*'`
- (See post-task run output in agent trace for exact summaries; all clean, selectors match centrals + local.)
- `forge fmt` not needed as no logic; build confirms.

**Status:** LR-1 CLOSED (scoped); supports LR-7 declaration notes closure for this DFPkg.

**Priority:** High (core framework factories/registries DFPkg)
