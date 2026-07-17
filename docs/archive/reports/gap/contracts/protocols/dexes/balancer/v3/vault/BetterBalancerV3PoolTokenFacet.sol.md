# Gap Report for: contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol

**File Type:** Facet

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec Documentation Standard)

**Status: LR-1 CLOSED**

**Current State Summary:**
LR-1 CLOSED for this facet (facet, LR-6 n/a). Rich NatSpec + exact tags added modeled on golds. @custom: ONLY the listed central IFacet values for facet* methods. Other public: prose NatSpec only (no @custom per CENTRALLY rule). Strict order + 3-files-only followed. Preserved logic 100%.

**Detailed Gaps (LR-1 done here; LR-7 noted only - no test edits per scope):**
- LR-7: Add test asserting facetInterfaces() and facetFuncs() match expected (use Behavior_IFacet).
- LR-1: Document facetName, facetInterfaces, facetFuncs, facetMetadata. (COMPLETED)

**Specific Actions Completed for LR-1 (scoped):**
- Wrapped EVERY documented symbol with exact // tag::Symbol(params)[] ... // end:: (hyphenated style not needed; no overloads).
- Added rich @title/@author/@notice/@dev/@inheritdoc/@param/@return modeled on golds (WETHAwareFacet/ERC165Facet/Create3FactoryFacet).
- Added @custom:selector/@custom:signature for 4 IFacet methods using ONLY centrals: facetName 0x5b6f4d01, facetInterfaces 0x2ea80826, facetFuncs 0x574a4cff, facetMetadata 0xf10d7a75 (referenced CENTRALLY_COMPUTED_NATSPEC_VALUES.md).
- No @custom for non-IFacet public surface (per "if no entry, use only prose").
- No logic changes; tags added around existing. Note facetMetadata not overridden specially (implements like most golds). No supportsInterface method.
- Consulted balancer-v3-vault skill + AGENTS for context (no edits to skill).

**Exact Symbols Tagged (22 total):**
BalancerV3PoolTokenFacet[], facetName()[], facetInterfaces()[], facetFuncs()[], facetMetadata()[], name()[], symbol()[], decimals()[], totalSupply()[], balanceOf(address)[], transfer(address,uint256)[], allowance(address,address)[], approve(address,uint256)[], transferFrom(address,address,uint256)[], emitTransfer(address,address,uint256)[], emitApproval(address,address,uint256)[], getRate()[], permit(address,address,uint256,uint256,uint8,bytes32,bytes32)[], nonces(address)[], DOMAIN_SEPARATOR()[], eip712Domain()[]

**Central values used:** exclusively from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IFacet section).

**Notes:**
- References to IERC20*/IRateProvider/IBalancerPoolToken/ERC*Repo etc for facetInterfaces/funcs/impl noted here only. Do not edit consumers.
- LR-7 etc outside this scoped LR-1 task.
- Update GAP_REPORT.md with [x] modeled on recent facet entries (e.g. WETHAwareFacet, ERC165Facet, ERC4626RateProviderFacet).
- Use relative everywhere. Targeted verif post source: forge inspect on the Facet (abi|methodIdentifiers) to confirm selectors match central; forge build --skip test --quiet; narrow list matching facet name.
- Final tag count for file: 22.

**Priority:** High (core framework files)
