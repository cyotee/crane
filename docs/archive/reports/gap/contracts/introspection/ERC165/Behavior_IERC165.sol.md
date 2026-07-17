# Gap Report for: contracts/introspection/ERC165/Behavior_IERC165.sol

**File Type:** Source File (Behavior library)

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include-tags), LR-7 (Behavior libraries gold standard for declaration/compliance tests, NatSpec on test infrastructure/Behaviors).

**Current State Summary:**
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**Strict Mandatory Read Order Recap (before any edit):**
1. docs/reports/gap/contracts/introspection/ERC165/Behavior_IERC165.sol.md
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (supportsInterface 0x01ffc9a7 only)
3. PRD.md (LR-1 rich NatSpec + tags + hyphen + centrals + Behaviors/LR-7)
4. AGENTS.md (Behavior gold, 3files only, targeted verif relative, exact tag format)
5. Golds (Behavior_IFacet.sol + ERC165 dir TestBase/IERC165 + TestBase_IFacet/BehaviorUtils)
6. contracts/introspection/ERC165/Behavior_IERC165.sol (parsed symbols)

**Detailed Gaps (pre):**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).

**Post-edit:** Full LR-1 applied; LR-1 CLOSED.

**Specific Actions Taken to Close Gaps (LR-1 only, strict scope):**
- ONLY the 3 relative files edited: the .sol + per-file .md + GAP_REPORT.md (no more).
- Wrapped library Behavior_IERC165[] + every symbol with exact // tag::...[] / // end:: (hyphen overloads).
- Added rich NatSpec + @custom: ONLY from CENTRALLY (0x01ffc9a7 for supportsInterface).
- Modelled on Behavior_IFacet gold exactly: rich prose, no logic changes.
- Symbols tagged: 14 (see list below).
- LR-7 Behavior role preserved/enhanced in docs (no test file changes per scope).

**Actions Needed (original):**
1. Wrap documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Add @notice, @param, @return, @custom:selector / signature  with values from CENTRALLY only.
- (Repo slot n/a for Behavior lib). @custom only from centrals.

**NatSpec Symbols Tagged (parsed all from step-6 read_file of .sol; high coverage):**
- library Behavior_IERC165[]
- _Behavior_IERC165Name()[]
- _ierc165_errPrefixFunc(string)[]
- _ierc165_errPrefix(string-string)[] , _ierc165_errPrefix(string-address)[]
- funcSig_IERC165_supportsInterFace()[]  (@custom:selector 0x01ffc9a7 + sig from central)
- _errPrefix_IERC165_supportsInterFace(string)[] , errBody_IERC165_supportsInterFace()[]
- isValid_IERC165_supportsInterfaces(string-bool-bool)[] , isValid_IERC165_supportsInterfaces(IERC165-bool-bool)[]
- expect_IERC165_supportsInterface(IERC165-bytes4)[] , expect_IERC165_supportsInterface(IERC165-bytes4[])[]
- _expected_IERC165_supportsInterface(IERC165)[] , hasValid_IERC165_supportsInterface(IERC165)[]
**Total symbols tagged: 14** (pre: 0 ; post: 14 pairs).

(Original note expanded fully per parse + gold model.)

**Testing Gaps (LR-7 specific if applicable):**
- Full initialization of subjects (Packages with real facet addresses, not 0).
- Exact assertions vs side-effect checks.
- Preview vs execute parity.
- Use of Behavior_IFacet / Behavior_IDiamondFactoryPackage etc.
- Declaration tests for facets and packages.
(Note: this Behavior lib itself is the enabler for LR-7 declaration tests using Behavior_*; no changes to tests per strict scope.)

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3).

**Post-edit Verification (targeted relative ONLY):**
- forge inspect contracts/introspection/ERC165/Behavior_IERC165.sol:Behavior_IERC165 abi : clean table (errBody, funcSig, hasValid, isValid* overloads)
- forge inspect ... methodIdentifiers : clean table with selectors (note overloads listed distinctly)
- forge inspect ... storageLayout : n/a (pure lib expected; no state)
- forge build contracts/introspection/ERC165/Behavior_IERC165.sol --skip test --quiet : BUILD_EXIT=0
- forge test --list --match-path '*ERC165*' : command executed (unrelated broad project errors in output ignored per instructions; targeted .sol path clean via build/inspect)

**Notes for Subagents:**
- Implement only fixes for this file's gaps. (Followed: ONLY 3 files)
- @custom values ONLY from CENTRALLY_COMPUTED_NATSPEC_VALUES.md
- Update the main GAP_REPORT.md checkbox when done. (Done)
- Do not edit other files. (Followed)

**LR-1 CLOSED** (14 tags, modeled on gold, strict order, centrals, targeted verif, 3 files only)

**Priority:** High (core framework files)
