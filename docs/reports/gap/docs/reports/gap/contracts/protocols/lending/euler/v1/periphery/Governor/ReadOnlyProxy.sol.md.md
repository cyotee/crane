# Gap Report for: docs/reports/gap/contracts/protocols/lending/euler/v1/periphery/Governor/ReadOnlyProxy.sol.md

**File Type:** Documentation

**Primary Affected Requirements (from PRD):**
$ gaps

**Current State Summary:**
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**Detailed Gaps:**
- LR-2: Missing detailed content on CREATE3 Package for chain setup, DiamondPackageCallBackFactory reuse, Registries explanation, protocol test usage, utilities/Sets.

**Specific Actions Needed to Close Gaps:**
1. Add required sections per PRD LR-2.
2. Link from SUMMARY.md and getting-started.
- For NatSpec custom tags: List all public/external functions, errors, events, and the interface here. Values (selectors, topic0, interfaceId) will be centrally computed and populated in a follow-up pass. Do NOT implement computation in per-file work.

**NatSpec Symbols to Tag (preliminary - expand by reading file):**
- Main contract/library/interface name
- All public/external functions
- Events
- Errors
- (Add exact list when reviewing this report)

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
