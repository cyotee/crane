# Gap Report for: contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard

**Current State Summary:**
Source edits completed. ERC1967 slot fixed, dual _layoutStruct/_initialize/_balancerV3Vault added with exact // tag:: / // end:: (hyphenated where appropriate) and rich NatSpec modeled on gold (DiamondPackageFactoryAwareRepo/OperableRepo/DeployedAddressesRepo/Create3FactoryAwareRepo). No @custom needed (internal AwareRepo; confirmed none in CENTRALLY_COMPUTED_NATSPEC_VALUES.md apply). Per-file gap and GAP_REPORT updated.

**Detailed Gaps (Closed):**
- LR-6: STORAGE_SLOT updated to exact `bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.vault.aware"))) - 1)`. Dual _layoutStruct implemented/used (no other slot refs inside file).
- LR-1: Full NatSpec + exact gold-standard tags for library (BalancerV3VaultAwareRepo[]), STORAGE_SLOT, Storage, both _layoutStruct, both _initialize (hyphenated Storage-IVault / IVault), both _balancerV3Vault. Rich @dev/@param/@return with "The Storage struct to operate on." modeled on gold. Strict use of CENTRALLY only (none for this).

**Specific Actions Completed:**
- Strict read order followed pre-edits (per-file gap, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD.md LR-1/6 sections, AGENTS.md (full relevant: Facet-Target-Repo, storage slots dual _layoutStruct, tag style, hyphenated overloads, rich NatSpec, AwareRepo pattern, no viaIR), source file, gold examples: Create3FactoryAwareRepo.sol + DiamondPackageFactoryAwareRepo.sol + OperableRepo.sol).
- Source edits only (as allowed): slot fix to ERC1967 form, added duals + tags + rich prose.
- Note from CENTRALLY: no entries apply to internal AwareRepo (no fabricated customs).
- Verification (targeted only): `forge inspect contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol:BalancerV3VaultAwareRepo (abi|storageLayout)`, `forge build --skip test --quiet`, `forge test --list --match-path '*BalancerV3*'`.

**NatSpec Symbols Tagged:**
- BalancerV3VaultAwareRepo[], STORAGE_SLOT, Storage, _layoutStruct(bytes32)[], _layoutStruct()[], _initialize(Storage-IVault)[], _initialize(IVault)[], _balancerV3Vault(Storage)[], _balancerV3Vault()[]
- (9+ tags total on library/symbols; hyphenated overloads per AGENTS gold.)

**Notes:**
- ONLY edited 3 files: the .sol + its per-file gap .md + GAP_REPORT.md.
- Strict order + only central values + targeted verif per instructions.
- LR-6 + LR-1 CLOSED for this file.

**Priority:** High — CLOSED
