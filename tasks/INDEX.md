# Task Index: Crane Framework

**Repo:** CRANE
**Last Updated:** 2026-01-14

## Active Tasks

| ID | Title | Status | Dependencies | Worktree |
|----|-------|--------|--------------|----------|
| CRANE-016 | Add End-to-End Factory Deployment Tests | Ready | CRANE-002 | `test/factory-e2e` |
| CRANE-017 | Add Negative Assertions to Test Framework | Ready | CRANE-003 | `fix/test-negative-assertions` |
| CRANE-018 | Improve Test Verification Rigor | Ready | CRANE-003 | `fix/test-verification-rigor` |
| CRANE-019 | Add Test Edge Cases and Cleanup | Ready | CRANE-003 | `fix/test-edge-cases` |
| CRANE-026 | Strengthen Overflow Boundary Tests | Ready | CRANE-006 | `test/overflow-boundary-tests` |
| CRANE-027 | Add Multi-hop Routing Tests | Ready | CRANE-007 | `test/multihop-routing-tests` |
| CRANE-028 | Add Price Impact Tests | Ready | CRANE-007 | `test/price-impact-tests` |
| CRANE-029 | ConstProdUtils Code Cleanup and NatSpec | Ready | CRANE-007 | `fix/constprodutils-cleanup` |
| CRANE-030 | Add FEE_LOWEST Constant to TestBase | Ready | CRANE-008 | `fix/fee-lowest-constant` |
| CRANE-031 | Fix EdgeCases Test Count Documentation | Ready | CRANE-008 | `fix/edgecases-count-doc` |
| CRANE-032 | Add TickMath Bijection Fuzz Tests | Ready | CRANE-008 | `test/tickmath-bijection-fuzz` |
| CRANE-033 | Add Uniswap V4 Pure Math Unit Tests | Ready | CRANE-009 | `test/v4-pure-math-tests` |
| CRANE-034 | Add Uniswap V4 SwapMath Fuzz Tests | Ready | CRANE-009 | `test/v4-swapmath-fuzz` |
| CRANE-035 | Document Uniswap V4 Dynamic Fee Pool Limitations | Ready | CRANE-009 | `fix/v4-dynamic-fee-docs` |
| CRANE-036 | Optimize StateLibrary Hashing | Ready | CRANE-009 | `fix/statelibrary-hash-optimize` |
| CRANE-037 | Add Aerodrome Stable Pool Support | Ready | CRANE-010 | `feature/aerodrome-stable-pool` |
| CRANE-039 | Add Slipstream Fork Tests | Ready | CRANE-011 | `test/slipstream-fork-tests` |
| CRANE-040 | Add Slipstream Edge Case Tests | Ready | CRANE-011 | `test/slipstream-edge-cases` |
| CRANE-041 | Add Slipstream Invariant Tests | Ready | CRANE-011 | `test/slipstream-invariants` |
| CRANE-042 | Add Unstaked Fee Handling | Ready | CRANE-011 | `feature/slipstream-unstaked-fee` |
| CRANE-043 | Add Reward Quoting Utilities | Ready | CRANE-011 | `feature/slipstream-reward-utils` |
| CRANE-045 | Add Camelot V2 Stable Swap Pool Tests | Ready | CRANE-012 | `test/camelot-stable-swap` |
| CRANE-046 | Add Protocol Fee Mint Parity Tests | Ready | CRANE-012 | `test/camelot-protocol-fee-parity` |
| CRANE-047 | Add Fee-on-Transfer Token Integration Tests | Ready | CRANE-012 | `test/camelot-fot-integration` |
| CRANE-048 | Add Referrer Fee Integration Tests | Ready | CRANE-012 | `test/camelot-referrer-fee` |
| CRANE-049 | Add K Invariant Preservation Tests | Ready | CRANE-012 | `test/camelot-k-invariant` |
| CRANE-050 | Add Multi-Hop Swap with Directional Fees Tests | Ready | CRANE-012 | `test/camelot-multihop-fees` |
| CRANE-052 | Add FixedPoint Rounding to Balancer V3 Swaps | Ready | CRANE-013 | `fix/balancer-fixedpoint-rounding` |
| CRANE-054 | Add DFPkg Deployment Test for Selector Collision | Ready | CRANE-013 | `test/dfpkg-deployment` |
| CRANE-055 | Implement Balancer V3 Weighted Pool Facet/Target | Ready | CRANE-013 | `feature/weighted-pool-facet` |
| CRANE-056 | Add Proxy-Level Routing Regression Test | Ready | CRANE-014 | `test/proxy-routing-regression` |
| CRANE-057 | Fix Remove Selector Ownership Validation | Ready | CRANE-014 | `fix/remove-selector-ownership` |
| CRANE-058 | Implement Partial Remove Semantics | Ready | CRANE-014 | `fix/partial-remove-semantics` |
| CRANE-059 | Add ERC165Repo Storage Overload Test | Ready | CRANE-015 | `test/erc165-storage-overload` |
| CRANE-060 | Add ERC-165 Strict Semantics for 0xffffffff | Ready | CRANE-015 | `fix/erc165-strict-semantics` |
| CRANE-061 | Add DFPkg Deployment Integration Test | Ready | CRANE-053 | `test/dfpkg-deployment-integration` |
| CRANE-062 | Add Heterogeneous TokenConfig Order-Independence Tests | Ready | CRANE-053 | `test/tokenconfig-heterogeneous` |
| CRANE-063 | Add EXACT_OUT Pool-Favorable Rounding Tests | Ready | CRANE-053 | `test/exact-out-rounding` |
| CRANE-064 | Adopt IFacet TestBase Pattern for ERC5267 | Ready | CRANE-023 | `refactor/erc5267-testbase` |
| CRANE-065 | Add ERC5267 Diamond Proxy Integration Test | Ready | CRANE-023 | `test/erc5267-proxy-integration` |
| CRANE-066 | Strengthen Zap-In Value Conservation Assertions | Ready | CRANE-038 | `test/slipstream-zapin-conservation` |
| CRANE-067 | Add Slipstream Single-Tick Guard Assertion | Ready | CRANE-038 | `test/slipstream-singletick-guard` |
| CRANE-068 | Add Slipstream Fuzz Test Repro Notes | Ready | CRANE-038 | `docs/slipstream-repro-notes` |
| CRANE-069 | Tighten Camelot Bidirectional Fuzz Assertion | Ready | CRANE-044 | `test/camelot-bidirectional-fuzz` |
| CRANE-070 | Reduce Noisy Logs from Camelot Stubs | Ready | CRANE-044 | `fix/camelot-stub-logs` |

## Status Legend

- **Ready** - All dependencies met, can be launched with `/backlog:launch`
- **In Progress** - Implementation agent working (has worktree)
- **In Review** - Implementation complete, awaiting code review
- **Changes Requested** - Review found issues, needs fixes
- **Pending Merge** - Approved and rebased, ready for fast-forward merge
- **Complete** - Review passed, ready to archive with `/backlog:prune`
- **Blocked** - Waiting on dependencies

## Quick Filters

### Ready for Agent

**Core Framework (20 tasks):**
- CRANE-016: Add End-to-End Factory Deployment Tests (from CRANE-002)
- CRANE-017: Add Negative Assertions to Test Framework (from CRANE-003)
- CRANE-018: Improve Test Verification Rigor (from CRANE-003)
- CRANE-019: Add Test Edge Cases and Cleanup (from CRANE-003)
- **CRANE-024: Harden Zap-Out Fee-On Input Validation (High - from CRANE-006)**
- CRANE-025: Replace Fee-Denominator Heuristic (from CRANE-006)
- CRANE-026: Strengthen Overflow Boundary Tests (from CRANE-006)
- CRANE-027: Add Multi-hop Routing Tests (from CRANE-007)
- CRANE-028: Add Price Impact Tests (from CRANE-007)
- CRANE-029: ConstProdUtils Code Cleanup and NatSpec (from CRANE-007)
- CRANE-030: Add FEE_LOWEST Constant to TestBase (from CRANE-008)
- CRANE-031: Fix EdgeCases Test Count Documentation (from CRANE-008)
- CRANE-032: Add TickMath Bijection Fuzz Tests (from CRANE-008)
- CRANE-033: Add Uniswap V4 Pure Math Unit Tests (from CRANE-009)
- CRANE-034: Add Uniswap V4 SwapMath Fuzz Tests (from CRANE-009)
- CRANE-035: Document Uniswap V4 Dynamic Fee Pool Limitations (from CRANE-009)
- CRANE-036: Optimize StateLibrary Hashing (from CRANE-009)
- CRANE-037: Add Aerodrome Stable Pool Support (from CRANE-010)

**Slipstream Follow-ups (5 tasks - from CRANE-011):**
- CRANE-039: Add Slipstream Fork Tests (High)
- CRANE-040: Add Slipstream Edge Case Tests (High)
- CRANE-041: Add Slipstream Invariant Tests (High)
- CRANE-042: Add Unstaked Fee Handling (Medium)
- CRANE-043: Add Reward Quoting Utilities (Low)

**Slipstream Fuzz Test Follow-ups (3 tasks - from CRANE-038):**
- CRANE-066: Strengthen Zap-In Value Conservation Assertions (Medium)
- CRANE-067: Add Slipstream Single-Tick Guard Assertion (Low)
- CRANE-068: Add Slipstream Fuzz Test Repro Notes (Low)

**Camelot V2 Follow-ups (6 tasks - from CRANE-012):**
- CRANE-045: Add Camelot V2 Stable Swap Pool Tests (High)
- CRANE-049: Add K Invariant Preservation Tests (High)
- CRANE-046: Add Protocol Fee Mint Parity Tests (Medium)
- CRANE-047: Add Fee-on-Transfer Token Integration Tests (Medium)
- CRANE-048: Add Referrer Fee Integration Tests (Low)
- CRANE-050: Add Multi-Hop Swap with Directional Fees Tests (Low)

**Camelot Asymmetric Fee Test Follow-ups (2 tasks - from CRANE-044):**
- CRANE-069: Tighten Camelot Bidirectional Fuzz Assertion (Medium)
- CRANE-070: Reduce Noisy Logs from Camelot Stubs (Low)

**Balancer V3 Follow-ups (6 tasks - from CRANE-013/CRANE-053):**
- **CRANE-054: Add DFPkg Deployment Test for Selector Collision (High)**
- **CRANE-061: Add DFPkg Deployment Integration Test (High - from CRANE-053)**
- **CRANE-062: Add Heterogeneous TokenConfig Order-Independence Tests (High - from CRANE-053)**
- CRANE-052: Add FixedPoint Rounding to Balancer V3 Swaps (Medium)
- CRANE-063: Add EXACT_OUT Pool-Favorable Rounding Tests (Medium - from CRANE-053)
- CRANE-055: Implement Balancer V3 Weighted Pool Facet/Target (Low)

**ERC2535 Follow-ups (3 tasks - from CRANE-014):**
- **CRANE-057: Fix Remove Selector Ownership Validation (High)**
- CRANE-056: Add Proxy-Level Routing Regression Test (Medium)
- CRANE-058: Implement Partial Remove Semantics (Medium)

**ERC165 Follow-ups (2 tasks - from CRANE-015):**
- CRANE-059: Add ERC165Repo Storage Overload Test (Low)
- CRANE-060: Add ERC-165 Strict Semantics for 0xffffffff (Low)

**ERC5267 Follow-ups (2 tasks - from CRANE-023):**
- CRANE-064: Adopt IFacet TestBase Pattern for ERC5267 (Low)
- CRANE-065: Add ERC5267 Diamond Proxy Integration Test (Low)

### Blocked

(No blocked tasks)

## Retired Tasks

| ID | Reason |
|----|--------|
| CRANE-004 | Split into per-DEX per-version tasks (CRANE-007 through CRANE-013) |

## Archived Tasks

| ID | Title | Completed | Location |
|----|-------|-----------|----------|
| CRANE-001 | CREATE3 Factory and Deterministic Deployment Review | 2026-01-13 | archive/CRANE-001-create3-factory-determinism/ |
| CRANE-002 | Diamond Package and Proxy Architecture Review | 2026-01-13 | archive/CRANE-002-diamond-package-proxy/ |
| CRANE-003 | Test Framework and IFacet Pattern Audit | 2026-01-13 | archive/CRANE-003-test-framework-ifacet/ |
| CRANE-005 | Token Standards Review (ERC20, Permit, EIP-712) | 2026-01-13 | archive/CRANE-005-token-standards-eip712-permit/ |
| CRANE-006 | Constant Product & Bonding Math Review | 2026-01-13 | archive/CRANE-006-constprodutils-bonding-math/ |
| CRANE-007 | Uniswap V2 Utilities Review | 2026-01-13 | archive/CRANE-007-uniswap-v2-utils/ |
| CRANE-008 | Uniswap V3 Utilities Review | 2026-01-13 | archive/CRANE-008-uniswap-v3-utils/ |
| CRANE-009 | Uniswap V4 Utilities Review | 2026-01-13 | archive/CRANE-009-uniswap-v4-utils/ |
| CRANE-010 | Aerodrome V1 Utilities Review | 2026-01-13 | archive/CRANE-010-aerodrome-v1-utils/ |
| CRANE-011 | Slipstream Utilities Review | 2026-01-13 | archive/CRANE-011-slipstream-utils/ |
| CRANE-012 | Camelot V2 Utilities Review | 2026-01-13 | archive/CRANE-012-camelot-v2-utils/ |
| CRANE-013 | Balancer V3 Utilities Review | 2026-01-14 | archive/CRANE-013-balancer-v3-utils/ |
| CRANE-014 | Fix ERC2535 Remove/Replace Correctness | 2026-01-14 | archive/CRANE-014-fix-erc2535-remove-replace/ |
| CRANE-015 | Fix ERC165Repo Overload Bug | 2026-01-14 | archive/CRANE-015-fix-erc165-overload/ |
| CRANE-020 | Fix Critical ERC20 transferFrom Allowance Bypass | 2026-01-14 | archive/CRANE-020-fix-erc20-transferfrom-allowance/ |
| CRANE-021 | Fix ERC5267Facet Array Size Bug | 2026-01-14 | archive/CRANE-021-fix-erc5267-array-size/ |
| CRANE-022 | Rename EIP721_TYPE_HASH to EIP712_TYPE_HASH | 2026-01-14 | archive/CRANE-022-fix-eip712-typehash-typo/ |
| CRANE-023 | Add ERC-5267 Test Coverage | 2026-01-14 | archive/CRANE-023-add-erc5267-tests/ |
| CRANE-024 | Harden Zap-Out Fee-On Input Validation | 2026-01-14 | archive/CRANE-024-harden-zapout-fee-validation/ |
| CRANE-025 | Replace Fee-Denominator Heuristic | 2026-01-14 | archive/CRANE-025-explicit-fee-denominator/ |
| CRANE-053 | Create Comprehensive Test Suite for Balancer V3 | 2026-01-14 | archive/CRANE-053-balancer-v3-comprehensive-tests/ |
| CRANE-038 | Add Slipstream Fuzz Tests | 2026-01-15 | archive/CRANE-038-slipstream-fuzz-tests/ |
| CRANE-044 | Add Camelot V2 Asymmetric Fee Tests | 2026-01-15 | archive/CRANE-044-camelot-asymmetric-fee-tests/ |
| CRANE-051 | Fix TokenConfigUtils._sort() Data Corruption Bug | 2026-01-15 | archive/CRANE-051-fix-tokenconfig-sort-bug/ |

## Cross-Repo Dependencies

Tasks in other repos that depend on this repo's tasks:
- (none yet)
