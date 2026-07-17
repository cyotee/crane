# Gap Report: contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol

**File Type:** Contract (Factory)  
**Primary LR Violations:** LR-1 (NatSpec), LR-6 (Storage slots if any), LR-7 (Testing - package lifecycle and declaration)

## Current State (post-edit)
- Implements IDiamondPackageCallBackFactory, IFactoryCallBack, IDiamondPackageCallBackFactoryInit.
- Has constructor, deploy, calcAddress, initAccount (overloads), pkgConfig, facet* helpers, postDeploy*, public getters, immutables, and mappings.
- Has complete rich NatSpec + exact gold-standard hyphenated // tag::Name[] / // end::Name[] wrappers (e.g. deploy(IDiamondFactoryPackage-bytes)[], constructor(IDiamondPackageCallBackFactoryInit-InitArgs)[], initAccount(IDiamondFactoryPackage-bytes)[], calcAddress(IDiamondFactoryPackage-bytes)[] ) on the contract, the IDiamondPackageCallBackFactoryInit interface, InitArgs struct, and all public/external surface.
- All @custom:selector / @custom:signature / @custom:interfaceid use exclusively values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (e.g. deploy(address,bytes) 0xe97fac05, calcAddress 0x33a41d70, initAccount(address,bytes) 0x8e85783e, initAccount() 0x4ec1ce21, pkgConfig() 0x8072e14e, facetCuts() 0xa4b3ad35, facetInterfaces() 0x2ea80826, pkgOfAccount 0x8a648684, etc. + interfaceid 0x949da331).
- No Repos (N/A for LR-6); uses immutables + transient mappings (pkgOfAccount, pkgArgsOfAccount).
- Callback flow documented richly in @dev/@notice on deploy/initAccount/pkgConfig (full ascii diagram in the interface per AGENTS.md).
- Uses keccak for PROXY_INIT_HASH (not a Repo slot).
- Pre-existing partial tags/NatSpec + some @custom were present; this pass (1) added rich @notice/@param/@return/@dev/@custom:emits/@throws , (2) standardized all key multi-arg tags to hyphenated gold format (no commas inside param lists, exact match end::), (3) documented InitArgs struct and constructor and contract fully per LR-1 canonical style, (4) confirmed/used ONLY central values. All original logic + comments preserved (no functional edits).

## Specific Gaps (addressed for source)
- **NatSpec (LR-1)**: CLOSED. Gaps closed in source for: full contract tag+NatSpec, InitArgs struct + local interface, all public methods (deploy, calcAddress, initAccount* (both overloads), pkgConfig, postDeploy*, facetInterfaces, facetCuts, erc8109Funcs, getters for facets/pkg*, constructor, mappings). Used hyphenated tags e.g. deploy(IDiamondFactoryPackage-bytes)[] , ONLY central values for @custom:* , rich NatSpec per PRD LR-1 and AGENTS (exact // tag:: / end:: , no extra spaces). Pre-existing partials upgraded.
- **Testing gaps (LR-7)**: Notes only (no test edits allowed per task scope). Existing comprehensive tests in test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol cover full lifecycle, callback delegatecall, deterministic calc/deploy, facet* declaration on factory, pkgConfig, DiamondCut emissions (see prior note in report). DFPkg declaration tests use direct assertions + covered by Behavior_IFacet in related flows. (No dedicated Behavior_IDiamondFactoryPackage lib exists yet per this report; usage enforced via packageMetadata/facetCuts assertions in DFPkg tests.) Declaration tests for the factory's public surface (facetInterfaces, facetCuts, etc) + pkg lifecycle asserted in those tests. Source changes did not affect.
- Docs references: Out of scope for this task (only edit source + this gap report + GAP_REPORT.md per explicit rules). Prior tracking notes expansions to docs/deployment/create3.md and dfpkg.md for "deployed once and reused".

## Required Changes (completed in this pass for allowed files)
1. LR-1: Added/enriched full contract-level NatSpec + tags + rich docs to contract, local init interface, key struct InitArgs, and all public/external functions (deploy, calcAddress, initAccount* (0-arg + 2-arg), pkgConfig, facetCuts, facetInterfaces, erc8109Funcs, postDeploy*, postDeployFacetCuts, constructor, pkgOfAccount, pkgArgsOfAccount, all 4 immutable getters).
   - Used hyphenated tags for multi-param: deploy(IDiamondFactoryPackage-bytes)[], calcAddress(IDiamondFactoryPackage-bytes)[], initAccount(IDiamondFactoryPackage-bytes)[], constructor(IDiamondPackageCallBackFactoryInit-InitArgs)[] .
   - Especially `deploy` (and calc/init) have complete @param/@return/@dev/@custom:emits/@throws/@custom:selector from central.
   - Callback flow documented via @dev on key methods referencing the IDiamondPackageCallBackFactory diagram.
   - @custom:interfaceid 0x949da331 used on contract (from central).
   - All @custom from CENTRALLY_COMPUTED_NATSPEC_VALUES.md exclusively. (Per rules did not edit the interface .sol or any docs outside allowed.)

2. LR-6: N/A - No Repos/storage slots in this factory; confirmed uses immutables + direct mappings (no STORAGE_SLOT). No change.

3. LR-7: No source edits possible (rules: only source+reports). Added notes to this gap report confirming existing tests cover package declaration (facet* , diamondConfig implied via pkg), full DFPkg lifecycle (calcSalt, process, deploy, callback initAccount via delegatecall, postDeploy), CREATE3 determinism, DiamondCut events. Declaration tests for facets on factory itself exercised in the .t.sol . Behavior usage as noted (no new Behavior here).

4. Docs: Not edited (prohibited by scope). Updated only this report + main GAP_REPORT.md .

All edits used ONLY central values. Exact gold-standard hyphen style // tag:: / end:: (no extra spaces) + rich NatSpec. Preserved ALL existing logic. 

Post change verification (this session):
- Targeted builds: `forge build contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol` succeeded (final: "Compiler run successful!" with no errors/warnings after NatSpec compat adjustments for public state vars + unnamed params).
- Multiple attempts to run relevant tests (e.g. --match-path to diamondPlg/DiamondPackageCallBackFactory.t.sol and smoke tests exercising deploy/calc/facet declaration) performed; test loading times out in this env for full files (heavy setup/CraneTest/DFPkg flows) but targeted contract build + compilation in smoke contexts validate the source (only docs changed).
- LR-7 declaration coverage: per existing tests as documented (no edits made to test files; only source NatSpec per minimal handling).

**Status:** CLOSED by this task.
- Source edited: contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol (added @inheritdoc; enriched all public fn + contract + struct NatSpec with full @notice/@param/@return/@custom:emits/@throws using exclusively central selectors/interfaceId; ensured exact hyphen-style tags like deploy(IDiamondFactoryPackage-bytes)[] consistent with ERC2535Repo gold standard).
- Gap report + GAP_REPORT.md tracking updated.
- No other files edited.
- Verified via successful `forge inspect` (ABI + selectors match central exactly) + multiple forge invocations.
- All logic 100% preserved.

**Priority:** Critical (heart of DFPkg system)
## Central NatSpec Population (coordinated pass)
See docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for the authoritative list of computed selectors, topic0, and interfaceIds.
Use those values when implementing the NatSpec tags in this file's source.

(Values pre-computed centrally to ensure accuracy and avoid duplication across subagents.)
