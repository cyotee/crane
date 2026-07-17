# Gap Report for: contracts/tokens/ERC721/ERC721MetadataRepo.sol

**Status: LR-6 + LR-1 CLOSED**

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation (STORAGE_SLOT)
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; hyphenated overload tags; no customs)

**Strict Process Followed (no skips, read in exact order before ANY edit):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/tokens/ERC721/ERC721MetadataRepo.sol.md
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no entries apply for this pure storage; none used)
3. Read relevant PRD.md sections for LR-1 and LR-6
4. Read AGENTS.md (Repo section + dual _layoutStruct gold + ERC1967 + hyphen tags + layoutStruct param)
5. Read gold examples: ERC20Repo, ERC4626Repo, OperableRepo, EIP712Repo
6. Then read the SOURCE: contracts/tokens/ERC721/ERC721MetadataRepo.sol

**ONLY 3 files edited:** .sol + this .md + GAP_REPORT.md

**Source Changes:**
- STORAGE_SLOT to `bytes32(uint256(keccak256(abi.encode("eip.erc.721.metadata"))) - 1)`
- Full tags: ERC721MetadataRepo[], STORAGE_SLOT[], Storage[], _layoutStruct(bytes32)[], _layoutStruct()[]
- _initialize 3 variants tagged (Storage-... and defaults): _initialize(Storage-string-memory-string-memory)[], _initialize(string-memory-string-memory)[], _initialize(Storage-string-memory-string-memory-string-memory)[]
- All getters/setters dual tagged e.g. _name(Storage)[], _name()[], _symbol*, _baseURI*, _tokenURI(Storage-uint256)[], _setTokenURI*
- Param standardized to layoutStruct
- Rich NatSpec + @dev "The Storage struct to operate on." modeled on golds
- No @custom (none in central)

**Symbols:**
- library/STORAGE_SLOT/Storage/_layout* duals,  _initialize* (3), _name*2, _symbol*2, _baseURI*2, _tokenURI*2, _setTokenURI*2

**Verification:**
- `forge inspect contracts/tokens/ERC721/ERC721MetadataRepo.sol:ERC721MetadataRepo (abi|storageLayout|methodIdentifiers)`
- `forge build --skip test --quiet`
- `forge test --list --match-path '*ERC721*'`

Success (0). CLOSED. See GAP [x] entry.

**CLOSED** (process, changes, symbols, and verifications recorded in full above + GAP_REPORT.md entry).

(Previous stub content fully superseded by closure details above.)
