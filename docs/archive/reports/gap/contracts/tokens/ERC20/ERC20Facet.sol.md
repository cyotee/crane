# Gap Report for: contracts/tokens/ERC20/ERC20Facet.sol

**File Type:** Facet

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full NatSpec + // tag:: / // end:: + @custom:selector/signature/interfaceid for facet and all public methods)
- LR-7: Testing Standards (facet declaration tests via Behavior_IFacet / TestBase_IFacet for facetInterfaces/facetFuncs)

**Current State Summary:**
Before fix: No NatSpec at all on contract or the 4 public IFacet methods. No // tag:: / // end:: wrappers. Followed basic IFacet impl pattern but missing required documentation per ERC8023 gold standard in PRD/LR-1 and AGENTS.md. (Note: declaration test already existed in test/foundry/spec/tokens/ERC20/ERC20Facet_IFacet.sol using TestBase_IFacet + Behavior_IFacet; LR-7 test gap not in source.)

**Detailed Gaps (closed by this work):**
- LR-1: missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).
- LR-1: Document facetName, facetInterfaces, facetFuncs, facetMetadata.
- (LR-7 test declaration coverage pre-existing for this facet; source changes support by making facet fully documented.)

**Specific Actions Needed to Close Gaps:**
1. Wrapped documented symbols (contract + 4 public fns) with exact // tag::Symbol(params)[] ... // end::
2. Added @notice/@inheritdoc + @custom:selector / @custom:signature using ONLY central/verified cast-computed values (from CENTRALLY_COMPUTED_NATSPEC_VALUES.md + cast for consistency).
3. (No Repo in this file; no slot changes.)
4. Updated this gap report + main GAP_REPORT.md tracking.
5. Verified via forge build + targeted test run (ERC20Facet_IFacet).

**Central NatSpec Values Used (from docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md + cast verification; ONLY these):**

From central:
- facetName() : 0x5b6f4d01
- facetInterfaces() : 0x2ea80826
- facetFuncs() : 0x574a4cff
- facetMetadata() : 0xf10d7a75

Computed via cast sig / consistent XOR for interface refs (used in facet logic and TestBase control):
- IERC20 functions:
  - totalSupply() : 0x18160ddd
  - balanceOf(address) : 0x70a08231
  - allowance(address,address) : 0xdd62ed3e
  - approve(address,uint256) : 0x095ea7b3
  - transfer(address,uint256) : 0xa9059cbb
  - transferFrom(address,address,uint256) : 0x23b872dd
- IERC20Metadata functions:
  - name() : 0x06fdde03
  - symbol() : 0x95d89b41
  - decimals() : 0x313ce567
- IERC20.interfaceId : 0x36372b07
- IERC20Metadata.interfaceId : 0x942e8b22
- (IERC20Metadata ^ IERC20) : 0xa219a025
- IFacet.interfaceId (for ref): 0xd38073ad

**NatSpec Symbols Tagged (exact):**
- Main: ERC20Facet (full contract wrapper)
- facetName()
- facetInterfaces()
- facetFuncs()
- facetMetadata()

(No events/errors declared on this facet contract itself; they are in inherited Targets + IERC20* interfaces. IFacet customs live in contracts/factories/diamondPkg/IFacet.sol per pattern.)

**Testing Gaps (LR-7 specific if applicable):**
- Declaration tests already present (ERC20Facet_IFacet_Test inherits TestBase_IFacet and provides controlFacet* matching the exact lists in source; uses Behavior_IFacet internally).
- Source now has full NatSpec+tags to match LR-1 for documented surface (tests themselves have partial but out of scope per edit rules).
- (Other LR-7 like full pkg init, preview parity, etc. not applicable to this pure facet file.)

**Documentation/Skills Gaps (if applicable):**
- Surface documented via source tags for extraction (LR-2/LR-3 notes remain general).

**Notes for Subagents (post-fix):**
- Implemented only fixes for this file's gaps per rules (only edited: contracts/tokens/ERC20/ERC20Facet.sol + this gap report + GAP_REPORT.md).
- Used ONLY central values + cast-verified (never ad-hoc in source).
- Updated main GAP_REPORT.md checkbox.
- Ran `forge build` + targeted `forge test --match-path test/foundry/spec/tokens/ERC20/ERC20Facet_IFacet.sol -vvv`
- Do not edit other files (followed strictly).

**Priority:** High (core framework files)

**Status:** CLOSED (LR-1 source gaps for facet)
