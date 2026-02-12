# Progress Log: CRANE-061

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Ready for code review
**Build status:** ✅ Passing
**Test status:** ✅ 12/12 tests passing

---

## Session Log

### 2026-01-14 - Task Created

- Task created from code review suggestion (Suggestion 2)
- Origin: CRANE-053 REVIEW.md
- Priority: High (P1)
- Ready for agent assignment via /backlog:launch

### 2026-01-17 - Implementation Complete

**Summary:** Created comprehensive integration tests for `BalancerV3ConstantProductPoolDFPkg` that exercise the full deployment flow using the real factory stack from `InitDevService`.

**Files Created:**
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol`

**Files Modified:**
- `contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol`
  - Added import for `BalancerV3VaultAwareRepo`
  - Added `BalancerV3VaultAwareRepo._initialize()` in constructor (bug fix)

**Bug Found and Fixed:**
During integration testing, discovered that `BalancerV3ConstantProductPoolDFPkg` was missing the initialization of `BalancerV3VaultAwareRepo` in its constructor. This caused `postDeploy` to fail because `_registerPoolWithBalV3Vault` couldn't read the vault address from storage. Fixed by adding the missing initialization call.

**Tests Implemented (12 total):**

1. **US-CRANE-061.1: Full Deployment via Factory Stack**
   - `test_factoryStack_isInitialized()` - Verifies InitDevService creates working factories
   - `test_deployProxy_viaRealFactory()` - Tests end-to-end proxy deployment
   - `test_deployedProxy_hasExpectedFacets()` - Verifies facets are properly attached
   - `test_deployedProxy_hasExpectedSelectors()` - Checks selector-to-facet mapping
   - `test_deployedProxy_supportsERC165()` - Tests ERC-165 introspection

2. **US-CRANE-061.2: Verify initAccount Initialization**
   - `test_initAccount_initializesERC20Metadata()` - Tests name/symbol/decimals
   - `test_initAccount_initializesEIP712Domain()` - Tests EIP-5267 domain
   - `test_initAccount_domainSeparatorIsValid()` - Tests DOMAIN_SEPARATOR

3. **US-CRANE-061.3: Verify postDeploy Vault Registration**
   - `test_postDeploy_triggersVaultRegistration()` - Tests vault.registerPool call
   - `test_updatePkg_recordsTokenConfigs()` - Tests token config storage

4. **Deterministic Address Tests**
   - `test_calcAddress_matchesDeployedAddress()` - Tests address prediction
   - `test_tokenOrderIndependence_produceSameAddress()` - Tests token order invariance

**Test Run Output:**
```
Ran 12 tests for test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol:BalancerV3ConstantProductPoolDFPkg_Integration_Test
[PASS] test_calcAddress_matchesDeployedAddress() (gas: 3936972)
[PASS] test_deployProxy_viaRealFactory() (gas: 3930866)
[PASS] test_deployedProxy_hasExpectedFacets() (gas: 3977628)
[PASS] test_deployedProxy_hasExpectedSelectors() (gas: 3940054)
[PASS] test_deployedProxy_supportsERC165() (gas: 3932140)
[PASS] test_factoryStack_isInitialized() (gas: 5273)
[PASS] test_initAccount_domainSeparatorIsValid() (gas: 3929822)
[PASS] test_initAccount_initializesEIP712Domain() (gas: 3937602)
[PASS] test_initAccount_initializesERC20Metadata() (gas: 3940124)
[PASS] test_postDeploy_triggersVaultRegistration() (gas: 3931754)
[PASS] test_tokenOrderIndependence_produceSameAddress() (gas: 26193)
[PASS] test_updatePkg_recordsTokenConfigs() (gas: 3930505)
Suite result: ok. 12 passed; 0 failed; 0 skipped
```

**Mock Contracts Created:**
- `MockERC20` - Simple ERC20 for test tokens
- `MockPoolInfoFacet` - Implements IFacet for IPoolInfo
- `MockBalancerV3Vault` - Records pool registration calls
