# Gap Report for: contracts/test/comparators/Bytes4SetComparator.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
$ gaps

**Current State Summary:**
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**Detailed Gaps (pre-edit):**
- LR-1: 1 tag stub only (`// tag::_layout[]`, no ends, minimal prose NatSpec). No rich @notice/@param, no exact gold tags/hyphen overloads for Bytes4ComparatorRequest / Bytes4SetComparatorLayout / Bytes4SetComparatorRepo (with _recExpectedBytes4 etc) / Bytes4SetComparator (_compare / _logCompare). "tests almost entirely undocumented". Used by Behaviors for set compare in declaration tests. No @custom apply.

**LR-1 Actions Performed (gold standard):**
- Strict 6 reads order completed first (see recap below).
- Rich NatSpec + EXACT // tag::Name(with-hyphen-params)[] / end:: wrapped for all surface.
- Modeled on AddressSetComparator (14+), AddressSetRepo/Bytes4SetRepo (20+), Behavior_IFacet.
- No @custom (CENTRALLY prose only; comparators have none).
- Preserved 100% logic exactly.
- ONLY edited relative: contracts/test/comparators/Bytes4SetComparator.sol + this per-file gap + GAP_REPORT.md .

**STRICT READ ORDER (before ANY edit):**
1. read_file docs/reports/gap/contracts/test/comparators/Bytes4SetComparator.sol.md
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (prose only; no @custom for comparators)
3. read_file PRD.md (LR-1 scope: all test files incl comparators/handlers)
4. read_file AGENTS.md (comparator/Behavior patterns, exact tags, "tests almost entirely undocumented")
5. Golds: AddressSetComparator.sol (14+ rich hyphen _rec*/_compare*), AddressSetRepo + Bytes4SetRepo (20+ hyphen _add*), Behavior_IFacet, other comparators (String*, ComparatorLogger*, FacetsComparator)
6. Read source contracts/test/comparators/Bytes4SetComparator.sol

**Symbols closed (13+ tags):**
- Bytes4ComparatorRequest[], Bytes4SetComparatorLayout[]
- Bytes4SetComparatorRepo[] + _layoutStruct(bytes32)[], _b4SetCompare(bytes32)[], _recExpectedBytes4(address-bytes4-bytes4[])[], _recExpectedBytes4(address-bytes4-bytes4)[], _recedExpectedBytes4(address-bytes4)[], _tempExpectedBytes4(bytes32)[], _actualBytes4(bytes32)[]
- Bytes4SetComparator[] + _compare(bytes4[]-bytes4[]-string-string)[], _logCompare(Bytes4ComparatorRequest)[], _compare(bytes4[]-bytes4)[]

**LR-1 CLOSED**
Pre: 1 / Post: 13+ tags. Centrals: none used/fab. No slots.

**Verification (targeted ONLY post):**
- forge inspect contracts/test/comparators/Bytes4SetComparator.sol:Bytes4SetComparator (abi|methodIdentifiers)
- forge build contracts/test/comparators/Bytes4SetComparator.sol --skip test --quiet
- narrow forge test --list '*Bytes4SetComparator*|*Comparator*'

See GAP_REPORT.md [x] entry. Per LR-1/PRD/AGENTS.

**Priority:** High (supports LR-7 Behavior_IFacet set comparisons)
