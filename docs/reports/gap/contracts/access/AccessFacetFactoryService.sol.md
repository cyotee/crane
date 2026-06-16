# Gap Report for: contracts/access/AccessFacetFactoryService.sol

**File Type:** Source File (Library)

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec Documentation Standard), related LR-7 notes (core *Service used for full non-0 init of access facets in tests/TestBases; see usage in ReentrancyLock.t.sol, DiamondCutFacetDFPkg.t.sol, DevEnvSmokeTest etc.)

**Current State Summary:**
Prior to this closure pass: partial NatSpec (basic @title/@author/@notice/@param/@return) and partial // tag:: on library + 3 deploy* functions. Tags used simplified (address) param form rather than full/hyphenated style. No @dev, no @custom references to IFacet (even for return types). No end tag for the library symbol itself. This is a key *FactoryService (listed as gold pattern example in AGENTS.md alongside IntrospectionFacetFactoryService and InitDevService). LR-1 enrichment to full gold standard required (rich NatSpec modeled on closed services + ERC8023, exact tags with (ICreate3FactoryProxy), central values for referenced IFacet/IDiamond* surfaces). No storage (not a Repo; LR-6 n/a). No logic changes permitted -- additive NatSpec+tags only.

After edits: LR-1 CLOSED for this file. 4 symbols fully tagged with rich docs + central-sourced values (IFacet facet* selectors referenced for return types + IDiamondFactoryPackage flow mentions). See Verification and NatSpec Symbols Tagged sections below.

**Detailed Gaps (addressed):**
- LR-1: Incomplete rich NatSpec + include tags. (Closed.)
- LR-7 notes: This service is critical for "Full initialization of subjects" (real facets never address(0)) and declaration tests via Behavior_IFacet in consuming tests. No direct test changes here (scope limited to this .sol + its gap + GAP_REPORT.md).

**Specific Actions Taken to Close Gaps (additive only):**
1. Wrapped ALL symbols with exact // tag::Name(params)[] ... // end::Name(params)[] (library + 3 fns; improved param form to (ICreate3FactoryProxy) for consistency/hyphenated-overload style per AGENTS; preserved structure of existing partial tags).
2. Enriched to full gold LR-1: rich @title/@author/@notice/@param/@return/@dev on library and every internal function. Added @dev with CREATE3 salt details, LR-7 usage, references to IFacet + IOperable using ONLY values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no ad-hoc; e.g. 0x5b6f4d01 etc for facet*, 0xa7f11160 + sub-selectors for operable).
3. No @custom:selector added on the library fns themselves (they are internal non-interface; per closed examples like InitDevService/CamelotV2Service: only reference centrals in prose/docs where return types or flows mention; no fabrication).
4. No Repos here so no slot work. Pkg* structs rule n/a. Modeled exactly on *Service golds per AGENTS (InitDevService entry, Camelot/Aerodrome Services) + Create3/ERC8023 patterns.

**NatSpec Symbols Tagged (exact, post-edit):**
- AccessFacetFactoryService[] (library: full header NatSpec + @title/@author/@notice/@dev referencing IFacet 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75 + IDiamondFactoryPackage flow)
- deployMultiStepOwnableFacet(ICreate3FactoryProxy)[] (internal fn: @notice/@param/@return/@dev ; references EIP-8023 + IFacet)
- deployOperableFacet(ICreate3FactoryProxy)[] (internal fn: @notice/@param/@return/@dev ; IOperable interfaceId 0xa7f11160 + selectors 0x6d70f7ae etc from central)
- deployReentrancyLockFacet(ICreate3FactoryProxy)[] (internal fn: @notice/@param/@return/@dev ; + IFacet)
(4 tags total; all symbols now wrapped. No events/errors in this lib.)

**Verification (targeted ONLY, run after edits; never full suite):**
- `forge inspect contracts/access/AccessFacetFactoryService.sol:AccessFacetFactoryService (abi|methodIdentifiers)` (confirms library surface -- clean/empty as expected for pure internal lib; no public selectors exposed directly)
- `forge build --skip test --quiet` (BUILD_EXIT=0; clean compile of the service + dependents)
- `forge test --list --match-path '*AccessFacet*'` (or '*AccessFacetFactoryService*' / '*reentrancy*ReentrancyLock*' narrow; lists relevant using the service)
See closure summary + GAP_REPORT.md entry for outputs/summary. Used relative paths only.

**Notes for Subagents:**
- Strict read order followed BEFORE ANY edit: 1. docs/reports/gap/contracts/access/AccessFacetFactoryService.sol.md , 2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY for values; referenced IFacet/IOperable/IDiamond* prose; no fabrication), 3. PRD.md (focus LR-1 + LR-7 sections), 4. AGENTS.md (full: NatSpec+AsciiDoc tags, hyphenated for overloads, gold *Service e.g. Access/Introspection/InitDev + CamelotV2Service, rich @* , "layoutStruct" n/a here, Facet-Target-Repo, Pkg on iface etc), 5. source contracts/access/AccessFacetFactoryService.sol .
- ONLY edited exactly 3 files max: this .sol + its per-file gap .md + GAP_REPORT.md . Relative paths used. No other files.
- LR-1/LR-7 tie-in: this *Service enables LR-7 "full init" + Behavior declaration tests (real facets via deploy* in consuming tests).
- Centrals only: IFacet facet* from CENTRALLY (0x5b6f4d01 etc); IOperable values from CENTRALLY; no others invented.
- Preserved all original logic/comments/imports exactly. Additive NatSpec+tags+doc only.
- If per-file was stubby: now fully expanded like InitDevService / Balancer / CamelotV2Service closures (Current State, exact symbols, Verification cmds, Notes, closure).
- Update main GAP_REPORT.md with [x] using copy of style (e.g. InitDevService or Access mentions).

**Closure Summary:**
AccessFacetFactoryService - LR-1 CLOSED. Strict read order (per-file gap, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD LR-1/LR-7, AGENTS.md full, source) completed first. Enriched library + 3 deploy fns to gold LR-1 (rich NatSpec modeled on closed Access/Introspection/InitDev *Services + ERC8023/AGENTS; 4 exact // tag:: / end:: with (ICreate3FactoryProxy) param form for consistency; @title/@author/@notice/@param/@return/@dev + ONLY central IFacet 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75 + IOperable 0xa7f11160 etc; references IDiamondFactoryPackage flow). No logic change. ONLY 3 files edited (relative paths). Targeted verif: forge inspect ...AccessFacetFactoryService (abi|methodIdentifiers), forge build --skip test --quiet, forge test --list --match-path '*AccessFacet*'. See this per-file gap. (Contributes to core factories LR-1 for launch readiness.)

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3). (Addressed via prior docs updates referencing *Service pattern; no edit to docs here.)

**Priority:** High (core framework files) - CLOSED.
