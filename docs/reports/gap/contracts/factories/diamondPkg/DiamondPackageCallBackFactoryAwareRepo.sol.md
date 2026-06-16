# Gap Report for: contracts/factories/diamondPkg/DiamondPackageCallBackFactoryAwareRepo.sol

**Status: LR-6 + LR-1 CLOSED**

**File Type:** Repo (internal *AwareRepo)

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; hyphenated overload tags; no @custom on internals)

**Strict Process Followed (no skips):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/factories/diamondPkg/DiamondPackageCallBackFactoryAwareRepo.sol.md
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (internal AwareRepo - NO @custom:selector etc values apply or fabricated)
3. Read relevant PRD.md sections for LR-1 (NatSpec, tags, central values only, gold ERC8023 style) and LR-6 (exact bytes32(uint256(keccak256(abi.encode("..."))) - 1) form, dual _layoutStruct(bytes32) + (), _initialize duals, getters duals, Storage struct, "The Storage struct to operate on.")
4. Read AGENTS.md sections on *AwareRepo, Facet-Target-Repo, storage slots, dual _layout, tag rules (hyphenated overloads e.g. _initialize(Storage-IX)[], _foo()[] ), rich NatSpec, param_ naming.
5. Read gold examples (full): Create3FactoryAwareRepo.sol, DiamondPackageFactoryAwareRepo.sol (note similar), BalancerV3VaultAwareRepo.sol, CamelotV2RouterAwareRepo.sol (just closed), OperableRepo.sol.
6. Then read the SOURCE: contracts/factories/diamondPkg/DiamondPackageCallBackFactoryAwareRepo.sol

**ONLY 3 files edited:** the .sol + its per-file gap .md + GAP_REPORT.md (append matching [x] entry). No other files touched.

**Symbols with exact gold // tag:: / end:: (hyphenated for overloads):**
- // tag::DiamondPackageCallBackFactoryAwareRepo[] ... // end::DiamondPackageCallBackFactoryAwareRepo[]
- // tag::STORAGE_SLOT[] ... // end::STORAGE_SLOT[]
- // tag::Storage[] ... // end::Storage[]
- // tag::_layoutStruct(bytes32)[] ... // end::_layoutStruct(bytes32)[]
- // tag::_layoutStruct()[] ... // end::_layoutStruct()[]
- // tag::_initialize(Storage-IDiamondPackageCallBackFactory)[] ... // end::_initialize(Storage-IDiamondPackageCallBackFactory)[]
- // tag::_initialize(IDiamondPackageCallBackFactory)[] ... // end::_initialize(IDiamondPackageCallBackFactory)[]
- // tag::_diamondPackageCallBackFactory(Storage)[] ... // end::_diamondPackageCallBackFactory(Storage)[]
- // tag::_diamondPackageCallBackFactory()[] ... // end::_diamondPackageCallBackFactory()[]

**Source Changes (per exact requirements, modeled on DiamondPackageFactoryAwareRepo + Create3 + Balancer/Camelot golds):**
- Kept imports/SPDX unchanged.
- STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.diamond.package.callback.factory.aware"))) - 1); (logical string, ERC1967 exact form)
- struct Storage { IDiamondPackageCallBackFactory diamondPackageCallBackFactory; } (gold "Storage" + descriptive field; was old external layout struct + short "factory")
- Full duals: _layoutStruct(bytes32 slot_), _layoutStruct(), _initialize(Storage, ID...), _initialize(ID...), _diamondPackageCallBackFactory(Storage), _diamondPackageCallBackFactory().
- Param names: slot_ , factory_
- Rich NatSpec: @title/@author/@dev on lib ( "Follows the gold standard from ...", references golds), @dev "The Storage struct to operate on." on param'd funcs, clear @param/@return.
- No other changes. (no @custom fabricated)

**Targeted Verification (ONLY as specified, after edits):**
- `forge inspect contracts/factories/diamondPkg/DiamondPackageCallBackFactoryAwareRepo.sol:DiamondPackageCallBackFactoryAwareRepo (abi|storageLayout)`
- `forge build --skip test --quiet`
- `forge test --list --match-path '*DiamondPackageCallBack*' ` (or similar)

**Pre-edit state (from source read):** no NatSpec, no tags, old keccak direct without -1, non-Storage struct name, non-dual naming consistent with golds, short field.

**CLOSED:** All LR-6/LR-1 requirements met for this file using strict reads + gold modeling. See appended entry in GAP_REPORT.md LR-1/LR-6 sections. (internal AwareRepo; no central selector values used)

**Priority:** High (core framework) - CLOSED
