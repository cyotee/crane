# Gap Report for: contracts/tokens/ERC2612/ERC2612Repo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-6: ERC1967-Compliant Storage Slot Derivation
- LR-1: NatSpec Documentation Standard (Mandatory & Verifiable)

**Current State Summary:**
LR-6 + LR-1 closed for this Repo (see below). Followed ERC20Repo/ERC721Repo/ERC4626Repo/EIP712Repo/OperableRepo gold exactly.

**Detailed Gaps Closed:**
- LR-6: Slot fixed from direct `keccak256(abi.encode("eip.erc.2612"))` to exact ERC1967 form `bytes32(uint256(keccak256(abi.encode("eip.erc.2612"))) - 1)`.
- LR-1: Added rich NatSpec + exact `// tag::Name[]` / `// end::Name[]` (hyphenated overloads) for library, STORAGE_SLOT, Storage, dual _layoutStruct, and all _* functions. Used "The Storage struct to operate on." phrasing, layoutStruct param, full duals on every accessor, modeled precisely on current gold token/Repo standards. No @custom:selector/signature values (none in CENTRALLY_COMPUTED_NATSPEC_VALUES.md for this internal Repo; @custom:throws used for error path).

**Strict Read Order Executed (before ANY edit):**
1. docs/reports/gap/contracts/tokens/ERC2612/ERC2612Repo.sol.md
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no ERC2612 entries; used none)
3. PRD.md (LR-1 and LR-6 sections)
4. AGENTS.md (Repo patterns, ERC1967 slot, dual _layoutStruct, gold NatSpec + tags, layoutStruct, hyphenated, no viaIR)
5. contracts/tokens/ERC2612/ERC2612Repo.sol + gold examples (ERC20Repo.sol, ERC721Repo.sol, ERC4626Repo.sol, EIP712Repo.sol, OperableRepo.sol) for exact style.

**NatSpec Symbols Tagged (exact // tag:: / end::):**
- ERC2612Repo[]
- STORAGE_SLOT[]
- Storage[]
- _layoutStruct(bytes32)[]
- _layoutStruct()[]
- _useNonce(Storage-address)[]
- _useNonce(address)[]
- _useCheckedNonce(Storage-address-uint256)[]
- _useCheckedNonce(address-uint256)[]
- _nonces(Storage-address)[]
- _nonces(address)[]

**Specific Actions Taken:**
- Fixed LR-6 slot to exact ERC1967 (bytes32(uint256(keccak...)-1)).
- Ensured/added dual _layoutStruct (bytes32 + default).
- Full rich NatSpec: @title/@author/@dev on lib; @dev ERC1967 on slot + reference list of golds; @dev on Storage; @dev "Argumented/Default version...", "@dev The Storage struct to operate on.", @param layoutStruct, @return, @custom:throws for error cases.
- Preserved all logic, comments, unchecked nonce inc, revert on InvalidAccountNonce, internal calls using duals (e.g. _useNonce(layoutStruct, ...) inside checked).
- Updated param/return docs and layout var names to gold (layoutStruct no trailing _ in returns).
- ONLY edited: this .sol + its per-file gap .md + GAP_REPORT.md (3 files).
- No viaIR, no centrals fabricated, consumers (ERC2612Target, BetterBalancerV3PoolTokenFacet) use default overloads unchanged.

**Verification Steps (targeted only, post-edit):**
- `forge inspect contracts/tokens/ERC2612/ERC2612Repo.sol:ERC2612Repo (abi|storageLayout)`
- `forge build --skip test --quiet`
- `forge test --list --match-path '*ERC2612*'`

**Testing Gaps (LR-7 specific if applicable):**
- N/A for this scoped subagent (LR-6+LR-1 only on the Repo; pre-existing tests via ERC20PermitDFPkg, ERC2612Facet usage, BetterBalancer... cover via targets/facets; no test edits allowed or performed).

**Documentation/Skills Gaps (if applicable):**
- N/A (scope strict to this file).

**Notes for Subagents:**
- Centrals only (none applied here).
- Update the main GAP_REPORT.md with detailed [x] entry.
- Do not edit other files.

**Priority:** High (core framework files) - CLOSED for LR-6 + LR-1.
