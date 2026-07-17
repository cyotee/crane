# Gap Report for: contracts/tokens/ERC721/ERC721Repo.sol

**Status: LR-6 + LR-1 CLOSED**

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation (STORAGE_SLOT)
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; hyphenated overload tags; layoutStruct param; no customs as pure internal)

**Strict Process Followed (no skips, read in exact order before ANY edit):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/tokens/ERC721/ERC721Repo.sol.md
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no ERC721 entries; none fabricated/used per ONLY rule)
3. Read relevant PRD.md sections for LR-1 (NatSpec + tags + gold ERC8023/MultiStep + rich @dev etc) and LR-6 (exact `bytes32(uint256(keccak256(abi.encode("eip.erc.721" or hierarchical))) - 1)` for STORAGE_SLOT)
4. Read AGENTS.md (Repo section, dual _layoutStruct gold, ERC1967 form, tag style with hyphens for overloads e.g. _xxx(Storage-addr)[], layoutStruct param, NatSpec requirements, "The Storage struct to operate on.", param_ naming)
5. Read gold examples (full): contracts/tokens/ERC20/ERC20Repo.sol, contracts/tokens/ERC4626/ERC4626Repo.sol, contracts/access/operable/OperableRepo.sol, contracts/utils/cryptography/EIP712/EIP712Repo.sol
6. Then read the SOURCE: contracts/tokens/ERC721/ERC721Repo.sol

**ONLY 3 files edited total for this closure:** contracts/tokens/ERC721/ERC721Repo.sol + docs/reports/gap/contracts/tokens/ERC721/ERC721Repo.sol.md + GAP_REPORT.md . No other files (no facets, targets, tests, interfaces, no other repos).

**Pre-edit state (from step 6 read):** direct `keccak256(abi.encode("eip.erc.721"))` (no uint256-1 bytes32), no NatSpec whatsoever, no // tag:: , _layout return used layoutStruct_ (not layoutStruct), all _* funcs used layoutStruct_ + non-_ params, no dual doc, missing rich @dev/@param/@return/@custom:emits , incomplete standardization.

**Source Changes (exact requirements, modeled on ERC20/ERC4626/Operable/EIP712 golds):**
- STORAGE_SLOT updated to exact LR-6: `bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.721"))) - 1);`
- Added // tag::ERC721Repo[] at top of lib + // end::ERC721Repo[] before final }
- Added // tag::STORAGE_SLOT[] / end , // tag::Storage[] / end
- Standardized dual _layoutStruct(bytes32 slot_) / _layoutStruct() with exact tags _layoutStruct(bytes32)[] and _layoutStruct()[]
- Return binding var and all Storage storage params changed to `layoutStruct` (no trailing _ per gold/AGENTS)
- All internal bodies + call sites updated for new param names
- Added trailing _ to params consistently (owner_, tokenId_, from_ etc) per param_ convention
- Full duals documented for every _* (balanceOf, ownerOf, 4x safeTransferFrom variants, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, mint, 4x burn variants)
- Exact hyphenated tags e.g. // tag::_balanceOf(Storage-address)[] , // tag::_balanceOf(address)[] ; // tag::_safeTransferFrom(Storage-address-address-uint256-bytes-memory)[] , // tag::_safeTransferFrom(address-address-uint256-bytes-memory)[] etc.
- Rich NatSpec: @title/@author/@dev on library (references golds + "ERC1967-compliant"), @dev "The Storage struct to operate on." + @param/@return on all, @custom:emits for events
- forge-lint disable on struct (per gold)
- No @custom:* inserted (no public surface, none in CENTRALLY for this; internals only)

**Symbols with exact gold // tag:: / end:: (hyphenated overloads):**
- // tag::ERC721Repo[] ... // end::ERC721Repo[]
- // tag::STORAGE_SLOT[] ... // end::STORAGE_SLOT[]
- // tag::Storage[] ... // end::Storage[]
- // tag::_layoutStruct(bytes32)[] ... // end::_layoutStruct(bytes32)[]
- // tag::_layoutStruct()[] ... // end::_layoutStruct()[]
- // tag::_balanceOf(Storage-address)[] ... // end::_balanceOf(Storage-address)[]
- // tag::_balanceOf(address)[] ... // end::_balanceOf(address)[]
- // tag::_ownerOf(Storage-uint256)[] ... // end::...
- // tag::_ownerOf(uint256)[] ...
- // tag::_safeTransferFrom(Storage-address-address-uint256-bytes-memory)[] ...
- // tag::_safeTransferFrom(address-address-uint256-bytes-memory)[] ...
- // tag::_safeTransferFrom(Storage-address-address-uint256)[] ...
- // tag::_safeTransferFrom(address-address-uint256)[] ...
- // tag::_transferFrom(Storage-address-address-uint256)[] ... (and default)
- // tag::_approve(Storage-address-uint256)[] ... (and default)
- // tag::_setApprovalForAll(Storage-address-bool)[] ... (and default)
- // tag::_getApproved(Storage-uint256)[] ... (and default)
- // tag::_isApprovedForAll(Storage-address-address)[] ... (and default)
- // tag::_mint(Storage-address)[] ... (and default)
- // tag::_burn(Storage-address-uint256)[] ... (and 3 more variants: address-uint, Storage-uint, uint)
- (All  _* functions covered with duals)

**Targeted Verification (ONLY as specified, after edits):**
- `forge inspect contracts/tokens/ERC721/ERC721Repo.sol:ERC721Repo (abi|storageLayout|methodIdentifiers)`
- `forge build --skip test --quiet`
- `forge test --list --match-path '*ERC721*'`

All passed with exit 0 (abi/ids empty as pure lib; build/list clean, no errors).

**CLOSED:** LR-6 (exact slot form using "eip.erc.721") + LR-1 (full tags + NatSpec modeled precisely on golds). Strict read order followed. See [x] in GAP_REPORT.md. Centrals referenced (none applied). ONLY the 3 files edited per rules.

**Priority:** High (core framework) - CLOSED
