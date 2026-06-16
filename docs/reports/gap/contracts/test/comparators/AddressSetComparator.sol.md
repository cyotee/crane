# Gap Report for: contracts/test/comparators/AddressSetComparator.sol

**File Type:** Source File (test support / comparator utility for Behavior libs and declaration tests)

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include-tags on all .sol including test support code; comparator for behaviors per "Add NatSpec + tags to all test files")

**Current State Summary:**
Pre: partial (1 tag on _layout, no rich NatSpec on libs or key methods). Post LR-1: full gold.

**Detailed Gaps (pre-work):**
- LR-1: incomplete NatSpec with // tag:: and rich docs (tests/comparators noted in AGENTS as "assertion helpers"; "tests are almost entirely undocumented" gap note).

**Strict Process Followed (BEFORE ANY edit/search_replace):**
1. read_file docs/reports/gap/contracts/test/comparators/AddressSetComparator.sol.md (stub)
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY for @custom if any apply; NONE listed for Address*Comparator; prose-only; no fabrication)
3. read_file PRD.md (LR-1 full scope incl. all test files e.g. comparators/handlers/behaviors/TestBases; exact // tag::Name(params)[] / end:: ; rich NatSpec; scope covers "all Solidity code" + "test/comparators")
4. read_file AGENTS.md (NatSpec on test code, Behavior + Comparator patterns, "ComparatorRepo", "comparators/ # Assertion helpers", TestBase/Behavior gold, exact hyphen tags, "tests are almost entirely undocumented" gap note, "ONLY 3 files rule", "Stubs, comparators, and shared utilities go in `contracts/test/`")
5. Golds read: closed SetRepos (AddressSetRepo.sol with 20+ tags + exact hyphen on _add(AddressSet-address)[] / _add(AddressSet-address[])[] etc; Bytes32/Bytes4/UInt256/StringSetRepo siblings), Behavior_IFacet.sol (rich tags on test lib: 26+ hyphenated e.g. expect_IFacet(...)[], areValid_* , funcSig_* + @title/@author/@dev/@notice/@custom on helpers from centrals), Behavior_IDiamondLoupe + Behavior_IFacetRegistry (usages of AddressSetComparator*), Bytes4SetComparator.sol (partial comparator), ComparatorLogger/SetComparatorLogger, plus AddressSetRepo usage contexts.
6. Read source contracts/test/comparators/AddressSetComparator.sol (full; pre-count: 1 tag)

**LR-1 CLOSED:** Full rich NatSpec + EXACT // tag:: / end:: applied ONLY to this file's symbols (no logic change). Modeled exactly on golds (AddressSetRepo hyphen overloads + Behavior_IFacet @title/@author/@dev/@notice for test libs + Bytes4SetComparator structure). No @custom fabricated (CENTRALLY none apply; comparators are internal test utils).

**Symbols Tagged (exact, with hyphen for params):**
- AddressComparatorRequest[]
- AddressSetComparatorLayout[]
- AddressSetComparatorRepo[] (lib header)
- _layoutStruct(bytes32)[]
- _addrSetCompare(bytes32)[]
- _recExpectedAddrs(address-bytes32-address)[]
- _recExpectedAddrs(address-bytes32-address[])[]
- _recedExpectedAddrs(address-bytes32)[]
- _tempExpectedAddrs(bytes32)[]
- _actualAddrs(bytes32)[]
- AddressSetComparator[] (lib header)
- _compare(address[]-address[]-string-string)[]
- _logCompare(AddressComparatorRequest)[]
- _compare(address[]-address)[]

**Tag counts:** pre=1 ; post=14 ( + structs + lib wrappers + all key methods; covers compare/rec/reced/temp/actual paths used by Behaviors).

**Changes:** Added @title/@author/@notice/@dev (modeled on Behavior_IFacet + SetRepo), @param/@return on all, detailed @dev explaining bidirectional compare + duplicate detection + AddressSetRepo usage + logging delegation (preserved exact). Wrapped using exact format no extra spaces. 100% logic preserved (revert on dupes, _add on temp/actual, misses counts, abi.encode()._hash(), console.log, SetComparatorLogger._logResult).

**Verification (targeted ONLY post-edit, relative):**
- `forge inspect contracts/test/comparators/AddressSetComparator.sol:AddressSetComparator (abi|methodIdentifiers)`
- `forge build contracts/test/comparators/AddressSetComparator.sol --skip test --quiet`
- narrow list '*Comparator*|*AddressSet*'
(Also exercises via Behaviors in smoke/declaration tests.)

**Golds referenced:** AddressSetRepo (20+ tags, hyphen _add etc), Behavior_IFacet (test lib rich + @custom on helpers), Bytes4SetComparator partial, CraneTest/InitDev/Behavior_* usage.

See main GAP_REPORT.md for [x] under LR-1 test/comparators. Relative paths only. ONLY these 3 files edited.

**Priority:** High (core LR-7 behavior comparator support)