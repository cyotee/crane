# Progress Log: CRANE-161

## Current Checkpoint

**Last checkpoint:** Task complete
**Next step:** Ready for code review
**Build status:** PASS (forge build succeeds)
**Test status:** PASS (4915 tests pass, 6 pre-existing fork failures unrelated)

---

## Session Log

### 2026-02-07 - Task Complete

#### US-CRANE-161.1: Resolve Loupe Facet Strategy

**Decision: Factory-provided DiamondLoupeFacet (Option A)**

The `DiamondPackageCallBackFactory` automatically adds 4 facets to every diamond:
- ERC165Facet
- DiamondLoupeFacet (provides IDiamondLoupe)
- ERC8109IntrospectionFacet
- PostDeployAccountHookFacet (removed after deployment)

Creating a custom `VaultLoupeFacet.sol` would cause selector collisions with the
factory-provided facet. The existing Vault DFPkg correctly:
- Omits loupe from its `PkgInit` struct
- Lists `IDiamondLoupe.interfaceId` in `facetInterfaces()` acknowledging factory provision

**Changes:**
- Updated `tasks/archive/CRANE-159-balancer-v3-vault-dfpkg-fix/TASK.md`:
  - US-CRANE-159.5: Documented factory-provided loupe approach, marked acceptance criteria resolved
  - US-CRANE-159.7: Documented router integration test deferral to CRANE-161
  - Removed VaultLoupeFacet.sol from file structure and new files lists

#### US-CRANE-161.2: Integrate Real Vault in Router Tests

**Created:** `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterVaultIntegration.t.sol`

Integration test contract `BalancerV3RouterVaultIntegrationTest` that:
- Extends `TestBase_BalancerV3Router` (inherits all unit test infrastructure)
- Overrides `_deployMockContracts()` to deploy real vault facets
- After factory setup, deploys `BalancerV3VaultDFPkg` and a real Vault Diamond
- Deploys router pointing to the real vault via `_deployIntegrationRouter()`

**7 integration tests:**
1. `test_integration_routerPointsToRealVault` - Router getVault() returns real vault
2. `test_integration_vaultHasDiamondLoupe` - Vault has 12 facets (9 vault + 3 factory)
3. `test_integration_vaultSupportsExpectedInterfaces` - ERC165, IDiamondLoupe, IVaultMain, IVaultExtension, IVaultAdmin
4. `test_integration_vaultSelectorsResolve` - Key selectors (swap, addLiquidity, etc.) resolve via loupe
5. `test_integration_vaultStorageInitialized` - Vault config values match deployment params
6. `test_integration_routerDeploymentIsDeterministic` - Deterministic addresses with real vault
7. `test_integration_sharedFactoryInfrastructure` - Router and Vault share same factory

**Plus 8 inherited tests from TestBase** (package deployment, facet sizes, etc.)

#### Test Results

All 15 tests in integration test file pass. All 17 existing router tests pass. All 18 existing vault tests pass. Full suite: 4915 pass, 6 pre-existing fork failures.

### 2026-01-29 - Task Created

- Task created from code review suggestion
- Origin: CRANE-159 REVIEW.md Suggestion 2
- Ready for agent assignment via /backlog:launch
