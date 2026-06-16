# Gap Report for: contracts/tokens/ERC20/ERC20MinterFacadeRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
LR-6 (ERC1967 slot), LR-1 (full NatSpec + // tag::/end:: )

**Current State Summary:**
LR-6/LR-1 gaps closed for this core ERC20MinterFacadeRepo. (See closure below; prior state had non-ERC1967 DEFAULT_SLOT, no tags, no rich NatSpec.)

## Closure Summary (LR-6 + LR-1)

- [x] LR-6: Converted DEFAULT_SLOT to exact ERC1967 STORAGE_SLOT form: `bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.20.minter.facade"))) - 1);` (appropriate hierarchical name per existing + AGENTS eip.erc pattern; matched gold).
- [x] Dual _layoutStruct ensured (pre-existing duals preserved + now documented/tagged).
- [x] Full LR-1: rich NatSpec + exact // tag:: / end:: on library (ERC20MinterFacadeRepo[]), STORAGE_SLOT, Storage, dual _layoutStruct(bytes32)[]/_layoutStruct()[], and ALL _* funcs (hyphenated overloads): _initialize(Storage-uint256-uint256)[], _initialize(uint256-uint256)[], _setMaxMintAmount*2, _maxMintAmount*2, _setMinMintInterval*2, _minMintInterval*2, _lastMintTimestamp*2, _setLastMintTimestamp*2 .
- [x] Aligned with gold (ERC4626Repo, OperableRepo, EIP712Repo etc.): layoutStruct param name, "The Storage struct to operate on.", "Argumented version..." / "Default version...", @dev Standardized storage layout, rich @dev/@param/@return on all.
- [x] Internal calls fixed/verified (all _set/_get dual calls use layoutStruct or _layoutStruct() correctly; no DEFAULT left).
- [x] NO @custom values (none in CENTRALLY_COMPUTED for this; internal-only per rule).
- [x] Strict read order + only allowed files edited (2 .sol + 2 gaps + GAP_REPORT).
- Targeted verif: forge inspect ...ERC20MinterFacadeRepo (abi|storageLayout), build --skip test --quiet, list match-path '*ERC20Repo*'.

See main GAP_REPORT.md for detailed [x] closure entry.

**Priority:** High (core framework files) - CLOSED for LR-6/LR-1
