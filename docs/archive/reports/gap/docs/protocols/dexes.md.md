# Gap Report for: docs/protocols/dexes.md

**File Type:** Documentation

**Primary Affected Requirements (from PRD):**
LR-2 (GitBook-Formatted Documentation — detailed ported protocol explanations, test usage with TestBases/stubs, protocol-specific utilities, cross-links; also ties to LR-7 testing standards and LR-3 skills)

**Current State Summary:**
Before: Stub file with only high-level bullet list of skills and one-sentence mentions of TestBases/ConstProdUtils. Did not address LR-2 requirements for detailed explanations of "how to integrate and use them", "how to use them inside tests (TestBases, stubs, etc.)", or "detailed coverage of all protocol-specific utility libraries" (ConstProdUtils + services for Camelot/Aerodrome/Uniswap etc.). No concrete inheritance examples, no Balancer DFPkg/facet test usage, insufficient cross-links. (Per strict read of this gap report + CENTRALLY_COMPUTED_NATSPEC_VALUES.md + PRD LR-2 + AGENTS.md + source dexes.md + key contracts/protocols/dexes/* files.)

After closure (this pass): Full LR-2 fleshing per instructions. Used ONLY central values (e.g. IFacet selectors 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75, IDiamondFactoryPackage 0xabc8b346, IDiamondPackageCallBackFactory 0x949da331, postDeploy 0x70068fcf etc.) for any interface examples in the doc. Focused exclusively on LR-2 content for this dexes doc (test usage, TestBases, stubs, Behaviors/declaration, protocol utils e.g. ConstProdUtils for Camelot/Aerodrome/etc., cross-links). No other files edited.

**Detailed Gaps (now closed for this file):**
- LR-2: Missing detailed content on protocol test usage (TestBases, stubs, Behaviors), utilities/Sets (here: ConstProdUtils + cross-protocol services; refs to Sets elsewhere per LR-2), cross-links, and how the DEX ports fit the reusable Diamond/DFPkg model (incl. explicit reuse of DiamondPackageCallBackFactory).
- Insufficient coverage of specific TestBase inheritance (Weth9 -> Camelot/Aerodrome/Uniswap/Balancer variants), handlers, IFacet declaration tests for Balancer pool facets, fork vs unit distinction, and exact usage patterns for services + quoting parity.
- No GitBook-ready sections enabling agents to use DEXes inside tests or consumer Diamonds.

**Specific Actions Taken to Close Gaps (limited to allowed edits):**
1. Read in strict order: 1. this gap report, 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY those values used for selectors in doc examples), 3. PRD.md (LR-2 full text + related), 4. AGENTS.md (dex structure, TestBase patterns, Behavior, ConstProd, stubs, Camelot/Aerodrome/Balancer examples), 5. the source doc + referenced sources (all TestBase_*.sol, services/*.sol, stubs, handler, IFacet tests, ConstProdUtils, Balancer DFPkg tests, fork bases, etc.).
2. Completely rewrote docs/protocols/dexes.md with:
   - Overview tying to FTR+Service+DFPkg + reuse benefits (LR-4 alignment).
   - Protocol directory structure (per AGENTS).
   - Dedicated section on shared protocol utility ConstProdUtils with key functions, service usage examples, and direct test links (e.g. purchaseQuote_Camelot, Aerodrome fee calc, priceImpact).
   - Per-protocol sections (Camelot V2, Uniswap V2/V3/V4, Aerodrome V1+Slipstream, Balancer V3) with:
     - File layout.
     - Detailed TestBases (inheritance, what setUp does, provided state like routers/factories/pools, pool creation helpers).
     - Stubs usage (deployed inside bases for unit tests).
     - Services + AwareRepos.
     - Specific test patterns: handlers (CamelotV2Handler for invariants), declaration/IFacet tests (Balancer pool facets using Behavior_IFacet patterns + central selectors e.g. facetName() 0x5b6f4d01), DFPkg integration tests (real facets, full init), ConstProd parity.
     - Fork bases noted.
   - "Using DEX Integrations in Tests" summary with 7 best-practice steps covering full init, exact asserts, Behavior usage, AwareRepos + CraneTest factories, quoting parity.
   - Cross-links to CODEBASE_MAP, lifecycle docs, AGENTS.md, testing.md, deployment/dfpkg.md, reference/agent-skills, specific spec test paths, central interface selectors (from CENTRALLY... only).
3. Updated this gap report (and will update GAP_REPORT.md).
4. No NatSpec work on .sol (not applicable; this was docs gap; template NatSpec notes left but scoped to doc examples only using central values).

**NatSpec Symbols (for doc examples only):**
Used ONLY central values in the updated dexes.md for referenced interfaces (no source .sol edits here):
- IFacet: facetName() 0x5b6f4d01, facetInterfaces() 0x2ea80826, facetFuncs() 0x574a4cff, facetMetadata() 0xf10d7a75.
- IDiamondFactoryPackage methods (e.g. packageName() 0xabc8b346, facetCuts() 0xa4b3ad35, initAccount() 0x870d4838, postDeploy() 0x70068fcf).
- IDiamondPackageCallBackFactory interfaceId 0x949da331.

**Testing Gaps (LR-7) addressed via doc (no test file edits per rules):**
- Documents full initialization of subjects (real facet addresses to DFPkgs, TestBase guard `if (address(x) == address(0))`).
- Exact assertions vs side effects + preview/execute parity (service quote vs router + ConstProdUtils in tests).
- Use of Behavior_IFacet / declaration tests for facets/packages (Balancer *IFacet.t.sol + core Behavior/TestBase_IFacet).
- References handler pattern for invariants.

**Documentation/Skills Gaps closed for this surface:**
- Now GitBook-ready LR-2 content for DEX protocols with test usage + utilities.
- Enables skills (cross-ref to crane-testing, crane-deployment, protocol skills) and getting-started/SUMMARY links (existing SUMMARY entry to dexes.md now points to rich content).
- Ties protocols back to CREATE3/DFPkg reuse (DiamondPackageCallBackFactory reuse + registries for facets/packages) without duplicating other docs.

**Notes for Subagents:**
- Only edited: docs/protocols/dexes.md + this gap report + GAP_REPORT.md.
- All content derived strictly from required read order + source exploration.
- Update the main GAP_REPORT.md checkbox when done (see below).

**Priority:** High (core framework files) — CLOSED.
