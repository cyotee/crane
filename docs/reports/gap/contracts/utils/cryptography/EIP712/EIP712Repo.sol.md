# Gap Report for: contracts/utils/cryptography/EIP712/EIP712Repo.sol

**Status: LR-6 + LR-1 CLOSED**

**File Type:** Repo (EIP-712 domain separator and typed data hash storage)

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; hyphenated overload tags; no @custom on pure storage internals per CENTRALLY_COMPUTED_NATSPEC_VALUES.md)

**Strict Process Followed (no skips, read in exact order before ANY edit):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/utils/cryptography/EIP712/EIP712Repo.sol.md (stub)
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no entries apply for this pure storage/internal Repo; none fabricated/used/inserted)
3. Read relevant PRD.md sections for LR-1 (NatSpec, tags, gold ERC8023/MultiStep style, central values only, rich @dev/@param/@return, include tags on all) and LR-6 (exact bytes32(uint256(keccak256(abi.encode("..."))) - 1) form for STORAGE_SLOT, dual _layoutStruct(bytes32 slot_)+(), duals for _initialize/*Domain/*Hash/*Name/*Version, standardize struct Storage, "The Storage struct to operate on.")
4. Read AGENTS.md (full relevant: Repo pattern, dual _layoutStruct, Naming (slot_), Storage struct, AsciiDoc // tag:: exact no spaces, NatSpec gold, storage slot hierarchical "eip.eip.712", param_ convention)
5. Read gold examples (full): AerodromeRouterAwareRepo.sol, Permit2AwareRepo.sol, ERC4626Repo.sol, DiamondPackageCallBackFactoryAwareRepo.sol, Create3FactoryAwareRepo.sol, OperableRepo.sol, ERC2535Repo.sol (modeled especially on just-closed token/repo golds ERC4626/Permit2 + aware)
6. Then read the SOURCE: contracts/utils/cryptography/EIP712/EIP712Repo.sol (noted it used EIP712Layout + partial _layoutStruct tag + ShortStrings/BetterEfficientHashLib/MessageHashUtils/EIP712_TYPE_HASH imports; current direct keccak slot)

**ONLY 3 files edited:** contracts/utils/cryptography/EIP712/EIP712Repo.sol + its per-file gap .md + GAP_REPORT.md (append [x] entry). No other files touched (explicitly: no EIP712.sol, no ERC5267Target.sol, no ERC2612/ERC20Permit/DFPkgs/Balancer pools, no tests).

**Symbols with exact gold // tag:: / end:: (hyphenated for overloads per ERC4626Repo/ERC2535Repo/Diamond*Aware golds):**
- // tag::EIP712Repo[] ... // end::EIP712Repo[]
- // tag::STORAGE_SLOT[] ... // end::STORAGE_SLOT[]
- // tag::Storage[] ... // end::Storage[]
- // tag::_layoutStruct(bytes32)[] ... // end::_layoutStruct(bytes32)[]
- // tag::_layoutStruct()[] ... // end::_layoutStruct()[]
- // tag::_initialize(Storage-string-string)[] ... // end::_initialize(Storage-string-string)[]
- // tag::_initialize(string-string)[] ... // end::_initialize(string-string)[]
- // tag::_domainSeparatorV4(Storage)[] ... // end::_domainSeparatorV4(Storage)[]
- // tag::_domainSeparatorV4()[] ...
- // tag::_buildDomainSeparator(Storage)[] ...
- // tag::_buildDomainSeparator()[] ...
- // tag::_hashTypedDataV4(Storage-bytes32)[] ... // end::_hashTypedDataV4(Storage-bytes32)[]
- // tag::_hashTypedDataV4(bytes32)[] ...
- // tag::_EIP712Name(Storage)[] ... // end::_EIP712Name(Storage)[]
- // tag::_EIP712Name()[] ...
- // tag::_EIP712Version(Storage)[] ... // end::_EIP712Version(Storage)[]
- // tag::_EIP712Version()[] ...

**Source Changes (per exact requirements, modeled on golds):**
- Kept imports/SPDX/pragma + using + header comment + forge-lint disables exactly (ShortStrings, EIP712_TYPE_HASH, BetterEfficientHashLib, MessageHashUtils).
- STORAGE_SLOT fixed to exact: bytes32(uint256(keccak256(abi.encode("eip.eip.712"))) - 1); (per task + eip.* gold from ERC2535/ERC4626)
- Standardized to `struct Storage { ... }` (mapped _cachedDomainSeparator, _cachedChainId, _cachedThis, _hashedName, _hashedVersion, _name, _version, _nameFallback, _versionFallback exactly).
- Full dual _layoutStruct(bytes32 slot_) + default; full duals for _initialize, _domainSeparatorV4, _hashTypedDataV4, _EIP712Name, _EIP712Version + _build* helpers.
- Param names standardized: slot_, layoutStruct, name_, version_ etc.
- Rich NatSpec: @title/@author/@dev on lib (golds ref + EIP712 usage), @dev "The Storage struct to operate on." on Storage-param overloads, @param/@return on all. No @custom (internal storage Repo per CENTRALLY_COMPUTED_NATSPEC_VALUES.md).
- Exact tags at library root + per-symbol (integrated/enhanced existing partial _layoutStruct tag) + closing.
- All internal calls updated to use new Storage + consistent dual _xxx(_layoutStruct()).

**Pre-edit state (from source read in step 6):** direct keccak no (uint256(...) - 1), EIP712Layout not Storage, partial tags only on one _layoutStruct, incomplete NatSpec, some direct layout access without duals, slot param style not fully slot_.

**Targeted Verification (ONLY as specified, after edits):**
- `forge inspect contracts/utils/cryptography/EIP712/EIP712Repo.sol:EIP712Repo (abi|storageLayout)`
- `forge build --skip test --quiet`
- `forge test --list --match-path '*EIP712*'`

**CLOSED:** All LR-6/LR-1 requirements met for this file. Strict mandatory read order 1-6 followed before any edit. See appended [x] entry in GAP_REPORT.md (LR-1 utils/cryptography + recent repos). (EIP712 storage Repo; no central selector values used)

**Priority:** High (core framework utils/cryptography) - CLOSED
