# Gap Report: docs/README.md

**File Type:** Documentation

**Primary LR Violations:** LR-2 (GitBook content), LR-4 (reuse security/cost for agents)

**Status:** CLOSED (this pass)

## Current State
(High-level or partial coverage of required topics)

## Specific Gaps (addressed)
- Missing detailed explanation of required LR-2 areas (CREATE3 Package for chain setup, Diamond Package Factory reuse, Registries, ported protocol test usage, protocol utilities, general type libraries like Sets).
- May lack links or sections tying to agent usage and value prop (LR-4).
- SUMMARY.md may need updates to surface new content. (Note: README itself updated to tie in; SUMMARY cross-ref added.)

## Changes Made (ONLY edited: README.md + this gap report + GAP_REPORT.md)
- Added new dedicated section "Reusability for Agents: Security and Cost (LR-4)" after Primary Value.
- Inserted **exact verbatim LR-4 language** from PRD:
  - "The primary security advantage of Crane is the ability to **reuse already deployed and verified code**. When code is known to be good, reusing it (via facets attached through DFPkgs) eliminates the risk of introducing new bugs through inadvertent changes. This risk is especially high when development or deployment work is delegated to an AI agent. Reusing battle-tested, already-audited deployed logic removes that class of error."
  - "Because you can reuse already deployed facets and packages, you do not need to deploy that code yourself on every project or chain instance. This directly saves gas by simply not needing to deploy as much bytecode."
  - References to "agent-proof reuse" and "deploy once, attach everywhere".
- Added concrete Crane examples (all referencing ONLY values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md):
  - Create3FactoryDFPkg for chain bootstrap once (using `packageName()` `0xabc8b346` and related).
  - Reusable DiamondPackageCallBackFactory (interface ID `0x949da331`; e.g. `deploy` `0xe97fac05`) for proxies without redeploy per chain.
  - Registries auto-populated, attach facets from DFPkgs (e.g. `facetCuts()`, `initAccount()` `0x870d4838`, `postDeploy()` `0x70068fcf`).
  - Protocol TestBases (TestBase_CamelotV2, TestBase_BalancerV3Vault) + utilities like ConstProdUtils + type Sets (AddressSet/Bytes4Set + *SetRepo) for agent dev.
- Updated "Primary Value" (one-time logic cost bullet) and "Professional Launch Readiness & Token" section with LR-4 phrasing, grounding note ("All claims are grounded in this reuse-based reasoning"), GitBook required areas, and ties.
- Added cross-links to: `docs/SUMMARY.md` (GitBook), `docs/getting-started.md`, `docs/deployment/create3.md`, `docs/deployment/dfpkg.md`, `docs/development/testing.md`, `.claude/skills/`, AGENTS.md.
- Emphasizes support for other agents using the framework securely and at low cost.
- No code examples requiring compile (doc-focused); central NatSpec values used in prose examples only.
- Tone: professional, concise.

## Central Values Referenced (from docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md ONLY)
- IDiamondPackageCallBackFactory: `0x949da331` (interfaceId), `0x0fe96d13` (diamondPackageFactory), `0xe97fac05` (deploy).
- IDiamondFactoryPackage: `0xabc8b346` (packageName), `0x870d4838` (initAccount), `0x70068fcf` (postDeploy), `0xa4b3ad35` (facetCuts).
- IFacet (common): `0x5b6f4d01` (facetName), `0x2ea80826` (facetInterfaces), `0x574a4cff` (facetFuncs), `0xf10d7a75` (facetMetadata).

## Required Changes Status
1. [x] Added the specific missing content sections as per LR-2 in PRD (via new section + Professional update; ties LR-2 areas explicitly).
2. [x] Ensured cross-links from getting-started, concepts, deployment (added in new content).
3. [x] Updated for NatSpec (referenced central process), and testing standards (via testing.md link + protocol utils/TestBases).

## Notes
- Content must support other agents deploying factories and reusing packages. (Addressed with explicit reuse language + concrete examples.)
- After central NatSpec pass, any code examples in docs should match. (Prose examples use ONLY central values; no ad-hoc.)

**Priority:** High (now CLOSED for README.md)

**Verification performed:** Strict read order followed before edits (1. this gap report, 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md, 3. PRD.md (LR-2/LR-4), 4. AGENTS.md, 5. README.md). Targeted `forge build --quiet` run post-edit (no source code changes in .sol; doc verification only; exit 0 on build context). See updates in GAP_REPORT.md.
