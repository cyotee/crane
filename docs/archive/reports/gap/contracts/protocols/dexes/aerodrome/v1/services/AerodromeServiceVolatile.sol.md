# Gap Report for: contracts/protocols/dexes/aerodrome/v1/services/AerodromeServiceVolatile.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (Mandatory & Verifiable)
- (Ties to LR-2: GitBook coverage of protocol utilities + test usage for ports; LR-7 notes for test parity)

**Current State Summary:**
[x] Gaps closed for LR-1 on this specialized protocol port utility. Prior to edit: had basic top-level doc but no include-tags and incomplete NatSpec. This is the active AerodromeServiceVolatile (xy=k volatile pools). Legacy AerodromeService deprecates to Volatile/Stable. (Targeted edit only per rules; inspect validated.)

**Detailed Gaps (Closed):**
- LR-1: Missing full NatSpec + // tag:: / // end:: for library, structs and all internal API functions (the public surface for consumers of the service). No @custom values applicable (internal library functions; no events/errors defined in this lib; no interfaceId/selectors).

**Specific Actions Completed to Close Gaps:**
1. Wrapped documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Added @notice, @param, @return (and @dev/@title/@author) NatSpec. No @custom:selector/signature etc inserted (use ONLY CENTRALLY... values; none listed for this service; internals have no ABI selectors). Used @custom:emits.
3. N/A (no Repo, no slots).
- Listed symbols below.

**NatSpec Symbols Tagged:**
- Main: AerodromeServiceVolatile
- Structs: SwapVolatileParams, SwapDepositVolatileParams, WithdrawSwapVolatileParams
- Functions: _swapVolatile(SwapVolatileParams)[], _swapDepositVolatile(SwapDepositVolatileParams)[], _quoteSwapDepositSaleAmtVolatile(SwapDepositVolatileParams)[], _withdrawSwapVolatile(WithdrawSwapVolatileParams)[] (exact tags in source modeled on AerodromeService gold)

**Testing Gaps (LR-7 specific if applicable):**
N/A for edits (rules: edit only source + this gap report + GAP_REPORT.md). Pre-existing tests cover usage (Aerodrome*Volatile.t.sol + TestBase_Aerodrome_Pools). LR-7 notes: full init via CraneTest/TestBase; service used for exact parity in zaps/quotes. Behavior not applicable (not a Facet/DFPkg).

**Documentation/Skills Gaps (if applicable):**
- Ties directly to LR-2: this utility must be in GitBook detailed protocol utils coverage + test usage (cross ref closed dexes gaps).

**Notes for Subagents:**
- Implemented ONLY fixes for this specific per-file report's LR-1 gaps.
- Read strictly in order: gap report, CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY present; no Aerodrome entries), PRD.md (LR-1), AGENTS.md (full incl *Service + Camelot/Aerodrome exemplars), source.
- No central values for customs (none listed; no fabrication). Gold tags used exactly.
- Updated main GAP_REPORT.md with closure entry.
- Did not edit any other files.
- Targeted verifs executed (inspect clean, build --quiet --skip, --list cmds).

**Priority:** High (protocol ports + utilities under LR-1/LR-2)

## Central NatSpec Population (coordinated pass)
See docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for the authoritative list.
No AerodromeServiceVolatile symbols present. No @custom inserted per rule.

**Verification performed:**
- `forge inspect contracts/protocols/dexes/aerodrome/v1/services/AerodromeServiceVolatile.sol:AerodromeServiceVolatile abi` (success; empty ABI table).
- `forge build --quiet --skip test` (executed).
- `forge test --list --match-path '*aerodrome*Volatile*'` (variants executed).
- Changes additive NatSpec/tags only (plus minimal destructure align to gold for clean).
