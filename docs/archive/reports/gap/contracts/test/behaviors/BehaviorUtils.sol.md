# Gap Report for: contracts/test/behaviors/BehaviorUtils.sol

**File Type:** Source File (core shared test behavior helper library)

**LR-1 Status:** CLOSED (scoped subagent LR-1 ONLY on this core test behavior helper, used by many Behaviors)

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec Documentation Standard): full rich NatSpec + exact // tag::Name(params)[] / end:: for all documented symbols on ALL .sol including test files, Behaviors, helpers, TestBases, comparators. Hyphenated overload tags. Rich @notice/@param/@return/@dev. Scope explicitly includes test code.

**Strict Mandatory Process (EXACT ORDER before ANY edit - logged):**
1. read_file docs/reports/gap/contracts/test/behaviors/BehaviorUtils.sol.md
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY; prose) - confirmed no @custom entries apply (internal helper util; no selectors/interfaceids to insert)
3. read_file PRD.md (LR-1 on test files/Behaviors + "NatSpec on test code" + "Behavior libraries must be used" + "all test files (Behavior_*.sol ...)" + mandatory verification)
4. read_file AGENTS.md (test infra NatSpec + tags, Behavior patterns section, key files listing BehaviorUtils.sol, "If a handler/test contract... must also have clear NatSpec and include-tags", crane-testing skill refs, exact tag format no extra spaces)
5. Read golds: closed Behaviors (Behavior_IFacet.sol, Behavior_IERC165.sol) + TestBase_IFacet.sol + TestBase_IERC165.sol + CraneTest.sol + Behavior usages in IDiamondLoupe/IFacetRegistry etc.
6. read_file contracts/test/behaviors/BehaviorUtils.sol (parsed all public symbols for tagging)

**ONLY 3 relative files edited (per rules):** contracts/test/behaviors/BehaviorUtils.sol + docs/reports/gap/contracts/test/behaviors/BehaviorUtils.sol.md + GAP_REPORT.md . No other files touched.

**Symbols / Tags added (4 total):**
- BehaviorUtils[]
- _errPrefixFunc(string-string)[]
- _errPrefix(string-string-string)[]
- _errPrefix(string-string-address)[]

**Detailed Gaps (pre-fix):**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).

**Specific Actions Needed to Close Gaps:**
1. Wrap documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Add @notice, @param, @return, @custom:selector / signature / topiczero / interfaceid with accurate values (to be centrally computed).
3. For Repos: ensure DEFAULT_SLOT uses bytes32(uint256(keccak256(...)) - 1) per ERC1967.
- For NatSpec custom tags: List all public/external functions, errors, events, and the interface here. Values (selectors, topic0, interfaceId) will be centrally computed and populated in a follow-up pass. Do NOT implement computation in per-file work.

**NatSpec Symbols to Tag (final - from step 6 parse):**
- Main library name: BehaviorUtils
- All key helpers: _errPrefixFunc(string,string), _errPrefix(string,string,string) [label], _errPrefix(string,string,address) [subject]
- (No events, errors, public external interface surface)

**Testing Gaps (LR-7 specific if applicable):**
- Full initialization of subjects (Packages with real facet addresses, not 0).
- Exact assertions vs side-effect checks.
- Preview vs execute parity.
- Use of Behavior_IFacet / Behavior_IDiamondFactoryPackage etc.
- Declaration tests for facets and packages.
- (Notes only for this helper file; consumers enforce.)

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3). (Referenced via AGENTS.md + docs/development/testing.md)

**Detailed Changes (post LR-1):**
- Added full rich NatSpec + EXACT // tag::BehaviorUtils[] + _errPrefixFunc(string-string)[] + _errPrefix(string-string-string)[] + _errPrefix(string-string-address)[] /end:: (hyphen overloads).
- Rich @title/@author/@notice/@dev/@param/@return modeled on Behavior_IFacet gold + Behavior_IERC165 (includes usage notes, delegation, LR refs).
- NO @custom (step2 prose + no applicable surface).
- 0 -> 4 tags. Preserved all logic/imports/structure.

**Pre / Post tag count:** 0 / 4

**Notes for Subagents:**
- Implement only fixes for this file's gaps.
- NatSpec values will be pre-filled centrally after review. (N/A here)
- Update the main GAP_REPORT.md checkbox when done.
- Do not edit other files.
- Targeted post: inspect on BehaviorUtils, build specific --skip quiet. Report tags/health.

**Priority:** High (core framework files)
