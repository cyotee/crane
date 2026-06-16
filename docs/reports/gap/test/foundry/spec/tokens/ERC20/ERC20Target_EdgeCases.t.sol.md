# Gap Report for: test/foundry/spec/tokens/ERC20/ERC20Target_EdgeCases.t.sol

**File Type:** Test (spec, ERC20 edge cases via DFPkg + Behavior)

**Primary Affected Requirements (from PRD):**
- LR-7: Testing Standards (full real non-0 init via InitDevService/CraneTest, exact asserts, Behavior_IFacet for declaration since facets involved, NatSpec on test code)
- LR-1: NatSpec on test code (// tag:: + @custom using central values)

**Current State Summary:**
Gaps closed for this file (edge case tests for ERC20Target/DFPkg proxy). Explicit setUp full init (real non-0 ERC20Facet + ERC20DFPkg via InitDevService + deployPackageWithArgs; labels; no lazy/address(0)), Behavior_IFacet.expect for facetName/interfaces (using central IFacet values), _deployToken override with real DFPkg.deploy, exact asserts throughout (assertEq with INITIAL_SUPPLY/precise deltas, no side-effect 'changed' checks). Added NatSpec + exact // tag::[] / end:: on contract + several tests + _deployToken_override. References ONLY central NatSpec values (IFacet 0x5b6f4d01 etc from CENTRALLY_COMPUTED_NATSPEC_VALUES.md) + LR-7 rules (full init, exact, Behavior for decl). Strict read order followed. Only edited: this .t.sol + its gap report + GAP_REPORT.md.

**Detailed Gaps (addressed):**
- LR-7: Full initialization (real DFPkg/facet + handler), exact value assertions (precise balances/deltas), use of Behavior_IFacet for declaration (facets in init), NatSpec on test code.
- LR-1: Add full NatSpec + // tag:: + @custom:signature/@custom:selector on contract + tests using central values.

**Specific Actions Taken to Close Gaps:**
1. Full LR-7 init in setUp override (InitDevService + real ERC20DFPkg deploy + labels + super/TestBase_ERC20; never address(0)).
2. Added Behavior_IFacet.expect for facet surfaces (central values only).
3. _deployToken override uses real DFPkg (production-like Diamond proxy).
4. Exact asserts (assertEq with INITIAL_SUPPLY, assertTrue success, precise after-transfer values).
5. Added full NatSpec + exact gold-standard // tag::Name()[] / end:: + @custom on contract + tests (using ONLY central).
6. Updated per-file gap + GAP_REPORT.md. Strict process + verification.

**NatSpec Symbols Tagged (using ONLY central for customs):**
From CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IFacet + IDiamondFactoryPackage):
- facetName() : 0x5b6f4d01
- facetInterfaces() : 0x2ea80826
- (and related for DFPkg surfaces as in sibling ERC20DFPkg test)

Test symbols (with tags):
- ERC20Target_EdgeCases (contract)
- setUp()
- _deployToken(ERC20TargetStubHandler)  [// tag::deployToken_override[]]
- test_transfer_zeroAmount_succeeds()
- test_transfer_toSelf_succeeds()
- test_transfer_emitsEvent()
- ... (other transfer/approve/transferFrom edge cases)

**Testing Gaps (LR-7 specific - CLOSED):**
- Full initialization of subjects (real non-0 DFPkg/facet via InitDev + diamondFactory; no 0).
- Exact assertions vs side-effect (assertEq with INITIAL_SUPPLY/precise values, no 'unchanged' vars).
- Use of Behavior_IFacet (expect for name/interfaces in setUp; declaration coverage).
- NatSpec + tags on test code (contract + tests + override).
- Proper TestBase/CraneTest usage (inheritance + init order).

**Documentation/Skills Gaps (if applicable):**
- Covered in crane-testing skill + development/testing.md + tokens/erc20.md (LR-2/3).

**Notes for Subagents:**
- Implemented only fixes for this file's gaps (source + gap report + GAP_REPORT.md).
- Used ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md for customs (strict read order: gap, central, PRD LR-7/LR-1, AGENTS, source).
- Verified: targeted forge test --list --match-path "*ERC20Target_EdgeCases*" + build/inspect paths (compile clean on edits).
- Updated this gap + main GAP_REPORT.md.

**Status:** LR-7 + LR-1 CLOSED.
**Priority:** High (core framework + ERC20 DFPkg reuse)
