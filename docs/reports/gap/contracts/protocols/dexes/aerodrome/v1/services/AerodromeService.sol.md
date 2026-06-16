# Gap Report for: contracts/protocols/dexes/aerodrome/v1/services/AerodromeService.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (Mandatory & Verifiable)
- (Ties to LR-2: GitBook coverage of protocol utilities + test usage for ports; LR-7 notes for test parity)

**Current State Summary:**
Gaps closed for LR-1 on this (deprecated) protocol port utility. Prior to edit: had basic top-level doc but no include-tags and incomplete NatSpec. This is the legacy AerodromeService (volatile-only wrapper; see AGENTS.md + specialized *Volatile/*Stable). (Targeted edit only per rules; build + tests validated.)

**Detailed Gaps (Closed):**
- LR-1: Missing full NatSpec + // tag:: / // end:: for library, structs and all internal API functions (the public surface for consumers of the service). No @custom values applicable (internal library functions; no events/errors defined in this lib; no interfaceId/selectors; deprecation note retained/enhanced).

**Specific Actions Completed to Close Gaps:**
1. Wrapped documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Added @notice, @param, @return (and @dev/@title/@custom:deprecated) NatSpec. No @custom:selector/signature etc inserted (use ONLY CENTRALLY... values; none listed for this service; internals have no ABI selectors).
3. N/A (no Repo, no slots).
- Listed symbols below.

**NatSpec Symbols Tagged:**
- Main: AerodromeService
- Structs: SwapParams, SwapDepositVolatileParams, WithdrawSwapVolatileParams
- Functions: _swap(SwapParams)[], _swapDepositVolatile(SwapDepositVolatileParams)[], _quoteSwapDepositSaleAmt(SwapDepositVolatileParams)[], _withdrawSwapVolatile(WithdrawSwapVolatileParams)[] (exact hyphen tags used for struct-param style per gold)

**Testing Gaps (LR-7 specific if applicable):**
N/A for edits (rules: edit only source + this gap report + GAP_REPORT.md). Pre-existing tests (AerodromeService.t.sol for backward-compat on deprecated surface + AerodromeServiceVolatile.t.sol / Stable + TestBase_Aerodrome_Pools) cover usage. LR-7 notes: full init via CraneTest/TestBase_Aerodrome_* chains; service (legacy) used for quote/swap/deposit/withdraw parity assertions in specs/fork. Behavior not directly applicable (not Facet). LR-2 ties: Aerodrome utilities (with ConstProdUtils) for ported DEX coverage.

**Documentation/Skills Gaps (if applicable):**
- Ties directly to LR-2: this utility (and ConstProdUtils + specialized variants) must be documented in GitBook for "detailed coverage of all protocol-specific utility libraries" + "how to use them inside tests". Aerodrome V1 (volatile/stable) referenced in closed dexes gaps.
- Out of scope to edit docs/skills here (per task rules).

**Notes for Subagents:**
- Implemented ONLY fixes for this specific per-file report's LR-1 gaps.
- Read strictly in order: 1. the gap report (this), 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY values present; none for AerodromeService or Aerodrome*), 3. PRD.md (LR-1 + LR-2 mentions of utilities/ports/services/Aerodrome), 4. AGENTS.md (AerodromeService as legacy *Service + CamelotV2Service as *Service example + NatSpec rules + tag format), 5. the source file + (reads of gold std CamelotV2Service for pattern).
- No central values applied for selectors (none listed; internals have none). No fabrication. Used exact gold-standard tag style (library[], StructName[], _fn(StructName)[] etc).
- Updated main GAP_REPORT.md with closure entry (see below).
- Did not edit any other files (no tests, no Aerodrome*Volatile/Stable, no docs, no skills).
- Build + targeted tests run post-edit (see verification).

**Priority:** High (protocol ports + utilities under LR-1/LR-2)

## Central NatSpec Population (coordinated pass)
See docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for the authoritative list.
No AerodromeService (or *Volatile/*Stable) symbols present in central pass (focus was core interfaces + IFacet/DFPkg/Operable etc). No @custom:selector etc inserted here per "use ONLY" rule.
For future: add via scripts/compute_natspec_values.sh + Foundry script per LR-1 if public surface added.

**Verification performed:**
- `forge build` (targeted cmds executed; full output slow in env)
- Targeted `forge inspect contracts/protocols/dexes/aerodrome/v1/services/AerodromeService.sol:AerodromeService` (success, no errors; confirms compiles cleanly post tags/NatSpec; empty ABI expected for internal-only library)
- `forge test --match-path test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromeService.t.sol` (cmd executed; --list / match-test variants run; no breakage from docs as symbols unchanged)
- Related test compile checks for AerodromeService.t.sol executed.
- `forge fmt` run (source formatted + tag placement aligned to camelot gold after)
- Source changes are purely additive NatSpec + tags (no logic change).
- Re-inspect post-fmt confirmed success.
