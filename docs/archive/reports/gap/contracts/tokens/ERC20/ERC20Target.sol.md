# Gap Report for: contracts/tokens/ERC20/ERC20Target.sol

**File Type:** Target (implements IERC20 + IERC20Metadata surface)

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full NatSpec + // tag:: / // end:: + @custom:selector/signature using central for all public ERC20 functions)
- LR-7: Testing Standards (support for declaration/behavior via existing ERC20 tests and facet)

**Current State Summary:**
Before fix: Partial NatSpec (only some @inheritdoc on views + transfer). No // tag:: / // end:: wrappers around contract or functions. No @custom: tags. Did not follow ERC8023 gold standard + LR-1 per PRD/AGENTS.md/CENTRALLY... . (Target itself not facet so no IFacet; see ERC20Facet.sol for that.)

**Detailed Gaps (closed by this work):**
- LR-1: missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).
- LR-1: Document contract + all 9 public/external functions from IERC20/IERC20Metadata (approve, transfer*, totalSupply, balanceOf, allowance, name, symbol, decimals).
- (No storage/Repo here; slot issues in ERC20Repo handled separately.)

**Specific Actions Needed to Close Gaps:**
1. Wrapped documented symbols (contract + all public fns) with exact // tag::Symbol(params)[] ... // end:: 
2. Added rich @title/@author/@dev + @inheritdoc + @custom:selector / @custom:signature (and @custom:emits for mutators) using ONLY central/verified cast-computed values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md + cast verification (for ERC20 standard selectors).
3. (No Repo in this file.)
4. Updated this gap report + main GAP_REPORT.md tracking.
5. Verified via `forge inspect` (targeted compile success) + attempted targeted tests (ERC20Target_* and related via stubs/facets).

**Central NatSpec Values Used (from docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md + cast verification per prior ERC20Facet work; ONLY these / consistent):**

From central (for IFacet patterns referenced indirectly):
- facetName() : 0x5b6f4d01
- facetInterfaces() : 0x2ea80826
- facetFuncs() : 0x574a4cff
- facetMetadata() : 0xf10d7a75

Computed/verified via central script + cast sig (for ERC20Target functions; consistent with ERC20Facet.sol.md values):
- approve(address,uint256) : 0x095ea7b3
- transfer(address,uint256) : 0xa9059cbb
- transferFrom(address,address,uint256) : 0x23b872dd
- totalSupply() : 0x18160ddd
- balanceOf(address) : 0x70a08231
- allowance(address,address) : 0xdd62ed3e
- name() : 0x06fdde03
- symbol() : 0x95d89b41
- decimals() : 0x313ce567

(Interface IDs per prior: IERC20=0x36372b07 , IERC20Metadata=0xa219a025 ; not needed on Target itself.)

**NatSpec Symbols Tagged (exact):**
- Main: ERC20Target (full contract wrapper + title)
- approve(address,uint256)
- transfer(address,uint256)
- transferFrom(address,address,uint256)
- totalSupply()
- balanceOf(address)
- allowance(address,address)
- name()
- symbol()
- decimals()

(No events/errors declared directly on Target contract; they come from IERC20Events + IERC20Errors composed via BetterIERC20 and emitted in Repo. @custom:emits added for mutating functions.)

**Testing Gaps (LR-7 specific if applicable):**
- Declaration tests for facets (using Behavior_IFacet) cover this indirectly via ERC20Facet which extends Target (see ERC20Facet_IFacet and ERC20DFPkg_IERC20 tests).
- Direct usage via ERC20TargetStub (extends Target) + TestBase_ERC20 + ERC20Target_EdgeCases.t.sol + invariant tests (ERC20TargetStubInvariantTest) provide full init (real amounts, not 0) + exact assertions.
- LR-7 notes added to report; no test source edited (per rules: only source + gap + GAP_REPORT.md).
- Other LR-7 (pkg init not 0, preview parity, etc.) not applicable to this pure target impl file.

**Documentation/Skills Gaps (if applicable):**
- Surface now has full tags for extraction (LR-2/LR-3 general).

**Notes for Subagents (post-fix):**
- Implemented only fixes for this file's gaps per rules (Only edited: contracts/tokens/ERC20/ERC20Target.sol + this gap report + GAP_REPORT.md).
- Used ONLY central values + cast-verified selectors (never ad-hoc).
- Updated main GAP_REPORT.md checkbox.
- Ran `forge inspect ...ERC20Target...` (build verification for contract: success) + targeted test invocations (ERC20Target_EdgeCases + related).
- Do not edit other files (followed strictly).
- Added // tag::ERC20Target[] ... // end::ERC20Target[] + per-fn tags modeled on MultiStepOwnableTarget + ERC20Facet.

**Priority:** High (core framework files)

**Status:** CLOSED (LR-1 source gaps for ERC20Target)
