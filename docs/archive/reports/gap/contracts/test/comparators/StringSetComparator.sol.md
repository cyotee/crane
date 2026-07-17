# Gap Report for: contracts/test/comparators/StringSetComparator.sol

**File Type:** Source File (test support / comparator utility for Behavior libs and declaration tests)

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include-tags on all .sol including test support code; sibling comparator to Address/Bytes4 for behaviors per LR-1 on test files/comparators)

**Current State Summary:**
Pre: 1 tag stub only (incomplete `_layout`). Post LR-1: full gold (14 tags, rich + exact hyphen overloads).

**Detailed Gaps (pre-edit):**
- LR-1: 1 tag stub only (`// tag::_layout[]`, no ends, no rich prose NatSpec). No rich @notice/@param on StringComparatorRequest / StringSetComparatorLayout / StringSetComparatorRepo (with _recExpected etc) / StringSetComparator (_compare* / _logCompare). "tests almost entirely undocumented". Not yet consumed by Behaviors (prepared for string[] cases); modeled for parity with closed siblings. No @custom apply (per CENTRALLY).

**STRICT READ ORDER (before ANY edit):**
1. read_file docs/reports/gap/contracts/test/comparators/StringSetComparator.sol.md (stub)
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (prose only; no @custom for comparators)
3. read_file PRD.md (LR-1 scope: all test files incl comparators/handlers; "tests undocumented"; test support)
4. read_file AGENTS.md (comparator patterns, exact tags, "tests undocumented", comparators/ as assertion helpers, NatSpec on test code, hyphen overloads)
5. Golds: the just-closed Bytes4SetComparator + AddressSetComparator (14+ tags each, rich + exact hyphen on _rec*/_compare*/_log*), Bytes*SetRepo + StringSetRepo golds (hyphen _add*(Set-xxx)[]), Behavior_IFacet
6. Read source contracts/test/comparators/StringSetComparator.sol

**Symbols closed (14 tags):**
- StringComparatorRequest[]
- StringSetComparatorLayout[]
- StringSetComparatorRepo[] + _layoutStruct(bytes32)[], _stringSetCompare(bytes32)[], _recExpected(address-bytes32-string)[], _recExpected(address-bytes32-string[])[], _recedExpected(address-bytes32)[], _tempExpected(bytes32)[], _actual(bytes32)[]
- StringSetComparator[] + _compare(string[]-string[]-string-string)[], _logCompare(StringComparatorRequest)[], _compare(string[]-string[])[]

**LR-1 CLOSED**
Pre: 1 / Post: 14 tags. Centrals: none used/fab. No slots (pure test util like siblings).

**Verification (targeted ONLY post):**
- forge inspect contracts/test/comparators/StringSetComparator.sol:StringSetComparator (abi|methodIdentifiers)
- forge build contracts/test/comparators/StringSetComparator.sol --skip test --quiet
- narrow list '*StringSetComparator*|*Comparator*'
(Exercises via future Behaviors + Set patterns; parity with Address/Bytes4 closed.)

See GAP_REPORT.md [x] entry. Per LR-1/PRD/AGENTS. Relative paths only.

**Tag counts/health:** 14/14 symbols wrapped with exact format (hyphen overloads for _rec*/_compare); rich @title/@author/@notice/@dev/@param/@return/@dev details; logic 100% identical; imports/headers preserved; builds cleanly. Matches sibling closures exactly in style.

**Priority:** High (completes LR-1 on test support comparators; sibling to Address/Bytes4)


