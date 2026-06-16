# Gap Report for: contracts/protocols/l2s/superchain/senders/SuperchainSenderNonceRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (Mandatory & Verifiable)
- LR-6: ERC1967-Compliant Storage Slot Derivation (DEFAULT_SLOT / STORAGE_SLOT)

**Current State Summary:**
Gaps closed for this file per LR-1 and LR-6. Strict read order followed before any edits: (1) this gap report, (2) CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY; no entries for these superchain internals so no @custom: fabricated), (3) PRD.md (LR-1 and LR-6 sections), (4) AGENTS.md (Repo section + ERC1967 form exactly bytes32(uint256(keccak...)-1), dual _layoutStruct, gold NatSpec + exact // tag:: / end:: including hyphenated overloads, layoutStruct param name, "The Storage struct to operate on."), (5) the source .sol + gold examples (MultiStepOwnableRepo.sol, OperableRepo.sol, ERC20Repo.sol, ERC721Repo.sol, ERC2535Repo.sol etc). ONLY edited the 3 .sol + 3 per-file .md gaps + GAP_REPORT.md.

**Detailed Gaps (Closed):**
- LR-6: STORAGE_SLOT fixed to EXACT ERC1967 form `bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.protocols.l2s.superchain.senders.nonce"))) - 1);`. Hierarchical name chosen per original + AGENTS ("crane.protocols.l2s..."). All _layout + calls updated.
- LR-1: Added rich NatSpec (@title/@author/@notice/@dev/@param/@return) + EXACT gold // tag:: / end:: (library SuperchainSenderNonceRepo[], STORAGE_SLOT, Storage, _layoutStruct(bytes32)[], _layoutStruct()[], and every _* with hyphenated for Storage-param versions e.g. _nextNonce(Storage-address-uint256)[], _useCheckedNonce(Storage-address-uint256-uint256)[]). Modeled directly on OperableRepo/MultiStepOwnableRepo/ERC20Repo gold. No @custom:selector etc added (none in CENTRALLY_COMPUTED_NATSPEC_VALUES.md for this internal Repo; followed "if no entry, add only rich prose/docs"). Internal error documented with @dev.
- Dual _layoutStruct(bytes32 slot_) + _layoutStruct() ensured (with slot_ param, layoutStruct return naming; fixed incomplete return type).
- All internal calls use the dual overloads; layoutStruct param standardized; "The Storage struct to operate on." phrasing used.
- No other files touched (callers rely on default overloads, slot change is encapsulated).

**Actions Completed:**
- Performed strict read order exactly as specified.
- Fixed STORAGE_SLOT + updated duals + internal calls.
- Added full gold NatSpec + EXACT // tag:: / end:: for listed symbols.
- Referenced reads, centrals (only prose), PRD, AGENTS.
- ONLY the 3 allowed file categories edited.
- After edits: ran ONLY `forge inspect ...SuperchainSenderNonceRepo (abi|storageLayout)`, `forge build --skip test --quiet`, `forge test --list --match-path '*SuperChain*|*Superchain*'`.
- Fleshed this per-file gap with symbols list + closure notes.
- Added detailed [x] to GAP_REPORT.md.

**NatSpec Symbols Tagged (exact):**
- SuperchainSenderNonceRepo, STORAGE_SLOT, Storage, _layoutStruct(bytes32)[], _layoutStruct()[]
- _nextNonce(Storage-address-uint256)[], _nextNonce(address-uint256)[]
- _useNonce(Storage-address-uint256)[], _useNonce(address-uint256)[]
- _useCheckedNonce(Storage-address-uint256-uint256)[], _useCheckedNonce(address-uint256-uint256)[]

**Testing Gaps (LR-7 specific if applicable):**
Scoped out per task (only .sol + per-md-gap + GAP_REPORT.md; no test edits). Pre-existing coverage via Superchain tests assumed.

**Documentation/Skills Gaps (if applicable):**
Out of scope (edits limited).

**Notes for Subagents:**
- Implemented ONLY for these gaps on these 3 files.
- Used ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no values for these Repos).
- References exact slot names, verification commands, reads in GAP_REPORT.md.
- Did not edit any other files.
- All post-edit cmds strictly limited as required.

**Priority:** High (closed)

## Central NatSpec Population (coordinated pass)
Consult CENTRALLY_COMPUTED_NATSPEC_VALUES.md. No entries for SuperchainSenderNonce* (internal Repo symbols) in this pass. Only rich NatSpec used; no @custom inserted. If public interface ISuperchainSenderNonce or Facet symbols are added later to centrals, they would be populated separately.
