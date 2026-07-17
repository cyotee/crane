# Gap Report for: contracts/registries/target/Behavior_ICallTargetRegistryManagement.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc tags)

**Current State Summary:**
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**6-Read Strict Recap (before ANY edit/search_replace):**
1. read_file docs/reports/gap/contracts/registries/target/Behavior_ICallTargetRegistryManagement.sol.md
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ICallTargetRegistryManagement values only: interfaceId 0x9400c76a, setDefaultCallTargetForID 0xaf87fa1d, setCallTargetForIDForCaller 0x3b873d77)
3. read_file PRD.md (focus LR-1 NatSpec + LR-7 Behavior mentions)
4. read_file AGENTS.md (Behavior libs section + NatSpec patterns, exact // tag::Name(params)[] hyphen overloads, gold examples Behavior_IFacet/Behavior_IERC165/Behavior_IDiamondLoupe, ONLY 3 files, relative, targeted verif)
5. Golds: read_file contracts/factories/diamondPkg/Behavior_IFacet.sol , read_file contracts/introspection/ERC165/Behavior_IERC165.sol , read_file contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol (rich title/author/notice/dev + @custom on funcSig_ + expect/isValid/hasValid with hyphen tags)
6. read_file contracts/registries/target/Behavior_ICallTargetRegistryManagement.sol (full re-read immediately before planning edits)

**Detailed Gaps (pre-edit):**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).

**Actions Taken to Close LR-1 (this file only):**
- Added rich NatSpec to library (modeled on golds with title/author/notice/dev refs in @dev).
- Wrapped all key symbols (library + _name + _errPrefix* (hyphen overloads) + funcSig_* + expect_* + hasValid_* + recInvariant_*) with EXACT // tag::Name(params)[] / end:: .
- Used @custom: ONLY from CENTRALLY on the funcSig_* (selectors + signatures).
- Preserved 100% logic, imports, forge-lint disables (no viaIR, relative paths, 3 files max). No Repos so no slot changes.
- Centrals referenced only from CENTRALLY_COMPUTED_NATSPEC_VALUES.md .

**NatSpec Symbols Tagged (exact match to source surface, count=13):**
- Behavior_ICallTargetRegistryManagement[]
- _name()[]
- _errPrefixFunc(string)[]
- _errPrefix(string-string)[] , _errPrefix(string-address)[]
- funcSig_setDefaultCallTargetForID()[]  (@custom:selector 0xaf87fa1d + sig from central)
- expect_setDefaultCallTargetForID(ICallTargetRegistryManagement-bytes4-address-bool)[]
- hasValid_setDefaultCallTargetForID(ICallTargetRegistryManagement-bytes4-address-bool)[]
- funcSig_setCallTargetForIDForCaller()[]  (@custom:selector 0x3b873d77 + sig from central)
- expect_setCallTargetForIDForCaller(ICallTargetRegistryManagement-bytes4-address-address-bool)[]
- hasValid_setCallTargetForIDForCaller(ICallTargetRegistryManagement-bytes4-address-address-bool)[]
- recInvariant_setDefaultCallTargetForID(ICallTargetRegistryManagement-bytes4-address-bool)[]
- recInvariant_setCallTargetForIDForCaller(ICallTargetRegistryManagement-bytes4-address-address-bool)[]
Pre: 0 -> Post: 13 tags.

**LR-7 Notes (no test edits per scope):**
- This Behavior supports LR-7 declaration/management tests for CallTarget registry (similar to Behavior_IFacet usage).
- Targeted verif only (no broad test runs).

**Verification Outputs (targeted only, relative):**
- forge inspect contracts/registries/target/Behavior_ICallTargetRegistryManagement.sol:Behavior_ICallTargetRegistryManagement (abi|methodIdentifiers) => exit 0 (public funcSigs shown).
- forge build contracts/registries/target/Behavior_ICallTargetRegistryManagement.sol --skip test --quiet => exit 0
- narrow forge test --list --match-path '*CallTarget*Behavior*' => executed (narrow per instructions; no compile failure).

**LR-1 CLOSED** (scoped to this ONE file; ONLY edited: contracts/registries/target/Behavior_ICallTargetRegistryManagement.sol + docs/reports/gap/contracts/registries/target/Behavior_ICallTargetRegistryManagement.sol.md + GAP_REPORT.md ; strict read order + relative + centrals + targeted verif followed exactly. 13 tags.)
