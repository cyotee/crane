# Gap Report: docs/deployment/create3.md

**File Type:** Documentation

**Primary LR Violations:** LR-2 (GitBook content)

**Status:** CLOSED

## Current State
Expanded with full LR-2 required coverage. Previously high-level/partial.

## Specific Gaps (Closed)
- [x] Added detailed CREATE3 Package chain setup guide (using Create3FactoryDFPkg / ICREATE3DFPkg, PkgInit/PkgArgs on interface, bootstrap flow with central selectors e.g. packageName 0xabc8b346, deployCreate3Factory 0x34cb11b5, initAccount 0x870d4838).
- [x] Expanded explicit DiamondPackageCallBackFactory reuse statement (deployed once; safe for public reuse across chains; no per-chain redeploy; central interfaceId 0x949da331; selectors e.g. deploy 0xe97fac05, diamondPackageFactory 0x0fe96d13; quotes from impl + IDiamondPackageCallBackFactory).
- [x] Detailed registries explanation (FacetRegistry, IDiamondFactoryPackageRegistry, CallTarget) including purpose, auto-population via Create3Factory _register* + Repos, consumer interaction (canonicalFacet via interfaceId, exposed on Create3Factory instances installed by Create3DFPkg).
- [x] Cross-links to protocol test usage/utilities (CraneTest + InitDevService inheritance; specific TestBase_CamelotV2, TestBase_BalancerV3Vault, TestBase_Reliquary; Balancer DFPkg integration test examples using deployFacet/deploy; utilities: ConstProdUtils, DEX services, collections Sets/Repos; references to AGENTS.md, crane-testing, docs/protocols/*).
- Used ONLY values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md in all code examples (no ad-hoc computation).
- Added ties to agent value (LR-4 reuse security/cost: deploy-once, attach-everywhere, verified facets).

## Required Changes (Completed)
1. Added specific missing content sections per LR-2 in PRD (chain setup via CREATE3 pkg, DPCF reuse, registries, protocol test cross-links + utilities).
2. Internal cross-links (to dfpkg.md, AGENTS.md sections, source contracts, test bases) -- external updates like SUMMARY/getting-started per separate gaps.
3. Code examples use central NatSpec (@custom:signature/selector, interfaceid) matching the pass.

## Notes
- Content supports other agents deploying factories and reusing packages (per original).
- Edits strictly limited to: this gap report + the doc (docs/deployment/create3.md) + GAP_REPORT.md.
- Verified read order followed: gap report first, then CENTRALLY..., PRD LR-2, AGENTS.md, then source files (Create3FactoryDFPkg.sol, DiamondPackageCallBackFactory.sol, ICreate3Factory.sol, IDiamondPackageCallBackFactory.sol, InitDevService.sol, CraneTest.sol, registry IFs, Create3Factory*.sol, protocol test bases, etc.).
- See expanded doc for full content.

**Priority:** High (now resolved)
