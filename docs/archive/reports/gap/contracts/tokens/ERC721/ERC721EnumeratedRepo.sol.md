# Gap Report for: contracts/tokens/ERC721/ERC721EnumeratedRepo.sol

**Status: LR-6 + LR-1 CLOSED**

**File Type:** Repo (ERC721 enumeration augmentation)

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation (STORAGE_SLOT)
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; hyphenated overload tags; no customs)

**Strict Process Followed (no skips, read in exact order before ANY edit):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/tokens/ERC721/ERC721EnumeratedRepo.sol.md
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no entries apply; none used/fabricated)
3. Read relevant PRD.md sections for LR-1 and LR-6
4. Read AGENTS.md (Repo section, dual _layoutStruct, ERC1967 form, hyphen tags, layoutStruct param)
5. Read gold examples (ERC20Repo, ERC4626Repo, OperableRepo, EIP712Repo)
6. Then read the SOURCE: contracts/tokens/ERC721/ERC721EnumeratedRepo.sol

**ONLY 3 files edited:** the .sol + this per-file gap .md + GAP_REPORT.md . Scope strictly limited.

**Source Changes:**
- STORAGE_SLOT to exact: bytes32(uint256(keccak256(abi.encode("eip.erc.721.enummerated"))) - 1) (string key preserved)
- Added full // tag::ERC721EnumeratedRepo[] ... end , STORAGE_SLOT, Storage, dual _layoutStruct tags
- Standardized param to layoutStruct (no _)
- Added rich NatSpec + hyphen tags for all: _tokenIds*, _ownedIds*, _globalOperatorOf*, _safeTransferFrom* (4 variants incl dual-storage), _transferFrom* (2), _setApprovalForAll (dual), _mint* (dual), _burn* (dual)
- Tags e.g. _safeTransferFrom(Storage-ERC721Repo.Storage-address-address-uint256-bytes-memory)[] , _mint(Storage-ERC721Repo.Storage-address)[]
- @dev "The Storage struct to operate on." , modeled exactly on golds. Notes composition with ERC721Repo.Storage
- No @custom (per central + internal)

**Symbols list (exact tags added):**
- ERC721EnumeratedRepo[], STORAGE_SLOT[], Storage[], _layoutStruct(bytes32)[], _layoutStruct()[]
- _tokenIds(Storage)[], _tokenIds()[], _ownedIds(Storage-address)[], _ownedIds(address)[], _globalOperatorOf(Storage-address)[], _globalOperatorOf(address)[]
- _safeTransferFrom(Storage-ERC721Repo.Storage-address-address-uint256-bytes-memory)[], _safeTransferFrom(address-address-uint256-bytes-memory)[], _safeTransferFrom(Storage-ERC721Repo.Storage-address-address-uint256)[], _safeTransferFrom(address-address-uint256)[]
- _transferFrom(Storage-ERC721Repo.Storage-address-address-uint256)[], _transferFrom(address-address-uint256)[]
- _setApprovalForAll(Storage-ERC721Repo.Storage-address-bool)[]
- _mint(Storage-ERC721Repo.Storage-address)[], _mint(address)[]
- _burn(Storage-ERC721Repo.Storage-uint256)[], _burn(uint256)[]

**Verification (post edit):**
- `forge inspect contracts/tokens/ERC721/ERC721EnumeratedRepo.sol:ERC721EnumeratedRepo (abi|storageLayout|methodIdentifiers)`
- `forge build --skip test --quiet`
- `forge test --list --match-path '*ERC721*'`

All exit 0, clean.

**CLOSED** for LR-6/LR-1. Strict order + only allowed files. See GAP_REPORT [x].
