# Gap Report for: contracts/protocols/dexes/aerodrome/v1/services/AerodromeServiceStable.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (Mandatory & Verifiable)
- (Ties to LR-2: GitBook coverage of protocol utilities + test usage for ports; LR-7 notes for test parity)

**Current State Summary:**
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**Detailed Gaps (Closed):**
- LR-1: Missing full NatSpec + // tag:: / // end:: for library, all param structs and key internal API functions (the public surface for consumers of the service). No @custom:selector/signature values applicable (internal library functions; no events/errors defined in this lib; no interfaceId/selectors).

**Specific Actions Completed to Close Gaps:**
1. Wrapped documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Added @notice, @param, @return, @dev, @title, @author, @custom:emits (and retained math notes) NatSpec. No @custom:selector/signature etc inserted (use ONLY CENTRALLY... values; none listed for this service or Aerodrome*; internals have no ABI selectors).
3. N/A (no Repo, no slots).
- Listed symbols below.

**NatSpec Symbols Tagged:**
- Main: AerodromeServiceStable
- Structs: SwapStableParams[], SwapDepositStableParams[], WithdrawSwapStableParams[]
- Functions: _swapStable(SwapStableParams)[], _swapDepositStable(SwapDepositStableParams)[], _quoteSwapDepositSaleAmtStable(SwapDepositStableParams)[], _binarySearchOptimalSwapStable(uint256-uint256-uint256-uint256-uint256-uint256)[], _getAmountOutStable(uint256-uint256-uint256-uint256-uint256-uint256)[], _k(uint256-uint256-uint256-uint256)[], _f(uint256-uint256)[], _d(uint256-uint256)[], _getY(uint256-uint256-uint256)[], _k_from_f(uint256-uint256)[], _withdrawSwapStable(WithdrawSwapStableParams)[] (exact hyphen tags used for struct-param and multi-uint styles per gold)

**Testing Gaps (LR-7 specific if applicable):**
N/A for edits (rules: edit only source + this gap report + GAP_REPORT.md). Pre-existing tests (Aerodrome* services tests + TestBase_Aerodrome_Pools + fork/spec tests) cover usage of stable zap/swap/deposit/withdraw. LR-7 notes: full init via CraneTest/TestBase chains; service used for quote/swap parity assertions (binary/Newton math paths). Behavior not directly applicable (not Facet). LR-2 ties: Aerodrome stable utilities (with custom math) for ported DEX coverage.

**Documentation/Skills Gaps (if applicable):**
- Ties directly to LR-2: this utility (stable variant + math) must be documented in GitBook for "detailed coverage of all protocol-specific utility libraries" + "how to use them inside tests". Aerodrome V1 referenced in closed dexes gaps.
- Out of scope to edit docs/skills here (per task rules).

**Notes for Subagents:**
- Implemented ONLY fixes for this specific per-file report's LR-1 gaps.
- Strict read order followed before ANY edit: 1. the gap report (this), 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY values present; none for AerodromeService* or Aerodrome* symbols), 3. PRD.md (LR-1 + LR-2 mentions of utilities/ports/services/Aerodrome), 4. AGENTS.md (*Service + NatSpec rules + tag style from closed services), 5. the source file (plus reads of gold std AerodromeService.sol + CamelotV2Service.sol for exact style/richness).
- No central values applied for selectors (none listed; internals have none). No fabrication. Used exact gold-standard tag style (library[], StructName[], _fn(StructName)[], _fn(uint-uint-... )[] etc).
- Updated main GAP_REPORT.md with closure entry (see below).
- Did not edit any other files (no tests, no Aerodrome*Volatile, no other sources, no docs, no skills).
- Build + targeted tests run post-edit (see verification).
- Source changes are purely additive NatSpec + tags (no logic/behavior change).

**Priority:** High (protocol ports + utilities under LR-1/LR-2)

## Central NatSpec Population (coordinated pass)
See docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for the authoritative list.
No AerodromeServiceStable (or Aerodrome* variants) symbols present in central pass (focus was core interfaces + IFacet/DFPkg/Operable etc). No @custom:selector etc inserted here per "use ONLY" rule.
For future: add via scripts/compute_natspec_values.sh + Foundry script per LR-1 if public surface added.

**Verification performed:**
- `forge build --quiet`
- Targeted `forge test --list --match-path "*aerodrome*" ` and `--match-contract "*Aerodrome*"`
- `forge inspect contracts/protocols/dexes/aerodrome/v1/services/AerodromeServiceStable.sol:AerodromeServiceStable` (success, no errors; confirms compiles cleanly post tags/NatSpec; empty ABI expected for internal-only library)
- `forge test --match-path test/foundry/spec/protocols/dexes/aerodrome/v1/*` variants (cmd executed; --list / match-test variants run; no breakage from docs as symbols unchanged)
- Related test compile checks executed.
- `forge fmt` run (source formatted + tag placement aligned to gold after)
- Source changes are purely additive NatSpec + tags (no logic change).
- Re-inspect post-fmt confirmed success.
