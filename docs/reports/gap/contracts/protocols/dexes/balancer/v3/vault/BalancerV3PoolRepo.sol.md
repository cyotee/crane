# Gap Report for: contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc // tag::/end::), LR-6 (ERC1967 STORAGE_SLOT form).

**Current State Summary:**
Pre-fix: no NatSpec, no include-tags, STORAGE_SLOT used direct `keccak256("...")` (not ERC1967 bytes32(uint256(keccak(abi.encode))-1) form), param naming inconsistent with gold (slot vs slot_), insufficient dual docs.

**LR-6 + LR-1 CLOSED:** strict read order followed: 1. this per-file gap report, 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no entries for this internal repo; no @custom fabricated), 3. PRD.md (LR-1 + LR-6 sections), 4. AGENTS.md (full Repo pattern: ERC1967 bytes32(uint256(keccak...)-1) with STORAGE_SLOT, dual _layoutStruct, gold NatSpec/include-tags, hyphenated overload tags e.g. _initialize(Storage-...)[], layoutStruct param, "The Storage struct to operate on.", no viaIR), 5. source + gold examples (BalancerV3VaultAwareRepo, OperableRepo, ERC2535Repo, DeployedAddressesRepo, EIP712Repo, ERC20Repo etc.).

Fixed STORAGE_SLOT to exact ERC1967 form `bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.pool.common"))) - 1)`; full rich NatSpec + exact gold-standard // tag:: / // end:: for library (BalancerV3PoolRepo[]), STORAGE_SLOT, Storage, _layoutStruct(bytes32)[], _layoutStruct()[], dual _initialize (hyphenated overloads), and dual getters for all fields (_minimumInvariantRatio*2, _maximumInvariantRatio*2, _minimumSwapFeePercentage*2, _maximumSwapFeePercentage*2).

Rich @dev/@param/@return modeled on BalancerV3VaultAwareRepo / OperableRepo / ERC2535Repo golds (incl. "The Storage struct to operate on." and library header referencing recent golds). Used dual _layout internally. No @custom values (pure internal storage Repo per CENTRALLY).

ONLY edited exactly the 3 allowed files: this .sol + its per-file gap .md + GAP_REPORT.md. Targeted verification ONLY: `forge inspect contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol:BalancerV3PoolRepo (abi|storageLayout)`, `forge build --skip test --quiet`, `forge test --list --match-path '*BalancerV3*'`. Symbols covered (16 tags): BalancerV3PoolRepo, STORAGE_SLOT, Storage, _layoutStruct(bytes32), _layoutStruct(), _initialize(Storage-...), _initialize(...), _minimumInvariantRatio*2, _maximumInvariantRatio*2, _minimumSwapFeePercentage*2, _maximumSwapFeePercentage*2.

**Detailed Actions / Symbols List (post-edit):**
- Converted + tagged STORAGE_SLOT per LR-6 (exact form from task + BalancerV3VaultAwareRepo gold).
- Added // tag::BalancerV3PoolRepo[] ... // end::BalancerV3PoolRepo[] around whole lib.
- Added full dual layout tags + all active _* : 2x _initialize (with hyphenated (Storage-uint256-...-address[]-memory) ), 4 getter pairs with (Storage) and () variants.
- Rich NatSpec: @title/@author/@dev (refs golds + duals + "layoutStruct"), @param on all, @return, @dev "The Storage struct to operate on." for Storage-param overloads. No logic or field/comment changes.
- Updated internal param names (slot_ , *_ ) + calls minimally for gold/AGENTS compliance (no behavior change).
- 15+ include tags added. All per AGENTS.md exact style.

**Targeted Verification Performed (ONLY; no full test suite):**
- `forge inspect contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol:BalancerV3PoolRepo abi` : exit 0 ; empty table (expected for internal lib).
- `forge inspect ...:BalancerV3PoolRepo storageLayout` : exit 0 ; clean.
- `forge inspect ... methodIdentifiers` : exit 0 ; clean.
- `forge build contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol --skip test --quiet` : BUILD_EXIT=0 success.
- `forge test --list --match-path '*BalancerV3Pool*'` (and similar narrow '*BalancerV3*') : executed targeted (narrow; scan handled; no compile errors).
- Re-ran inspect post-edit: clean.

**Process Note:** Strict mandatory reads 1-5 completed before any edit. ONLY 3 files edited total. Referenced CENTRALLY... (prose). Used targeted cmds only. Modeled EXACTLY on gold BalancerV3*AwareRepo + Operable/ERC*Repos.

See GAP_REPORT.md [x] entry under LR-1/LR-6. CLOSED.
