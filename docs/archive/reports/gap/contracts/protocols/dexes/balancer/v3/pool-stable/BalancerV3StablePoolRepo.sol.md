# Gap Report for: contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard

**Current State Summary:**
Source edits completed for scoped batch (with weighted sibling). ERC1967 slot fixed, dual _layoutStruct + all _* duals wrapped with exact // tag:: / // end:: (hyphenated) and rich NatSpec modeled on gold (BalancerV3VaultAwareRepo/OperableRepo/ERC20Repo/ERC2535Repo/EIP712Repo). No @custom needed (internal storage Repo; confirmed none in CENTRALLY_COMPUTED_NATSPEC_VALUES.md apply). Per-file gap and GAP_REPORT updated.

**Detailed Gaps (Closed):**
- LR-6: STORAGE_SLOT updated to exact `bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.pool.stable"))) - 1)`. Dual _layoutStruct implemented/used (internal calls to _layoutStruct() for default; param version used in all logic, incl. _getAmplificationParameter(layoutStruct) calls).
- LR-1: Full NatSpec + exact gold-standard tags for library (BalancerV3StablePoolRepo[]), STORAGE_SLOT, Storage, _layoutStruct(bytes32)[], _layoutStruct()[], _initialize(Storage-uint256)[], _initialize(uint256)[], _startAmplificationParameterUpdate(Storage-uint256-uint256)[], _startAmplificationParameterUpdate(uint256-uint256)[], _stopAmplificationParameterUpdate(Storage)[], _stopAmplificationParameterUpdate()[], _getAmplificationParameter(Storage)[], _getAmplificationParameter()[], _getAmplificationState(Storage)[], _getAmplificationState()[]. Rich @dev/@param/@return with "The Storage struct to operate on." + @custom:throws, modeled on gold. Strict use of CENTRALLY only (none for this).

**Specific Actions Completed:**
- Strict read order followed pre-edits (per-file gap, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD.md LR-1/6 sections, AGENTS.md (full relevant: Facet-Target-Repo, storage slots dual _layoutStruct, tag style, hyphenated overloads, rich NatSpec, Balancer pool context), source file, gold examples: BalancerV3VaultAwareRepo.sol + OperableRepo.sol + ERC20Repo.sol + EIP712Repo.sol).
- Source edits only (as allowed): slot fix to ERC1967 form, added/enriched tags + rich prose (preserved all logic; internal helper _stopAmplification left untagged).
- Note from CENTRALLY: no entries apply to this internal pool Repo (no fabricated customs).
- Verification (targeted only, after edits): `forge inspect contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolRepo.sol:BalancerV3StablePoolRepo (abi|storageLayout)`, `forge build --skip test --quiet` (via narrow specific-path build), `forge test --list --match-path '*BalancerV3*'` (narrow).

**NatSpec Symbols Tagged:**
- BalancerV3StablePoolRepo[], STORAGE_SLOT, Storage, _layoutStruct(bytes32)[], _layoutStruct()[], _initialize(Storage-uint256)[], _initialize(uint256)[], _startAmplificationParameterUpdate(Storage-uint256-uint256)[], _startAmplificationParameterUpdate(uint256-uint256)[], _stopAmplificationParameterUpdate(Storage)[], _stopAmplificationParameterUpdate()[], _getAmplificationParameter(Storage)[], _getAmplificationParameter()[], _getAmplificationState(Storage)[], _getAmplificationState()[]
- (16+ tags total on library/symbols; hyphenated overloads per AGENTS gold. Constants/errors kept/enhanced.)

**Testing Gaps (LR-7 specific if applicable):**
- (LR-7 not in target scope for this scoped LR-6+LR-1 Repo batch; see Balancer pool DFPkgs/Targets in other reports.)

**Documentation/Skills Gaps (if applicable):**
- (Protocol surface covered via BalancerV3VaultAwareRepo and dexes.md updates; this internal Repo now documented via tags.)

**Notes:**
- Scoped batch of 2 (weighted + stable PoolRepos). ONLY edited: 2 .sol + their 2 per-file .md + GAP_REPORT.md (5 files max).
- Strict order followed, centrals only (none), targeted cmds only post-edit.
- LR-6 + LR-1 CLOSED. Use relative paths in final writeup.
- Status: **CLOSED**

**Priority:** High — CLOSED
