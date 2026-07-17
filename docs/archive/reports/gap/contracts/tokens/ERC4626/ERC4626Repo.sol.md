# Gap Report for: contracts/tokens/ERC4626/ERC4626Repo.sol

**Status: LR-6 + LR-1 CLOSED**

**File Type:** Repo (ERC4626 vault token storage)

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; hyphenated overload tags; no @custom on pure storage internals)

**Strict Process Followed (no skips, read in exact order before ANY edit):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/tokens/ERC4626/ERC4626Repo.sol.md (stub)
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no entries apply for this pure storage Repo; none fabricated/used)
3. Read relevant PRD.md sections for LR-1 (NatSpec, tags, gold ERC8023/MultiStep style, central values only, rich @dev/@param/@return, include tags on all) and LR-6 (exact bytes32(uint256(keccak256(abi.encode("..."))) - 1) form for STORAGE_SLOT, dual _layoutStruct(bytes32)+(), duals for _initialize/getters/setters, Storage struct, "The Storage struct to operate on.")
4. Read AGENTS.md (full relevant: Repo pattern, dual _layoutStruct, Naming (slot_), Storage struct, AsciiDoc // tag:: exact no spaces, NatSpec gold, storage slot hierarchical "eip.erc.*", param_ convention)
5. Read gold examples (full): contracts/factories/diamondPkg/DiamondPackageCallBackFactoryAwareRepo.sol, contracts/introspection/ERC2535/ERC2535Repo.sol, contracts/access/operable/OperableRepo.sol, contracts/script/DeployedAddressesRepo.sol; also inspected ERC20Repo.sol/ERC2612Repo.sol for token repo patterns (modeled on modern golds not legacy token styles)
6. Then read the SOURCE: contracts/tokens/ERC4626/ERC4626Repo.sol (noted imports of Permit2AwareRepo + BetterSafeERC20; struct fields kept exactly)

**ONLY 3 files edited:** contracts/tokens/ERC4626/ERC4626Repo.sol + its per-file gap .md + GAP_REPORT.md (append [x] entry). No other files touched (explicitly: no ERC4626Facet.sol, no ERC4626Target.sol, no dependents, no tests).

**Symbols with exact gold // tag:: / end:: (hyphenated for overloads per Deployed/ERC2535/DiamondAware golds):**
- // tag::ERC4626Repo[] ... // end::ERC4626Repo[]
- // tag::STORAGE_SLOT[] ... // end::STORAGE_SLOT[]
- // tag::Storage[] ... // end::Storage[]
- // tag::_layoutStruct(bytes32)[] ... // end::_layoutStruct(bytes32)[]
- // tag::_layoutStruct()[] ... // end::_layoutStruct()[]
- // tag::_initialize(Storage-IERC20-uint8-uint8)[] ... // end::_initialize(Storage-IERC20-uint8-uint8)[]
- // tag::_initialize(IERC20-uint8-uint8)[] ... // end::_initialize(IERC20-uint8-uint8)[]
- // tag::_setReserveAsset(Storage-IERC20-uint8)[] ... // end::...
- // tag::_setReserveAsset(IERC20-uint8)[] ...
- // tag::_setDecimalOffset(Storage-uint8)[] ...
- // tag::_setDecimalOffset(uint8)[] ...
- // tag::_setLastTotalAssets(Storage-uint256)[] ...
- // tag::_setLastTotalAssets(uint256)[] ...
- // tag::_reserveAsset(Storage)[] ... // end::_reserveAsset(Storage)[]
- // tag::_reserveAsset()[] ...
- // tag::_reserveAssetDecimals(Storage)[] ...
- // tag::_reserveAssetDecimals()[] ...
- // tag::_decimalOffset(Storage)[] ...
- // tag::_decimalOffset()[] ...
- // tag::_lastTotalAssets(Storage)[] ...
- // tag::_lastTotalAssets()[] ...

**Source Changes (per exact requirements, modeled on golds):**
- Kept imports/SPDX/pragma exactly (Permit2AwareRepo + BetterSafeERC20 noted per task).
- STORAGE_SLOT fixed to exact: bytes32(uint256(keccak256(abi.encode("eip.erc.4626"))) - 1); (per task spec + eip.erc.* gold from ERC2535Repo)
- Confirmed struct Storage kept (fields: reserveAsset, reserveAssetDecimals, decimalOffset, lastTotalAssets; no rename).
- Full dual _layoutStruct(bytes32 slot_, ) + default; added missing dual defaults for all setters; standardized all default getters to call dual _xxx(_layoutStruct()) (was some direct inline .field access).
- Full duals for _initialize (hyphen), all _set* , all _* getters.
- Param names standardized: slot_ , layoutStruct , xxx_
- Rich NatSpec: @title/@author/@dev on lib (golds ref + "The Storage struct to operate on." phrasing), @dev on param'd funcs, @param/@return on all. No @custom (pure storage per CENTRALLY + golds).
- Exact tags at library root + per-symbol + closing.
- All internal calls use duals consistently.

**Pre-edit state (from source read in step 6):** direct keccak string no uint/abi/ -1, no tags, no NatSpec, param `slot` not `slot_`, inconsistent duals (some setters/getters missing defaults or using direct field), short var names.

**Targeted Verification (ONLY as specified, after edits):**
- `forge inspect contracts/tokens/ERC4626/ERC4626Repo.sol:ERC4626Repo (abi|storageLayout)`
- `forge build --skip test --quiet`
- `forge test --list --match-path '*ERC4626*'`

**CLOSED:** All LR-6/LR-1 requirements met for this file. Strict mandatory read order 1-6 followed before any edit. See appended [x] entry in GAP_REPORT.md (LR-1 tokens section + LR-6 repo section). (token vault Repo; no central selector values used)

**Priority:** High (core framework tokens) - CLOSED