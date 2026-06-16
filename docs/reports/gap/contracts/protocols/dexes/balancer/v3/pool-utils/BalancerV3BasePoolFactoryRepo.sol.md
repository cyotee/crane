# Gap Report for: contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc // tag::/end::), LR-6 (ERC1967 STORAGE_SLOT form).

**Current State Summary:**
Pre-fix (low tag 1): STORAGE_SLOT used direct `keccak256("...")` (not ERC1967 `bytes32(uint256(keccak(abi.encode(...)))-1)`), partial tags only on _layoutStruct (non-hyphen, incomplete), missing rich NatSpec + exact // tag::/end:: on library, STORAGE_SLOT, Storage, dual layouts, _initialize, all _* getters/setters (incl. isDisabled/disable/pause*/poolManager/pools-via-AddressSetRepo/tokensOf*/typeOf*/rateProvider*/paysYield*/hooks*/ + error), no "The Storage struct to operate on." or layoutStruct param gold style.

**LR-6 + LR-1 CLOSED:** strict read order followed before any edit: 1. this per-file gap report (docs/reports/gap/contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol.md), 2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY; no entries for this internal Balancer pool-utils Repo or its error; prose only - no @custom fabricated/inserted), 3. PRD.md (LR-1/LR-6 sections incl. exact ERC1967 form + NatSpec rules), 4. AGENTS.md (full relevant: ERC1967 STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("name")))-1), dual _layoutStruct, hyphen tags e.g. _initialize(Storage-uint32-address)[], rich NatSpec, "The Storage struct to operate on.", layoutStruct param, relative paths only, targeted verif only, ONLY 3 files), 5. Golds: recent Balancer pool Repos (BalancerV3PoolRepo.sol, BalancerV3WeightedPoolRepo.sol, BalancerV3StablePoolRepo.sol), CamelotV2FactoryAwareRepo.sol, OperableRepo.sol, FacetRegistryRepo.sol (for slot form, dual patterns, AddressSet via, rich headers, hyphen overloads, NatSpec phrasing), 6. Source (BalancerV3BasePoolFactoryRepo.sol).

Fixed STORAGE_SLOT to exact ERC1967 form using key "protocols.dexes.balancer.v3.base.pool.factory.common" -> `bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.base.pool.factory.common"))) - 1)`; ensured dual _layoutStruct(bytes32)[] / ()[] + updated internals (layoutStruct return/param); full rich NatSpec + EXACT gold // tag:: / // end:: for library (BalancerV3BasePoolFactoryRepo[]), STORAGE_SLOT, Storage, dual layouts, _initialize*2 (hyphenated overloads), error (PoolPauseWindowDurationOverflow[]), and ALL dual _* getters/setters (isDisabled*2, disable*2, ensureEnabled, pauseWindowDuration*2, pauseWindowEndTime*2, getPoolManager*2, addPool*2 (hyphen Storage-address), isPoolFromFactory*2 (hyphen), getPoolCount*2, getPoolsInRange*2 (hyphen uint256-uint256), getPools*2, set/getTokenConfigs* (address- + Storage- + hyphen), getNewPoolPauseWindowEndTime*2, setHooksContract*2 (hyphen), getHooksContract*2 (hyphen); pools documented as "via AddressSetRepo").

Rich @dev/@param/@return/@custom:throws modeled on BalancerV3*PoolRepo golds + Camelot/Operable/FacetRegistry (incl. "The Storage struct to operate on." for param overloads + layoutStruct, @title/@author/@dev library header refs golds, pool tracking desc). No @custom values (internal storage Repo per CENTRALLY). No logic change; preserved existing exactly (incl. param names like poolFeeManager, split _setTokenConfigs, _ensureEnabled revert, _MAX_TIMESTAMP, AddressSetRepo calls on pools/tokensOfPool etc). Updated layout binding/return names to layoutStruct for gold compliance (no behavior impact).

ONLY edited exactly the 3 allowed files: this .sol + its per-file gap .md + GAP_REPORT.md. Relative paths used throughout. 39 // tag:: include tags added (final tag count).

**Detailed Actions / Symbols List (post-edit):**
- LR-6: STORAGE_SLOT converted + tagged with ERC1967 + abi.encode + -1 (key "protocols.dexes.balancer.v3.base.pool.factory.common" per task; comment refs golds + computation).
- Library: added // tag::BalancerV3BasePoolFactoryRepo[] ... // end:: at close.
- Storage + dual _layoutStruct(bytes32)[] / _layoutStruct()[] + error with tags.
- _initialize dual (hyphen _initialize(Storage-uint32-address)[] / _initialize(uint32-address)[] ).
- All listed + other _* duals: _isDisabled(Storage)[] / _isDisabled()[], _disable*2, _ensureEnabled()[], pause*2 each, _getPoolManager*2, pools via AddressSet (_addPool(Storage-address)[] etc for is/getCount/range/values), token mappings (_get/setTokenConfigs with Storage- + address- hyphens), _getNew...*2, _set/_getHooksContract (hyphenated).
- Rich NatSpec everywhere per golds: @dev for "The Storage...", @param layoutStruct, @return, @custom:throws for error + Disabled.
- Symbols recap: library, STORAGE_SLOT, Storage, error, 2 layouts, 2 inits, 30+ getter/setter/guard overloads (hyphen where multi-arg; total 39 tags).
- Verifs: see below.

**Targeted Verification Performed (ONLY; no full test suite):**
- `forge inspect contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol:BalancerV3BasePoolFactoryRepo abi` : exit 0 (shows PoolPauseWindowDurationOverflow selector 0x68755a11).
- `forge inspect ... storageLayout` : exit 0 (clean/empty as expected for Repo).
- `forge inspect ... methodIdentifiers` : exit 0 (clean).
- `forge build contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol --skip test --quiet` : BUILD_EXIT=0 success (multiple runs).
- narrow list '*BalancerV3*' (via find on *BalancerV3* + '*BalancerV3BasePoolFactory*'; full `forge test --list` hits pre-existing unrelated test errors in workspace but our .sol + narrow build clean).
- Re-ran inspect + build post all fixes: clean. No new errors introduced.

**Process Note:** Strict mandatory reads 1-6 completed first (relative paths). Modeled EXACTLY on gold BalancerV3Pool/Weighted/Stable + Camelot Aware + Operable + FacetRegistry (slot, duals, hyphen tags, NatSpec, AddressSet pools, "layoutStruct", "The Storage struct..."). ONLY 3 files edited. See GAP_REPORT.md [x]. CLOSED. (34 tags total.)
