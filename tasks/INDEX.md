# Task Index: Crane Framework

**Repo:** CRANE
**Last Updated:** 2026-02-08

## Active Tasks

| ID | Title | Status | Dependencies | Worktree |
|----|-------|--------|--------------|----------|
| CRANE-116 | Add Negative Test for Facet/Selector Mismatch During Remove | Complete | CRANE-058 | - |
| CRANE-117 | Guard Against Partial Facet Removal Bookkeeping Corruption | Complete | CRANE-057 | - |
| CRANE-118 | Make Integration Test Truly Factory-Stack E2E | Complete | CRANE-061 | - |
| CRANE-119 | Add Proxy-State Assertions for Pool/Vault-Aware Repos | Complete | CRANE-061 | - |
| CRANE-120 | Tighten postDeploy Call Expectations | Ready | CRANE-061 | `feature/CRANE-120-postdeploy-payload-validation` |
| CRANE-121 | Tighten Fuzz Assumptions for Realism | Ready | CRANE-062 | `feature/CRANE-121-tighten-fuzz-assumptions` |
| CRANE-122 | Remove Unnecessary ERC20 Metadata Mocks | Ready | CRANE-062 | `feature/CRANE-122-remove-erc20-mocks` |
| CRANE-123 | Split ERC5267 IFacet Tests into Dedicated File | Ready | CRANE-064 | `refactor/CRANE-123-erc5267-split-ifacet-tests` |
| CRANE-124 | Use Canonical Proxy Fixture for ERC5267 Integration Test | Ready | CRANE-065 | `refactor/CRANE-124-erc5267-canonical-proxy-fixture` |
| CRANE-125 | Align ERC5267 Integration Test Pragma with Repo Version | Ready | CRANE-065 | `fix/CRANE-125-erc5267-pragma-alignment` |
| CRANE-126 | Fix Unchecked-Call Lint Warning | Ready | CRANE-071 | `fix/CRANE-126-fix-unchecked-call-lint` |
| CRANE-127 | Assert Zero-Fee Outcome in Safe Boundary Test | Ready | CRANE-073 | `test/CRANE-127-zero-fee-assertion` |
| CRANE-128 | Replace Heuristic Percent Bounds with Explicit Tolerances | Ready | CRANE-073 | `test/CRANE-128-explicit-tolerances` |
| CRANE-129 | Align SwapMath Golden Vector Comments with Upstream | Ready | CRANE-080 | `fix/CRANE-129-swapmath-golden-vector-comments` |
| CRANE-130 | Add Direction Assertion to SwapMath Fully-Spent Test | Ready | CRANE-080 | `fix/CRANE-130-swapmath-direction-assertion` |
| CRANE-131 | Delete Deprecated AerodromService Test File | Ready | CRANE-083 | `fix/CRANE-131-delete-deprecated-aerodrome-test` |
| CRANE-132 | Align Aerodrome Test Pragma with Repo Version | Ready | CRANE-083 | `fix/CRANE-132-aerodrome-pragma-alignment` |
| CRANE-133 | Make Stable-vs-Volatile Comparison Apples-to-Apples | Ready | CRANE-084 | `test/CRANE-133-aerodrome-apples-to-apples-comparison` |
| CRANE-134 | Assert Aerodrome Fee Config in Stub | Ready | CRANE-084 | `test/CRANE-134-aerodrome-fee-config-assertion` |
| CRANE-135 | Tighten/Clarify Aerodrome Gas Estimate Language | Ready | CRANE-085 | `docs/CRANE-135-aerodrome-gas-estimate-clarity` |
| CRANE-136 | Simplify _k_from_f Helper in Aerodrome Stable | Ready | CRANE-085 | `fix/CRANE-136-aerodrome-k-helper-simplify` |
| CRANE-137 | Remove Redundant vm.assume in SwapMath Fuzz Test | Ready | CRANE-086 | `fix/CRANE-137-swapmath-redundant-assume` |
| CRANE-138 | Test SwapMath Edge Case Where Limit Equals Current | Ready | CRANE-086 | `test/CRANE-138-swapmath-limit-equals-current` |
| CRANE-139 | Remove Always-True feeAmount >= 0 Assertions | Ready | CRANE-087 | `fix/CRANE-139-swapmath-feeamount-assertions` |
| CRANE-140 | Align Fee Test Naming with Assertions | Ready | CRANE-088 | `fix/CRANE-140-swapmath-fee-test-rename` |
| CRANE-153 | Port Resupply Protocol to Local Contracts | Ready | - | `feature/CRANE-153-resupply-port` |
| CRANE-162 | Expand Balancer V3 Router Test Coverage | Ready | CRANE-142 | `test/CRANE-162-router-test-coverage` |
| CRANE-163 | Fix Prepaid Router Mode for Permit2-less Operations | Complete | CRANE-142 | `fix/CRANE-163-router-prepaid-mode-fix` |
| CRANE-164 | Add Target Layer to Router Facets | Ready | CRANE-142 | `refactor/CRANE-164-router-target-layer` |
| CRANE-165 | Add NatSpec Custom Tags to Router Contracts | Ready | CRANE-142 | `docs/CRANE-165-router-natspec-tags` |
| CRANE-166 | Refactor Router Guards to Follow Repo Pattern | Ready | CRANE-142 | `refactor/CRANE-166-router-guard-repo-pattern` |
| CRANE-168 | Add SafeCast160 Unit Tests | Ready | CRANE-150 | `test/CRANE-168-safecast160-tests` |
| CRANE-169 | Add Permit2Lib Integration Tests | Ready | CRANE-150 | `test/CRANE-169-permit2lib-tests` |
| CRANE-170 | Document DeployPermit2 Bytecode Source | Ready | CRANE-150 | `docs/CRANE-170-deploypermit2-docs` |
| CRANE-172 | Remove Deprecated AerodromService | Ready | CRANE-148 | `chore/CRANE-172-remove-deprecated-aerodrom-service` |
| CRANE-173 | Add Aerodrome Interface Comparison Report | Ready | CRANE-148 | `docs/CRANE-173-aerodrome-interface-comparison-doc` |
| CRANE-174 | Add Router getWeth/getPermit2 Validation | Ready | CRANE-167 | `test/CRANE-174-router-weth-permit2-validation` |
| CRANE-175 | Consolidate Router Facet Size Checks | Ready | CRANE-167 | `refactor/CRANE-175-router-facet-size-consolidation` |
| CRANE-176 | Replace LBP String Revert with Custom Error | Ready | CRANE-143 | `fix/CRANE-176-lbp-custom-error` |
| CRANE-177 | Add NatSpec Examples to GradualValueChange | Ready | CRANE-143 | `docs/CRANE-177-gradualvaluechange-natspec` |
| CRANE-178 | Integration Tests for Weighted Pool Package | Ready | CRANE-143 | `test/CRANE-178-pool-weighted-integration-tests` |
| CRANE-179 | Fix LBP DFPkg calcSalt Address Collisions | Ready | CRANE-143 | `fix/CRANE-179-lbp-dfpkg-calcsalt-fix` |
| CRANE-180 | Add Stable Pool DFPkg Salt Consistency Tests | Ready | CRANE-144 | `test/CRANE-180-stable-pool-salt-consistency-tests` |
| CRANE-181 | Remove lib/aerodrome-contracts Submodule | Ready | CRANE-148 | `chore/CRANE-181-remove-aerodrome-submodule` |
| CRANE-184 | Add V3 Quoter Function Tests | Ready | CRANE-151 | `test/CRANE-184-v3-quoter-tests` |
| CRANE-185 | Add V3Migrator Integration Test | Ready | CRANE-151 | `test/CRANE-185-v3-migrator-tests` |
| CRANE-186 | Remove v3-core and v3-periphery Submodules | Ready | CRANE-151 | `chore/CRANE-186-remove-v3-submodules` |
| CRANE-187 | Add POOL_INIT_CODE_HASH Regression Test | Ready | CRANE-151 | `test/CRANE-187-v3-init-code-hash-test` |
| CRANE-190 | Add Gyro Pool Token-Order Independence Tests | Ready | CRANE-145 | `test/CRANE-190-gyro-token-order-independence-tests` |
| CRANE-192 | Add Input Length Validation in CoW Router | Ready | CRANE-146 | `fix/CRANE-192-cow-router-length-validation` |
| CRANE-193 | Add Diamond-Vault Integration Tests for Hooks | Ready | CRANE-147 | `test/CRANE-193-hooks-diamond-vault-integration` |
| CRANE-194 | Align Hook Comments With Actual Behavior | Ready | CRANE-147 | `fix/CRANE-194-hooks-comment-alignment` |
| CRANE-195 | Make lib/reclamm Submodule Removal Possible | Ready | CRANE-149 | `fix/CRANE-195-reclamm-submodule-removal-enablement` |
| CRANE-196 | Replace Unsupported Foundry Config Key | Ready | CRANE-149 | `fix/CRANE-196-foundry-config-cleanup` |
| CRANE-197 | Stabilize ReClaMM Deterministic Address Test | Ready | CRANE-149 | `fix/CRANE-197-reclamm-deterministic-address-test` |
| CRANE-198 | Add Submodule Removal Verification to CI | Ready | CRANE-152 | `feature/CRANE-198-v4-submodule-removal-ci-check` |
| CRANE-199 | Resolve CRANE-152 TASK.md Scope Mismatch | Ready | CRANE-152 | `fix/CRANE-199-v4-task-scope-cleanup` |
| CRANE-213 | Add Balancer V3 Stable Pool Fork Parity Tests | Ready | - | `test/CRANE-213-balancer-v3-stable-pool-fork-parity-tests` |
| CRANE-214 | Add Upstream Execute Parity Assertions | Ready | CRANE-211 | `test/CRANE-214-execute-parity-upstream-assertions` |
| CRANE-215 | Add End-to-End tokenURI() Shape Test | Ready | CRANE-201 | `test/CRANE-215-v3-tokenuri-e2e-shape-test` |
| CRANE-216 | Add POOL_INIT_CODE_HASH Regression Test | Ready | CRANE-201 | `test/CRANE-216-pool-init-code-hash-regression` |
| CRANE-217 | Reduce False Positives In JSON Validation | Ready | CRANE-201 | `test/CRANE-217-json-image-field-extraction` |
| CRANE-221 | Complete Uniswap V4 Port Verification with Base Fork Tests | Ready | - | `feature/CRANE-221-uniswap-v4-port-verification` |
| CRANE-230 | Document SafeCast Wrapper Delegation Pattern | Ready | CRANE-223 | `docs/CRANE-230-document-safecast-delegation-pattern` |
| CRANE-231 | Add USDT Approval Tests for safeIncreaseAllowance/safeDecreaseAllowance | Ready | CRANE-229 | `test/CRANE-231-add-usdt-approval-tests-increase-decrease` |
| CRANE-232 | Add Slipstream Near-Depletion Exact-Output Test | Ready | CRANE-090 | `test/CRANE-232-slipstream-near-depletion-test` |
| CRANE-234 | Add BetterEfficientHashLib Extended Overload Tests | Ready | CRANE-091 | `test/CRANE-234-hash-extended-overload-tests` |
| CRANE-235 | Add SlipstreamQuoter Fee Guard Revert Test | Ready | CRANE-095 | `test/CRANE-235-quoter-fee-guard-revert-test` |
| CRANE-236 | Add k() Assertion for Constant-Product Mode | Ready | CRANE-099 | `test/CRANE-236-k-constant-product-assertion` |
| CRANE-237 | Add k() Assertion for Mixed-Decimal Pair | Ready | CRANE-099 | `test/CRANE-237-k-mixed-decimal-assertion` |
| CRANE-240 | Remove Commented-Out Console Imports from CamelotV2Service | Ready | - | `fix/CRANE-240-remove-commented-console-imports` |
| CRANE-241 | Add FoT Output Token Fix-Up Verification Tests | Ready | CRANE-102 | `test/CRANE-241-fot-output-token-fixup-verification` |
| CRANE-242 | Add Fix-Up Sanity Assertion to FoT Tests | Ready | CRANE-102 | `test/CRANE-242-fixup-sanity-assertion` |
| CRANE-243 | Extract Shared Vault Test Mocks to TestBase | Ready | CRANE-161 | `refactor/CRANE-243-extract-vault-test-mocks` |
| CRANE-244 | Add End-to-End Swap Integration Test for Router-Vault | Ready | CRANE-161 | `test/CRANE-244-router-vault-swap-integration-test` |
| CRANE-245 | Add Burn Proportional Tests to Stable Pool Contract | Ready | CRANE-104 | `test/CRANE-245-stable-pool-burn-proportional-tests` |
| CRANE-246 | Add Debugging Info to Violation Tracking | Ready | CRANE-104 | `fix/CRANE-246-violation-tracking-debug-info` |
| CRANE-247 | Fix Misleading NatSpec in Burn Invariant Tests | Ready | CRANE-104 | `fix/CRANE-247-fix-burn-invariant-natspec` |
| CRANE-248 | Add onSwap 2-Token Guardrails to Balancer V3 Pool | Ready | CRANE-109 | `fix/CRANE-248-onswap-two-token-guardrails` |
| CRANE-249 | Add Zero-Selector and Collision Guards to Behavior_IFacet | Ready | CRANE-110 | `feature/CRANE-249-behavior-ifacet-selector-guard` |
| CRANE-250 | Create Behavior_IDiamondFactoryPackage Test Library | Ready | CRANE-110 | `feature/CRANE-250-behavior-idiamondFactoryPackage` |
| CRANE-251 | Add Negative Test for Duplicate Token Configs | Ready | CRANE-111 | `test/CRANE-251-duplicate-token-config-negative-test` |
| CRANE-252 | Add ConstantProduct DFPkg 3+ Token Count Revert Test | Ready | CRANE-111 | `test/CRANE-252-constprod-token-count-revert-test` |
| CRANE-253 | Remove Empty Helper Libraries from Integration Test | Ready | CRANE-111 | `fix/CRANE-253-remove-empty-helper-libraries` |
| CRANE-254 | Protect computeInvariant Overflow Boundary with mulDiv | Ready | CRANE-108 | `fix/CRANE-254-computeinvariant-overflow-protection` |
| CRANE-255 | Diamond Implementation of ERC-6909 Multi-Token Standard | Ready | - | `feature/CRANE-255-erc6909-diamond-implementation` |
| CRANE-256 | Extract DFPkg Test Mocks to Shared Utility | Ready | CRANE-112 | `refactor/CRANE-256-extract-dfpkg-test-mocks` |
| CRANE-257 | Add Negative Test for WeightedTokenConfigUtils LengthMismatch | Ready | CRANE-113 | `test/CRANE-257-length-mismatch-negative-test` |
| CRANE-258 | Add Fuzz Test for Weight Sum Validation | Ready | CRANE-114 | `test/CRANE-258-weight-sum-fuzz-test` |
| CRANE-259 | Add Maximum Token Count Boundary Test | Ready | CRANE-114 | `test/CRANE-259-max-token-count-boundary` |
| CRANE-260 | Remove Dead _computeUpstreamRequestTypeHash Function | Ready | CRANE-239 ✓ | `fix/CRANE-260-remove-dead-compute-upstream-typehash` |
| CRANE-261 | Add Forwarder Codehash Equality Assertion | Ready | CRANE-239 ✓ | `fix/CRANE-261-add-forwarder-codehash-assertion` |
| CRANE-262 | Add Explanatory Comment for Large APR in Fork Test | Ready | CRANE-238 ✓ | `docs/CRANE-262-add-apr-test-comment` |
| CRANE-263 | Add Mixed-Mismatch Remove FacetCut Test | Ready | CRANE-116 ✓ | `test/CRANE-263-mixed-mismatch-remove-test` |
| CRANE-264 | Extract ConstantProductPoolFactoryService | Ready | CRANE-118 ✓ | `refactor/CRANE-264-extract-constprod-factory-service` |
| CRANE-265 | Add Create3Factory Registry Verification Test | Ready | CRANE-118 ✓ | `test/CRANE-265-create3factory-registry-assertion` |
| CRANE-266 | Remove Unused BALANCER_V3_VAULT_AWARE_SLOT Constant | Ready | CRANE-119 ✓ | `fix/CRANE-266-remove-unused-vault-aware-slot-constant` |
| CRANE-267 | Add Double-Initialization Documentation Test for VaultAwareRepo | Ready | CRANE-119 ✓ | `test/CRANE-267-vault-aware-double-init-test` |
| CRANE-268 | Add Prepaid Mode Tests for Router | Ready | CRANE-163 ✓ | `test/CRANE-268-prepaid-mode-router-tests` |
| CRANE-269 | Add NatSpec Documenting Prepaid Mode Behavior | Ready | CRANE-163 ✓ | `docs/CRANE-269-prepaid-mode-natspec` |
| CRANE-270 | Verify Ported Balancer V3 for Production Deployment | Ready | - | `feature/CRANE-270-verify-balancer-v3-port` |

## Status Legend

- **Ready** - All dependencies met, can be launched with `/backlog:launch`
- **In Progress** - Implementation agent working (has worktree)
- **In Review** - Implementation complete, awaiting code review
- **Changes Requested** - Review found issues, needs fixes
- **Pending Merge** - Approved and rebased, ready for fast-forward merge
- **Complete** - Review passed, ready to archive with `/backlog:prune`
- **Blocked** - Waiting on dependencies
- **Superseded** - Consolidated into another task, will be archived

## Quick Filters

### Ready for Agent

**Core Framework (0 tasks - CRANE-091 in review):**
- ~~CRANE-091: Add BetterEfficientHashLib Hash Equivalence Test~~ → In Review

**Slipstream Unstaked Fee Follow-ups (2 tasks - from CRANE-042/CRANE-095):**
- ~~CRANE-095: Add Slipstream Combined Fee Guard~~ → Complete
- ~~CRANE-096: Add Unstaked Fee Positive-Path Tests~~ → Complete
- CRANE-235: Add SlipstreamQuoter Fee Guard Revert Test (Low, from CRANE-095 review)

**Slipstream RewardUtils Follow-ups (completed - from CRANE-043):**
- ~~CRANE-097: Add SlipstreamRewardUtils Fork Test~~ → Complete
- ~~CRANE-098: Document SlipstreamRewardUtils Limitations~~ → Complete

**Slipstream Edge Case Follow-ups (3 tasks - from CRANE-040):**
- CRANE-092: Tighten Slipstream Edge Case Test Assertions (Medium)
- CRANE-093: Make Slipstream Price-Limit Exactness Provable (Medium)
- CRANE-094: Align Slipstream Test Pragma with Repo Conventions (Low)

**Slipstream Fuzz Test Follow-ups (completed - from CRANE-038):**
(All follow-up tasks from CRANE-038 have been completed)

**Camelot K Invariant Follow-ups (2 tasks - from CRANE-049):**
- CRANE-104: Add Burn Proportional Invariant Check (Low)
- CRANE-105: Document K-on-Burn Behavior Clarification (Low)

**Camelot Multihop Follow-ups (2 tasks - from CRANE-050):**
- CRANE-106: Use Balance Deltas Consistently in Multihop Tests (Low)
- CRANE-107: Reduce Stub Log Noise in Verbose Test Runs (Very Low)

**Camelot Asymmetric Fee Test Follow-ups (completed - from CRANE-044):**
(All follow-up tasks from CRANE-044 have been completed)

**TokenConfigUtils Follow-ups (completed - from CRANE-051):**
(All follow-up tasks from CRANE-051 have been completed)

**Balancer V3 Follow-ups (completed - from CRANE-052):**
- ~~CRANE-108: Use Math.mulDiv for Overflow Protection in Balancer V3 Pool~~ → Complete
- ~~CRANE-109: Add 2-Token Pool Guardrails to Balancer V3 Pool~~ → Complete

**ERC5267 Follow-ups (4 tasks - from CRANE-023/CRANE-064/CRANE-065):**
- CRANE-123: Split ERC5267 IFacet Tests into Dedicated File (from CRANE-064)
- CRANE-124: Use Canonical Proxy Fixture for ERC5267 Integration Test (from CRANE-065)
- CRANE-125: Align ERC5267 Integration Test Pragma with Repo Version (from CRANE-065)

**Overflow Boundary Test Follow-ups (from CRANE-026/CRANE-073):**
- CRANE-127: Assert Zero-Fee Outcome in Safe Boundary Test (Low - from CRANE-073)
- CRANE-128: Replace Heuristic Percent Bounds with Explicit Tolerances (Low - from CRANE-073)

**Multihop/Price Impact Test Follow-ups (completed - from CRANE-027/CRANE-028):**
(All follow-up tasks from CRANE-028 have been completed)

**ConstProdUtils Cleanup Follow-ups (completed - from CRANE-029):**
(All follow-up tasks from CRANE-029 have been completed)

**TickMath Follow-ups (completed - from CRANE-032):**
(All follow-up tasks from CRANE-032 have been completed)

**ERC2535 Remove Semantics Follow-ups (3 tasks - from CRANE-057/CRANE-058):**
- ~~CRANE-115: Enforce Correct Facet Address During Remove~~ → Complete
- ~~CRANE-116: Add Negative Test for Facet/Selector Mismatch During Remove~~ → Complete
- CRANE-117: Guard Against Partial Facet Removal Bookkeeping Corruption (Medium - from CRANE-057)
- CRANE-263: Add Mixed-Mismatch Remove FacetCut Test (Low - from CRANE-116 review)

**DFPkg Integration Test Follow-ups (from CRANE-118/CRANE-119 reviews):**
- CRANE-264: Extract ConstantProductPoolFactoryService (Low - from CRANE-118 review)
- CRANE-265: Add Create3Factory Registry Verification Test (Low - from CRANE-118 review)
- CRANE-266: Remove Unused BALANCER_V3_VAULT_AWARE_SLOT Constant (Low - from CRANE-119 review)
- CRANE-267: Add Double-Initialization Documentation Test for VaultAwareRepo (Low - from CRANE-119 review)

**Balancer V3 Lite (Deployable Refactor):**
- CRANE-141: Refactor Balancer V3 Vault as Diamond Facets ✓ **Complete**
- CRANE-142: Refactor Balancer V3 Router as Diamond Facets ✓ **Complete**
- CRANE-159: Fix Balancer V3 Vault Diamond with DFPkg Pattern ✓ **Complete**
- ~~CRANE-160: Remove Non-Routed Duplicate Selectors from Vault Facets~~ → Complete
- ~~CRANE-161: Resolve Vault Loupe and Router Integration~~ → Complete
- CRANE-143: Refactor Balancer V3 Weighted Pool Package ✓ **Complete**
- ~~CRANE-144: Refactor Balancer V3 Stable Pool Package~~ → Archived
- (Complete tasks for this initiative are listed in **Archived Tasks**)

**Balancer V3 Router Review Follow-ups (6 tasks - from CRANE-142):**
- **CRANE-162: Expand Balancer V3 Router Test Coverage (Ready - HIGH)**
- **CRANE-163: Fix Prepaid Router Mode for Permit2-less Operations (Ready - HIGH)**
- **CRANE-164: Add Target Layer to Router Facets (Ready - HIGH)**
- CRANE-165: Add NatSpec Custom Tags to Router Contracts (Medium)
- CRANE-166: Refactor Router Guards to Follow Repo Pattern (Medium)
- CRANE-167: Add TestBase and Behavior Patterns to Router Tests (Medium)

**Balancer V3 Vault Review Follow-ups (Superseded by CRANE-159):**
- ~~CRANE-155: Add Balancer V3 Vault Interface Coverage Tests~~ → Superseded
- ~~CRANE-156: Fix Pool Token Selector Signatures in Vault Tests~~ → Superseded
- ~~CRANE-157: Implement Missing Balancer V3 Vault Interface Functions~~ → Superseded
- ~~CRANE-158: Add DiamondLoupe Support to Balancer V3 Vault~~ → Superseded

**Aerodrome Port Verification (1 task):**
- ~~CRANE-148: Verify Aerodrome Contract Port Completeness~~ → Complete

**Permit2 Port Verification (1 task):**
- ~~CRANE-150: Verify Permit2 Contract Port Completeness~~ → Complete

**Uniswap V3 Port (1 task):**
- ~~CRANE-151: Port and Verify Uniswap V3 Core + Periphery~~ → Complete

**Uniswap V4 Port Verification (1 task):**
- **CRANE-221: Complete Uniswap V4 Port Verification with Base Fork Tests (Ready)**
- (Previous tasks CRANE-152, CRANE-205 are archived as Complete)

**Resupply CDP Port (1 task):**
- **CRANE-153: Port Resupply Protocol to Local Contracts (Ready)**

**Sky/DSS CDP Port (1 task):**
- ~~CRANE-154: Port Sky/DSS Protocol to Local Contracts~~ → Complete

**Uniswap V2 Fork Tests (1 task):**
- ~~CRANE-202: Add Uniswap V2 Fork Comparison Tests~~ → Complete

**Aerodrome V1 Fork Tests (1 task):**
- ~~CRANE-203: Add Aerodrome V1 Fork Comparison Tests~~ → Complete

**Uniswap V3 Ported Contract Parity Tests (1 task):**
- ~~CRANE-204: Add Uniswap V3 Ported Contract Parity Tests~~ → Complete

**Uniswap V4 Ported Contract Parity Tests (1 task):**
- ~~CRANE-205: Add Uniswap V4 Ported Contract Parity Tests~~ → Complete

**Balancer V3 Gyro Pool Parity Tests (1 task):**
- ~~CRANE-206: Add Balancer V3 Gyro Pool Fork Parity Tests~~ → Complete

**Balancer V3 CoW Pool Parity Tests (1 task):**
- ~~CRANE-207: Add Balancer V3 CoW Pool Fork Parity Tests~~ → Complete

**Balancer V3 Weighted Pool Parity Tests (1 task):**
- ~~CRANE-208: Add Balancer V3 Weighted Pool Fork Parity Tests~~ → Complete

**Balancer V3 Stable Pool Parity Tests (1 task):**
- **CRANE-213: Add Balancer V3 Stable Pool Fork Parity Tests (Ready)**

**OpenGSN Forwarder Follow-ups (1 task - from CRANE-211):**
- ~~CRANE-239: Fix OpenGSN Forwarder Fork Test Type Hash Registration~~ → Complete
- CRANE-214: Add Upstream Execute Parity Assertions (Low)

**Slipstream Port and Parity Tests (1 task):**
- ~~CRANE-212: Port Slipstream + Add Fork Parity Tests (Temporary forge install)~~ → Complete

**Test Failure Fix Groups (6 tasks - 43 failures total, all parallelizable):**
- ~~CRANE-222: Fix Internal expectRevert Depth Failures - 24 tests~~ → Complete
- ~~CRANE-223: Fix Error Selector Mismatches After OZ Removal - 4 tests~~ → Complete
- ~~CRANE-224: Fix BetterSafeERC20 Test Error Expectations - 5 tests~~ → Complete
- ~~CRANE-225: Fix E2eErc4626Swaps Fuzz Input Bounds - 4 tests~~ → Complete
- ~~CRANE-226: Fix BetterStrings toHexString Missing 0x Prefix - 1 test~~ → Complete
- ~~CRANE-227: Fix StableSurgeHook Error Expectation - 1 test~~ → Complete

**Submodule Removal (1 task):**
- ~~CRANE-219: Port OpenZeppelin Code to Remove Submodule Dependency~~ → Complete
- ~~CRANE-220: Port Solady Code to Remove Submodule Dependency~~ → Complete
- ~~CRANE-171: Remove lib/permit2 Submodule~~ → Complete
- **CRANE-181: Remove lib/aerodrome-contracts Submodule (Ready)**
- ~~CRANE-188: Remove lib/reclamm Submodule~~ → Complete

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
| CRANE-068 | Add Slipstream Fuzz Test Repro Notes | 2026-01-18 | archive/CRANE-068-slipstream-repro-notes/ |
| CRANE-069 | Tighten Camelot Bidirectional Fuzz Assertion | 2026-01-18 | archive/CRANE-069-camelot-bidirectional-fuzz/ |
| CRANE-070 | Reduce Noisy Logs from Camelot Stubs | 2026-01-18 | archive/CRANE-070-camelot-stub-logs/ |
| CRANE-067 | Add Slipstream Single-Tick Guard Assertion | 2026-01-18 | archive/CRANE-067-slipstream-singletick-guard/ |
| CRANE-071 | Remove Unused IERC20 Import from TokenConfigUtils | 2026-01-18 | archive/CRANE-071-tokenconfig-unused-import/ |
| CRANE-072 | Add TokenConfigUtils Field Alignment Fuzz Test | 2026-01-18 | archive/CRANE-072-tokenconfig-alignment-fuzz/ |
| CRANE-073 | Tighten Non-Revert Assertions in Overflow Tests | 2026-01-18 | archive/CRANE-073-tighten-overflow-assertions/ |
| CRANE-074 | Align Multihop Test with Camelot TestBase Patterns | 2026-01-18 | archive/CRANE-074-multihop-testbase-alignment/ |
| CRANE-075 | Rename Price Impact Fuzz Test for Clarity | 2026-01-18 | archive/CRANE-075-priceimpact-test-rename/ |
| CRANE-076 | Remove Console Logs from Price Impact Tests | 2026-01-18 | archive/CRANE-076-priceimpact-remove-logs/ |
| CRANE-077 | Remove Commented-Out Parameter Stubs | 2026-01-18 | archive/CRANE-077-remove-param-stubs/ |
| CRANE-078 | Tighten TickMath Revert Expectations | 2026-01-18 | archive/CRANE-078-tighten-tickmath-revert-expectations/ |
| CRANE-080 | Add SwapMath Golden Vector Tests | 2026-01-18 | archive/CRANE-080-swapmath-golden-vectors/ |
| CRANE-082 | Add TickMath Exact Known Pairs | 2026-01-18 | archive/CRANE-082-tickmath-exact-pairs/ |
| CRANE-081 | Add SqrtPriceMath Custom Error Tests | 2026-01-18 | archive/CRANE-081-sqrtpricemath-error-tests/ |
| CRANE-083 | Clarify Deprecated Aerodrome Library Test Intent | 2026-01-21 | archive/CRANE-083-aerodrome-deprecated-test-intent/ |
| CRANE-084 | Strengthen Stable-vs-Volatile Slippage Assertion | 2026-01-21 | archive/CRANE-084-aerodrome-slippage-assertion/ |
| CRANE-085 | Document Stable Swap-Deposit Gas/Complexity | 2026-01-21 | archive/CRANE-085-aerodrome-stable-gas-docs/ |
| CRANE-086 | Add Explicit sqrtPriceLimit Bound Test | 2026-01-21 | archive/CRANE-086-swapmath-sqrtpricelimit-fuzz/ |
| CRANE-087 | Handle amountRemaining == int256.min Edge Case | 2026-01-21 | archive/CRANE-087-swapmath-int256min-edge/ |
| CRANE-088 | Remove Minor Test Cruft from SwapMath Fuzz Tests | 2026-01-21 | archive/CRANE-088-swapmath-test-cleanup/ |
| CRANE-144 | Refactor Balancer V3 Stable Pool Package | 2026-01-30 | archive/CRANE-144-balancer-v3-pool-stable/ |
| CRANE-089 | Add Additional High-Liquidity Pool to Fork Tests | 2026-01-31 | archive/CRANE-089-slipstream-fork-multipool/ |
| CRANE-141 | Refactor Balancer V3 Vault as Diamond Facets | 2026-01-31 | archive/CRANE-141-balancer-v3-vault-facets/ |
| CRANE-142 | Refactor Balancer V3 Router as Diamond Facets | 2026-01-31 | archive/CRANE-142-balancer-v3-router-facets/ |
| CRANE-143 | Refactor Balancer V3 Weighted Pool Package | 2026-01-31 | archive/CRANE-143-balancer-v3-pool-weighted/ |
| CRANE-148 | Verify Aerodrome Contract Port Completeness | 2026-01-31 | archive/CRANE-148-aerodrome-port-verification/ |
| CRANE-150 | Verify Permit2 Contract Port Completeness | 2026-01-31 | archive/CRANE-150-permit2-port-verification/ |
| CRANE-151 | Port and Verify Uniswap V3 Core + Periphery | 2026-01-31 | archive/CRANE-151-uniswap-v3-port-verification/ |
| CRANE-154 | Port Sky/DSS Protocol to Local Contracts | 2026-01-31 | archive/CRANE-154-sky-dss-port/ |
| CRANE-159 | Fix Balancer V3 Vault Diamond with DFPkg Pattern | 2026-01-31 | archive/CRANE-159-balancer-v3-vault-dfpkg-fix/ |
| CRANE-167 | Add TestBase and Behavior Patterns to Router Tests | 2026-01-31 | archive/CRANE-167-router-testbase-behavior/ |
| CRANE-149 | Fork ReClaMM Pool to Local Contracts | 2026-02-01 | archive/CRANE-149-reclamm-port/ |
| CRANE-152 | Port and Verify Uniswap V4 Core + Periphery | 2026-02-01 | archive/CRANE-152-uniswap-v4-port-verification/ |
| CRANE-202 | Add Uniswap V2 Fork Comparison Tests | 2026-02-02 | archive/CRANE-202-uniswap-v2-fork-comparison-tests/ |
| CRANE-203 | Add Aerodrome V1 Fork Comparison Tests | 2026-02-02 | archive/CRANE-203-aerodrome-v1-fork-comparison-tests/ |
| CRANE-204 | Add Uniswap V3 Ported Contract Parity Tests | 2026-02-02 | archive/CRANE-204-uniswap-v3-ported-contract-parity-tests/ |
| CRANE-205 | Add Uniswap V4 Ported Contract Parity Tests | 2026-02-02 | archive/CRANE-205-uniswap-v4-ported-contract-parity-tests/ |
| CRANE-207 | Add Balancer V3 CoW Pool Fork Parity Tests | 2026-02-03 | archive/CRANE-207-balancer-v3-cow-pool-fork-parity-tests/ |
| CRANE-206 | Add Balancer V3 Gyro Pool Fork Parity Tests | 2026-02-03 | archive/CRANE-206-balancer-v3-gyro-pool-fork-parity-tests/ |
| CRANE-208 | Add Balancer V3 Weighted Pool Fork Parity Tests | 2026-02-03 | archive/CRANE-208-balancer-v3-weighted-pool-fork-parity-tests/ |
| CRANE-211 | OpenGSN Forwarder Port + Fork Parity Tests | 2026-02-03 | archive/CRANE-211-opengsn-forwarder-port-and-tests/ |
| CRANE-212 | Port Slipstream + Add Fork Parity Tests | 2026-02-03 | archive/CRANE-212-slipstream-port-and-parity/ |
| CRANE-219 | Port OpenZeppelin Code to Remove Submodule Dependency | 2026-02-06 | archive/CRANE-219-openzeppelin-port/ |
| CRANE-220 | Port Solady Code to Remove Submodule Dependency | 2026-02-06 | archive/CRANE-220-solady-port/ |
| CRANE-182 | Final Submodule Cleanup and forge-std Installation | 2026-02-06 | archive/CRANE-182-final-submodule-cleanup/ |
| CRANE-228 | Pin Gyro Fork Test Block Number for RPC Cache Reliability | 2026-02-06 | archive/CRANE-228-pin-gyro-fork-block/ |
| CRANE-189 | Remove lib/v4-core and lib/v4-periphery Submodules | 2026-02-06 | archive/CRANE-189-remove-v4-submodules/ |
| CRANE-171 | Remove lib/permit2 Submodule | 2026-02-07 | archive/CRANE-171-remove-permit2-submodule/ |
| CRANE-188 | Remove lib/reclamm Submodule | 2026-02-07 | archive/CRANE-188-remove-reclamm-submodule/ |
| CRANE-200 | Remove v4-periphery-coupled Remappings | 2026-02-07 | archive/CRANE-200-v4-periphery-remapping-removal/ |
| CRANE-095 | Add Slipstream Combined Fee Guard | 2026-02-07 | archive/CRANE-095-slipstream-fee-guard/ |
| CRANE-096 | Add Unstaked Fee Positive-Path Tests | 2026-02-07 | archive/CRANE-096-unstaked-fee-positive-tests/ |
| CRANE-097 | Add SlipstreamRewardUtils Fork Test | 2026-02-07 | archive/CRANE-097-reward-utils-fork-test/ |
| CRANE-098 | Document SlipstreamRewardUtils Limitations | 2026-02-07 | archive/CRANE-098-reward-utils-natspec/ |
| CRANE-099 | Add Direct Assertion for Cubic Invariant _k() | 2026-02-07 | archive/CRANE-099-stableswap-k-assertion/ |
| CRANE-100 | Assert Stable-Swap Behavior Using Balance Deltas | 2026-02-07 | archive/CRANE-100-stableswap-balance-delta-assertions/ |
| CRANE-101 | Remove/Gate console.log in Camelot Stubs | 2026-02-07 | archive/CRANE-101-camelot-stub-log-cleanup/ |
| CRANE-102 | Strengthen _purchaseQuote() Tests with Fix-Up Input Verification | 2026-02-07 | archive/CRANE-102-fot-fixup-input-verification/ |
| CRANE-103 | Add Guards for Extreme Tax Values Near 100% | 2026-02-07 | archive/CRANE-103-fot-extreme-tax-guards/ |
| CRANE-104 | Add Burn Proportional Invariant Check | 2026-02-07 | archive/CRANE-104-burn-proportional-invariant/ |
| CRANE-105 | Document K-on-Burn Behavior Clarification | 2026-02-07 | archive/CRANE-105-k-burn-docs/ |
| CRANE-106 | Use Balance Deltas Consistently in Multihop Tests | 2026-02-07 | archive/CRANE-106-multihop-balance-deltas/ |
| CRANE-107 | Reduce Stub Log Noise in Verbose Test Runs | 2026-02-08 | archive/CRANE-107-stub-log-noise/ |
| CRANE-108 | Use Math.mulDiv for Overflow Protection in Balancer V3 Pool | 2026-02-08 | archive/CRANE-108-muldiv-overflow-protection/ |
| CRANE-109 | Add 2-Token Pool Guardrails to Balancer V3 Pool | 2026-02-08 | archive/CRANE-109-two-token-guardrails/ |
| CRANE-110 | Add Non-Zero Selector Guard to DFPkg Tests | 2026-02-08 | archive/CRANE-110-selector-nonzero-guard/ |
| CRANE-111 | Add Factory Integration Deployment Test for DFPkg | 2026-02-08 | archive/CRANE-111-factory-deployment-test/ |
| CRANE-112 | Clean Up Mock Reuse in DFPkg Tests | 2026-02-08 | archive/CRANE-112-mock-cleanup/ |
| CRANE-113 | Replace require String with Custom Error in WeightedTokenConfigUtils | 2026-02-08 | archive/CRANE-113-weighted-pool-custom-error/ |
| CRANE-114 | Add Explicit Negative Tests for Weight Validation | 2026-02-08 | archive/CRANE-114-weight-validation-negative-tests/ |
| CRANE-115 | Enforce Correct Facet Address During Remove | 2026-02-07 | archive/CRANE-115-remove-facet-address-validation/ |
| CRANE-160 | Remove Non-Routed Duplicate Selectors from Vault Facets | 2026-02-07 | archive/CRANE-160-vault-facet-selector-cleanup/ |
| CRANE-161 | Resolve Vault Loupe and Router Integration | 2026-02-07 | archive/CRANE-161-vault-loupe-router-integration/ |
| CRANE-233 | Fix TASK.md encodePacked Typo | 2026-02-07 | archive/CRANE-233-fix-hash-task-typo/ |
| CRANE-238 | Fix test_calculateRewardAPR_livePool Assertion | 2026-02-08 | archive/CRANE-238-fix-reward-apr-sanity-bound/ |
| CRANE-239 | Fix OpenGSN Forwarder Fork Test Type Hash Registration | 2026-02-08 | archive/CRANE-239-fix-opengsn-forwarder-typehash-registration/ |

**Prepaid Router Mode Follow-ups (2 tasks - from CRANE-163 review):**
- CRANE-268: Add Prepaid Mode Tests for Router (High - from CRANE-163 review)
- CRANE-269: Add NatSpec Documenting Prepaid Mode Behavior (Low - from CRANE-163 review)

## Cross-Repo Dependencies

Tasks in other repos that depend on this repo's tasks:
- (none yet)
