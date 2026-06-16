# Gap Report for: contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol

**File Type:** Facet

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include tags)

**Current State Summary:**
LR-1 CLOSED (scoped subagent LR-1 on ERC4626RateProviderFacet). Full rich NatSpec + EXACT gold // tag:: / end:: for contract + all public IFacet methods (facetName, facetInterfaces, facetFuncs, facetMetadata). @custom:selector/signature used ONLY from CENTRALLY_COMPUTED_NATSPEC_VALUES (IFacet: 0x5b6f4d01 / 0x2ea80826 / 0x574a4cff / 0xf10d7a75). @inheritdoc IFacet. Rich @title/@author/@dev/@notice/@return + @custom. Modeled on ERC20Facet / ERC165Facet / FacetRegistryFacet golds + WETHAwareFacet recent closure. No storage (LR-6 n/a). No rate-provider method bodies in this file (inherited from Target; selectors declared in facetFuncs). ONLY 3 files edited (relative paths). Targeted verif executed.

**Strict Reads Recap (BEFORE ANY edit, exact order):**
1. docs/reports/gap/contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol.md (this per-file gap, stub)
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY centrals; used IFacet values 0x5b6f4d01 etc for all @custom)
3. PRD.md (LR-1 sections: full NatSpec, @custom:selector/signature, rich, tag::/end::, @inheritdoc, facets must doc the 4 IFacet methods, canonical refs)
4. AGENTS.md (facet NatSpec + tags + @custom centrals, hyphen tags, rich @inheritdoc, ONLY 3 files rule, targeted verif, no viaIR)
5. contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol (source)
6. Gold facet examples: contracts/tokens/ERC20/ERC20Facet.sol , contracts/introspection/ERC165/ERC165Facet.sol , contracts/registries/facet/FacetRegistryFacet.sol

**Centrals Used (ONLY from CENTRALLY_COMPUTED_NATSPEC_VALUES.md):**
- facetName() : 0x5b6f4d01
- facetInterfaces() : 0x2ea80826
- facetFuncs() : 0x574a4cff
- facetMetadata() : 0xf10d7a75

**Detailed Gaps:**
- LR-1: (CLOSED) incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard + facet golds).
- LR-7: (not in scope) Add test asserting facetInterfaces() and facetFuncs() match expected (use Behavior_IFacet).
- LR-1: (CLOSED) Document facetName, facetInterfaces, facetFuncs, facetMetadata.

**Specific Actions Needed to Close Gaps:**
1. (DONE) Wrap documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. (DONE) Add @notice, @param, @return, @custom:selector / signature using ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md values for IFacet.
3. N/A (no Repo in this file).

**Symbols Closed with Tags (5 total):**
- ERC4626RateProviderFacet[] (contract + rich header)
- facetName()[]
- facetInterfaces()[]
- facetFuncs()[]
- facetMetadata()[]

**Verification Summary (targeted ONLY, post-edit):**
- forge inspect contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol:ERC4626RateProviderFacet (abi|methodIdentifiers)
- forge build contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol --skip test --quiet
- narrow list '*Balancer*' or '*RateProvider*'
(Results reported in final writeup.)

**Notes:**
- Preserved ALL logic 100% (no body/signature changes).
- @custom ONLY central IFacet values.
- @inheritdoc IFacet where applicable.
- Scope: ONLY the .sol + its per-file gap.md + GAP_REPORT.md . "ONLY 3 files".
- LR-7 / other LR out of scope for this polish; no other files touched.
- Rate provider specifics (getRate, erc4626Vault) are inherited; their selectors declared in facetFuncs().

**Status:** CLOSED (LR-1 NatSpec + tags for ERC4626RateProviderFacet; 5 symbols; ONLY centrals; strict order + ONLY 3 files followed)

**Priority:** High (core framework files)
