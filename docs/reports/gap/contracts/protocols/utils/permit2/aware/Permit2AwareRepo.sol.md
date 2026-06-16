# Gap Report for: contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol

**File Type:** Repo (internal *AwareRepo)

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; hyphenated overload tags; no @custom on internals)

**Current State Summary:**
Source edits completed for LR-6 + LR-1. See process and symbols below.

**Detailed Gaps (CLOSED):**
- LR-6: STORAGE_SLOT + dual _layoutStruct implemented per exact ERC1967 + gold pattern.
- LR-1: Full rich NatSpec + exact // tag:: / end:: (hyphenated overloads) + Storage struct. No @custom per central for AwareRepo internal.

**Specific Actions Completed:**
- Strict read order before any edit.
- Changed to ERC1967 STORAGE_SLOT, inner Storage struct, full duals with gold tags/NatSpec/param names.
- ONLY 3 files. Targeted verifs used. Modeled exactly on closed awares.

**Testing Gaps (LR-7 n/a for this scoped fix):**
- Not addressed (scope: only the 3 files for LR-6/LR-1 on this Repo).

**Notes:**
- Per CENTRALLY: internal AwareRepo uses NO @custom.
- Existing // tag::struct[] / repo[] noted and integrated via gold style outer+inners.
- LR-6 + LR-1 CLOSED. See full process in post section at bottom.

**Priority:** High (core framework) - CLOSED

---

**Post-Edit Update (LR-6 + LR-1 CLOSED):**

**Strict Process Followed (no skips):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol.md
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (internal AwareRepo - NO @custom:selector etc values apply or fabricated)
3. Read relevant PRD.md sections for LR-1 (NatSpec, tags, central values only, gold ERC8023 style) and LR-6 (exact bytes32(uint256(keccak256(abi.encode("..."))) - 1) form, dual _layoutStruct(bytes32) + (), _initialize duals, getters duals, Storage struct, "The Storage struct to operate on.")
4. Read AGENTS.md sections on *AwareRepo, Facet-Target-Repo, storage slots, dual _layout, tag rules (hyphenated overloads e.g. _initialize(Storage-IPermit2)[], _permit2()[] ), rich NatSpec, param_ naming.
5. Read gold examples (full recent closed): contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol, UniswapV2RouterAwareRepo.sol, CamelotV2RouterAwareRepo.sol, BalancerV3VaultAwareRepo.sol, DiamondPackageCallBackFactoryAwareRepo.sol (just done), Create3FactoryAwareRepo.sol. Also noted Permit2 usage in token repos (ERC4626* etc, no edits).
6. Then read the SOURCE: contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol

**ONLY 3 files edited:** the .sol + its per-file gap .md + GAP_REPORT.md (append matching [x] entry). NOTHING else touched (no IPermit2Aware, no ERC4626, no other users, no tests).

**Symbols with exact gold // tag:: / end:: (hyphenated for overloads):**
- // tag::Permit2AwareRepo[] ... // end::Permit2AwareRepo[]
- // tag::STORAGE_SLOT[] ... // end::STORAGE_SLOT[]
- // tag::Storage[] ... // end::Storage[]
- // tag::_layoutStruct(bytes32)[] ... // end::_layoutStruct(bytes32)[]
- // tag::_layoutStruct()[] ... // end::_layoutStruct()[]
- // tag::_initialize(Storage-IPermit2)[] ... // end::_initialize(Storage-IPermit2)[]
- // tag::_initialize(IPermit2)[] ... // end::_initialize(IPermit2)[]
- // tag::_permit2(Storage)[] ... // end::_permit2(Storage)[]
- // tag::_permit2()[] ... // end::_permit2()[]

**Source Changes (per exact requirements, modeled on UniswapV2*/Camelot*/Balancer*/DiamondPackageCallBackFactoryAwareRepo + Create3 golds):**
- Kept imports/SPDX unchanged (including unused IPermit2Aware import).
- STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("protocols.utils.permit2.aware"))) - 1); (used the existing logical name in abi.encode, ERC1967 exact form per task/PRD).
- struct Storage { IPermit2 permit2; } (standard gold "Storage"; was external Permit2AwareLayout struct + using-for-bytes32 pattern; all internal usage updated).
- Full duals for _layoutStruct(bytes32 slot_)/_layoutStruct(), _initialize duals, _permit2 dual getters. Param names: slot_, permit2_ .
- Exact outer // tag::Permit2AwareRepo[] (top before NatSpec) + inner tags as listed (integrated note of old struct/repo tags by adopting the gold naming convention).
- Rich NatSpec on library (@title/@author/@dev referencing golds + usage for Permit2) + on all funcs ( @dev "The Storage struct to operate on." for param'd, @param/@return). No @custom fabricated (per CENTRALLY for internal AwareRepo).
- Slot made internal constant (consistent with golds).
- No other changes.

**Targeted Verification (ONLY as specified, after edits):**
- `forge inspect contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol:Permit2AwareRepo (abi|storageLayout)`
- `forge build --skip test --quiet`
- `forge test --list --match-path '*Permit2Aware*'`

**Pre-edit state (from source read):** old direct keccak without -1 (private), used external Permit2AwareLayout + using bytes32 dispatch + old _layout naming (storageRange, layoutStruct_), partial duals, no rich NatSpec, partial existing tags::struct/repo, non-gold param naming.

**CLOSED:** All LR-6/LR-1 requirements met for this file using strict reads + gold modeling. Existing tags integrated into new exact gold style. See appended entry in GAP_REPORT.md LR-1 section. (internal AwareRepo; no central selector values used)

