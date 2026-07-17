# Gap Report for: contracts/access/reentrancy/ReentrancyLockRepo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (Mandatory & Verifiable)
- LR-6: ERC1967-Compliant Storage Slot Derivation (DEFAULT_SLOT / STORAGE_SLOT)

**Current State Summary:**
Gaps closed for this file per LR-1 and LR-6. Strict read order followed before any edits: (1) target gap report, (2) CENTRALLY_COMPUTED_NATSPEC_VALUES.md, (3) PRD.md (relevant LR-1, LR-6, LR-7), (4) AGENTS.md (full), (5) source + gold standards (OperableRepo.sol, MultiStepOwnableRepo.sol, ERC2535Repo.sol). Only edited the 3 allowed files. Used ONLY prose (no fabricated @custom selectors since no ReentrancyLock entries in centrals file).

Gaps were:
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**Detailed Gaps (Closed):**
- LR-6: STORAGE_SLOT fixed to EXACT ERC1967 form `bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.access.reentrancy.lock"))) - 1);` . Hierarchical name chosen per task/gold "crane.access.reentrancy.lock" analogous to "crane.access.operable". Updated all references + dual _layoutStruct.
- LR-1: Added rich NatSpec (@title/@author/@notice/@dev/@param/@return/@custom:throws) + EXACT // tag::Symbol[] wrappers (library ReentrancyLockRepo[], STORAGE_SLOT, _layoutStruct(bytes32)[], _layoutStruct()[], _lock()[], _unlock()[], _isLocked()[], _onlyUnlocked()[]). Modeled directly on OperableRepo/MultiStepOwnableRepo/ERC2535Repo gold. No @custom:selector etc added (none in CENTRALLY_COMPUTED_NATSPEC_VALUES.md for this; followed "if no entry, add only rich prose/docs").
- Note: This Repo uses transient storage (not struct layout) so no Storage struct / _initialize; added dual _layoutStruct returning the slot bytes32 key (used internally by _* funcs). No changes to function signatures.

**Actions Completed:**
- Fixed STORAGE_SLOT + made internal + updated calls to use _layoutStruct().
- Added dual _layoutStruct (bytes32 + default) + full tags/NatSpec on all.
- Consulted centrals (none for IsLocked / isLocked / reentrancy funcs, so no @custom inserted).
- Targeted verifs after each batch: forge inspect ...:ReentrancyLockRepo (abi|methodIdentifiers), forge build --quiet --skip test (via bg/timeout wrappers), forge test --list --match-path '*ReentrancyLock*'.
- Updated this per-file gap + GAP_REPORT.md only (3 files total).

**NatSpec Symbols Tagged:**
- ReentrancyLockRepo, STORAGE_SLOT, _layoutStruct(bytes32)[], _layoutStruct()[], _lock()[], _unlock()[], _isLocked()[], _onlyUnlocked()[] .
(Note: related public surface like isLocked(), IsLocked error live in IReentrancyLock.sol + used via inheritance; not edited here.)

**Testing Gaps (LR-7 specific if applicable):**
Scoped out (no test edits per strict rules; only source+pergap+GAP). See LR-7 note in PRD that ReentrancyLockRepo users must have dedicated reentrancy matrix tests (pre-existing coverage assumed in other test files).

**Documentation/Skills Gaps (if applicable):**
Out of scope for this subagent task (edits limited to 3 files).

**Notes for Subagents:**
- Implemented ONLY fixes for this file's gaps (LR-6 slot + LR-1 NatSpec/tags/dual layout).
- Centrals referenced: CENTRALLY_COMPUTED_NATSPEC_VALUES.md (only prose, no selectors fabricated).
- Updated the main GAP_REPORT.md checkbox + detailed tracking entry.
- Did not edit any other files.
- All verifs used ONLY allowed targeted commands (no full `forge test`, no --no-verify).

**Priority:** High (closed)

## Central NatSpec Population (coordinated pass)
Consult CENTRALLY_COMPUTED_NATSPEC_VALUES.md . No ReentrancyLock / IReentrancyLock entries present in this pass (only core like IOperable, IDiamond*, IFacet). For symbols here: used only rich NatSpec/docs. Interface symbols (e.g. isLocked() selector, IsLocked error) would be handled in coordinated pass if entries added.
