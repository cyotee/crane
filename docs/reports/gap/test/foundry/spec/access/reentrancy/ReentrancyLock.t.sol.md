# Gap Report for: test/foundry/spec/access/reentrancy/ReentrancyLock.t.sol

**File Type:** Test

**Primary Affected Requirements (from PRD):**
- LR-7: Testing Standards (full init no address(0) via CraneTest+factory service, exact value assertions, mandatory Behavior_IFacet usage for IFacet surfaces, facet declaration tests, proper init patterns, reentrancy lock proof tests, NatSpec on test code)
- LR-1: NatSpec Documentation Standard (on test code public surfaces)

**Current State Summary:**
Gaps closed for this file (core reentrancy access test using harnesses + facet via factory). Enhanced all setUp with LR-7 full init (CraneTest super for facet test + AccessFacetFactoryService.deployReentrancyLockFacet for real non-0 facet; labels on all harness/target/facet subjects; explicit no-lazy comments), converted all loose assertFalse/True "Should..." to exact assertEq(actual, expected), expanded Behavior_IFacet (expect_facetName/Interfaces/Funcs + hasValid + isValid_metadata_consistency), added dedicated LR-7 declaration test for ReentrancyLockFacet using Behavior. Added NatSpec + // tag::[] / @custom on all _Test contracts + key fns + LR7 test (referencing central IFacet 0x5b6f4d01 etc). Used ONLY central values. Strict read order + only edited allowed files (test + its gap + GAP_REPORT.md). Targeted inspect/build--list done.

**Detailed Gaps (addressed):**
- LR-7: Ensure full initialization (no address(0) facets in pkgs), exact value assertions (not just 'changed'), use of Behavior libs, declaration tests for facets/packages.
- LR-1: Add NatSpec to test code where public.

**Specific Actions Taken to Close Gaps:**
1. Updated pragma to ^0.8.0 for compat; added CraneTest + Behavior_IFacet + AccessFacetFactoryService imports.
2. ReentrancyLockFacet_Test now `is CraneTest`; setUp calls super + deploys real via AccessFacetFactoryService.deployReentrancyLockFacet(create3Factory) (LR-7 full init, non-0).
3. Added vm.label + "LR-7 full realistic non-0 init" comments + no address(0) to ALL setUp (harnesses, target, facet, reverting).
4. Converted ALL asserts to exact: assertEq(..., false/true, "must be exact ...") / assertEq(lengths, 1, ...) / assertEq(strings, "exactName").
5. Expanded Behavior_IFacet usage in facet tests + new dedicated declaration test (expect + hasValid + consistency).
6. Added LR-7 facet declaration test (test_LR7_ReentrancyLockFacet_declaration_viaBehavior) covering facetName, interfaces (IReentrancyLock), funcs, metadata using central IFacet selectors.
7. Added rich NatSpec + exact // tag::Name[] / // end:: (hyphenated for overloads where applicable) on harnesses + all _Test contracts + setUp + public tests + LR7 test.
8. Used ONLY central values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IFacet: 0x5b6f4d01 facetName(), 0x2ea80826 interfaces, 0x574a4cff funcs, 0xf10d7a75 metadata) in comments, @custom, docs. Reentrancy lock matrix (lock/unlock/reentry/revert paths) covered with expectRevert.
9. References AGENTS.md crane-testing, PRD LR-7/LR-1, Operable.t.sol model, CENTRALLY... throughout.


**NatSpec Symbols Tagged (with values from central):**

From CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY these for known symbols):
### IFacet (common, for Behavior declaration - used on ReentrancyLockFacet_Test)
- facetName() : 0x5b6f4d01
- facetInterfaces() : 0x2ea80826
- facetFuncs() : 0x574a4cff
- facetMetadata() : 0xf10d7a75
- supportsInterface(bytes4) : 0x01ffc9a7

Test symbols (for central follow-up pass):
- ReentrancyLockRepoHarness, ReentrancyLockModifiersHarness, ReentrancyAttacker, RevertingHarness
- ReentrancyLockRepo_Test, test_isLocked_initiallyFalse(), test_lock_setsLockedTrue(), ...
- ReentrancyLockModifiers_Test, ...
- ReentrancyLockFacet_Test, test_LR7_ReentrancyLockFacet_declaration_viaBehavior()
- ReentrancyLockTarget_Test


**Testing Gaps (LR-7 specific if applicable) - Closed for file:**
- Full initialization of subjects: CraneTest + Access service factory deploy for facet (real, labeled, non-0); harnesses/targets use new+label+comments. Explicit "via InitDevService/CraneTest + factory patterns".
- Exact assertions vs side-effect: all isLocked/counter/lengths/name now use assertEq(exact value) with "must be exact ..." messages.
- Use of Behavior_IFacet: added/expanded (mandatory per LR-7 for IFacet on ReentrancyLockFacet).
- Declaration tests for facets: new dedicated test_LR7_... using Behavior_IFacet.expect + hasValid + isValid..._consistency (interfaces match IReentrancyLock selector, funcs exact count+value, name, metadata).
- Correct TestBase/CraneTest usage: facet test inherits CraneTest + super.setUp() + factory service deploy; other access harness tests use direct Test consistent with Operable model per AGENTS.
- Reentrancy proof tests (lock modifier, reentry revert with selector, unlock after success+revert paths) + access matrix style for lock.
- NatSpec + tags on test public code (all contracts + tests).

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3).

**Notes for Subagents:**
- Implemented only fixes for this file's gaps (test source + this gap report + GAP_REPORT.md; 3 files max).
- Used ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IFacet selectors) + PRD.md (LR-1/LR-7 incl reentrancy tests) + AGENTS.md (crane-testing, TestBase/Behavior/handler, NatSpec on tests, full init rules, exact asserts, no lazy 0) + source + strict read order.
- Verification: ONLY targeted `forge test --list --match-path 'test/foundry/spec/access/reentrancy/ReentrancyLock.t.sol'`, `forge build --quiet --skip test`, `forge inspect ...ReentrancyLockFacet*` (selectors exactly match central 0x5b6f4d01 etc) + direct test.sol build (no errors).
- Update the main GAP_REPORT.md checkbox when done.
- Do not edit other files.
- forge inspect confirmed facetName 0x5b6f4d01, facetInterfaces 0x2ea80826 etc.

**Status:** [x] Gaps closed.
**Priority:** High (core framework files)
