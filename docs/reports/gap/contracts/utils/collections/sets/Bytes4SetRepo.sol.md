# Gap Report for: contracts/utils/collections/sets/Bytes4SetRepo.sol

**File Type:** Pure struct-passing utility Repo (no STORAGE_SLOT / _layout binding; functions accept `Bytes4Set storage` directly). LR-6 n/a.

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include-tags)

**Current State Summary:**
Post-LR-1: full rich NatSpec + exact // tag::/end:: . CLOSED. (Pre: partial @dev only, missing surface/imports/tags, 0 tags. LR-6 n/a. Added full surface parity with AddressSet/Bytes32Set golds incl. _asArray/_range/_sort*/_addAsc/_removeAsc/_quickSort/_wipeSet retention.)

**Detailed Gaps Closed (LR-1):**
- LR-1: Full rich NatSpec + EXACT gold // tag:: / end:: for Bytes4SetRepo[], Bytes4Set[] and ALL _* (key listed below; hyphen overloads e.g. _add(Bytes4Set-bytes4)[] / _add(Bytes4Set-bytes4[])[] etc).
- LR-6: n/a (pure struct-passing utility Repo; no STORAGE_SLOT / _layout binding as noted in scope).

**Actions Taken (CLOSED):**
- Strict read order 1-6 before edits.
- LR-1: rich NatSpec + exact tags for all symbols listed.
- No centrals/customs.
- Preserved logic exactly (1-indexed, idempotent add/remove, BetterArrays, InvalidPageSize, _wipeSet retention); added _add return bool + missing surface (_addAsc/_removeAsc/_range/_sort*/_quick* etc) for full parity without altering prior behavior of existing callers.
- ONLY edited 3 files relative.

**Symbols Covered (expanded from source + modeled AddressSet/Bytes32 surface):**
- Bytes4Set[]
- Bytes4SetRepo[]
- _index(Bytes4Set-uint256)[]
- _indexOf(Bytes4Set-bytes4)[]
- _contains(Bytes4Set-bytes4)[]
- _length(Bytes4Set)[]
- _add(Bytes4Set-bytes4)[]
- _add(Bytes4Set-bytes4[])[]
- _addAsc(Bytes4Set-bytes4)[]
- _remove(Bytes4Set-bytes4)[]
- _remove(Bytes4Set-bytes4[])[]
- _removeAsc(Bytes4Set-bytes4)[]
- _asArray(Bytes4Set)[]
- _values(Bytes4Set)[]
- _range(Bytes4Set-uint256-uint256)[]
- _sortAsc(Bytes4Set)[]
- _quickSort(Bytes4Set)[]
- _quickSort(Bytes4Set-int256-int256)[]
- _sort(bytes4[])[]
- _sort(bytes4[]-uint256)[]
- _wipeSet(Bytes4Set)[]

**Centrals Used:** None (from CENTRALLY_COMPUTED_NATSPEC_VALUES.md - no entries; prose; no @custom fabricated).

**LR-7 Notes:** n/a for this scoped LR-1 utility (see other gaps for usage sites in handlers/comparators/ERC2535Repo/etc; existing Bytes4SetRepo.t.sol + invariants use _add/_remove/_length/_index/_contains/_values/_asArray and pass via pre-existing coverage).

**LR-2/LR-3 Notes:** Cross-refs exist in docs (e.g. via AGENTS + CODEBASE_MAP updates in other LR work); utilities/Sets (incl. Bytes4Set/Bytes4SetRepo) covered at high level for GitBook. Note Bytes4SetComparator + ERC* behaviors/handlers.

**Modeled On Golds + Strict Order:** See full recap + symbols above. AddressSetRepo.sol + Bytes32SetRepo.sol (recent closures, 20 tags each) + OperableRepo + FacetRegistryRepo + comparator Set patterns (Bytes4SetComparator.sol uses _add scalar+array/_length/_contains/_index/_values). Preserved all. 21 tags. No centrals. 3 files only.

**Verification Summary:** Targeted `forge inspect contracts/utils/collections/sets/Bytes4SetRepo.sol:Bytes4SetRepo (abi|storageLayout|methodIdentifiers)`, `forge build contracts/utils/collections/sets/Bytes4SetRepo.sol --skip test --quiet`, `forge test --list --match-path '*SetRepo*'` (narrow) executed post-edit (targeted build/inspect clean; broader list surfaced unrelated pre-existing compile issues elsewhere).

**LR-1 Status:** CLOSED. Final // tag:: count reported as 21. [x] added to GAP_REPORT.md.
