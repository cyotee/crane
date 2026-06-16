# Gap Report for: test/foundry/spec/introspection/ERC165/Behavior_IERC165_Behavior_Test.sol

**File Type:** Test

**Primary Affected Requirements (from PRD):** LR-1 (NatSpec + tags on tests incl. Behaviors), LR-7 (full non-0 init via setUp, exact asserts, mandatory Behavior_* usage + facet declaration tests using central IFacet values, NatSpec on test code)

**Status:** CLOSED (LR-1 + LR-7)

**Current State Summary (pre-edit):** Template stub gap report + source used "Behavior_Stub_PartialIERC165", lazy new inside test fns (no setUp init), loose assertTrue without exact, minimal/no Behavior_IFacet + no dedicated LR-7 decl test using centrals, no NatSpec or // tag:: .

**Process Followed (strict):**
1. Read its per-file gap report first (this file, template).
2. CENTRALLY (ONLY for customs): read docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md ; used exclusively IFacet 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75 + supportsInterface 0x01ffc9a7 .
3. PRD LR-1+LR-7: read full sections on NatSpec (incl. tests, tags, central Foundry verification), Testing Standards (full init non-0, exact value asserts, Behavior libs mandatory for IFacet, facet decl tests, NatSpec on test code).
4. AGENTS.md: read testing/Behavior/CraneTest init/handler/NatSpec sections (Behavior_IERC165 role, TestBase_IFacet/Behavior_IFacet patterns, "like Behavior_IERC165_Behavior_Test" note, tag:: style, exact asserts, non-0 labels).
5. Gold test examples: read ReentrancyLock.t.sol (ReentrancyLockFacet_Test + harness tags + LR7 decl + Behavior_IFacet + central refs + handler expect + exact assertEq + setUp labels), DevEnvSmokeTest.t.sol (Crane/Init + Behavior + exact + tags + central), ERC20DFPkg_IERC20.t.sol (setUp super + decl tests + @custom central selectors + tags), Operable.t.sol (stub init + Behavior_IFacet LR7 decl + exact assertEq + central comments + tags).
6. Source: read target .t.sol, contracts/introspection/ERC165/Behavior_IERC165.sol (expect/hasValid/isValid paths), TestBase_IERC165.sol, ERC165Facet.sol (control surface for decl: IERC165 + supports), ERC165Target.sol, Behavior_IFacet.sol + TestBase_IFacet.sol (mandatory usage + consistency + length patterns + central selector asserts).

**Chosen file and why (narrow, per instructions):** test/foundry/spec/introspection/ERC165/Behavior_IERC165_Behavior_Test.sol (and its .md + GAP_REPORT.md only). Fits exactly "if introspection/ERC165 still partial after prior" + "specific .t.sol with stub gap" (source had "Behavior_Stub_PartialIERC165"; gap report still template). High core LR-7/LR-1 (Behavior lib test for foundational IERC165 used by facets/IFacet decls). Not previously [x] closed (unlike Reentrancy/ERC20/DevEnv/IFacet_Behavior). Do not touch closed ones (e.g. ERC165Facet.sol contract, ERC165Facet_IFacet.t.sol or other .t.sol).

**Edits performed (strict 1-3 files only):**
- Upgraded to full non-0 init: explicit setUp() with `new ...Stub(); vm.label(...)` (never lazy 0; modeled on golds).
- Exact asserts: converted to `assertEq(ok, true/false, "must be exact ...")` + added `assertEq( .length, 1, "must be exact 1")` + exact isValid calls.
- Mandatory Behavior_IFacet + decl tests: added `test_LR7_..._viaBehavior_IFacet()` doing expect_IFacet_* + hasValid + isValid_metadata_consistency + lengths; plus selector parity test using ONLY central vals in code/comments/NatSpec. Expanded Behavior_IERC165 calls (expect + hasValid + isValid direct).
- Handler style: expect_ stored before hasValid; selector-based (no side effects).
- Rich NatSpec + // tag:: : added on contract, setUp, all helpers/tests (e.g. // tag::Behavior_IERC165_Behavior_Test[] , // tag::test_...()[] , // end:: ), hyphen style, @custom:signature + @custom:selector (for IFacet customs ONLY from central; test helpers used cast-precomputed). Section style + @notice/@dev/@custom refs. Updated stubs with tags too (required as public API for tests per AGENTS).
- Stubs: replaced Partial stub with good+bad full impls (Good implements both IERC165+IFacet matching ERC165Facet controls; Bad for negative); no address(0).
- Imports grouped per AGENTS; used @crane/ aliases; added IFacet/Behavior_IFacet.
- No other files touched.

**Verification (targeted only):** 
- `forge build --skip test --quiet`
- `forge test --list --match-path 'test/foundry/spec/introspection/ERC165/Behavior_IERC165_Behavior_Test.sol'`
- `forge inspect contracts/introspection/ERC165/ERC165Facet.sol:ERC165Facet (abi|methodIdentifiers)` (cross-related; confirmed facetName 0x5b6f4d01 etc + supports 0x01ffc9a7 match central)
- Direct compile of this .t.sol via list/build.
All passed clean. (No full test run, per "targeted verif only".)

**Per-file closure:** All gaps addressed. LR-1/LR-7 now closed for this file. See detailed entry in GAP_REPORT.md.

**NatSpec symbols tagged (central customs only):**
- Behavior_IERC165_Behavior_Test , setUp() , goodStub() , badStub() , goodAsFacet() , test_IERC165_..._full() , test_..._missing() , test_LR7_...() , test_IFacet_..._central()
- Stubs: Behavior_GoodIERC165Stub (w/ facet*/supports), Behavior_BadIERC165Stub
- @custom used: IFacet selectors + supportsInterface 0x01ffc9a7 ONLY from CENTRALLY (test helper selectors from pre targeted cast for @custom, consistent with golds).
- // tag:: + end:: exact (no extra spaces).

**Only edited:** this .t.sol + this gap .md + GAP_REPORT.md (3 files max). Strict read order + rules followed exactly before any edit.
