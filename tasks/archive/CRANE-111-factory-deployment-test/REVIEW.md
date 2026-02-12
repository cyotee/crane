# Code Review: CRANE-111

**Reviewer:** Claude Agent (Code Review)
**Review Started:** 2026-02-08
**Status:** Complete

---

## Acceptance Criteria Verification

### AC-1: Test uses `InitDevService.initEnv()` for canonical bootstrap
**Status:** PASS
**Evidence:** Test extends `CraneTest`, which calls `InitDevService.initEnv(address(this))` in `setUp()` (CraneTest.sol:19). The integration test's `setUp()` calls `CraneTest.setUp()` at line 295, correctly inheriting the canonical bootstrap. `test_factoryStack_isInitialized()` (line 358) explicitly asserts both `create3Factory` and `diamondFactory` are non-zero.

### AC-2: Test deploys DFPkg via `DiamondPackageCallBackFactory.deploy()`
**Status:** PASS
**Evidence:** `test_deployProxy_viaRealFactory()` (line 366) and 15 other tests all deploy via `diamondFactory.deploy(pkg, pkgArgs)`, which is the real `DiamondPackageCallBackFactory.deploy()` inherited from `CraneTest`.

### AC-3: Test asserts vault-aware storage is set correctly
**Status:** PASS
**Evidence:** Three tests cover vault-aware storage behavior:
- `test_vaultAwareStorage_proxyReturnsZeroAddress()` (line 679) - Documents that `proxy.balV3Vault()` returns `address(0)` because `initAccount()` does NOT initialize vault-aware storage on the proxy. This is correctly identified as by-design behavior.
- `test_vaultAwareStorage_pkgHoldsVaultRef()` (line 700) - Asserts `pkg.BALANCER_V3_VAULT()` equals the mock vault.
- `test_vaultAwareStorage_postDeployUsesVaultFromPkg()` (line 708) - Proves vault-aware storage is functional by confirming `postDeploy()` successfully registered the pool with the mock vault, and `lastPoolFactory()` is the DFPkg.

### AC-4: Test asserts token configs are sorted/recorded
**Status:** PASS
**Evidence:** Three tests cover token config sorting:
- `test_tokenConfigs_areSortedInFactoryRepo()` (line 735) - Passes tokens in reverse order, verifies `pkg.tokenConfigs(proxy)` returns sorted by address ascending.
- `test_tokenConfigs_preserveFieldAlignment()` (line 777) - Uses heterogeneous configs (different TokenType, rateProvider, paysYieldFees) and verifies all fields follow their token through sorting.
- `test_tokenConfigs_vaultReceivesSortedConfigs()` (line 820) - Verifies the mock vault received tokens in sorted order during `registerPool()`.

### AC-5: Existing tests still pass
**Status:** PASS
**Evidence:** `forge test` run confirms 124/124 tests pass across all 6 pool-constProd test suites. The 14 pre-existing tests in the integration file and all other test files are unaffected.

### AC-6: Build succeeds
**Status:** PASS
**Evidence:** `forge build` completes with no compilation errors. Only pre-existing warnings (AST source not found, unchecked-call lint, asm-keccak256 lint).

---

## Review Findings

### Finding 1: Unused `using` library directives in MockBalancerV3Vault
**File:** BalancerV3ConstantProductPoolDFPkg_Integration.t.sol:172-173
**Severity:** Low (Code Quality)
**Description:** `MockBalancerV3Vault` has two `using` directives for empty helper libraries:
```solidity
using PoolRoleAccountsHelper for PoolRoleAccounts;
using LiquidityManagementHelper for LiquidityManagement;
```
Both `PoolRoleAccountsHelper` and `LiquidityManagementHelper` (lines 260-261) are empty libraries with no functions. The `using` directives have no effect and add visual clutter.
**Status:** Open
**Resolution:** Remove both `using` directives and the empty library declarations. These appear to be remnants from earlier development where they may have been needed to work around Solidity memory struct issues.

### Finding 2: Stale user story references in pre-existing test sections
**File:** BalancerV3ConstantProductPoolDFPkg_Integration.t.sol:267-269
**Severity:** Informational
**Description:** The NatSpec on the test contract references `US-CRANE-061.1`, `US-CRANE-061.2`, `US-CRANE-061.3` for the pre-existing tests. These reference a prior task's user stories, not CRANE-111. The new CRANE-111 tests correctly use `US-CRANE-111.1` and `US-CRANE-111.2` in their section headers.
**Status:** Resolved (Accepted)
**Resolution:** This is expected since the pre-existing tests were written during an earlier task (CRANE-054/CRANE-061). The new CRANE-111 sections have correct references. No action needed.

### Finding 3: `_createTwoTokenConfig` helper has implicit token ordering
**File:** BalancerV3ConstantProductPoolDFPkg_Integration.t.sol:911-916
**Severity:** Informational
**Description:** The `_createTwoTokenConfig()` helper always creates configs with `tokenA` first and `tokenB` second. The numerical ordering of these addresses depends on the deployment nonce, which means the helper creates configs in an arbitrary but fixed order. The sorting-specific tests (lines 735-849) correctly handle this by determining `lower`/`higher` at runtime. Tests that use `_createTwoTokenConfig` for non-sorting concerns are fine since order doesn't affect their assertions.
**Status:** Resolved (Acceptable)
**Resolution:** No action needed. The sorting tests correctly determine token order at runtime.

### Finding 4: MockPoolInfoFacet reused for non-PoolInfo facet slots
**File:** BalancerV3ConstantProductPoolDFPkg_Integration.t.sol:338-339
**Severity:** Low (Code Quality)
**Description:** In `_deployPkg()`, the `MockPoolInfoFacet` is passed for both `standardSwapFeePercentageBoundsFacet` and `unbalancedLiquidityInvariantRatioBoundsFacet` PkgInit fields, with comments noting they are "Not used in facetCuts." While this works (the DFPkg's `facetCuts()` doesn't include these), it slightly obscures the test's intent. A reader might wonder why a PoolInfo facet is passed for fee/ratio slots.
**Status:** Resolved (Acceptable)
**Resolution:** This is acceptable for a test file. Creating separate mock facets for unused slots would add unnecessary complexity. The inline comments explain the intent.

---

## Suggestions

### Suggestion 1: Consider adding a negative test for duplicate token configs
**Priority:** Low
**Description:** None of the tests verify what happens when both token configs use the same token address (e.g., `TokenConfig(tokenA) + TokenConfig(tokenA)`). Depending on the DFPkg's `calcSalt` and `processArgs` behavior, this could either revert or produce an unexpected state. A test documenting this edge case would strengthen the suite.
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-251. This may already be tested in the unit-level `BalancerV3ConstantProductPoolDFPkg.t.sol` - worth checking.

### Suggestion 2: Consider adding a 3+ token config test
**Priority:** Low
**Description:** The `calcSalt` function enforces exactly 2 tokens (`tokenConfigs.length != 2` check), but the integration tests only verify the happy path with 2 tokens. A test showing that 3-token configs revert at the factory level would document this constraint.
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-252. May already be covered by unit tests (`test_calcSalt_revertsForWrongTokenCount` exists in the unit file). An integration-level test would confirm the factory stack also handles this correctly.

### Suggestion 3: Remove empty helper libraries
**Priority:** Low
**Description:** Remove the empty `PoolRoleAccountsHelper` and `LiquidityManagementHelper` libraries and their corresponding `using` directives. They serve no purpose and add confusion.
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol (lines 172-173, 260-261)
**User Response:** Accepted
**Notes:** Converted to task CRANE-253. Minor cleanup, could be part of a general test quality pass.

---

## Review Summary

**Findings:** 4 (0 Critical, 0 High, 2 Low, 2 Informational)
**Suggestions:** 3 (all Low priority)
**Recommendation:** APPROVE

The implementation correctly satisfies all 6 acceptance criteria for CRANE-111. The test suite adds 7 meaningful integration tests (plus 2 bonus tests for factory pool tracking and swap fee verification) that validate:

1. **Vault-aware storage** is correctly documented and tested (lives on DFPkg, not proxy)
2. **Token config sorting** is verified at both the factory repo level and the vault registration level, including field alignment preservation through heterogeneous configs
3. **Full factory deployment path** uses the canonical `InitDevService.initEnv()` + `DiamondPackageCallBackFactory.deploy()` stack

The code is clean, well-documented with NatSpec, properly organized with section headers, and the mock vault enhancement is minimal and focused. No bugs, security issues, or architectural concerns were found.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
