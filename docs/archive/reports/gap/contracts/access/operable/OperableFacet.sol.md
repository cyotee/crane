# Gap Report for: contracts/access/operable/OperableFacet.sol

**File Type:** Facet

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full rich + // tag:: + @custom ONLY from centrals + @inheritdoc IFacet)
- LR-7: Facet declaration tests use Behavior_IFacet (note only here; no test edits)

**Current State Summary:**
LR-1/LR-7 gaps for this Facet closed. (OperableFacet was partial: broken tags, insufficient @notice/@custom/@dev, incomplete surface doc for IFacet. No storage so LR-6 N/A. Follows Facet-Target-Repo; exposes IOperable surface via Target + IFacet.)

**Detailed Gaps (pre-fix):**
- LR-1: incomplete NatSpec with // tag:: and @custom: tags (per ERC8023/AGENTS gold).
- LR-1: Document facetName, facetInterfaces, facetFuncs, facetMetadata.
- LR-7: Declaration of facet*() via Behavior_IFacet (note; tests elsewhere use it for OperableFacet).

**Specific Actions Taken to Close Gaps:**
1. Strict read order 1-6 followed BEFORE ANY edit.
2. Wrapped with exact // tag::OperableFacet[] / facetName()[] / facetInterfaces()[] / facetFuncs()[] / facetMetadata()[] (~5 pre tags; full documented surface incl. note on exposed IOperable publics).
3. Rich NatSpec + @custom ONLY from CENTRALLY for IFacet + @inheritdoc IFacet. Modeled on facet golds.
4. Per-file gap + GAP_REPORT updated with [x] LR-1 (LR-7: declaration via Behavior_IFacet; no test edit).
5. Post: targeted inspect (abi|methodIdentifiers), build specific --skip --quiet. Tags/build/health reported.
- Only this .sol + gap.md + GAP_REPORT.md edited (relative). No other changes. LR-6 N/A.

**NatSpec Symbols Tagged (full documented surface, ~5 tags):**
- OperableFacet[]
- facetName()[]
- facetInterfaces()[]
- facetFuncs()[]
- facetMetadata()[]
(Note: IOperable publics e.g. isOperator(address), isOperatorFor(bytes4,address) etc exposed via facet inheritance; tags reside in OperableTarget per pattern. Used IOperable customs + IFacet from CENTRALLY.)

**LR-7 Note (declaration via Behavior_IFacet; no test edit per strict rules):**
Facet declaration (facetInterfaces() + facetFuncs() matching expected for IOperable + IFacet) validated using Behavior_IFacet (see TestBase_IFacet, PRD LR-7, golds). Pre-existing coverage in access/operable tests + DevEnv (Behavior usage + exact decl asserts); note here only.

**Documentation/Skills Gaps (if applicable):**
- Handled by this scoped update (LR-2/3 out of this task scope per "ONLY this .sol + its gap + GAP_REPORT").

**Reads Log (exact order before edit):**
1. docs/reports/gap/contracts/access/operable/OperableFacet.sol.md
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IFacet + IOperable refs only)
3. PRD.md (LR-1 + LR-7 Behavior_IFacet)
4. AGENTS.md (facet IFacet impl + tags + 3files/relative/targeted)
5. Golds: Operable context + ERC165/ERC20/WETHAware/FacetRegistry Facets + Behavior_IFacet + TestBase_IFacet
6. contracts/access/operable/OperableFacet.sol (surface parse: facet* + operable via inherit)

**Status: LR-1 CLOSED (LR-7 noted).** Pre tags ~5. Full surface. Targeted verif passed. Only 3 relative files.

**Priority:** High (core framework files)
