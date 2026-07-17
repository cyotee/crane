# Gap Report for: contracts/introspection/ERC2535/DiamondCutFacet.sol

**Status: LR-1 CLOSED**

**File Type:** Facet

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; IFacet surface + diamondCut declaration; @custom from CENTRALLY only)
- LR-7: (notes only; facet decls for Behavior_IFacet/TestBase_IFacet)

**Strict Process Followed (read order 1-6, no skips, NO EDITS until complete):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/introspection/ERC2535/DiamondCutFacet.sol.md
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY: IFacet facetName 0x5b6f4d01 / facetInterfaces 0x2ea80826 / facetFuncs 0x574a4cff / facetMetadata 0xf10d7a75 ; diamondCut(IDiamondCut) 0x1f931c1c ; supportsInterface 0x01ffc9a7 noted for context; IDiamondCut prose for signature/emits)
3. Read relevant LR sections from AGENTS.md + known: full sections on NatSpec & AsciiDoc include-tags, Facet-Target-Repo, IFacet, "Custom NatSpec tags", "How to compute values (use cast)", tag format EXACT no extra spaces, hyphenated for overloads (e.g. _foo(Bar-baz)[]), layoutStruct naming ONLY for repos, param_ trailing _ convention.
4. Read gold examples (full): contracts/introspection/ERC165/ERC165Facet.sol , contracts/access/operable/OperableFacet.sol , contracts/access/reentrancy/ReentrancyLockFacet.sol , contracts/factories/diamondPkg/Behavior_IFacet.sol , contracts/factories/diamondPkg/TestBase_IFacet.sol , closed model docs/reports/gap/contracts/tokens/ERC721/ERC721Repo.sol.md + docs/reports/gap/contracts/access/AccessFacetFactoryService.sol.md
5. Read the SOURCE files: contracts/introspection/ERC2535/DiamondCutFacet.sol , contracts/introspection/ERC2535/DiamondCutTarget.sol
6. Analysis of symbols (no edits): contracts (DiamondCutFacet, diamondCut), facetName(), facetInterfaces(), facetFuncs(), facetMetadata(), IDiamondCut.diamondCut (no batch overload), event DiamondCut from IDiamond (prose), @custom ONLY centrals or prose. Then edits.

**ONLY files edited total for this closure (scoped 2 files task):** contracts/introspection/ERC2535/DiamondCutFacet.sol + contracts/introspection/ERC2535/DiamondCutTarget.sol + docs/reports/gap/contracts/introspection/ERC2535/DiamondCutFacet.sol.md + docs/reports/gap/contracts/introspection/ERC2535/DiamondCutTarget.sol.md + GAP_REPORT.md  (5 files per explicit scope note in GAP_REPORT; relative paths only; no other files touched).

**Pre-edit state (from step 5 read):** 0 tags, zero NatSpec (bare contract + 4 funcs with no docs). No // tag:: , no @title/@author/@notice/@dev/@inheritdoc/@custom , no Crane header sections. Facet impls IFacet + inherits IDiamondCut surface via Target. facetInterfaces declares IDiamondCut; facetFuncs declares diamondCut selector; delegates via Target to ERC2535Repo.

**Source Changes (additive NatSpec+tags ONLY, no logic/imports/pragma):** 
- Added /* Crane */ header + // tag::DiamondCutFacet[] ... // end::DiamondCutFacet[] 
- Full rich header NatSpec (@title/@author/@notice/@dev explaining "Extends DiamondCutTarget ... delegates to ERC2535Repo" + "Implements IFacet + IDiamondCut" ; @custom:contractlistipfs) modeled on ERC165Facet.sol + OperableFacet.sol
- Added IFacet section header.
- Wrapped + enriched all 4 IFacet methods: facetName()[] , facetInterfaces()[] , facetFuncs()[] , facetMetadata()[]  using EXACT tag form no spaces (e.g. facetName()[]), @inheritdoc IFacet, rich @notice/@return/@dev , @custom:selector/@custom:signature EXACTLY from CENTRALLY (0x5b6f4d01 etc).
- Diamond specific: facetInterfaces uses IDiamondCut; facetFuncs uses IDiamondCut.diamondCut.selector (0x1f931c1c from CENTRALLY).
- Pre: 0 tags. Post: 5 tags on this file.

**NatSpec Symbols with exact // tag:: / end:: (post-edit):**
- // tag::DiamondCutFacet[] ... // end::DiamondCutFacet[]
- // tag::facetName()[] ... // end::facetName()[]
- // tag::facetInterfaces()[] ... // end::facetInterfaces()[]
- // tag::facetFuncs()[] ... // end::facetFuncs()[]
- // tag::facetMetadata()[] ... // end::facetMetadata()[]

**Centrals used (ONLY from CENTRALLY_COMPUTED_NATSPEC_VALUES.md, no fabrication):** IFacet: facetName()=0x5b6f4d01, facetInterfaces()=0x2ea80826, facetFuncs()=0x574a4cff, facetMetadata()=0xf10d7a75 ; IDiamondCut diamondCut=0x1f931c1c (for prose/sig in Target; facet here refs selector via code).

**Targeted Verification (ONLY as specified, relative paths, narrow, after edits):**
- `forge inspect contracts/introspection/ERC2535/DiamondCutFacet.sol:DiamondCutFacet methodIdentifiers`
- `forge inspect contracts/introspection/ERC2535/DiamondCutFacet.sol:DiamondCutFacet abi`
- `forge build --skip test --quiet contracts/introspection/ERC2535/DiamondCutFacet.sol`
- `forge test --list --match-path '*DiamondCut*' --match-contract '*Diamond*'`
- `git status --porcelain` (on the edited gaps)
All executed; build exit 0; see final report for outputs.

**CLOSED:** LR-1 for DiamondCutFacet (full rich NatSpec + exact tags modeled on golds; centrals only). LR-7 notes (decl surface now documented for Behavior_IFacet use in consuming tests). Strict read order + narrow scope followed. See [x] entry in GAP_REPORT.md. ONLY assigned files edited (relative). Contributes to introspection ERC2535 LR-1.

**Priority:** High (core framework files) - CLOSED
