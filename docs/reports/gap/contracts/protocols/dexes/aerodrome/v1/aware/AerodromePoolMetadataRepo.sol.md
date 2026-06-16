# Gap Report for: contracts/protocols/dexes/aerodrome/v1/aware/AerodromePoolMetadataRepo.sol

**Status: LR-6 + LR-1 CLOSED**

**File Type:** Repo (internal *AwareRepo)

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; hyphenated overload tags; no @custom on internals)

**Strict Process Followed (no skips):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/protocols/dexes/aerodrome/v1/aware/AerodromePoolMetadataRepo.sol.md
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (internal AwareRepo - NO @custom:selector etc values apply or fabricated)
3. Read relevant PRD.md sections for LR-1 (NatSpec, tags, central values only, gold ERC8023 style with @dev/@param/@return) and LR-6 (exact bytes32(uint256(keccak256(abi.encode("..."))) - 1), dual _layoutStruct(bytes32 slot_)/(), _initialize duals, getters duals, struct Storage, "The Storage struct to operate on.")
4. Read AGENTS.md sections on *AwareRepo, Facet-Target-Repo, storage slots, dual _layout, tag rules (hyphenated overloads e.g. _initialize(Storage-IPoolFactory-bool)[], _factory()[] etc.), rich NatSpec, param_ naming, gold examples.
5. Read gold examples (full recent): the just-closed AerodromeRouterAwareRepo.sol, UniswapV2FactoryAwareRepo.sol, UniswapV2RouterAwareRepo.sol, CamelotV2RouterAwareRepo.sol, BalancerV3VaultAwareRepo.sol, DiamondPackageCallBackFactoryAwareRepo.sol, Create3FactoryAwareRepo.sol, OperableRepo.sol.
6. Then read the SOURCE: contracts/protocols/dexes/aerodrome/v1/aware/AerodromePoolMetadataRepo.sol

**ONLY 3 files edited:** the .sol + its per-file gap .md + GAP_REPORT.md (append matching [x] entry). No other files touched.

**Symbols with exact gold // tag:: / end:: (hyphenated for overloads):**
- // tag::AerodromePoolMetadataRepo[] ... // end::AerodromePoolMetadataRepo[]
- // tag::STORAGE_SLOT[] ... // end::STORAGE_SLOT[]
- // tag::Storage[] ... // end::Storage[]
- // tag::_layoutStruct(bytes32)[] ... // end::_layoutStruct(bytes32)[]
- // tag::_layoutStruct()[] ... // end::_layoutStruct()[]
- // tag::_initialize(Storage-IPoolFactory-bool)[] ... // end::_initialize(Storage-IPoolFactory-bool)[]
- // tag::_initialize(IPoolFactory-bool)[] ... // end::_initialize(IPoolFactory-bool)[]
- // tag::_factory(Storage)[] ... // end::_factory(Storage)[]
- // tag::_factory()[] ... // end::_factory()[]
- // tag::_isStable(Storage)[] ... // end::_isStable(Storage)[]
- // tag::_isStable()[] ... // end::_isStable()[]

**Current State Summary:**
Source edits completed. ERC1967 slot fixed to hierarchical protocols.dexes style, full dual _layoutStruct/_initialize/_factory/_isStable with exact // tag:: / // end:: (hyphenated) and rich NatSpec modeled on golds (AerodromeRouter just-closed + UniswapV2*, CamelotV2Router, BalancerV3, Diamond recent, Operable). No @custom needed (internal AwareRepo; confirmed none in CENTRALLY apply). Per-file gap and GAP_REPORT updated.

**Detailed Gaps (Closed):**
- LR-6: STORAGE_SLOT updated to exact `bytes32(uint256(keccak256(abi.encode("protocols.dexes.aerodrome.v1.pool.metadata.repo"))) - 1)`. Dual _layoutStruct implemented/used (no other slot refs inside file).
- LR-1: Full NatSpec + exact gold-standard tags for library (AerodromePoolMetadataRepo[]), STORAGE_SLOT, Storage, both _layoutStruct, both _initialize (hyphenated Storage-IPoolFactory-bool / IPoolFactory-bool), both _factory, both _isStable. Rich @dev/@param/@return with "The Storage struct to operate on." + @title/@author/@dev library header modeled on gold. Strict use of CENTRALLY only (none for this).

**Specific Actions Completed:**
- Strict read order followed pre-edits (per-file gap, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD.md LR-1/6 sections, AGENTS.md (full relevant: *AwareRepo, dual layout, hyphenated tag overloads e.g. _initialize(Storage-IPoolFactory-bool)[], rich NatSpec, param_ names, gold examples), gold examples in order, source file).
- Source edits only (as allowed): slot fix to ERC1967 form, added duals + tags + rich prose. Also normalized param names to slot_, factory_, isStable_ per gold.
- Note from CENTRALLY: no entries apply to internal AwareRepo (no fabricated customs).
- Verification (targeted only): `forge inspect contracts/protocols/dexes/aerodrome/v1/aware/AerodromePoolMetadataRepo.sol:AerodromePoolMetadataRepo (abi|storageLayout)`, `forge build --skip test --quiet`, `forge test --list --match-path '*Aerodrome*'`. Confirmed ~11 tags.

**Notes:**
- ONLY edited 3 files: the .sol + its per-file gap .md + GAP_REPORT.md.
- Strict order + only central values (none) + targeted verif per instructions.
- Commands used in process: read_file (gap, CENTRALLY, PRD, AGENTS, source, golds), grep/list_dir for discovery, then search_replace for the 3 files, then run_terminal for targeted verif cmds.
- LR-6 + LR-1 CLOSED for this file.

**Priority:** High — CLOSED
