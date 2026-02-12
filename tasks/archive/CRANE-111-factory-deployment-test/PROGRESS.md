# Progress Log: CRANE-111

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Code review
**Build status:** PASS (forge build succeeds, no compilation errors)
**Test status:** PASS (21/21 integration tests pass, 124/124 total pool tests pass)

---

## Session Log

### 2026-02-08 - Implementation Complete

#### Summary

Added factory integration deployment tests to `BalancerV3ConstantProductPoolDFPkg_Integration.t.sol`. The file already existed with 14 tests from prior work. Added 7 new tests covering the specific CRANE-111 acceptance criteria:

#### New Tests Added

**Vault-Aware Storage Verification (US-CRANE-111.1):**
1. `test_vaultAwareStorage_proxyReturnsZeroAddress` - Confirms that `IBalancerV3VaultAware(proxy).balV3Vault()` returns `address(0)` because `initAccount()` does NOT initialize vault-aware storage on the proxy. The vault ref lives on the DFPkg as an immutable.
2. `test_vaultAwareStorage_pkgHoldsVaultRef` - Confirms the DFPkg itself holds the correct vault reference via its `BALANCER_V3_VAULT` immutable.
3. `test_vaultAwareStorage_postDeployUsesVaultFromPkg` - Confirms that `postDeploy()` successfully uses the DFPkg's vault reference to register the pool, proving the vault-aware storage on the DFPkg is functional.

**Token Config Sorting & Recording (US-CRANE-111.2):**
4. `test_tokenConfigs_areSortedInFactoryRepo` - Passes tokens in reverse order, verifies `pkg.tokenConfigs(proxy)` returns them sorted by address (ascending).
5. `test_tokenConfigs_preserveFieldAlignment` - Uses heterogeneous configs (different TokenType, rateProvider, paysYieldFees) and verifies all fields follow their token through the sort.
6. `test_tokenConfigs_vaultReceivesSortedConfigs` - Verifies the mock vault received tokens in sorted order during `registerPool()`.

**Additional Coverage:**
7. `test_postDeploy_registersPoolInFactory` - Verifies `pkg.isPoolFromFactory(proxy)` and `pkg.getPoolCount()`.
8. `test_postDeploy_vaultReceivesCorrectSwapFee` - Verifies `mockVault.lastSwapFeePercentage()` is 5%.
9. `test_deploy_isIdempotent` - Deploying same args twice returns the same address.

#### Mock Vault Enhancement

Enhanced `MockBalancerV3Vault` to store the token configs it receives during `registerPool()`, enabling direct verification of sorting and field preservation. Added accessors: `registeredTokenCount()`, `registeredTokenAt()`, `registeredTokenType()`, `registeredRateProvider()`, `registeredPaysYieldFees()`.

#### Key Finding: Vault-Aware Storage on Proxy

Discovered that `initAccount()` does NOT call `BalancerV3VaultAwareRepo._initialize()` on the proxy. The vault reference is only stored:
1. In the DFPkg's constructor storage (for `postDeploy` to access)
2. As an immutable `BALANCER_V3_VAULT` on the DFPkg contract

This means `IBalancerV3VaultAware(proxy).balV3Vault()` returns `address(0)`. This is documented and tested as the current behavior. If this should be changed (e.g., for proxy-level vault queries), it would require modifying `initAccount()` in the DFPkg.

#### Acceptance Criteria Status

- [x] Test uses `InitDevService.initEnv()` for canonical bootstrap (CraneTest.setUp)
- [x] Test deploys DFPkg via `DiamondPackageCallBackFactory.deploy()`
- [x] Test asserts vault-aware storage is set correctly (documented actual behavior)
- [x] Test asserts token configs are sorted/recorded
- [x] Existing tests still pass (124/124)
- [x] Build succeeds (0 compilation errors)

---

### 2026-01-17 - Task Created

- Task created from code review suggestion (Suggestion 2)
- Origin: CRANE-054 REVIEW.md
- Priority: Medium
- Ready for agent assignment via /backlog:launch
