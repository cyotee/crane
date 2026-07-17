# Gap Report for: contracts/interfaces/BetterIERC20.sol

**File Type:** Source File (Interface)

**Status:** CLOSED (LR-1)

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include-tags)

**Tagged Symbols (1):**
- `BetterIERC20[]` (the composed interface; focus surface only since inherits all members from IERC20Metadata/IERC20Errors/etc; no direct decls)

**Summary of Changes:**
Enriched to LR-1 gold standard for interfaces (rich NatSpec + preserved EXACT // tag::BetterIERC20[] / // end::). Modeled on closed golds: `contracts/interfaces/IPermit2Aware.sol`, `contracts/access/reentrancy/IReentrancyLock.sol`, `contracts/access/operable/IOperable.sol`, `contracts/access/ERC8023/IMultiStepOwnable.sol`. Replaced stub @title/@author/@dev/@notice with full @title/@author/@notice/@dev (multi-line) explaining composition, inheritance, usage in Crane tokens/DFPkgs/protocols, and explicit note on absence of @custom (per central). NO @custom:* added (CENTRALLY_COMPUTED_NATSPEC_VALUES.md has no entries for BetterIERC20 or ERC20 symbols; prose only). Preserved original logic/pragma/imports/empty body/tags exactly (additive docs only). Since composed/inherits, no inner // tag:: for funcs/events/errors.

**Pre-edit tags (from source read):** // tag::BetterIERC20[] ... // end::BetterIERC20[] (outer present; inner NatSpec weak: "who?", minimal)
**Post-edit tags:** 1 (outer preserved/enhanced with rich prose inside; no additional symbols as none declared directly)

**Detailed Gaps (historical before close):**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).

**Strict Ordered Reads Performed (EXACT ORDER before ANY edit + re-reads of key before search_replace):**
1. docs/reports/gap/contracts/interfaces/BetterIERC20.sol.md (per-file gap docs)
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY source for any @custom; confirmed NONE for BetterIERC20 or IERC20/Errors/Metadata symbols)
3. PRD.md (LR-1 and LR sections; canonical golds + rich NatSpec + exact tags req + scope for interfaces)
4. AGENTS.md (full NatSpec+tag rules, exact // tag::Name(params)[] / end:: no extra spaces inside [], gold interface examples like IReentrancyLock.sol / IMultiStepOwnable.sol / IPermit2Aware.sol, "ONLY edit 3 files", relative paths, targeted verif)
5. Golds: read at least 2-3 closed interfaces + their gaps: contracts/access/reentrancy/IReentrancyLock.sol + its gap, contracts/access/operable/IOperable.sol + its gap, contracts/interfaces/IPermit2Aware.sol + its gap, + contracts/access/ERC8023/IMultiStepOwnable.sol (and stub gap) for exact rich style (@title/@author/@notice/@dev/@param/@return + @custom from centrals only + hyphen tags, composition notes, central absence prose)
6. the source contracts/interfaces/BetterIERC20.sol (full; re-read immediately before edits)

**Centrals:** none for this interface (no @custom fabricated; followed "use ONLY these values" + "if IERC20 etc apply, pull from CENTRALLY only")
**ONLY 3 files edited (relative paths only):** contracts/interfaces/BetterIERC20.sol + docs/reports/gap/contracts/interfaces/BetterIERC20.sol.md + GAP_REPORT.md

**Surface from targeted inspect (pre + for recap):** 9 functions (allowance, approve, balanceOf, decimals, name, symbol, totalSupply, transfer, transferFrom); 2 events (Approval, Transfer); 6 errors (ERC20Insufficient* etc). No direct decls here; all via inheritance. Used for doc only.

**Verification (TARGETED ONLY, executed post edits):**
- `forge inspect contracts/interfaces/BetterIERC20.sol:BetterIERC20 (abi|methodIdentifiers)` -> succeeded (see outputs below for details matching pre-edit surface); abi lists the 9 funcs + events + errors; methodIdentifiers table confirms all 9 methods.
- `forge build contracts/interfaces/BetterIERC20.sol --skip test --quiet` -> BUILD_EXIT=0 (clean; docs only).
- narrow list if useful: `forge test --list --match-path '*BetterIERC20*|*ERC20DFPkg*' ` (executed for context; no impact on unrelated).

**LR-1 closed for this interface.** 1 tag (BetterIERC20[] outer; surface focused due to inheritance). See GAP_REPORT.md for concise [x] entry. Strict process + 6 reads + only centrals prose + 3 files + relative + targeted verif followed exactly. No unnecessary edit (tags were already exact outer; only richened NatSpec per golds). 

**Command outputs summary (targeted post-edit):**
(inspect abi abbreviated) includes events Approval/Transfer + errors ERC20* + funcs as listed. methodIdentifiers: allowance 0xdd62ed3e, approve 0x095ea7b3, balanceOf 0x70a08231, decimals 0x313ce567, name 0x06fdde03, symbol 0x95d89b41, totalSupply 0x18160ddd, transfer 0xa9059cbb, transferFrom 0x23b872dd. Build quiet success.
