# Gap Report for: contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryFacet.sol

**File Type:** Facet

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + include-tags + @custom using ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md)

**Status: LR-1 CLOSED**

**Current State Summary:**
LR-1 gaps closed for this Facet per strict scoped process. (LR-7 declaration testing gaps noted in this report only; no test files edited per scope limit.)

**Detailed Gaps Closed (LR-1 only):**
- Added rich NatSpec modeled on golds (WETHAwareFacet.sol, ERC165Facet.sol, Create3FactoryFacet.sol, OperableFacet.sol): @title, @author, @notice, @dev, @inheritdoc IFacet, @param/@return, Crane section header.
- Wrapped EVERY documented symbol with EXACT // tag::Symbol(params)[] ... // end:: (no extra spaces; () for no-param IFacet methods; contract-level too).
- For the 4 IFacet methods: added @custom:selector and @custom:signature using EXCLUSIVELY values from docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (facetName 0x5b6f4d01, facetInterfaces 0x2ea80826, facetFuncs 0x574a4cff, facetMetadata 0xf10d7a75). Also added supportsInterface ref note (0x01ffc9a7 from central) but not present in this file.
- Added missing facetMetadata() (modeled exactly on golds; thin delegation to the 3 others; no alteration to existing 3 function bodies/logic/structure).
- Existing partial/incomplete tags upgraded to full gold format (facetName[] -> facetName()[] etc).
- Preserved 100% existing logic/structure/bodies/return values (hardcoded name kept).
- Note on references (in gap only, per instructions): this file references IApprovedMessageSenderRegistry for .interfaceId and 3 selectors in facet*() bodies; consumers of facetInterfaces etc not edited.

**Strict Read Order Followed (BEFORE ANY EDIT):**
1. docs/reports/gap/contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryFacet.sol.md
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used EXCLUSIVELY for the 4 IFacet customs listed above; no other entries relevant, no fabrication)
3. PRD.md (LR-1 sections on NatSpec + include-tags + @custom requirements, canonical ERC8023, rich elements, accuracy rule)
4. AGENTS.md (full relevant: NatSpec standard with exact // tag::Name(params)[] / end:: incl. hyphenated overloads if any, IFacet gold examples, Facet patterns, "ONLY edit source + its per-file gap + GAP_REPORT.md", relative paths ONLY, no viaIR, targeted verification only with forge inspect abi|storageLayout|methodIdentifiers on the specific contract, forge build --skip test --quiet, narrow forge test --list --match-path)
5. Gold examples (2-3+ recent closed facets): contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol , contracts/introspection/ERC165/ERC165Facet.sol , contracts/factories/create3/Create3FactoryFacet.sol , contracts/access/operable/OperableFacet.sol
6. Then the source: contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryFacet.sol

**NatSpec Symbols Exactly Tagged (5 total tags; params as used):**
- ApprovedMessageSenderRegistryFacet[]
- facetName()[]
- facetInterfaces()[]
- facetFuncs()[]
- facetMetadata()[]

**Central Values Used (EXCLUSIVELY from CENTRALLY_COMPUTED_NATSPEC_VALUES.md):**
- IFacet facetName(): 0x5b6f4d01 , "facetName()"
- IFacet facetInterfaces(): 0x2ea80826 , "facetInterfaces()"
- IFacet facetFuncs(): 0x574a4cff , "facetFuncs()"
- IFacet facetMetadata(): 0xf10d7a75 , "facetMetadata()"
- (ERC165 supportsInterface(bytes4) 0x01ffc9a7 referenced in notes only; no @custom inserted where absent in file)

**ONLY 3 files edited (relative paths everywhere):** 
- contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryFacet.sol
- docs/reports/gap/contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryFacet.sol.md
- GAP_REPORT.md

**Verification (targeted only, after source edits):**
- `forge inspect contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryFacet.sol:ApprovedMessageSenderRegistryFacet (abi|methodIdentifiers)` (confirmed IFacet selectors match central exactly)
- `forge build --skip test --quiet`
- `forge test --list --match-path '*ApprovedMessageSenderRegistryFacet*'`

**Notes:**
- No storage changes (facet; LR-6 n/a).
- No interfaces/tests/other sources edited.
- facetInterfaces declares support for IApprovedMessageSenderRegistry (details in that interface's own docs/gap).
- Final tag count for file: 5

**Priority:** High (core framework files) - CLOSED for LR-1
