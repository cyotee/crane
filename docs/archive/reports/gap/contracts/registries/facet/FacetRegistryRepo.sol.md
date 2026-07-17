# Gap Report: contracts/registries/facet/FacetRegistryRepo.sol

**File Type:** Repo (Storage)  
**Primary LR Violations:** LR-1 (NatSpec - was partial: 1 tag -> full), LR-6 (slot already compliant - model file, no change)

**Status:** LR-1 CLOSED (scoped subagent)

## Strict Read Order (executed exactly before ANY edits)
1. docs/reports/gap/contracts/registries/facet/FacetRegistryRepo.sol.md (this per-file gap)
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY the listed centrals; relevant IFacet selectors referenced in context but NO @custom:selector/signature fabricated or inserted here as all Repo funcs are internal)
3. PRD.md (LR-1 section: full rich NatSpec + exact // tag:: / end:: required; also LR-6 ERC1967 form)
4. AGENTS.md (full relevant: Repo gold for ERC1967 slot + dual _layoutStruct + // tag:: / end:: + rich NatSpec, hyphenated for overloads e.g. _foo(Storage-bar)[], "The Storage struct to operate on.", no viaIR, relative paths, targeted verif only)
5. contracts/registries/facet/FacetRegistryRepo.sol (source)

## Current State (post LR-1 closure)
- Slot already correct (ERC1967 model, confirmed no change needed per task):
  `bytes32 internal constant DEFAULT_SLOT = bytes32(uint256(keccak256(abi.encode("crane.registries.facets"))) - 1);`
- Now full tags + rich NatSpec: 1 tag -> full coverage for library + all symbols.
- Logic, structure, comments, section headers, and DEFAULT_SLOT EXACTLY preserved (no code changes).
- Modeled exactly on golds: DiamondFactoryPackageRegistryRepo.sol (near-identical registry structure + DEFAULT_SLOT + hyphen tags), OperableRepo.sol (rich @title/@author/@dev + dual phrasing + "The Storage struct to operate on."), DeployedAddressesRepo.sol (DEFAULT_SLOT style + @dev notes + tag patterns).

## NatSpec Symbols Tagged (full list)
- FacetRegistryRepo (top level lib)
- DEFAULT_SLOT
- Storage
- _layoutStruct(bytes32), _layoutStruct()
- _registerFacet(Storage-IFacet-string-bytes4[]-bytes4[]), _registerFacet(IFacet-string-bytes4[]-bytes4[])
- _canonicalFacet(Storage-bytes4), _canonicalFacet(bytes4)
- _setCanonicalFacet(Storage-bytes4-IFacet), _setCanonicalFacet(bytes4-IFacet), _setCanonicalFacet(Storage-bytes4[]-IFacet), _setCanonicalFacet(bytes4[]-IFacet)
- _nameOfFacet(Storage-IFacet), _nameOfFacet(IFacet)
- _interfacesOfFacet(Storage-IFacet), _interfacesOfFacet(IFacet)
- _functionsOfFacet(Storage-IFacet), _functionsOfFacet(IFacet)
- _facetsOfName(Storage-string), _facetsOfName(string)
- _facetsOfInterface(Storage-bytes4), _facetsOfInterface(bytes4)
- _facetsOfFunction(Storage-bytes4), _facetsOfFunction(bytes4)
- _allFacets(Storage), _allFacets()

Rich NatSpec added: @title/@author/@dev (lib), @dev (argumented/default), @param (incl. "The Storage struct to operate on."), @return for all. No @custom: (none listed in CENTRALLY for these internal symbols; followed "ONLY use listed").

## Actions Completed
- Wrapped EVERY documented symbol with exact // tag::Symbol(params)[] ... // end:: (hyphenated overload disambiguation for duals).
- Enriched to full LR-1 gold NatSpec (no logic/indent/slot/comment changes).
- Updated this per-file gap report itself to CLOSED (symbols list, centrals recap, strict order, modeled golds, targeted verif).
- ONLY edited exactly these 3 files (relative): contracts/registries/facet/FacetRegistryRepo.sol , docs/reports/gap/contracts/registries/facet/FacetRegistryRepo.sol.md , GAP_REPORT.md .
- Slot confirmed already ERC1967 per pre-edit per-file + PRD; LR-6 n/a for changes.

## Targeted Verification (ONLY, per scope - no full suite)
- `forge inspect contracts/registries/facet/FacetRegistryRepo.sol:FacetRegistryRepo (abi|methodIdentifiers|storageLayout)`
- `forge build contracts/registries/facet/FacetRegistryRepo.sol --skip test --quiet`
- `forge test --list --match-path '*FacetRegistry*'`

**Priority:** High (core model Repo for slot + now full LR-1 tags)

---

**Note for all other Repo files:** This remains the model for correct ERC1967 DEFAULT_SLOT + dual layout. Most other Repos required LR-6 fixes in prior passes.

## Central NatSpec Population (coordinated pass)
See docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for the authoritative list of computed selectors, topic0, and interfaceIds.
Used ONLY listed values (no fabrication); none applied to this internal Repo (IFacet values used only for context in sibling Facet files).

(Values pre-computed centrally to ensure accuracy and avoid duplication across subagents.)
