# Gap Report for: test/foundry/spec/access/operable/Operable.t.sol

**File Type:** Test

**Primary Affected Requirements (from PRD):**
- LR-7: Testing Standards (full init no address(0) state, exact value assertions, mandatory Behavior lib usage for IFacet surfaces, facet declaration tests, proper init patterns, NatSpec on test code)
- LR-1: NatSpec Documentation Standard (on test code public surfaces)

**Current State Summary:**
Gaps closed for this file (core access control functional test using OperableTargetStub + added LR-7 facet declaration). Enhanced setUp with explicit full init (real owner init on stub, labels, no zeros), converted loose assertTrue/False "should" style + messages to exact assertEq(actual, expected), added Behavior_IFacet usage (expect/hasValid for name/interfaces/funcs + metadata_consistency), added dedicated LR-7 declaration test for OperableFacet using Behavior. Added NatSpec + // tag::[] / @custom on contract + new LR7 test fn (referencing central IOperable/IFacet values). No other files edited. Targeted test + build verification done.

**Detailed Gaps (addressed):**
- LR-7: Ensure full initialization (no address(0) facets in pkgs), exact value assertions (not just 'changed'), use of Behavior libs, declaration tests for facets/packages.
- LR-1: Add NatSpec to test code where public.

**Specific Actions Taken to Close Gaps:**
1. Updated setUp() with LR-7 full init comments (real OperableTargetStub(owner) providing initialized state; vm.label; explicit no-lazy).
2. Changed multiple asserts to exact expected values: assertEq(operable.isOperator(x), true/false, "exact...") instead of assertTrue/False with "Should..." descriptions.
3. Added Behavior_IFacet calls in new LR-7 test (expect_IFacet_* + hasValid + isValid_..._consistency).
4. Added facet declaration test (test_LR7_OperableFacet_declaration_viaBehavior) covering name, interfaces (IOperable 0xa7f11160), funcs (4 selectors), metadata.
5. Added NatSpec + hyphenated // tag:: / end:: on contract (OperableTest[]) and the LR-7 test fn. Used ONLY central values in docs/comments for known symbols.
6. Referenced AGENTS.md crane-testing, PRD LR-7, CENTRALLY... throughout.

**NatSpec Symbols Tagged (with values from central):**

From CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY these for known symbols):
### IOperable
- interfaceId: 0xa7f11160
**Events**
- NewGlobalOperatorStatus(address,bool) topic0: 0x26ba28058a3c072a70c8fd315037fe9b3957237cef5c61a9652a8da41c673daa
- NewFunctionOperatorStatus(address,bytes4,bool) topic0: 0xf071216dc06459e77b915d1883909d92f41239172000b60261dfdc0351889569
**Errors**
- NotOperator(address) selector: 0x76c6c93a
**Functions**
- isOperator(address) : 0x6d70f7ae
- isOperatorFor(bytes4,address) : 0xea562a25
- setOperator(address,bool) : 0x558a7297
- setOperatorFor(bytes4,address,bool) : 0x755dbe7c

### IFacet (common, for Behavior declaration)
- facetName() : 0x5b6f4d01
- facetInterfaces() : 0x2ea80826
- facetFuncs() : 0x574a4cff
- facetMetadata() : 0xf10d7a75
- supportsInterface(bytes4) : 0x01ffc9a7

Test symbols (for central follow-up pass):
- OperableTest
- test_LR7_OperableFacet_declaration_viaBehavior()

(No events/errors on test surface beyond imported I*.)

**Testing Gaps (LR-7 specific if applicable) - Closed for file:**
- Full initialization of subjects: setUp deploys/constructs real initialized stub + facet in test (no address(0)); comments reference no lazy pkgs/facets.
- Exact assertions vs side-effect: all key isOperator/isOperatorFor now use assertEq(exact bool) with precise messages; result values already exactEq; events use expectEmit.
- Use of Behavior_IFacet: added (mandatory per LR-7 for IFacet surfaces).
- Declaration tests for facets: new dedicated test_LR7_... using Behavior_IFacet.expect + hasValid for OperableFacet (interfaces match IOperable id from central, funcs exact count+values, name, metadata consistency).
- Correct TestBase/CraneTest: setUp comments tie to proper init order per AGENTS + LR-7 (direct Test ok as access logic test, consistent with other access tests; no duplication of factory init needed here).
- Access control matrix covered (owner, global op, func op, non-op paths + reverts).
- NatSpec + tags on test public code (contract + LR7 test).

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3).

**Notes for Subagents:**
- Implemented only fixes for this file's gaps (test source + this gap report + GAP_REPORT.md).
- Used ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IOperable + IFacet) + PRD.md (LR-1/LR-7) + AGENTS.md (NatSpec, testing patterns, Behavior) + source (Operable.t.sol + OperableFacet/IOperable/Behavior_IFacet) + strict read order.
- Update the main GAP_REPORT.md checkbox when done.
- Do not edit other files.
- forge build + targeted `forge test --match-path test/foundry/spec/access/operable/Operable.t.sol` executed.

**Status:** [x] Gaps closed.
**Priority:** High (core framework files)
