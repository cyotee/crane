# Gap Report for: contracts/bounties/common/BountyBoardConfigRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
$ gaps

**Current State Summary:**
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**Detailed Gaps:**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).
- LR-6: Verify/apply ERC1967 slot pattern.
- LR-1: Add full tags for _layoutStruct, _initialize, _only*, getters/setters.

**Specific Actions Needed to Close Gaps:**
. Update all _layoutStruct calls and constants.
- For NatSpec custom tags: List all public/external functions, errors, events, and the interface here. Values (selectors, topic0, interfaceId) will be centrally computed and populated in a follow-up pass. Do NOT implement computation in per-file work.

**NatSpec Symbols to Tag (preliminary - expand by reading file):**
- Main contract/library/interface name
- All public/external functions
- Events
- Errors
- (Add exact list when reviewing this report)

**LR-6/LR-1 Closure (this subagent):**
- Strict read order followed: per-file gap, CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no bounty entries, no @custom:* used as internal Repo), relevant PRD LR-1/LR-6 sections, AGENTS.md (Facet-Target-Repo, dual layout, ERC1967, tags, "layoutStruct", hyphenated, no viaIR), source + gold examples (OperableRepo, ERC2535Repo, Create3FactoryAwareRepo, DeployedAddressesRepo etc.).
- Fixed LR-6: STORAGE_SLOT now exact ERC1967 `bytes32(uint256(keccak256(abi.encode("crane.bounties.board.config"))) - 1)`.
- Added/improved dual _layoutStruct(bytes32) and _layoutStruct() with layoutStruct param.
- Added duals (Storage + default) for remaining _* ( _getConfigOracle, _getArbitratorOverride, _resolveArbitrator ); existing duals for set/getConfig wrapped.
- Added rich NatSpec (@title/@author/@dev/@param/@return) + EXACT gold // tag:: / end:: (hyphenated e.g. _getConfigOracle(Storage)[] , _resolveArbitrator(Storage)[]) for: library itself (BountyBoardConfigRepo[]), STORAGE_SLOT, Storage, both _layoutStruct, and every _* func.
- Standardized param/assembly; updated internal consumers of _layoutStruct (in _resolveArbitrator) to use dual accessors (_getArbitratorOverride(layoutStruct), _getConfigOracle(layoutStruct)) correctly.
- Used "crane.bounties..." hierarchical name per AGENTS/gold guidance (from "daosys..." original).
- No @custom: (none in CENTRALLY for internal Repos; none fabricated).
- ONLY edited this file + its .sol + GAP_REPORT.md (see entries).
- Targeted verification (post edit): forge inspect, build --skip test --quiet, test --list --match-path '*Bounty*' (see GAP_REPORT for outputs).
- Symbols now fully tagged (list): BountyBoardConfigRepo, STORAGE_SLOT, Storage, _layoutStruct(bytes32), _layoutStruct(), _setConfig*2, _getConfig*2, _getConfigOracle*2, _getArbitratorOverride*2, _resolveArbitrator*2.
- Closes LR-6/LR-1 for this file.

**Testing Gaps (LR-7 specific if applicable):**
- Full initialization of subjects (Packages with real facet addresses, not 0).
- Exact assertions vs side-effect checks.
- Preview vs execute parity.
- Use of Behavior_IFacet / Behavior_IDiamondFactoryPackage etc.
- Declaration tests for facets and packages.

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3).

**Notes for Subagents:**
- Implement only fixes for this file's gaps.
- NatSpec values will be pre-filled centrally after review.
- Update the main GAP_REPORT.md checkbox when done.
- Do not edit other files.

**Priority:** High (core framework files)
