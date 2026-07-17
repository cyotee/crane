# Gap Report for: contracts/bounties/common/BountyRepo.sol

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
- Fixed LR-6: STORAGE_SLOT now exact ERC1967 `bytes32(uint256(keccak256(abi.encode("crane.bounties.common"))) - 1)`.
- Added/improved dual _layoutStruct(bytes32) and _layoutStruct() with layoutStruct param.
- Added full dual overloads for *every* _* function (Storage-param impl + default delegating via _layoutStruct()).
- Added rich NatSpec (@title/@author/@dev/@param/@return) + EXACT gold // tag:: / end:: (hyphenated e.g. _bounty(Storage-uint256)[] for Storage-param, _bounty(uint256)[] for default) for: library itself (BountyRepo[]), STORAGE_SLOT, Storage, both _layoutStruct, and all _* funcs.
- Standardized param names to `layoutStruct`; consumers inside updated (now all delegate correctly).
- Used "crane.bounties..." hierarchical name per AGENTS/gold guidance (from "daosys..." original).
- No @custom: (none in CENTRALLY for internal Repos; none fabricated).
- ONLY edited this file + its .sol + GAP_REPORT.md (see entries).
- Targeted verification (post edit): forge inspect, build --skip test --quiet, test --list --match-path '*Bounty*' (see GAP_REPORT for outputs).
- Symbols now fully tagged (list): BountyRepo, STORAGE_SLOT, Storage, _layoutStruct(bytes32), _layoutStruct(), _nextBountyId(Storage), _nextBountyId(), _incrementBountyId(Storage), _incrementBountyId(), _bounty(Storage-uint256), _bounty(uint256), _setIssuer*2, _setFunder*2, _setStatus*2, _setAccess*2, _getAccess*2, _initializeBounty*2 (hyphenated long), _addContribution*2, _getContribution*2, _getTotalContributed*2, _getDisbursed*2, _getRemaining*2, _addDisbursed*2, _subtractContribution*2, _addAllowedSubmitter*2, _removeAllowedSubmitter*2, _isAllowedSubmitter*2, _setDisputeInfo*2, _getDisputeInfo*2, _getBountyIdForDispute*2, _setDisputeToBounty*2, _getBountyForDispute*2, _isSubmitterAllowed*2, _markClosed*2.
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
