# Gap Report: .claude/skills/crane-deployment/SKILL.md

**File Type:** Skill  
**Primary LR Violations:** LR-3 (Skills drift), LR-2 (content)

## Current State
- Covers deployment flow, factories, DFPkgs, salts, anti-patterns.
- Good references.

## Specific Gaps
- Does not explicitly document:
  - "The DiamondPackageCallBackFactory is intended to be deployed once and reused across all users/projects on a chain."
  - Step-by-step for "Using CREATE3 Package to deploy your own factory on a new chain."
- Does not reference the new NatSpec verification script process or ERC1967 slot requirement.
- Lacks ties to the required GitBook content (registries explanation, utility libs).
- May have outdated examples vs. current code (e.g. after ERC1967 updates).

## Required Changes
1. Add sections:
   - Reusability of DiamondPackageCallBackFactory
   - Chain bootstrap using Create3FactoryDFPkg
   - Link to registries documentation
2. Update for new standards from PRD (NatSpec script, slots, testing).
3. Sync with crane-architecture skill.

**Priority:** High - skills must not drift.