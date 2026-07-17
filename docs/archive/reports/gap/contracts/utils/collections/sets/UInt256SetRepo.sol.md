# Gap Report for: contracts/utils/collections/sets/UInt256SetRepo.sol

**File Type:** Pure struct-passing utility Repo (no STORAGE_SLOT / _layout binding; functions accept `UInt256Set storage` directly). LR-6 n/a.

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include-tags)

**Current State Summary:**
Post-LR-1: full rich NatSpec + exact // tag::/end:: . CLOSED. (Pre: partial @dev only with some inaccuracies, 0 tags. LR-6 n/a. Preserved unique maxValue/_max logic exactly.)

**Detailed Gaps Closed (LR-1):**
- LR-1: Full rich NatSpec + EXACT gold // tag:: / end:: for UInt256SetRepo[], UInt256Set[] and ALL _* (key listed below; hyphen overloads e.g. _add(UInt256Set-uint256)[], _add(UInt256Set-uint256[])[] etc).
- LR-6: n/a (pure struct-passing utility Repo; no STORAGE_SLOT / _layout binding as noted in scope).

**Actions Taken (CLOSED):**
- Strict read order 1-6 before edits.
- LR-1: rich NatSpec + exact tags for all symbols listed.
- No centrals/customs.
- Preserved logic exactly 100% (1-indexed, idempotency, BetterArrays, maxValue-only-increase on add, _remove no recompute max, etc).
- ONLY edited 3 files relative.

**Symbols Covered (expanded from source surface, modeled Address/Bytes32):**
- UInt256Set[]
- UInt256SetRepo[]
- _index(UInt256Set-uint256)[]
- _indexOf(UInt256Set-uint256)[]
- _contains(UInt256Set-uint256)[]
- _length(UInt256Set)[]
- _add(UInt256Set-uint256)[]
- _add(UInt256Set-uint256[])[]
- _remove(UInt256Set-uint256)[]
- _remove(UInt256Set-uint256[])[]
- _asArray(UInt256Set)[]
- _values(UInt256Set)[]
- _max(UInt256Set)[]

**Centrals Used:** None (from CENTRALLY_COMPUTED_NATSPEC_VALUES.md - none expected/does not exist; prose only; no @custom fabricated).

**LR-7 Notes:** n/a for this scoped LR-1 utility (see usage in UInt256SetRepo.t.sol invariants/handlers; tests cover via _add/_remove/_index/_contains/_max/_values/_length/_asArray/_indexOf).

**LR-2/LR-3 Notes:** Cross-refs exist in docs (e.g. via AGENTS + CODEBASE_MAP + per other LR work); utilities/Sets covered at high level for GitBook.

**Modeled On Golds + Strict Order:** Strict read order followed (1. docs/reports/gap/contracts/utils/collections/sets/UInt256SetRepo.sol.md , 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY; none expected), 3. PRD LR-1, 4. AGENTS.md (exact // tag::Name(params)[] /end, hyphen overloads, rich NatSpec for pure utils, only 3 files, relative, targeted verif), 5. golds (recent AddressSetRepo.sol + Bytes32SetRepo.sol closures (20 tags each), OperableRepo, FacetRegistryRepo, comparator Set patterns), 6. source. See full recap + symbols above. Preserved all. 13 tags. No centrals. 3 files only.

**Verification Summary:** Targeted `forge inspect contracts/utils/collections/sets/UInt256SetRepo.sol:UInt256SetRepo (abi|storageLayout|methodIdentifiers)`, `forge build contracts/utils/collections/sets/UInt256SetRepo.sol --skip test --quiet`, narrow list '*SetRepo*' executed post-edit.

**LR-1 Status:** CLOSED. Final // tag:: count reported below. [x] added to GAP_REPORT.md.
