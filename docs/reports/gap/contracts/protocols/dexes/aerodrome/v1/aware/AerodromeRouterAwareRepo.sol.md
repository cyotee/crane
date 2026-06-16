# Gap Report for: contracts/protocols/dexes/aerodrome/v1/aware/AerodromeRouterAwareRepo.sol

**Status: LR-6 + LR-1 CLOSED**

**File Type:** Repo (internal *AwareRepo)

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; hyphenated overload tags; no @custom on internals)

**Strict Process Followed (no skips):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/protocols/dexes/aerodrome/v1/aware/AerodromeRouterAwareRepo.sol.md
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (internal AwareRepo - NO @custom:selector etc values apply or fabricated)
3. Read relevant PRD.md sections for LR-1 (NatSpec, tags, central values only, gold ERC8023 style) and LR-6 (exact bytes32(uint256(keccak256(abi.encode("..."))) - 1) form, dual _layoutStruct(bytes32) + (), _initialize duals, getters duals, Storage struct, "The Storage struct to operate on.")
4. Read AGENTS.md sections on *AwareRepo, Facet-Target-Repo, storage slots, dual _layout, tag rules (hyphenated overloads e.g. _initialize(Storage-IRouter)[], _aerodromeRouter()[] ), rich NatSpec, param_ naming.
5. Read gold examples (full): UniswapV2FactoryAwareRepo.sol, UniswapV2RouterAwareRepo.sol, CamelotV2RouterAwareRepo.sol, BalancerV3VaultAwareRepo.sol, DiamondPackageCallBackFactoryAwareRepo.sol (just done), Create3FactoryAwareRepo.sol.
6. Then read the SOURCE: contracts/protocols/dexes/aerodrome/v1/aware/AerodromeRouterAwareRepo.sol

**ONLY 3 files edited:** the .sol + its per-file gap .md + GAP_REPORT.md (append matching [x] entry). No other files touched.

**Symbols with exact gold // tag:: / end:: (hyphenated for overloads):**
- // tag::AerodromeRouterAwareRepo[] ... // end::AerodromeRouterAwareRepo[]
- // tag::STORAGE_SLOT[] ... // end::STORAGE_SLOT[]
- // tag::Storage[] ... // end::Storage[]
- // tag::_layoutStruct(bytes32)[] ... // end::_layoutStruct(bytes32)[]
- // tag::_layoutStruct()[] ... // end::_layoutStruct()[]
- // tag::_initialize(Storage-IRouter)[] ... // end::_initialize(Storage-IRouter)[]
- // tag::_initialize(IRouter)[] ... // end::_initialize(IRouter)[]
- // tag::_aerodromeRouter(Storage)[] ... // end::_aerodromeRouter(Storage)[]
- // tag::_aerodromeRouter()[] ... // end::_aerodromeRouter()[]

**Current State Summary:**
Source edits completed. ERC1967 slot fixed to hierarchical protocols.dexes, full dual _layoutStruct/_initialize/_aerodromeRouter with exact // tag:: / // end:: (hyphenated) and rich NatSpec modeled on golds (UniswapV2*, CamelotV2Router, BalancerV3, Diamond recent). No @custom needed (internal AwareRepo; confirmed none in CENTRALLY apply). Per-file gap and GAP_REPORT updated.

**Detailed Gaps (Closed):**
- LR-6: STORAGE_SLOT updated to exact `bytes32(uint256(keccak256(abi.encode("protocols.dexes.aerodrome.v1.router.aware"))) - 1)`. Dual _layoutStruct implemented/used (no other slot refs inside file).
- LR-1: Full NatSpec + exact gold-standard tags for library (AerodromeRouterAwareRepo[]), STORAGE_SLOT, Storage, both _layoutStruct, both _initialize (hyphenated Storage-IRouter / IRouter), both _aerodromeRouter. Rich @dev/@param/@return with "The Storage struct to operate on." + @title/@author/@dev library header modeled on gold. Strict use of CENTRALLY only (none for this).

**Specific Actions Completed:**
- Strict read order followed pre-edits (per-file gap, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD.md LR-1/6 sections, AGENTS.md (full relevant: Facet-Target-Repo, storage slots dual _layoutStruct, tag style, hyphenated overloads, rich NatSpec, AwareRepo pattern, no viaIR), source file, gold examples: UniswapV2FactoryAwareRepo.sol, UniswapV2RouterAwareRepo.sol, CamelotV2RouterAwareRepo.sol, BalancerV3VaultAwareRepo.sol, DiamondPackageCallBackFactoryAwareRepo.sol, Create3FactoryAwareRepo.sol).
- Source edits only (as allowed): slot fix to ERC1967 form, added duals + tags + rich prose. Also normalized param names to slot_ per gold.
- Note from CENTRALLY: no entries apply to internal AwareRepo (no fabricated customs).
- Verification (targeted only): `forge inspect contracts/protocols/dexes/aerodrome/v1/aware/AerodromeRouterAwareRepo.sol:AerodromeRouterAwareRepo (abi|storageLayout)`, `forge build --skip test --quiet`, `forge test --list --match-path '*Aerodrome*'`. Confirmed tag count == 10.

**NatSpec Symbols Tagged:**
- AerodromeRouterAwareRepo[], STORAGE_SLOT, Storage, _layoutStruct(bytes32)[], _layoutStruct()[], _initialize(Storage-IRouter)[], _initialize(IRouter)[], _aerodromeRouter(Storage)[], _aerodromeRouter()[]
- (10 tags total on library/symbols incl. outer; hyphenated overloads per AGENTS/gold.)

**Notes:**
- ONLY edited 3 files: the .sol + its per-file gap .md + GAP_REPORT.md.
- Strict order + only central values + targeted verif per instructions.
- Commands used in process: read_file (gap, CENTRALLY, PRD, AGENTS, source, golds), grep/list_dir for discovery, then search_replace for the 3 files, then run_terminal for targeted verif cmds.
- LR-6 + LR-1 CLOSED for this file.

**Priority:** High — CLOSED
