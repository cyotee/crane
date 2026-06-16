# Gap Report for: contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (Mandatory & Verifiable)
- (Ties to LR-2: GitBook coverage of protocol utilities + test usage for ports; LR-7 notes for test parity)

**Current State Summary:**
Gaps closed for LR-1 on this protocol port utility. Prior to edit: no NatSpec, no include-tags. This is the canonical *Service example (see AGENTS.md). (Targeted edit only per rules; build + tests validated.)

**Detailed Gaps (Closed):**
- LR-1: Missing full NatSpec + // tag:: / // end:: for library, structs and all internal API functions (the public surface for consumers of the service). No @custom values applicable (internal library functions; no events/errors defined in this lib; no interfaceId/selectors).

**Specific Actions Completed to Close Gaps:**
1. Wrapped documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Added @notice, @param, @return (and @dev/@title) NatSpec. No @custom:selector/signature etc inserted (use ONLY CENTRALLY... values; none listed for this service; internals have no ABI selectors).
3. N/A (no Repo, no slots).
- Listed symbols below.

**NatSpec Symbols Tagged:**
- Main: CamelotV2Service
- Structs: ReserveInfo, SwapParams, BalanceParams, WithdrawSwapParams
- Functions: _deposit, _withdrawDirect, _prepareSwap, _executeSwap, _swap (overloads), _sortReserves*, _swapDeposit, _balanceAssets* , _calculateSwapAmount, _withdrawSwapDirect*, _determine*, _swapWithdrawn* (full list + exact tags in source)

**Testing Gaps (LR-7 specific if applicable):**
N/A for edits (rules: edit only source + this gap report + GAP_REPORT.md). Pre-existing tests (CamelotV2Service.t.sol, quote tests using ConstProdUtils + this service for Camelot parity, TestBase_CamelotV2) cover usage. LR-7 notes: full init via CraneTest/TestBase chains; service used in handlers for exact quote/swap assertions vs on-chain. Behavior not directly applicable (not Facet).

**Documentation/Skills Gaps (if applicable):**
- Ties directly to LR-2: this utility (and ConstProdUtils) must be documented in GitBook for "detailed coverage of all protocol-specific utility libraries" + "how to use them inside tests". See references in other closed gaps (dexes.md, create3.md, dfpkg.md) that cross-link services for Camelot.
- Out of scope to edit docs/skills here (per task rules).

**Notes for Subagents:**
- Implemented ONLY fixes for this specific per-file report's LR-1 gaps.
- Read strictly in order: gap report, CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY values present; none for CamelotV2Service), PRD.md (LR-1 + LR-2 mentions of utilities/ports/services), AGENTS.md (CamelotV2Service as *Service example + NatSpec rules), then the source file.
- No central values applied for selectors (none listed; internals have none). No fabrication.
- Updated main GAP_REPORT.md with closure entry (see below).
- Did not edit any other files (no tests, no other .sol, no docs, no skills).
- Build + targeted tests run post-edit (see verification).

**Priority:** High (protocol ports + utilities under LR-1/LR-2)

## Central NatSpec Population (coordinated pass)
See docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for the authoritative list.
No CamelotV2Service symbols present in central pass (focus was core interfaces + IFacet/DFPkg/Operable etc). No @custom:selector etc inserted here per "use ONLY" rule.
For future: add via scripts/compute_natspec_values.sh + Foundry script per LR-1 if public surface added.

**Verification performed:**
- `forge build` (success)
- `forge test --match-path test/foundry/spec/protocols/dexes/camelot/v2/services/CamelotV2Service.t.sol` + related quote tests (ran without breakage from added comments/docs)
- Source changes are purely additive NatSpec + tags (no logic change).
