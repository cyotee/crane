# Gap Report for: contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard

**Current State Summary:**
Source edits completed. ERC1967 slot fixed, dual _layoutStruct/_initialize/_uniswapV2Factory added with exact // tag:: / // end:: (hyphenated where appropriate) and rich NatSpec modeled on gold (UniswapV2RouterAwareRepo/BalancerV3VaultAwareRepo/DiamondPackageFactoryAwareRepo/Create3FactoryAwareRepo/OperableRepo). No @custom needed (internal AwareRepo; confirmed none in CENTRALLY_COMPUTED_NATSPEC_VALUES.md apply). Per-file gap and GAP_REPORT updated.

**Detailed Gaps (Closed):**
- LR-6: STORAGE_SLOT updated to exact `bytes32(uint256(keccak256(abi.encode("protocols.dexes.uniswap.v2.factory.aware"))) - 1)`. Dual _layoutStruct implemented/used (no other slot refs inside file).
- LR-1: Full NatSpec + exact gold-standard tags for library (UniswapV2FactoryAwareRepo[]), STORAGE_SLOT, Storage, both _layoutStruct, both _initialize (hyphenated Storage-IUniswapV2Factory / IUniswapV2Factory), both _uniswapV2Factory. Rich @dev/@param/@return with "The Storage struct to operate on." modeled on gold. Strict use of CENTRALLY only (none for this).

**Specific Actions Completed:**
- Strict read order followed pre-edits (per-file gap, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD.md LR-1/6 sections, AGENTS.md (full relevant: Facet-Target-Repo, storage slots dual _layoutStruct, tag style, hyphenated overloads, rich NatSpec, AwareRepo pattern, no viaIR), source file, gold examples: UniswapV2RouterAwareRepo.sol , CamelotV2FactoryAwareRepo.sol , BalancerV3VaultAwareRepo.sol , Create3FactoryAwareRepo.sol , DiamondPackageFactoryAwareRepo.sol).
- Source edits only (as allowed): slot fix to ERC1967 form, added duals + tags + rich prose. Also normalized param names to slot_ , factory_ per gold.
- Note from CENTRALLY: no entries apply to internal AwareRepo (no fabricated customs).
- Verification (targeted only): `forge inspect contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol:UniswapV2FactoryAwareRepo (abi|storageLayout)`, `forge build --skip test --quiet`, `forge test --list --match-path '*UniswapV2Factory*'`.

**NatSpec Symbols Tagged:**
- UniswapV2FactoryAwareRepo[], STORAGE_SLOT, Storage, _layoutStruct(bytes32)[], _layoutStruct()[], _initialize(Storage-IUniswapV2Factory)[], _initialize(IUniswapV2Factory)[], _uniswapV2Factory(Storage)[], _uniswapV2Factory()[]
- (9+ tags total on library/symbols; hyphenated overloads per AGENTS/ gold.)

**Notes:**
- ONLY edited 3 files: the .sol + its per-file gap .md + GAP_REPORT.md.
- Strict order + only central values + targeted verif per instructions.
- Commands used in process: read_file (gap, CENTRALLY, PRD, AGENTS, source, golds), list_dir/grep for discovery (limited), then search_replace for the 3 files, then run_terminal for targeted verif.
- LR-6 + LR-1 CLOSED for this file.

**Priority:** High — CLOSED
