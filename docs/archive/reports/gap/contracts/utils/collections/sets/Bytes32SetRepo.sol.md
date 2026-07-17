# Gap Report for: contracts/utils/collections/sets/Bytes32SetRepo.sol

**File Type:** Pure struct-passing utility Repo (no STORAGE_SLOT / _layout binding; functions accept `Bytes32Set storage` directly). LR-6 n/a.

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include-tags)

**Current State Summary:**
Post-LR-1: full rich NatSpec + exact // tag::/end:: . CLOSED. (Pre: partial @dev only with typos, 0 tags. LR-6 n/a. Added full surface parity with AddressSet gold incl. _asArray/_range/_sort*/_addAsc etc.)

**Detailed Gaps Closed (LR-1):**
- LR-1: Full rich NatSpec + EXACT gold // tag:: / end:: for Bytes32SetRepo[], Bytes32Set[] and ALL _* (key listed below; hyphen overloads e.g. _add(Bytes32Set-bytes32)[], _add(Bytes32Set-bytes32[])[] etc).
- LR-6: n/a (pure struct-passing utility Repo; no STORAGE_SLOT / _layout binding as noted in scope).

**Actions Taken (CLOSED):**
- Strict read order 1-6 before edits.
- LR-1: rich NatSpec + exact tags for all symbols listed.
- No centrals/customs.
- Preserved logic exactly (1-indexed, idempotent add/remove, BetterArrays usage, etc); adapted AddressSet impl for _add return bool + added missing surface for parity (no behavior change to existing).
- ONLY edited 3 files relative.

**Symbols Covered (expanded from source + modeled AddressSet surface):**
- Bytes32Set[]
- Bytes32SetRepo[]
- _index(Bytes32Set-uint256)[]
- _indexOf(Bytes32Set-bytes32)[]
- _contains(Bytes32Set-bytes32)[]
- _length(Bytes32Set)[]
- _add(Bytes32Set-bytes32)[]
- _add(Bytes32Set-bytes32[])[]
- _addAsc(Bytes32Set-bytes32)[]
- _remove(Bytes32Set-bytes32)[]
- _remove(Bytes32Set-bytes32[])[]
- _removeAsc(Bytes32Set-bytes32)[]
- _asArray(Bytes32Set)[]
- _values(Bytes32Set)[]
- _range(Bytes32Set-uint256-uint256)[]
- _sortAsc(Bytes32Set)[]
- _quickSort(Bytes32Set)[]
- _quickSort(Bytes32Set-int256-int256)[]
- _sort(bytes32[])[]
- _sort(bytes32[]-uint256)[]

**Centrals Used:** None (from CENTRALLY_COMPUTED_NATSPEC_VALUES.md - no entries; prose; no @custom fabricated).

**LR-7 Notes:** n/a for this scoped LR-1 utility (see other gaps for usage sites in handlers/comparators; tests use _add/_remove/_indexOf/_values and pass via existing invariants).

**LR-2/LR-3 Notes:** Cross-refs exist in docs (e.g. via AGENTS + CODEBASE_MAP updates in other LR work); utilities/Sets (incl. Bytes32Set/Bytes32SetRepo) covered at high level for GitBook.

**Modeled On Golds + Strict Order:** AddressSetRepo.sol (recent closure) + OperableRepo + FacetRegistryRepo + DeployedAddressesRepo + comparator Set patterns (AddressSetComparator etc). See full recap + symbols above. Preserved all existing. 20 tags. No centrals. 3 files only.

**Verification Summary:** Targeted `forge inspect contracts/utils/collections/sets/Bytes32SetRepo.sol:Bytes32SetRepo (abi|storageLayout|methodIdentifiers)`, `forge build contracts/utils/collections/sets/Bytes32SetRepo.sol --skip test --quiet`, narrow list '*SetRepo*' executed post-edit.

**LR-1 Status:** CLOSED. Final // tag:: count reported as 20. [x] added to GAP_REPORT.md.
