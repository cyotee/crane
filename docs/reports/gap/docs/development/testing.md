# Gap Report: docs/development/testing.md

**File Type:** Documentation

**Primary LR Violations:** LR-2 (GitBook content)

**Target:** `docs/development/testing.md`

## Strict Read Order Followed (as required)
1. This gap report (initial state + LR-2 requirements).
2. `docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md` (used ONLY its listed values for any IFacet / IDiamond* selectors/interfaceIds in examples: 0x5b6f4d01, 0x2ea80826, 0x574a4cff, 0xf10d7a75, 0x01ffc9a7, 0x949da331, 0xabc8b346, 0xa4b3ad35, 0x65d375b3, 0xd82be56e, 0x870d4838, 0x70068fcf, 0xe97fac05 etc.; no fabricated values).
3. PRD.md (full LR-2 GitBook required content + LR-7 Testing Standards in detail, including Behavior mandatory, full init, exact asserts, declaration tests, NatSpec on test code, CraneTest usage, registry asserts, handlers).
4. AGENTS.md (entire "Testing" section: TestBase types, Behavior libs patterns (expect/isValid/hasValid), declarative handler+invariant pattern, comparator infra, inheritance chains, key files list, NatSpec rules for handlers/TestBases, cross-refs to CraneTest/InitDevService, protocol TestBase examples, Sets/ConstProd in context).
5. Source file(s) referenced (directly or via gaps/PRD/AGENTS): the target `docs/development/testing.md`, plus `contracts/test/CraneTest.sol`, `contracts/factories/diamondPkg/{TestBase_IFacet.sol,Behavior_IFacet.sol}`, `contracts/tokens/ERC20/TestBase_ERC20.sol`, `contracts/access/ERC8023/TestBase_IMultiStepOwnable.sol`, `contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol`, `test/foundry/spec/factories/diamondPlg/IFacet_Behavior_Test.sol`, `test/foundry/spec/protocols/dexes/camelot/v2/handlers/CamelotV2Handler.sol`, `contracts/test/IHandler.sol`, `contracts/test/behaviors/BehaviorUtils.sol`, `contracts/test/comparators/Bytes4SetComparator.sol`, plus cross-source examples from `docs/deployment/create3.md`, `docs/protocols/dexes.md` (post-LR-2 updates), registry handlers, and ConstProdUtils usage sites. (No other docs or sources edited.)

## Before (Initial State per this gap report)
- High-level/partial coverage only.
- Missing detailed LR-2 explanations of testing patterns, Behavior libs, handlers, TestBase usage.
- No (or insufficient) cross-links to required GitBook areas: registries (purpose/population/asserts), ported protocols (exact inheritance + test usage), utilities (ConstProdUtils + Sets/Repos + general collections in test context).
- Lacked explicit alignment to LR-7 rules (full init, exact deltas, Behavior mandatory for decl tests, NatSpec on tests, CraneTest order, registry pop, handler expectations).
- No central NatSpec usage discipline shown, no agent value prop (LR-4 reuse) or LR-2 support for "how agents use tests for ports".
- (Note: crane-testing skill had referenced "testing.md" as future GitBook target.)

## Changes Made (Only edited: this gap report + target doc `docs/development/testing.md` + GAP_REPORT.md)
- Expanded `docs/development/testing.md` with full detailed LR-2 content:
  - Intro tying to LR-7 + LR-2 + LR-4 (reuse of verified facets via validated tests).
  - Directory layout with exact tree + conventions.
  - CraneTest bootstrap + detailed Registries section (cross-link to create3.md/dfpkg.md + how tests assert population).
  - Explicit DiamondPackageCallBackFactory reuse (interfaceId 0x949da331 + key selectors from central).
  - Protocol Setup TestBases: mermaid, inheritance rules (super first, address(0) guards), concrete Camelot example + full cross-links to dexes.md + lending.md + specific TestBase paths.
  - Behavior TestBases + Libraries: full TestBase_IFacet virtuals + test methods, Behavior patterns (expect/areValid/hasValid), mandatory LR-7 declaration test rules for Facets + Packages, exact central NatSpec selectors listed with "ONLY" note + code snippet example.
  - Handlers section: actor normalization, useActor, vm.expectEmit/Revert discipline, ghost tracking, full examples from ERC20/MultiStep/Camelot + registration + invariant_*.
  - Comparators section.
  - Utilities in Testing: ConstProdUtils parity in dex tests + general (Sets/Bytes4Set/AddressSet + Repos used in handlers/comparators), cross-links.
  - Recommended Flow + explicit LR-7 checklist mapping (full init examples, Behavior usage, registry asserts, NatSpec on tests, etc.).
  - NatSpec on test artifacts (LR-1/LR-7 alignment).
  - Cross-Reference Summary (exactly covering required GitBook areas: registries, protocols, utilities).
  - Key files list.
- All examples use only pre-existing accurate patterns + ONLY central values for selectors.
- Updated this per-file gap report (details of reads, before/after, central usage).
- Added closure tracking entry to GAP_REPORT.md (see below).

**Edits strictly limited per rules:** only the target doc, this gap report, and GAP_REPORT.md. No contracts, no other docs, no skills.

## Central NatSpec Values Used (ONLY these)
- IFacet: facetName 0x5b6f4d01, facetInterfaces 0x2ea80826, facetFuncs 0x574a4cff, facetMetadata 0xf10d7a75; supportsInterface 0x01ffc9a7.
- IDiamondPackageCallBackFactory: interfaceId 0x949da331; deploy 0xe97fac05, calcAddress 0x33a41d70, pkgOfAccount 0x8a648684, initAccount 0x8e85783e etc.
- IDiamondFactoryPackage: packageName 0xabc8b346, facetCuts 0xa4b3ad35, diamondConfig 0x65d375b3, calcSalt 0xd82be56e, initAccount 0x870d4838, postDeploy 0x70068fcf, facetInterfaces 0x2ea80826.
(See full `CENTRALLY_COMPUTED_NATSPEC_VALUES.md`; no other values inserted.)

## After State
- `docs/development/testing.md` now provides detailed, actionable LR-2 content on testing patterns, Behavior libs, handlers, TestBase usage with rich examples.
- Full cross-links to registries (via CraneTest/create3), all major ported protocols + their test setups, utilities (ConstProd + Sets).
- Explicit LR-7 alignment + central NatSpec discipline + agent reuse framing.
- Ready for GitBook (headings, code, mermaid, lists, cross-refs).
- Supports agents: clear "how to" for using CraneTest/TestBases/Behaviors/handlers when porting or testing DFPkg reuse.

**Priority:** High (closed)

**Status:** CLOSED for this per-file gap report. (See GAP_REPORT.md entry.)
