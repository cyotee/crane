# Gap Report for: contracts/tokens/ERC20/ERC20Repo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
LR-6 (ERC1967 slot), LR-1 (full NatSpec + // tag::/end:: )

**Current State Summary:**
LR-6/LR-1 gaps closed for this core ERC20 storage Repo. (See closure below; prior state had non-ERC1967 DEFAULT_SLOT=keccak direct, partial tags, incomplete NatSpec.)

## Closure Summary (LR-6 + LR-1)

- [x] LR-6: Converted DEFAULT_SLOT to exact ERC1967 STORAGE_SLOT form: `bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.20"))) - 1);` (using "eip.erc.20" per existing + AGENTS/PRD hierarchical for eip.erc.* ; matched gold in ERC4626Repo/ERC2535Repo/OperableRepo).
- [x] Dual _layoutStruct ensured (both bytes32 and default overloads, now with rich docs + tags).
- [x] Full LR-1: rich NatSpec + exact // tag:: / end:: on library (ERC20Repo[]), STORAGE_SLOT, Storage, dual _layoutStruct(bytes32)[] / _layoutStruct()[], and ALL _* funcs with hyphenated overload tags e.g. _initialize(Storage-string-memory-string-memory-uint8)[], _approve(Storage-address-address-uint256)[], _spendAllowance* , _increaseBalanceOf*, _decreaseBalanceOf*, _transfer*, _transferFrom*, _mint*, _burn*, _name(Storage)[], _name()[], _symbol* , _decimals* , _totalSupply* , _balanceOf*, _allowance* .
- [x] Aligned with gold (OperableRepo, ERC4626Repo, EIP712Repo, ERC2535Repo): 
  - param `layoutStruct` for Storage storage ( "The Storage struct to operate on." in @dev/@param )
  - "The Storage struct..." / "Argumented version..." / "Default version of _X binding to the standard STORAGE_SLOT."
  - @dev "Standardized storage layout for ...", rich @dev on lib + slot + Storage.
  - @custom:emits where applicable (Approval/Transfer events).
- [x] Fixed internal calls (all dual _X(layoutStruct, ...) calls preserved; _layoutStruct() default now resolves via STORAGE_SLOT; added symmetric default wrapper for _spendAllowance for full dual pattern).
- [x] NO @custom:* selectors added (pure internal Repo storage lib; CENTRALLY_COMPUTED_NATSPEC_VALUES.md has no ERC20Repo values; only used for interface surfaces in other files per "ONLY these values").
- [x] Strict process followed: read per-file gap, CENTRALLY_COMPUTED (only), PRD LR-1/LR-6 sections, AGENTS.md (Repo, duals, tag style, NatSpec, naming, "eip.erc.*", "layoutStruct"), sources + golds (Operable/ERC4626/EIP712/ERC2535) before any edit.
- ONLY edited: this .sol + its per-file gap .md + GAP_REPORT.md . No other files.

**Targeted Verification Performed (after edits):**
- `forge inspect contracts/tokens/ERC20/ERC20Repo.sol:ERC20Repo (abi|storageLayout)`
- `forge build --skip test --quiet`
- `forge test --list --match-path '*ERC20Repo*'`

See main GAP_REPORT.md for the [x] entry with command outputs + diff summary. (Internal lib: abi empty as expected, storageLayout shows ERC20 fields.)

**Notes:**
- Consumers (ERC20Target/DFPkg etc) not edited (scope strict limit).
- Slot migration safe (new form is deterministic, upgrade note per PRD).
- Matches "eip.erc.20" for main ERC20 per prior + eip.erc pattern.
- No viaIR, used struct patterns where needed (not here).

**Priority:** High (core framework files) - CLOSED for LR-6/LR-1
