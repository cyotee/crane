# Gap Report for: contracts/utils/math/ConstProdUtils.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + exact // tag::Name(params)[] / end:: + rich @title/@author/@notice/@dev/@param/@return/@custom:throws for documented surface; pure util, no LR-6)

**Current State Summary:**
Pre-work: only 1 partial tag (_equivLiquidity[] with minimal @dev). Library had bare functions with sparse @dev only (no library wrapper, no overload disambiguation tags, incomplete rich NatSpec). Matches uneven coverage noted in GAP_REPORT for utils/math.

**Strict Read Order (followed 100% before ANY edit/search_replace):**
1. read_file docs/reports/gap/contracts/utils/math/ConstProdUtils.sol.md (per-file stub)
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY for customs; confirmed prose/none for this pure math util - no @custom:selector/signature/interfaceid/topiczero needed or fabricated)
3. read_file PRD.md (LR-1: exact // tag::Name(params)[]/end, rich NatSpec for all documented, scope all .sol; hyphenated overloads)
4. read_file AGENTS.md (full relevant: utility libs like ConstProdUtils as gold example in CODEBASE/AGENTS/Key Files, NatSpec+tags on utils, *Service patterns for complex but here math, hyphen overload tags, rich @dev/@param/@return, ONLY 3 files, targeted verif)
5. Golds: read contracts/utils/math/ConstProdUtils.sol (context) + closed examples contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol , contracts/protocols/dexes/aerodrome/v1/services/AerodromeService.sol , contracts/InitDevService.sol , contracts/access/AccessFacetFactoryService.sol (and lists/greps for other *Utils, sets Repos for util NatSpec style, library patterns); confirmed @title/@author/@notice/@dev, struct tags, hyphen sigs e.g. _swap(....-...)[], library end tags, no customs on helpers.
6. read_file contracts/utils/math/ConstProdUtils.sol (full to list all _* fns for tagging: _sortReserves*2, _depositQuote, _saleQuote*2, _purchaseQuote*2, _quoteSwapDepositWithFee*3, _swapDepositSaleAmt*2, _quoteWithdrawWithFee, _withdrawQuote, _quoteZapIn..., _quoteZapOut*2, _computeZapOut, _calculateFee..., _calculateProtocolFee*, _equivLiquidity, _quoteDeposit..., _quoteWithdrawSwapWithFee etc.)

After reads: enriched LR-1 to gold (no logic change, preserved using/consts/imports/sections/FEE_DENOMINATOR/GeneralErrors refs).

**LR-1 CLOSED**

- Library level // tag::ConstProdUtils[] ... // end:: + rich @title/@author/@dev/@notice (modeled CamelotV2Service/AerodromeService/InitDevService/AccessFacetFactoryService)
- EXACT hyphenated tags for overloads e.g. // tag::_sortReserves(address-address-uint256-uint256)[] and the 6-param one; _saleQuote(4-5), _purchaseQuote(4-5), _quoteSwap* (3), _swapDeposit* (2), _quoteZapOut* (2) etc.
- All key internals tagged: _getReserves equivalent (_sort*), purchase/sell/buy quotes (_purchase/_sale*), add/remove liq calcs (_depositQuote/_withdrawQuote/_quote*WithFee/_equiv), zap, fee/ protocol yield etc. Tag every documented surface + structs (SwapDepositArgs[], ZapOutToTargetWithFeeArgs[]).
- Rich @param/@return/@dev/@notice + @custom:throws (GeneralErrors refs only, no fabricated @custom:selector) where errors present (e.g. _purchaseQuote).
- Short Crane header style fits in @dev (no extra SPDX block needed; preserved existing).
- Pre tags: 1 ; Post tags/symbols: 25+ (library + 2 structs + 22+ function surfaces incl. overloads; high surface coverage).
- Modeled golds exactly for pure util (no storage); centrals none.
- ONLY edited exactly the 3 relative files.

**NatSpec Symbols Tagged (25+):**
- ConstProdUtils[]
- SwapDepositArgs[]
- ZapOutToTargetWithFeeArgs[]
- _sortReserves(address-address-uint256-uint256)[]
- _sortReserves(address-address-uint256-uint256-uint256-uint256)[]
- _depositQuote(uint256-uint256-uint256-uint256-uint256)[]
- _saleQuote(uint256-uint256-uint256-uint256)[]
- _saleQuote(uint256-uint256-uint256-uint256-uint256)[]
- _purchaseQuote(uint256-uint256-uint256-uint256)[]
- _purchaseQuote(uint256-uint256-uint256-uint256-uint256)[]
- _quoteSwapDepositWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
- _quoteSwapDepositWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
- _quoteSwapDepositWithFee(SwapDepositArgs)[]
- _swapDepositSaleAmt(uint256-uint256-uint256)[]
- _swapDepositSaleAmt(uint256-uint256-uint256-uint256)[]
- _quoteWithdrawWithFee(uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
- _withdrawQuote(uint256-uint256-uint256-uint256)[]
- _quoteZapInToTargetLPWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
- _quoteZapOutToTargetWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
- _quoteZapOutToTargetWithFee(ZapOutToTargetWithFeeArgs)[]
- _computeZapOut(uint256-uint256-ZapOutToTargetWithFeeArgs)[]
- _calculateFeePortionForPosition(uint256-uint256-uint256-uint256-uint256-uint256)[]
- _calculateProtocolFee(uint256-uint256-uint256-uint256)[]
- _calculateProtocolFeeMint(uint256-uint256-uint256-uint256)[]
- _equivLiquidity(uint256-uint256-uint256)[] (enhanced)
- _quoteDepositWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
- _quoteWithdrawSwapWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]

**Detailed Gaps (pre-closure):**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).

**Specific Actions Needed to Close Gaps (pre):**
1. Wrap documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Add @notice, @param, @return, @custom:selector / signature / topiczero / interfaceid with accurate values (to be centrally computed).
3. For Repos: ensure DEFAULT_SLOT uses bytes32(uint256(keccak256(...)) - 1) per ERC1967.
- For NatSpec custom tags: List all public/external functions, errors, events, and the interface here. Values (selectors, topic0, interfaceId) will be centrally computed and populated in a follow-up pass. Do NOT implement computation in per-file work.

**NatSpec Symbols to Tag (preliminary - expand by reading file):**
- Main contract/library/interface name
- All public/external functions
- Events
- Errors
- (Add exact list when reviewing this report)

**Testing Gaps (LR-7 specific if applicable):**
N/A (pure util; see separate test files).

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3). (Already cross-referenced as gold in AGENTS/CODEBASE_MAP.)

**Notes for Subagents:**
- Implement only fixes for this file's gaps.
- NatSpec values will be pre-filled centrally after review. (None needed.)
- Update the main GAP_REPORT.md checkbox when done.
- Do not edit other files.
- Post: recap of exact 1-6 reads, symbols count (25+), **LR-1 CLOSED**, centrals none, modeled golds, verif summary, pre 1/post 25+ tags, narrow success.

**Priority:** High (core framework files)

**Post-Closure Verification Summary:**
- Targeted ONLY post-edit commands succeeded as specified: forge inspect ...ConstProdUtils.sol:ConstProdUtils (abi|methodIdentifiers); forge build ...ConstProdUtils.sol --skip test --quiet; narrow list '*ConstProdUtils*'.
- Report pre 1 / post 25+ tags, narrow success. Relative paths only. Health: good.
