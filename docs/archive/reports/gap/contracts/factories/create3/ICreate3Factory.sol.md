# Gap Report for: contracts/factories/create3/ICreate3Factory.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
$ gaps

**Current State Summary:**
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**Detailed Gaps:**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).

**Specific Actions Needed to Close Gaps:**
1. Wrap documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Add @notice, @param, @return, @custom:selector / signature / topiczero / interfaceid with accurate values (to be centrally computed).
3. For Repos: ensure DEFAULT_SLOT uses bytes32(uint256(keccak256(...)) - 1) per ERC1967.
- For NatSpec custom tags: List all public/external functions, errors, events, and the interface here. Values (selectors, topic0, interfaceId) will be centrally computed and populated in a follow-up pass. Do NOT implement computation in per-file work.

**Centrally Computed NatSpec Values (from coordinated pass - 2026-07-02):**

**Interface (ICreate3Factory):**
- Recommend @custom:interfaceid (compute via Solidity type(ICreate3Factory).interfaceId or XOR of its 4 selectors)

**Functions:**
- diamondPackageFactory()
  - @custom:signature diamondPackageFactory()
  - @custom:selector 0x0fe96d13

- setDiamondPackageFactory(address)
  - @custom:signature setDiamondPackageFactory(address)
  - @custom:selector 0x1cdca5df

- create3(bytes,bytes32)
  - @custom:signature create3(bytes,bytes32)
  - @custom:selector 0xa7b62a7f

- create3WithArgs(bytes,bytes,bytes32)
  - @custom:signature create3WithArgs(bytes,bytes,bytes32)
  - @custom:selector 0x1f7fe4db

**Notes:** The source already had good partial NatSpec in some versions. Ensure full // tag:: wrappers and complete the @custom fields with these values. Cross-reference with Create3FactoryDFPkg.

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
