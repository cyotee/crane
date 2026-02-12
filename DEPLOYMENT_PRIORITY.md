# Deployment Priority Report: Crane Framework

**Generated:** 2026-02-08
**Total Pending Tasks:** 93
**Scope:** All unarchived tasks assessed for deployment readiness

---

## Priority Tiers

### P0 - Deployment Blockers (Fix Before Any Production Use)

These tasks fix bugs that would cause incorrect behavior or reverts in production.

| ID | Title | Category | Why Blocking |
|----|-------|----------|--------------|
| CRANE-163 | Fix Prepaid Router Mode for Permit2-less Operations | BUG_FIX | `_takeTokenIn()` unconditionally calls Permit2, which reverts when `permit2 == address(0)`. Any router operation without Permit2 will fail. |
| CRANE-179 | Fix LBP DFPkg calcSalt Address Collisions | BUG_FIX | `calcSalt()` omits hooksContract, blockProjectTokenSwapsIn, and reserveTokenVirtualBalance. Pools with different configs but same tokens get identical deterministic addresses, causing CREATE3 deployment failures or proxy collisions. |

**Effort estimate:** Both are targeted fixes to specific functions. Can be done in parallel.

---

### P1 - Security / Correctness (Fix Before Mainnet)

These tasks address overflow protection gaps or deterministic address correctness that could cause loss of funds or broken state on mainnet.

| ID | Title | Category | Risk |
|----|-------|----------|------|
| CRANE-254 | Protect computeInvariant Overflow with mulDiv | SECURITY | `computeInvariant` uses `FixedPoint.mulDown`/`mulUp` which overflow for balances above ~3.4e38. `onSwap` and `computeBalance` already use `Math.mulDiv`. Inconsistency creates edge-case overflow risk. |
| CRANE-187 | Add POOL_INIT_CODE_HASH Regression Test | TEST | If Uniswap V3 pool bytecode drifts from the hardcoded hash, all deterministic address computations silently break. No test currently guards this. |
| CRANE-216 | Add POOL_INIT_CODE_HASH Regression Test | TEST | Same as CRANE-187 (duplicate coverage for V3 pool init code hash). |

**Effort estimate:** CRANE-254 is a targeted `mulDown`->`mulDiv` replacement. CRANE-187/216 are single-assertion tests.

---

### P2 - Production Quality (Complete Before Launch)

Input validation gaps, missing integration tests for deployed components, and architectural alignment needed for maintainable production code.

#### P2a - Input Validation / Defense in Depth

| ID | Title | Category | Gap |
|----|-------|----------|-----|
| CRANE-248 | Add onSwap 2-Token Guardrails to Balancer V3 Pool | SECURITY | No validation that `balancesScaled18.length == 2` in constant product pool's `onSwap`. Malformed input silently produces wrong results. |
| CRANE-192 | Add Input Length Validation in CoW Router | BUG_FIX | No array length validation in CoW router settlement paths. Mismatched arrays cause out-of-bounds reverts with unhelpful error messages. |
| CRANE-259 | Add Maximum Token Count Boundary Test | TEST | Unclear whether Balancer V3's 8-token limit is enforced. Need to decide and document the constraint. |

#### P2b - Integration Test Coverage for Deployed Components

| ID | Title | Category | Gap |
|----|-------|----------|-----|
| CRANE-162 | Expand Balancer V3 Router Test Coverage | TEST | Router Diamond has no functional swap/batch operation tests. Only wiring tests exist. |
| CRANE-244 | Add E2E Swap Integration Test for Router-Vault | TEST | No test performs actual token swap through Router->Vault Diamond path. |
| CRANE-178 | Integration Tests for Weighted Pool Package | TEST | No integration tests for WeightedPool/LBPool with actual Diamond Vault deployment. |
| CRANE-193 | Add Diamond-Vault Integration Tests for Hooks | TEST | Hook implementations untested with actual Diamond Vault deployment. |
| CRANE-213 | Add Balancer V3 Stable Pool Fork Parity Tests | TEST | No fork tests validating stable pool behavior against mainnet deployments. |
| CRANE-221 | Complete Uniswap V4 Port Verification | TEST | No Base mainnet fork tests confirming V4 port serves as drop-in replacement. |
| CRANE-190 | Add Gyro Pool Token-Order Independence Tests | TEST | No coverage confirming deterministic addresses regardless of token order for ECLP/2CLP pools. |

#### P2c - Architecture Alignment

| ID | Title | Category | Gap |
|----|-------|----------|-----|
| CRANE-164 | Add Target Layer to Router Facets | REFACTOR | Router facets skip Crane's Facet->Target->Repo architecture. Business logic in Facets makes upgradeability harder. |
| CRANE-166 | Refactor Router Guards to Follow Repo Pattern | REFACTOR | Guard logic in Modifiers instead of Repos. Inconsistent with framework conventions. |
| CRANE-195 | Make lib/reclamm Submodule Removal Possible | REFACTOR | Balancer V3 dependencies still resolve through lib/reclamm submodule. Blocks clean build without submodules. |
| CRANE-124 | Use Canonical Proxy Fixture for ERC5267 | TEST | ERC5267 integration test uses DiamondProxyStub instead of production deployment path. |

---

### P3 - Code Quality (Complete Before Audit)

Test hardening, negative test coverage, and validation improvements. Not blocking deployment but should be done before a security audit.

#### P3a - Test Hardening / Missing Negative Tests

| ID | Title | Category |
|----|-------|----------|
| CRANE-120 | Tighten postDeploy Call Expectations | TEST |
| CRANE-121 | Tighten Fuzz Assumptions for Realism | TEST |
| CRANE-127 | Assert Zero-Fee Outcome in Safe Boundary Test | TEST |
| CRANE-128 | Replace Heuristic Percent Bounds with Explicit Tolerances | TEST |
| CRANE-130 | Add Direction Assertion to SwapMath Fully-Spent Test | TEST |
| CRANE-133 | Make Stable-vs-Volatile Comparison Apples-to-Apples | TEST |
| CRANE-134 | Assert Aerodrome Fee Config in Stub | TEST |
| CRANE-138 | Test SwapMath Edge Case Where Limit Equals Current | TEST |
| CRANE-168 | Add SafeCast160 Unit Tests | TEST |
| CRANE-169 | Add Permit2Lib Integration Tests | TEST |
| CRANE-174 | Add Router getWeth/getPermit2 Validation | TEST |
| CRANE-180 | Add Stable Pool DFPkg Salt Consistency Tests | TEST |
| CRANE-184 | Add V3 Quoter Function Tests | TEST |
| CRANE-185 | Add V3Migrator Integration Test | TEST |
| CRANE-214 | Add Upstream Execute Parity Assertions | TEST |
| CRANE-215 | Add End-to-End tokenURI() Shape Test | TEST |
| CRANE-217 | Reduce False Positives In JSON Validation | TEST |
| CRANE-231 | Add USDT Approval Tests | TEST |
| CRANE-232 | Add Slipstream Near-Depletion Exact-Output Test | TEST |
| CRANE-234 | Add BetterEfficientHashLib Extended Tests | TEST |
| CRANE-235 | Add SlipstreamQuoter Fee Guard Revert Test | TEST |
| CRANE-236 | Add k() Assertion for Constant-Product Mode | TEST |
| CRANE-237 | Add k() Assertion for Mixed-Decimal Pair | TEST |
| CRANE-241 | Add FoT Output Token Fix-Up Verification Tests | TEST |
| CRANE-242 | Add Fix-Up Sanity Assertion to FoT Tests | TEST |
| CRANE-245 | Add Burn Proportional Tests to Stable Pool | TEST |
| CRANE-249 | Add Zero-Selector and Collision Guards | TEST |
| CRANE-250 | Create Behavior_IDiamondFactoryPackage Library | TEST |
| CRANE-251 | Add Negative Test for Duplicate Token Configs | TEST |
| CRANE-252 | Add ConstantProduct DFPkg 3+ Token Count Revert | TEST |
| CRANE-257 | Add Negative Test for LengthMismatch | TEST |
| CRANE-258 | Add Fuzz Test for Weight Sum Validation | TEST |
| CRANE-261 | Add Forwarder Codehash Equality Assertion | TEST |
| CRANE-263 | Add Mixed-Mismatch Remove FacetCut Test | TEST |
| CRANE-265 | Add Create3Factory Registry Verification Test | TEST |
| CRANE-267 | Add Double-Init Documentation Test | TEST |

#### P3b - Submodule Cleanup (Reduces Build Complexity)

| ID | Title | Category |
|----|-------|----------|
| CRANE-181 | Remove lib/aerodrome-contracts Submodule | CLEANUP |
| CRANE-186 | Remove v3-core and v3-periphery Submodules | CLEANUP |

#### P3c - Bug Fix (Test-Only)

| ID | Title | Category |
|----|-------|----------|
| CRANE-197 | Stabilize ReClaMM Deterministic Address Test | BUG_FIX |

---

### P4 - Cleanup / Documentation (Do Anytime)

Non-functional improvements. Safe to batch and do in bulk or opportunistically.

#### P4a - Code Cleanup

| ID | Title | Category |
|----|-------|----------|
| CRANE-122 | Remove Unnecessary ERC20 Metadata Mocks | CLEANUP |
| CRANE-125 | Align ERC5267 Pragma with Repo Version | CLEANUP |
| CRANE-126 | Fix Unchecked-Call Lint Warning | CLEANUP |
| CRANE-131 | Delete Deprecated AerodromService Test File | CLEANUP |
| CRANE-132 | Align Aerodrome Test Pragma | CLEANUP |
| CRANE-137 | Remove Redundant vm.assume in SwapMath | CLEANUP |
| CRANE-139 | Remove Always-True feeAmount >= 0 Assertions | CLEANUP |
| CRANE-172 | Remove Deprecated AerodromService | CLEANUP |
| CRANE-176 | Replace LBP String Revert with Custom Error | CLEANUP |
| CRANE-196 | Replace Unsupported Foundry Config Key | CLEANUP |
| CRANE-240 | Remove Commented-Out Console Imports | CLEANUP |
| CRANE-253 | Remove Empty Helper Libraries | CLEANUP |
| CRANE-260 | Remove Dead _computeUpstreamRequestTypeHash | CLEANUP |
| CRANE-266 | Remove Unused VAULT_AWARE_SLOT Constant | CLEANUP |

#### P4b - Refactoring

| ID | Title | Category |
|----|-------|----------|
| CRANE-123 | Split ERC5267 IFacet Tests into Dedicated File | REFACTOR |
| CRANE-136 | Simplify _k_from_f Helper | REFACTOR |
| CRANE-140 | Align Fee Test Naming with Assertions | REFACTOR |
| CRANE-175 | Consolidate Router Facet Size Checks | REFACTOR |
| CRANE-243 | Extract Shared Vault Test Mocks to TestBase | REFACTOR |
| CRANE-246 | Add Debugging Info to Violation Tracking | REFACTOR |
| CRANE-256 | Extract DFPkg Test Mocks to Shared Utility | REFACTOR |
| CRANE-264 | Extract ConstantProductPoolFactoryService | REFACTOR |

#### P4c - Documentation

| ID | Title | Category |
|----|-------|----------|
| CRANE-129 | Align SwapMath Golden Vector Comments | DOCS |
| CRANE-135 | Tighten/Clarify Gas Estimate Language | DOCS |
| CRANE-165 | Add NatSpec Custom Tags to Router Contracts | DOCS |
| CRANE-170 | Document DeployPermit2 Bytecode Source | DOCS |
| CRANE-173 | Add Aerodrome Interface Comparison Report | DOCS |
| CRANE-177 | Add NatSpec Examples to GradualValueChange | DOCS |
| CRANE-194 | Align Hook Comments With Actual Behavior | DOCS |
| CRANE-199 | Resolve CRANE-152 Scope Mismatch | DOCS |
| CRANE-230 | Document SafeCast Wrapper Delegation Pattern | DOCS |
| CRANE-247 | Fix Misleading NatSpec in Burn Invariant Tests | DOCS |
| CRANE-262 | Add Explanatory Comment for Large APR | DOCS |

#### P4d - New Features (Not Deployment-Critical)

| ID | Title | Category |
|----|-------|----------|
| CRANE-153 | Port Resupply Protocol to Local Contracts | FEATURE |
| CRANE-255 | Diamond Implementation of ERC-6909 | FEATURE |

#### P4e - CI / Infrastructure

| ID | Title | Category |
|----|-------|----------|
| CRANE-198 | Add Submodule Removal Verification to CI | TEST |

---

## Recommended Deployment Sequence

```
Phase 1: Fix Blockers (P0)                          2 tasks
  CRANE-163, CRANE-179

Phase 2: Security & Correctness (P1)                3 tasks
  CRANE-254, CRANE-187, CRANE-216

Phase 3: Input Validation (P2a)                     3 tasks
  CRANE-248, CRANE-192, CRANE-259

Phase 4: Integration Tests (P2b)                    7 tasks
  CRANE-162, CRANE-244, CRANE-178, CRANE-193,
  CRANE-213, CRANE-221, CRANE-190

Phase 5: Architecture Alignment (P2c)               4 tasks
  CRANE-164, CRANE-166, CRANE-195, CRANE-124

Phase 6: Audit Prep (P3)                           39 tasks
  Test hardening, negative tests, submodule cleanup

Phase 7: Polish (P4)                               35 tasks
  Cleanup, docs, refactoring, new features
```

## Summary by Priority

| Priority | Count | Description |
|----------|-------|-------------|
| P0 - Blockers | 2 | Bugs causing reverts or address collisions |
| P1 - Security | 3 | Overflow protection, hash drift detection |
| P2 - Production Quality | 14 | Validation, integration tests, architecture |
| P3 - Code Quality | 39 | Test hardening, submodule cleanup |
| P4 - Polish | 35 | Cleanup, docs, refactoring, features |
| **Total** | **93** | |

## Critical Path

The shortest path to a deployable system:

1. **CRANE-163** + **CRANE-179** (P0 blockers - do first, parallelizable)
2. **CRANE-254** (P1 security - overflow in computeInvariant)
3. **CRANE-248** + **CRANE-192** (P2a input validation - parallelizable)
4. **CRANE-162** + **CRANE-244** (P2b integration tests - validates router+vault work end-to-end)

These 7 tasks represent the minimum viable path to deployment confidence.
