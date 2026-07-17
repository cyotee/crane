# Gap Report: .claude/skills/resupply-redemption/SKILL.md

**File Type:** Agent Skill

**Primary LR Violations:** LR-3 (Up-to-date skills)

## Current State
Skill exists and covers related topic.

## Specific Gaps
- May have drifted from finalized PRD standards (NatSpec verification via Foundry Script, ERC1967 slots, LR-7 testing rules, specific GitBook required content).
- Missing explicit coverage of:
  - Reusing DiamondPackageCallBackFactory
  - Deploying own Create3Factory via Package
  - Detailed registry usage
  - Utility library patterns (Sets etc.)
  - Correct test initialization and Behavior usage
- Examples may use old slot formats or incomplete NatSpec.

## Required Changes
1. Update skill content to match current code patterns and PRD requirements.
2. Add sections for chain setup, factory reuse, registries.
3. Reference the central NatSpec computation process.
4. Align with updated docs (GitBook).

**Priority:** High for core crane-* skills; Medium for protocol ones.

**Subagent Notes:** Update skill to enable correct agent behavior per new standards. Do not edit source.
