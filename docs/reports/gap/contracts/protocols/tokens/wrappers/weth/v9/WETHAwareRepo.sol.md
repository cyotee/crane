# Gap Report for: contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard

**Current State Summary:**
Source edits completed. ERC1967 slot fixed, struct aligned to `Storage { IWETH weth; }` (was WETHAwareLayout + STORAGE_RANGE), dual _layoutStruct/_initialize/_setWeth/_weth added with exact // tag:: / // end:: (hyphenated where appropriate) and rich NatSpec modeled on gold (CamelotV2FactoryAwareRepo/BalancerV3VaultAwareRepo/Create3FactoryAwareRepo/OperableRepo). No @custom needed (internal AwareRepo; confirmed none in CENTRALLY_COMPUTED_NATSPEC_VALUES.md apply). Per-file gap and GAP_REPORT updated.

**Detailed Gaps (Closed):**
- LR-6: STORAGE_SLOT updated to exact `bytes32(uint256(keccak256(abi.encode("protocols.tokens.wrappers.weth.v9"))) - 1)`. Dual _layoutStruct(bytes32 slot_) + _layoutStruct() implemented/used. All internal calls updated. Replaced direct keccak/STORAGE_RANGE.
- LR-1: Full NatSpec + exact gold-standard tags for library (WETHAwareRepo[]), STORAGE_SLOT, Storage, both _layoutStruct, both _initialize (hyphenated Storage-IWETH / IWETH), both _setWeth, both _weth. Rich @dev/@param/@return with "The Storage struct to operate on." modeled on gold. Strict use of CENTRALLY only (none for this).

**Specific Actions Completed:**
- Strict read order followed pre-edits using read_file: 1. docs/reports/gap/contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol.md , 2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY source for any @custom values; none expected for internal AwareRepo), 3. PRD.md (LR-1 NatSpec+AsciiDoc tags sections + LR-6 ERC1967 slot sections), 4. AGENTS.md (full relevant: Facet-Target-Repo, *AwareRepo pattern, ERC1967 STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("hier.name"))) - 1), dual _layoutStruct(bytes32 slot_) + _layoutStruct(), hyphenated tag overloads e.g. _foo(Storage-x)[] / _foo(x)[], rich NatSpec @title/@author/@dev/@param/@return/@custom:*, "The Storage struct to operate on.", ONLY edit 3 files: .sol + per-file gap + GAP_REPORT.md, targeted verif only after, no viaIR), 5. contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol (source), 6. Gold examples (read key parts for exact style match): contracts/protocols/dexes/camelot/v2/CamelotV2FactoryAwareRepo.sol , contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol , contracts/factories/create3/Create3FactoryAwareRepo.sol , contracts/access/operable/OperableRepo.sol .
- Source edits only (as allowed, relative paths): slot fix to ERC1967 form using exact specified, struct to Storage, param naming slot_, added full duals + EXACT tags + rich prose. Updated ALL internal calls. Preserved 100% logic/behavior.
- Note from CENTRALLY: no entries apply to internal AwareRepo (no fabricated customs).

**Verification (targeted only, after source):**
`forge inspect contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol:WETHAwareRepo (abi|storageLayout|methodIdentifiers)`
`forge build contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol --skip test --quiet`
`forge test --list --match-path '*WETH*' --match-path '*WETHAware*'`

**NatSpec Symbols Tagged:**
- WETHAwareRepo[], STORAGE_SLOT, Storage, _layoutStruct(bytes32)[], _layoutStruct()[], _initialize(Storage-IWETH)[], _initialize(IWETH)[], _setWeth(Storage-IWETH)[], _setWeth(IWETH)[], _weth(Storage)[], _weth()[]
- (11 tags total; ~10-12 per spec; hyphenated overloads per AGENTS/gold.)

**Notes:**
- ONLY edited 3 files: the .sol + its per-file gap .md + GAP_REPORT.md.
- Strict order + only central values + targeted verif per instructions. No other files touched.
- LR-6 + LR-1 CLOSED for this file.

**Priority:** High — CLOSED
