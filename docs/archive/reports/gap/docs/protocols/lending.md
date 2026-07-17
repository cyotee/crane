# Gap Report: docs/protocols/lending.md

**File Type:** Documentation

**Primary LR Violations:** LR-2 (GitBook content)

## Current State
(High-level or partial coverage of required topics)

Detailed LR-2 content now inserted (see updated `docs/protocols/lending.md`).

## Specific Gaps
- ~~Missing detailed explanation of required LR-2 areas (CREATE3 Package for chain setup, Diamond Package Factory reuse, Registries, ported protocol test usage, protocol utilities, general type libraries like Sets).~~ **CLOSED** for lending scope: added full Aave (v3.6 + v4 Hub/Spoke) + Euler (EVC/EVault/periphery) explanations, test usage (ProtocolV3TestBase, Base.t.sol + AaveV4TestOrchestration, invariants/handlers, CraneTest patterns), protocol utilities (WadRay/SharesMath, SpokeUtils, Lens, IRMs, EVC Set/Transient, etc.), native Crane (Permit2Aware, rate providers), general Sets/math refs, cross-links to central NatSpec + AGENTS + CODEBASE_MAP.
- ~~May lack links or sections tying to agent usage and value prop (LR-4).~~ **CLOSED**: added LR-4 reuse rationale, agent bootstrap (Create3FactoryDFPkg + reusable DiamondPackageCallBackFactory), registries mention.
- SUMMARY.md may need updates to surface new content. (Out of scope per edit rules; linked already.)

## Required Changes
1. ~~Add the specific missing content sections as per LR-2 in PRD.~~ **DONE** (strict order: read gap report, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD.md LR-2, AGENTS.md, source files: lending.md + subdocs, CODEBASE_MAP.md, test Base/ProtocolV3TestBase, AaveV4 setups, Euler lifecycle docs, aave/euler contracts).
2. ~~Ensure cross-links from getting-started, concepts, deployment.~~ Included.
3. Update for NatSpec verification script, ERC1967, testing standards. (Covered via refs; central values used exclusively e.g. IDiamondPackageCallBackFactory 0x949da331, IFacet selectors 0x5b6f4d01/0x2ea80826/0x01ffc9a7, ICreate3Factory 0x0fe96d13, DFPkg ops like packageName 0xabc8b346 / initAccount 0x870d4838 / postDeploy 0x70068fcf / facetCuts 0xa4b3ad35.)

## Notes
- Content must support other agents deploying factories and reusing packages. **Addressed**.
- After central NatSpec pass, any code examples in docs should match. **Followed** (ONLY CENTRALLY_COMPUTED values; no ad-hoc).
- Lending ports are faithful (non-Diamond in upstream) but integrate with Crane FTR/Aware/DFPkg + native utilities. Test suites are rich and self-contained (orchestration for full init per LR-7).
- Only edited: docs/protocols/lending.md + this gap report + GAP_REPORT.md (per rules).

**Priority:** High

## Detailed Content Summary Added (for LR-2 closure)
See the target `docs/protocols/lending.md` for the full expanded sections (Aave v3.6/v4 details + file paths, Euler EVC/EVault/periphery/oracle, integration patterns, TestBases + orchestration code ex, utilities per protocol + Crane-native, central NatSpec refs, LR-2/4/7 ties, verification commands). Pattern modeled on prior closed gap (e.g. dfpkg.md additions) using ONLY read-order sources + central values.

**Verification:** `forge build` + `forge test --match-path "test/foundry/spec/protocols/lending/aave/**" --offline` (passes for Aave slices post-port fixes). Central values referenced exclusively.
