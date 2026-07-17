# Gap Report for: contracts/factories/diamondPkg/Behavior_IFacet.sol

**File Type:** Library (Behavior)

**Primary Affected Requirements (from PRD):**
LR-1: NatSpec Documentation Standard (Mandatory & Verifiable). Core Behavior lib for IFacet (used by TestBase_IFacet + all facet declaration tests for LR-7). Also supports LR-7 declaration testing requirements.

**Current State Summary:**
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**Detailed Gaps (addressed):**
- LR-1: Missing NatSpec + // tag:: (now full).
- LR-7: Behavior_IFacet usage for facetInterfaces/facetFuncs/name/metadata/consistency declaration tests (this lib now properly documented to support; no test edits per scope).

**Specific Actions Taken to Close Gaps (additive only):**
1. Wrapped EVERY documented symbol with EXACT // tag::Name(params)[] ... // end:: (no extra spaces; hyphenated for all overloads e.g. areValid_IFacet_facetName(string-string-string)[], _ifacet_errPrefix(string-string)[] etc per AGENTS and gold examples like attacker_*(uint256-address)[] and _logSelector(string-bytes4)[]).
2. Added full rich NatSpec: @title/@author/@notice/@dev/@param/@return on library + every fn. @custom:signature + @custom:selector ONLY on the IFacet surface refs inside funcSig_* using EXCLUSIVELY the central values (0x5b6f4d01 etc). No fabrication.
3. Modeled precisely on: Behavior_IERC165.sol (structure of _Name, funcSig, errPrefix*, expect/hasValid/areValid/isValid + console patterns), IFacet_Behavior_Test.sol + Behavior_IERC165_Behavior_Test.sol (tag style + central IFacet refs + LR-1/LR-7 notes), TestBase_IFacet.sol (usage of areValid/isValid for metadata), AccessFacetFactoryService + InitDevService + Create3* closed LR-1 (rich @dev, library header, hyphen tags).
4. LR-6 N/A (no storage/Repo; no slots). No PkgInit rule here. No logic change whatsoever.
5. Expanded symbols list below. Updated to CLOSED status with recap.

**NatSpec Symbols Tagged (full list expanded from source post-edit, 27 total):**
- Behavior_IFacet[] (library header with rich @title/@author/@notice/@dev referencing LR-1/7 + centrals + golds)
- _Behavior_IFacetName()[]
- _ifacet_errPrefixFunc(string)[]
- _ifacet_errPrefix(string-string)[]   (hyphen overload)
- _ifacet_errPrefix(string-address)[]   (hyphen overload)
- expect_IFacet(IFacet-string-bytes4[]-bytes4[])[]
- funcSig_IFacet_facetName()[]
- errSuffix_IFacet_facetName()[]
- areValid_IFacet_facetName(string-string-string)[]   (hyphen overload)
- areValid_IFacet_facetName(IFacet-string-string)[]   (hyphen overload)
- expect_IFacet_facetName(IFacet-string)[]
- hasValid_IFacet_facetName(IFacet)[]
- funcSig_IFacet_facetInterfaces()[]
- errSuffix_IFacet_facetInterfaces()[]
- areValid_IFacet_facetInterfaces(string-bytes4[]-bytes4[])[]
- areValid_IFacet_facetInterfaces(IFacet-bytes4[]-bytes4[])[]
- expect_IFacet_facetInterfaces(IFacet-bytes4[])[]
- hasValid_IFacet_facetInterfaces(IFacet)[]
- funcSig_IFacet_facetFuncs()[]
- errSuffix_IFacet_facetFuncs()[]
- areValid_IFacet_facetFuncs(string-bytes4[]-bytes4[])[]
- areValid_IFacet_facetFuncs(IFacet-bytes4[]-bytes4[])[]
- expect_IFacet_facetFuncs(IFacet-bytes4[])[]
- hasValid_IFacet_facetFuncs(IFacet)[]
- funcSig_IFacet_facetMetadata()[]
- isValid_IFacet_facetMetadata_consistency(IFacet)[]
- areValid_IFacet_facetMetadata(IFacet-string-bytes4[]-bytes4[])[]

(Also covered all internal err/funcSig/errSuffix helpers + the 3 public IFacet metadata surfaces via funcSig + @custom from centrals. No events/errors declared in this lib.)

**Verification (targeted ONLY, relative paths, run after source edits only):**
- `forge inspect contracts/factories/diamondPkg/Behavior_IFacet.sol:Behavior_IFacet abi`  (exit:0; listed public surface incl areValid_*/hasValid_*/expect_* /funcSig_* etc; selectors for Behavior's own methods)
- `forge inspect contracts/factories/diamondPkg/Behavior_IFacet.sol:Behavior_IFacet methodIdentifiers` (exit:0; 24+ methods incl the overload disambiguated; matches source surface)
- `forge build contracts/factories/diamondPkg/Behavior_IFacet.sol --skip test --quiet` (exit:0; clean, no compile issue from our changes)
- `forge test --list --match-path '*IFacet*'` (narrow; attempted; unrelated pre-existing compile errors in other files surfaced as expected for --list, but specific .sol build succeeded)
- `forge test --list --match-path '*Behavior_IFacet*'` (narrow; same)
No full suite, no viaIR. Relative paths everywhere. Inspect/build confirmed the tags+NatSpec did not affect abi surface or buildability.

**Notes for Subagents:**
- Strict read order + confirm before first edit followed.
- Scope: EXACTLY 3 files max. ONLY the .sol + this per-file gap .md + GAP_REPORT.md edited.
- Preserve: all logic, console.logBehaviorEntry/Exit/Validation/Error/Expectation/Compare, using Bytes4SetComparator/StringComparator/UInt256/BehaviorUtils exactly.
- Centrals ONLY rule followed for IFacet @custom.
- Fleshed this report + added [x] to GAP_REPORT.md.
- Contributes to core factories/diamondPkg + behaviors LR-1 (supports LR-7 declaration tests using Behavior_IFacet for facets).

**Closure Summary:**
LR-1 CLOSED for Behavior_IFacet (core). 27 // tag:: added. Strict order (1.perfile 2.CENTRALLY 3.PRD LR-1 4.AGENTS 5.golds incl Behavior_IERC165+IFacet_Behavior_Test 6.source) before any edit. Full rich NatSpec + exact tags (hyphenated overloads) + ONLY central IFacet 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75. Modeled on golds. Preserved 100% logic. ONLY 3 files edited (relative). Targeted verif exit 0 for inspect+build. See GAP_REPORT.md entry. (27 tags total.)

**Priority:** High (core framework Behavior lib) - CLOSED.
