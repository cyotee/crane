# Task Index: Crane Framework

**Repo:** CRANE
**Last Updated:** 2026-01-17

## Active Tasks

| ID | Title | Status | Dependencies | Worktree |
|----|-------|--------|--------------|----------|
| CRANE-067 | Add Slipstream Single-Tick Guard Assertion | In Progress | CRANE-038 | `test/slipstream-singletick-guard` |
| CRANE-068 | Add Slipstream Fuzz Test Repro Notes | Complete | CRANE-038 | - |
| CRANE-069 | Tighten Camelot Bidirectional Fuzz Assertion | Complete | CRANE-044 | - |
| CRANE-070 | Reduce Noisy Logs from Camelot Stubs | In Progress | CRANE-044 | `fix/camelot-stub-logs` |
| CRANE-071 | Remove Unused IERC20 Import from TokenConfigUtils | Ready | CRANE-051 | `fix/tokenconfig-unused-import` |
| CRANE-072 | Add TokenConfigUtils Field Alignment Fuzz Test | Ready | CRANE-051 | `test/tokenconfig-alignment-fuzz` |
| CRANE-073 | Tighten Non-Revert Assertions in Overflow Tests | Ready | CRANE-026 | `fix/tighten-overflow-assertions` |
| CRANE-074 | Align Multihop Test with Camelot TestBase Patterns | Ready | CRANE-027 | `refactor/multihop-testbase-alignment` |
| CRANE-075 | Rename Price Impact Fuzz Test for Clarity | Ready | CRANE-028 | `fix/priceimpact-test-rename` |
| CRANE-076 | Remove Console Logs from Price Impact Tests | Ready | CRANE-028 | `fix/priceimpact-remove-logs` |
| CRANE-077 | Remove Commented-Out Parameter Stubs | Ready | CRANE-029 | `fix/remove-param-stubs` |
| CRANE-078 | Tighten TickMath Revert Expectations | Ready | CRANE-032 | `fix/tickmath-revert-expectations` |
| CRANE-080 | Add SwapMath Golden Vector Tests | Ready | CRANE-033 | `test/swapmath-golden-vectors` |
| CRANE-081 | Add SqrtPriceMath Custom Error Tests | Ready | CRANE-033 | `test/sqrtpricemath-errors` |
| CRANE-082 | Add TickMath Exact Known Pairs | Ready | CRANE-033 | `test/tickmath-exact-pairs` |
| CRANE-083 | Clarify Deprecated Aerodrome Library Test Intent | Ready | CRANE-037 | `fix/aerodrome-deprecated-test-intent` |
| CRANE-084 | Strengthen Stable-vs-Volatile Slippage Assertion | Ready | CRANE-037 | `test/aerodrome-slippage-assertion` |
| CRANE-085 | Document Stable Swap-Deposit Gas/Complexity | Ready | CRANE-037 | `docs/aerodrome-stable-gas` |
| CRANE-086 | Add Explicit sqrtPriceLimit Bound Test | Ready | CRANE-034 | `test/swapmath-sqrtpricelimit-fuzz` |
| CRANE-087 | Handle amountRemaining == int256.min Edge Case | Ready | CRANE-034 | `test/swapmath-int256min-edge` |
| CRANE-088 | Remove Minor Test Cruft from SwapMath Fuzz Tests | Ready | CRANE-034 | `fix/swapmath-test-cleanup` |
| CRANE-089 | Add Additional High-Liquidity Pool to Fork Tests | Ready | CRANE-039 | `test/slipstream-fork-multipool` |
| CRANE-090 | Add Exact-Output Edge Case Tests to Slipstream Fork Tests | Ready | CRANE-039 | `test/slipstream-fork-exactout-edge` |
| CRANE-091 | Add BetterEfficientHashLib Hash Equivalence Test | Ready | CRANE-036 | `test/hash-equivalence` |
| CRANE-092 | Tighten Slipstream Edge Case Test Assertions | Ready | CRANE-040 | `fix/tighten-slipstream-assertions` |
| CRANE-093 | Make Slipstream Price-Limit Exactness Provable | Ready | CRANE-040 | `fix/price-limit-exactness` |
| CRANE-094 | Align Slipstream Test Pragma with Repo Conventions | Ready | CRANE-040 | `fix/slipstream-pragma-style` |
| CRANE-095 | Add Slipstream Combined Fee Guard | Ready | CRANE-042 | `fix/slipstream-fee-guard` |
| CRANE-096 | Add Unstaked Fee Positive-Path Tests | Ready | CRANE-042 | `test/unstaked-fee-positive` |
| CRANE-097 | Add SlipstreamRewardUtils Fork Test | Ready | CRANE-043 | `test/reward-utils-fork` |
| CRANE-098 | Document SlipstreamRewardUtils Limitations | Ready | CRANE-043 | `docs/reward-utils-natspec` |
| CRANE-099 | Add Direct Assertion for Cubic Invariant _k() | Ready | CRANE-045 | `test/stableswap-k-assertion` |
| CRANE-100 | Assert Stable-Swap Behavior Using Balance Deltas | Ready | CRANE-045 | `test/stableswap-balance-deltas` |
| CRANE-101 | Remove/Gate console.log in Camelot Stubs | Ready | CRANE-045 | `fix/camelot-stub-logs` |
| CRANE-102 | Strengthen _purchaseQuote() Tests with Fix-Up Input Verification | Ready | CRANE-047 | `test/fot-fixup-input-verification` |
| CRANE-103 | Add Guards for Extreme Tax Values Near 100% | Ready | CRANE-047 | `test/fot-extreme-tax-guards` |
| CRANE-104 | Add Burn Proportional Invariant Check | Ready | CRANE-049 | `test/burn-proportional-invariant` |
| CRANE-105 | Document K-on-Burn Behavior Clarification | Ready | CRANE-049 | `docs/k-burn-clarification` |
| CRANE-106 | Use Balance Deltas Consistently in Multihop Tests | Ready | CRANE-050 | `fix/multihop-balance-deltas` |
| CRANE-107 | Reduce Stub Log Noise in Verbose Test Runs | Ready | CRANE-050 | `fix/stub-log-noise` |
| CRANE-108 | Use Math.mulDiv for Overflow Protection in Balancer V3 Pool | Ready | CRANE-052 | `fix/muldiv-overflow-protection` |
| CRANE-109 | Add 2-Token Pool Guardrails to Balancer V3 Pool | Ready | CRANE-052 | `fix/two-token-guardrails` |
| CRANE-110 | Add Non-Zero Selector Guard to DFPkg Tests | Ready | CRANE-054 | `test/selector-nonzero-guard` |
| CRANE-111 | Add Factory Integration Deployment Test for DFPkg | Ready | CRANE-054 | `test/factory-deployment-test` |
| CRANE-112 | Clean Up Mock Reuse in DFPkg Tests | Ready | CRANE-054 | `fix/mock-cleanup` |
| CRANE-113 | Replace require String with Custom Error in WeightedTokenConfigUtils | Ready | CRANE-055 | `fix/weighted-pool-custom-error` |
| CRANE-114 | Add Explicit Negative Tests for Weight Validation | Ready | CRANE-055 | `test/weight-validation-negative-tests` |
| CRANE-115 | Enforce Correct Facet Address During Remove | Ready | CRANE-058 | `fix/remove-facet-address-validation` |
| CRANE-116 | Add Negative Test for Facet/Selector Mismatch During Remove | Ready | CRANE-058 | `test/remove-mismatch-negative` |
| CRANE-117 | Guard Against Partial Facet Removal Bookkeeping Corruption | Ready | CRANE-057 | `fix/partial-removal-guardrails` |
| CRANE-118 | Make Integration Test Truly Factory-Stack E2E | Ready | CRANE-061 | `feature/factory-stack-integration-test` |
| CRANE-119 | Add Proxy-State Assertions for Pool/Vault-Aware Repos | Ready | CRANE-061 | `feature/proxy-state-assertions` |
| CRANE-120 | Tighten postDeploy Call Expectations | Ready | CRANE-061 | `feature/postdeploy-payload-validation` |
| CRANE-121 | Tighten Fuzz Assumptions for Realism | Ready | CRANE-062 | `feature/tighten-fuzz-assumptions` |
| CRANE-122 | Remove Unnecessary ERC20 Metadata Mocks | Ready | CRANE-062 | `feature/remove-erc20-mocks` |
| CRANE-123 | Split ERC5267 IFacet Tests into Dedicated File | Ready | CRANE-064 | `refactor/erc5267-split-ifacet` |
| CRANE-124 | Use Canonical Proxy Fixture for ERC5267 Integration Test | Ready | CRANE-065 | `refactor/erc5267-canonical-proxy` |
| CRANE-125 | Align ERC5267 Integration Test Pragma with Repo Version | Ready | CRANE-065 | `fix/erc5267-pragma-alignment` |

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

**Core Framework (1 task):**
- CRANE-091: Add BetterEfficientHashLib Hash Equivalence Test (from CRANE-036)

**Slipstream Unstaked Fee Follow-ups (2 tasks - from CRANE-042):**
- CRANE-095: Add Slipstream Combined Fee Guard (Medium)
- CRANE-096: Add Unstaked Fee Positive-Path Tests (Medium)

**Slipstream RewardUtils Follow-ups (2 tasks - from CRANE-043):**
- CRANE-097: Add SlipstreamRewardUtils Fork Test (Low)
- CRANE-098: Document SlipstreamRewardUtils Limitations (Low)

**Slipstream Edge Case Follow-ups (3 tasks - from CRANE-040):**
- CRANE-092: Tighten Slipstream Edge Case Test Assertions (Medium)
- CRANE-093: Make Slipstream Price-Limit Exactness Provable (Medium)
- CRANE-094: Align Slipstream Test Pragma with Repo Conventions (Low)

**Slipstream Fuzz Test Follow-ups (2 tasks - from CRANE-038):**
- CRANE-067: Add Slipstream Single-Tick Guard Assertion (Low)
- CRANE-068: Add Slipstream Fuzz Test Repro Notes (Low)

**Camelot K Invariant Follow-ups (2 tasks - from CRANE-049):**
- CRANE-104: Add Burn Proportional Invariant Check (Low)
- CRANE-105: Document K-on-Burn Behavior Clarification (Low)

**Camelot Multihop Follow-ups (2 tasks - from CRANE-050):**
- CRANE-106: Use Balance Deltas Consistently in Multihop Tests (Low)
- CRANE-107: Reduce Stub Log Noise in Verbose Test Runs (Very Low)

**Camelot Asymmetric Fee Test Follow-ups (2 tasks - from CRANE-044):**
- CRANE-069: Tighten Camelot Bidirectional Fuzz Assertion (Medium)
- CRANE-070: Reduce Noisy Logs from Camelot Stubs (Low)

**TokenConfigUtils Follow-ups (2 tasks - from CRANE-051):**
- CRANE-072: Add TokenConfigUtils Field Alignment Fuzz Test (Medium)
- CRANE-071: Remove Unused IERC20 Import from TokenConfigUtils (Low)

**Balancer V3 Follow-ups (2 tasks - from CRANE-052):**
- CRANE-108: Use Math.mulDiv for Overflow Protection in Balancer V3 Pool (Low - from CRANE-052)
- CRANE-109: Add 2-Token Pool Guardrails to Balancer V3 Pool (Low - from CRANE-052)

**ERC5267 Follow-ups (4 tasks - from CRANE-023/CRANE-064/CRANE-065):**
- CRANE-123: Split ERC5267 IFacet Tests into Dedicated File (from CRANE-064)
- CRANE-124: Use Canonical Proxy Fixture for ERC5267 Integration Test (from CRANE-065)
- CRANE-125: Align ERC5267 Integration Test Pragma with Repo Version (from CRANE-065)

**Overflow Boundary Test Follow-ups (1 task - from CRANE-026):**
- CRANE-073: Tighten Non-Revert Assertions in Overflow Tests (Low)

**Multihop/Price Impact Test Follow-ups (3 tasks - from CRANE-027/CRANE-028):**
- CRANE-074: Align Multihop Test with Camelot TestBase Patterns (Low - from CRANE-027)
- CRANE-075: Rename Price Impact Fuzz Test for Clarity (Low - from CRANE-028)
- CRANE-076: Remove Console Logs from Price Impact Tests (Low - from CRANE-028)

**ConstProdUtils Cleanup Follow-ups (1 task - from CRANE-029):**
- CRANE-077: Remove Commented-Out Parameter Stubs (Low)

**TickMath Follow-ups (1 task - from CRANE-032):**
- CRANE-078: Tighten TickMath Revert Expectations (Low)

**ERC2535 Remove Semantics Follow-ups (3 tasks - from CRANE-057/CRANE-058):**
- **CRANE-115: Enforce Correct Facet Address During Remove (High - from CRANE-058)**
- CRANE-116: Add Negative Test for Facet/Selector Mismatch During Remove (Medium - from CRANE-058)
- CRANE-117: Guard Against Partial Facet Removal Bookkeeping Corruption (Medium - from CRANE-057)

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
| CRANE-016 | Add End-to-End Factory Deployment Tests | 2026-01-15 | archive/CRANE-016-add-factory-tests/ |
| CRANE-017 | Add Negative Assertions to Test Framework | 2026-01-15 | archive/CRANE-017-test-negative-assertions/ |
| CRANE-026 | Strengthen Overflow Boundary Tests | 2026-01-15 | archive/CRANE-026-overflow-boundary-tests/ |
| CRANE-018 | Improve Test Verification Rigor | 2026-01-15 | archive/CRANE-018-test-verification-rigor/ |
| CRANE-030 | Add FEE_LOWEST Constant to TestBase | 2026-01-15 | archive/CRANE-030-fee-lowest-constant/ |
| CRANE-019 | Add Test Edge Cases and Cleanup | 2026-01-15 | archive/CRANE-019-test-edge-cases/ |
| CRANE-027 | Add Multi-hop Routing Tests | 2026-01-15 | archive/CRANE-027-multihop-routing-tests/ |
| CRANE-028 | Add Price Impact Tests | 2026-01-15 | archive/CRANE-028-price-impact-tests/ |
| CRANE-029 | ConstProdUtils Code Cleanup and NatSpec | 2026-01-15 | archive/CRANE-029-constprodutils-cleanup/ |
| CRANE-032 | Add TickMath Bijection Fuzz Tests | 2026-01-15 | archive/CRANE-032-tickmath-bijection-fuzz/ |
| CRANE-033 | Add Uniswap V4 Pure Math Unit Tests | 2026-01-15 | archive/CRANE-033-v4-pure-math-tests/ |
| CRANE-037 | Add Aerodrome Stable Pool Support | 2026-01-15 | archive/CRANE-037-aerodrome-stable-pool-support/ |
| CRANE-059 | Add ERC165Repo Storage Overload Test | 2026-01-15 | archive/CRANE-059-erc165-storage-overload-test/ |
| CRANE-031 | Fix EdgeCases Test Count Documentation | 2026-01-15 | archive/CRANE-031-edgecases-count-fix/ |
| CRANE-034 | Add Uniswap V4 SwapMath Fuzz Tests | 2026-01-15 | archive/CRANE-034-v4-swapmath-fuzz/ |
| CRANE-039 | Add Slipstream Fork Tests | 2026-01-15 | archive/CRANE-039-slipstream-fork-tests/ |
| CRANE-079 | Remove Unused `using` Directive in ERC165Repo Stub | 2026-01-15 | archive/CRANE-079-erc165-unused-using/ |
| CRANE-035 | Document Uniswap V4 Dynamic Fee Pool Limitations | 2026-01-16 | archive/CRANE-035-v4-dynamic-fee-docs/ |
| CRANE-036 | Optimize StateLibrary Hashing | 2026-01-16 | archive/CRANE-036-statelibrary-hash-optimize/ |
| CRANE-040 | Add Slipstream Edge Case Tests | 2026-01-16 | archive/CRANE-040-slipstream-edge-cases/ |
| CRANE-041 | Add Slipstream Invariant Tests | 2026-01-16 | archive/CRANE-041-slipstream-invariants/ |
| CRANE-042 | Add Unstaked Fee Handling | 2026-01-16 | archive/CRANE-042-slipstream-unstaked-fee/ |
| CRANE-043 | Add Reward Quoting Utilities | 2026-01-16 | archive/CRANE-043-slipstream-reward-utils/ |
| CRANE-045 | Add Camelot V2 Stable Swap Pool Tests | 2026-01-16 | archive/CRANE-045-camelot-stable-swap-tests/ |
| CRANE-046 | Add Protocol Fee Mint Parity Tests | 2026-01-16 | archive/CRANE-046-camelot-protocol-fee-parity/ |
| CRANE-047 | Add Fee-on-Transfer Token Integration Tests | 2026-01-16 | archive/CRANE-047-camelot-fot-integration/ |
| CRANE-048 | Add Referrer Fee Integration Tests | 2026-01-16 | archive/CRANE-048-camelot-referrer-fee/ |
| CRANE-049 | Add K Invariant Preservation Tests | 2026-01-16 | archive/CRANE-049-camelot-k-invariant/ |
| CRANE-050 | Add Multi-Hop Swap with Directional Fees Tests | 2026-01-16 | archive/CRANE-050-camelot-multihop-fees/ |
| CRANE-052 | Add FixedPoint Rounding to Balancer V3 Swaps | 2026-01-17 | archive/CRANE-052-balancer-fixedpoint-rounding/ |
| CRANE-054 | Add DFPkg Deployment Test for Selector Collision | 2026-01-17 | archive/CRANE-054-dfpkg-deployment-test/ |
| CRANE-055 | Implement Balancer V3 Weighted Pool Facet/Target | 2026-01-17 | archive/CRANE-055-weighted-pool-facet/ |
| CRANE-056 | Add Proxy-Level Routing Regression Test | 2026-01-17 | archive/CRANE-056-proxy-routing-regression-test/ |
| CRANE-057 | Fix Remove Selector Ownership Validation | 2026-01-17 | archive/CRANE-057-remove-selector-ownership-validation/ |
| CRANE-058 | Implement Partial Remove Semantics | 2026-01-17 | archive/CRANE-058-partial-remove-semantics/ |
| CRANE-060 | Add ERC-165 Strict Semantics for 0xffffffff | 2026-01-17 | archive/CRANE-060-erc165-strict-semantics/ |
| CRANE-061 | Add DFPkg Deployment Integration Test | 2026-01-17 | archive/CRANE-061-dfpkg-deployment-integration-test/ |
| CRANE-062 | Add Heterogeneous TokenConfig Order-Independence Tests | 2026-01-17 | archive/CRANE-062-tokenconfig-heterogeneous-tests/ |
| CRANE-063 | Add EXACT_OUT Pool-Favorable Rounding Tests | 2026-01-17 | archive/CRANE-063-exact-out-rounding-tests/ |
| CRANE-064 | Adopt IFacet TestBase Pattern for ERC5267 | 2026-01-17 | archive/CRANE-064-erc5267-ifacet-testbase/ |
| CRANE-065 | Add ERC5267 Diamond Proxy Integration Test | 2026-01-17 | archive/CRANE-065-erc5267-proxy-integration/ |
| CRANE-066 | Strengthen Zap-In Value Conservation Assertions | 2026-01-17 | archive/CRANE-066-slipstream-zapin-conservation/ |

## Cross-Repo Dependencies

Tasks in other repos that depend on this repo's tasks:
- (none yet)
