# Gap Report for: contracts/script/DeployedAddressesRepo.sol

**Status:** CLOSED (LR-6 + LR-1)

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: )

**Strict Process Followed (before any edits):**
1. docs/reports/gap/contracts/script/DeployedAddressesRepo.sol.md
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no @custom values; internal repo)
3. PRD.md (LR-1 and LR-6 sections)
4. AGENTS.md (Repo patterns, dual _layoutStruct, gold-standard tags, "The Storage struct to operate on.", STORAGE_SLOT naming "crane.script.deployed.addresses" or hierarchical, only edit 3 files, targeted verif)
5. Gold examples: contracts/access/operable/OperableRepo.sol, contracts/introspection/ERC2535/ERC2535Repo.sol, contracts/utils/cryptography/EIP712/EIP712Repo.sol, contracts/tokens/ERC4626/ERC4626Repo.sol (and DEFAULT_SLOT models like DiamondFactoryPackageRegistryRepo.sol, CallTargetRegistryRepo.sol for STORAGE_SLOT + DEFAULT_SLOT form)
6. Then read the source: contracts/script/DeployedAddressesRepo.sol

**ONLY 3 FILES EDITED:** contracts/script/DeployedAddressesRepo.sol + this per-file gap + GAP_REPORT.md

**Key Changes:**
- Ensured exact ERC1967 STORAGE_SLOT + DEFAULT_SLOT form: DEFAULT_SLOT computed with -1 offset using hierarchical "crane.script.deployed.addresses"; STORAGE_SLOT = DEFAULT_SLOT alias.
- Dual _layoutStruct(bytes32) + _layoutStruct() using the form; all internal refs updated.
- Full rich NatSpec + EXACT // tag::Name(params)[] / // end::Name[] on library (DeployedAddressesRepo[]), DEFAULT_SLOT, STORAGE_SLOT, Storage, _layoutStruct(bytes32)[], _layoutStruct()[], and all _registerDeployedAddress* (4 duals e.g. _registerDeployedAddress(Storage-address-uint256-bytes32)[] ) + _deployedAddress* (4 duals) with hyphenated overloads.
- @dev "The Storage struct to operate on." on all Storage-param functions + rich dual overload docs. No @custom (internal per CENTRALLY_COMPUTED_NATSPEC_VALUES.md).
- Updated library header, slot docs, default _layout/docs for dual form compliance.

**All Tagged Symbols:**
DeployedAddressesRepo, DEFAULT_SLOT, STORAGE_SLOT, Storage, _layoutStruct(bytes32), _layoutStruct(), _registerDeployedAddress(Storage-address-uint256-bytes32), _registerDeployedAddress(address-uint256-bytes32), _registerDeployedAddress(Storage-address-bytes32), _registerDeployedAddress(address-bytes32), _deployedAddress(Storage-uint256-bytes32), _deployedAddress(uint256-bytes32), _deployedAddress(Storage-bytes32), _deployedAddress(bytes32)

**Current State Summary:**
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**Detailed Gaps (original, now resolved):**
- LR-1: missing NatSpec + tags (gold standard).
- LR-6: non-ERC1967 slot.
- LR-1: missing tags for _layoutStruct + functions.

**Actions Taken to Close:**
- Fixed to exact ERC1967 STORAGE_SLOT + DEFAULT_SLOT form + corrected hierarchical name per AGENTS + PRD LR-6.
- Ensured dual _layout + full tags/NatSpec on library + slot consts (both) + Storage + ALL _* duals (hyphen overloads) + "The Storage struct to operate on." @dev.
- Re-read strict order (gap, central, PRD LR-1/LR-6, AGENTS, golds, source) before ANY edit. Only 3 files.
- Targeted verif only (no other files, no full test suite).

**Verification Commands + Results (targeted ONLY; NO full `forge test`):**
- `forge inspect contracts/script/DeployedAddressesRepo.sol:DeployedAddressesRepo (abi|storageLayout|methodIdentifiers)` → success (exit 0)
- `forge build --skip test --quiet` → success (via targeted)
- `forge test --list --match-path '*DeployedAddresses*'` → success (lists without running full suite)
- Inspect confirms clean (internal lib: limited abi surface); storageLayout shows expected struct; build quiet no errors on this file.

**CENTRALLY_COMPUTED note:** None (internal repo).

**Remaining original sections retained for history but gaps closed per actions above.**

**Notes for Subagents:**
- Only this file's gaps implemented.
- GAP_REPORT.md updated with concise CLOSED.
- Strict order + only-3-files rule followed.

**Priority:** High (core framework files) — CLOSED.
