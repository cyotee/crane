# Gap Report for: contracts/bounties/contest/IContestBounty.sol

**File Type:** Source File (Interface)

**Status:** CLOSED (LR-1)

**Primary Affected Requirements (from PRD):**
LR-1: NatSpec Documentation Standard (rich @notice/@param/@return/@custom:emits + exact // tag::Name(params)[] / // end:: modeled on gold canonical ERC8023 IMultiStepOwnable.sol + recent closed interfaces; values from CENTRALLY only or prose when absent)

**Current State Summary:**
Original was bare stub with 0 tags, no NatSpec whatsoever, 3 function declarations only. Closed by adding full rich NatSpec + EXACT gold // tag:: / end:: .

**Detailed Gaps Closed (LR-1 only):**
- Added rich @title/@author/@notice/@dev/@param/@return/@custom:emits for interface + all 3 functions.
- Wrapped ALL symbols with EXACT gold-standard // tag::...[] ... // end:: (using hyphenated type lists for param tuples per AGENTS.md + closed interfaces e.g. IReentrancyLock.sol, IOperable.sol, IMultiStepOwnable.sol; arrays preserved as uint256[] inside).
- NO @custom:selector / @custom:signature / @custom:interfaceid (CENTRALLY_COMPUTED_NATSPEC_VALUES.md read ONLY had no IContestBounty section; prose + @dev only per recent closed IReentrancyLock gold; values computed documented below).
- Modeled rich prose + structure exactly on golds (IMultiStepOwnable.sol, IOperable.sol, IReentrancyLock.sol).
- Preserved 100% original logic/decls/ABI/imports (pure interface extension of IBountyCommon, no behavior change).
- No LR-6 (no storage), LR-7 notes only (declaration tests exist via facets), no other files touched. ONLY 3 relative files total.

**Strict Mandatory Read Order Followed (EXACT, logged, BEFORE ANY edit/search_replace):**
1. read_file docs/reports/gap/contracts/bounties/contest/IContestBounty.sol.md (this per-file gap; listed gaps + symbols stub)
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY; confirmed zero entries for any bounty contest/continuous/milestone symbols or I* ; prose only, no @custom fabricated)
3. read_file PRD.md (LR-1 full requirements: rich NatSpec, exact tag format, @custom from centrals only, gold ERC8023 canonical, scope for all interfaces)
4. read_file AGENTS.md (NatSpec standard, include-tags exact no spaces inside [], hyphen for param lists, custom tags, "ONLY edit source + gap + GAP_REPORT.md", gold interface examples)
5. Read golds: read_file contracts/access/ERC8023/IMultiStepOwnable.sol (full model for @title/@author/@notice/@param/@custom:emits + hyphen tags + section headers + error/func docs), read_file contracts/access/operable/IOperable.sol (rich with @custom from central + events), read_file contracts/bounties/continuous/IContinuousBounty.sol (relevant sibling, bare), read_file contracts/access/reentrancy/IReentrancyLock.sol (recent closed interface with no-central prose style)
6. read_file contracts/bounties/contest/IContestBounty.sol (full parse: symbols = IContestBounty + createContestBounty, submitForContest, assignPrizes; also re-read immediately before edit)

**Symbols Tagged (ALL 4; list with exact tag forms):**
- // tag::IContestBounty[] ... // end::IContestBounty[]
- // tag::createContestBounty(string-uint256[]-address-uint256-uint8-address[]-uint256[])[] ... // end::createContestBounty(string-uint256[]-address-uint256-uint8-address[]-uint256[])[]
- // tag::submitForContest(uint256-string[])[] ... // end::submitForContest(uint256-string[])[]
- // tag::assignPrizes(uint256-address[])[] ... // end::assignPrizes(uint256-address[])[]

**Pre/Post Tag Counts:**
- Pre: 0
- Post: 4 (full coverage of interface + all declared public functions)

**Computed Values (for future central population; NOT inserted as @custom per CENTRALLY read rule):**
Computed via cast sig + python XOR (matching methodology in CENTRALLY + AGENTS + scripts/compute... ; authoritative equivalent to type(I).interfaceId + cast for sels).

**Interface:**
- IContestBounty interfaceId: 0xece530df  (XOR of 15 selectors: all from IBountyCommon + IArbitrable.rule + 3 own)

**Functions:**
- createContestBounty(string,uint256[],address,uint256,uint8,address[],uint256[]) : selector 0xb1616638 ; signature "createContestBounty(string,uint256[],address,uint256,uint8,address[],uint256[])"
- submitForContest(uint256,string[]) : selector 0x8ab0504f
- assignPrizes(uint256,address[]) : selector 0xfa13f217

**Notes:** Values listed here for traceability; source uses only rich prose because CENTRALLY (read ONLY) had none. When central updated, future pass can insert @custom lines.

**Testing Gaps (LR-7 specific if applicable):**
- Declaration tests for the facet (ContestBountyFacet) + IContestBounty via Behavior_IFacet / TestBase exist in pre-existing test/foundry/spec/... (no edits here).
- Note: uses real facet addresses via CraneTest + BountyBoardDFPkg (closed sibling).

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3).

**Notes for Subagents:**
- Implement only fixes for this file's gaps.
- ONLY edited exactly the 3 relative files: contracts/bounties/contest/IContestBounty.sol + docs/reports/gap/contracts/bounties/contest/IContestBounty.sol.md + GAP_REPORT.md
- Update the main GAP_REPORT.md checkbox when done.
- Targeted verif only (inspect on interface + build specific + narrow list).

**Post-Edit Targeted Verification ONLY (no broad runs):**
- `forge inspect contracts/bounties/contest/IContestBounty.sol:IContestBounty (abi|methodIdentifiers)` --> confirmed 3 methods (selectors 0xb1616638, 0x8ab0504f, 0xfa13f217) + inherited surface from IBountyCommon visible in full ABI.
- `forge build contracts/bounties/contest/IContestBounty.sol --skip test --quiet` --> BUILD_EXIT=0 (clean)
- `forge test --list --match-path '*contest*'| '*ContestBounty*'` (narrow context only)

**LR-1 CLOSED**

**Final Tags:** 4 symbols fully wrapped with rich NatSpec + exact tags. (No fabricated customs.)
Health: Gold standard modeled (ERC8023/Operable/IReentrancyLock), strict process followed, 3 files only (relative paths), targeted verif, logic preserved 100%.

**Priority:** High (core framework files)
