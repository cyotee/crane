# Task CRANE-159: Fix Balancer V3 Vault Diamond with DFPkg Pattern

**Repo:** Crane Framework
**Status:** In Progress
**Created:** 2026-01-28
**Dependencies:** CRANE-142 (Router implementation as reference)
**Worktree:** `feature/balancer-v3-vault-dfpkg-fix`
**Supersedes:** CRANE-155, CRANE-156, CRANE-157, CRANE-158

---

## Description

Refactor the Balancer V3 Vault Diamond to use the DFPkg (Diamond Factory Package) pattern established in CRANE-142, fix all interface compatibility issues identified in the CRANE-141 code review, add IFacet compliance to all facets, and update both Vault and Router tests to use the corrected implementation.

This task consolidates and supersedes:
- CRANE-155: Add Balancer V3 Vault Interface Coverage Tests
- CRANE-156: Fix Pool Token Selector Signatures in Vault Tests
- CRANE-157: Implement Missing Balancer V3 Vault Interface Functions
- CRANE-158: Add DiamondLoupe Support to Balancer V3 Vault

## Dependencies

- **CRANE-142**: Balancer V3 Router Diamond Facets (reference implementation for DFPkg pattern)

## User Stories

### US-CRANE-159.1: Migrate to DFPkg Pattern

As a deployer, I want the Vault to use the DFPkg pattern so that I can deploy Vaults deterministically via the factory infrastructure.

**Acceptance Criteria:**
- [ ] Delete `BalancerV3VaultDiamond.sol` (standalone Diamond)
- [ ] Create `BalancerV3VaultDFPkg.sol` implementing `IDiamondFactoryPackage`
- [ ] Bundle all facet references as immutables in DFPkg
- [ ] Implement `deployVault()` function for vault instance creation
- [ ] Implement `initAccount()` for storage initialization via delegatecall
- [ ] Support deterministic deployment via `DiamondPackageCallBackFactory`

### US-CRANE-159.2: IFacet Compliance for All Facets

As a developer, I want all Vault facets to implement the IFacet interface so that facet metadata is introspectable.

**Acceptance Criteria:**
- [ ] All 9 Vault facets implement `IFacet` interface:
  - `facetName()` - Returns contract type name
  - `facetInterfaces()` - Returns supported interface IDs
  - `facetFuncs()` - Returns function selectors
  - `facetMetadata()` - Returns combined metadata
- [ ] Selector references use `this.function.selector` pattern (not `Interface.function.selector`)
- [ ] Fix any incorrect/non-existent function references

### US-CRANE-159.3: Complete Interface Compatibility

As a user, I want the Vault Diamond to implement 100% of IVaultMain, IVaultExtension, and IVaultAdmin interfaces so that it is a drop-in replacement.

**Acceptance Criteria:**
- [ ] Implement missing `IVaultMain` functions:
  - `getVaultExtension()` - Return self-reference
- [ ] Implement missing `IVaultExtension` functions:
  - `getVaultAdmin()` - Return self-reference
  - `getNonzeroDeltaCount()` - Transient accounting read
  - `getTokenDelta(IERC20)` - Transient accounting read
  - `getAddLiquidityCalledFlag(address)` - Transient flag read
  - `getHooksConfig(address)` - Return hooks config struct
  - `getBptRate(address)` - Return pool BPT rate
  - `getPoolPausedState(address)` - Return paused state
  - `quote(bytes)` - Query entrypoint
  - `quoteAndRevert(bytes)` - Query with revert
  - `emitAuxiliaryEvent(bytes32,bytes)` - Event emission
  - `isERC4626BufferInitialized(IERC4626)` - Buffer check
  - `getERC4626BufferAsset(IERC4626)` - Buffer asset
  - `getAggregateSwapFeeAmount(address,IERC20)` - Split fee read
  - `getAggregateYieldFeeAmount(address,IERC20)` - Split fee read
- [ ] Implement missing `IVaultAdmin` functions:
  - `getPauseWindowEndTime()` - Rename from `getVaultPauseWindowEndTime()`
  - `getMinimumPoolTokens()` - Return constant
  - `getMaximumPoolTokens()` - Return constant
  - `getPoolMinimumTotalSupply()` - Return constant
  - `getBufferMinimumTotalSupply()` - Return constant

### US-CRANE-159.4: Fix Pool Token Selectors

As a developer, I want the pool token function selectors to match the Balancer interfaces exactly so that calls route correctly.

**Acceptance Criteria:**
- [ ] Pool token functions use correct signatures (pool is `msg.sender`, not parameter):
  - `approve(address owner, address spender, uint256 amount)`
  - `transfer(address owner, address to, uint256 amount)`
  - `transferFrom(address spender, address from, address to, uint256 amount)`
  - `balanceOf(address token, address account)` → verify vs interface
  - `totalSupply(address token)` → verify vs interface
- [ ] Update any tests using wrong selector signatures

### US-CRANE-159.5: Add DiamondLoupe Support

As a developer, I want the Vault to support IDiamondLoupe so that I can introspect facets at runtime.

**Acceptance Criteria:**
- [ ] Create `VaultLoupeFacet.sol` implementing `IDiamondLoupe`:
  - `facets()` - Return all facets and their selectors
  - `facetFunctionSelectors(address)` - Return selectors for a facet
  - `facetAddresses()` - Return all facet addresses
  - `facetAddress(bytes4)` - Return facet for a selector
- [ ] VaultLoupeFacet implements IFacet interface
- [ ] Include in DFPkg facet bundle

### US-CRANE-159.6: Interface Completeness Tests

As a developer, I want comprehensive tests verifying every interface selector routes correctly so that interface compatibility is guaranteed.

**Acceptance Criteria:**
- [ ] Test file: `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.t.sol`
- [ ] Tests enumerate every selector from:
  - `IVaultMain` - Assert all selectors resolve to facets
  - `IVaultExtension` - Assert all selectors resolve to facets
  - `IVaultAdmin` - Assert all selectors resolve to facets
- [ ] Tests verify calls don't revert with "function not found"
- [ ] Include DFPkg pattern tests (matching Router test pattern):
  - Package deployment/metadata tests
  - Vault deployment via DFPkg
  - Deterministic address verification
  - Idempotent deployment
  - Storage initialization verification
  - IFacet compliance for all facets
  - Facet size limits (<24KB each)

### US-CRANE-159.7: Update Router Tests

As a developer, I want the Router tests to use the fixed Vault DFPkg so that integration is verified.

**Acceptance Criteria:**
- [ ] Update `BalancerV3RouterDFPkg.t.sol` to:
  - Import and deploy real `BalancerV3VaultDFPkg`
  - Remove or reduce mock Vault usage
  - Test Router functions against real Vault
- [ ] Verify Router-Vault integration:
  - Swap operations through Router hit real Vault
  - Liquidity operations through Router hit real Vault
  - Query functions work end-to-end

## Technical Details

### File Structure

```
contracts/protocols/dexes/balancer/v3/vault/diamond/
├── BalancerV3VaultDFPkg.sol           # NEW: Replace BalancerV3VaultDiamond.sol
├── BalancerV3VaultStorageRepo.sol     # Existing (may need updates)
├── BalancerV3VaultModifiers.sol       # Existing (may need updates)
├── BalancerV3MultiTokenRepo.sol       # Existing
├── BalancerV3ReentrancyGuardRepo.sol  # Existing
└── facets/
    ├── VaultSwapFacet.sol             # Add IFacet, fix selectors
    ├── VaultLiquidityFacet.sol        # Add IFacet, fix selectors
    ├── VaultBufferFacet.sol           # Add IFacet, fix selectors
    ├── VaultPoolTokenFacet.sol        # Add IFacet, FIX SELECTORS (critical)
    ├── VaultQueryFacet.sol            # Add IFacet, add missing functions
    ├── VaultRegistrationFacet.sol     # Add IFacet, fix selectors
    ├── VaultAdminFacet.sol            # Add IFacet, add missing functions
    ├── VaultRecoveryFacet.sol         # Add IFacet, fix selectors
    ├── VaultTransientFacet.sol        # Add IFacet, add missing functions
    └── VaultLoupeFacet.sol            # NEW: IDiamondLoupe implementation
```

### Key Implementation Patterns (from Router)

1. **DFPkg Pattern:**
   ```solidity
   contract BalancerV3VaultDFPkg is IDiamondFactoryPackage {
       // All facets as immutables
       address public immutable vaultSwapFacet;
       address public immutable vaultLiquidityFacet;
       // ... etc

       function deployVault(bytes32 salt) external returns (address);
       function initAccount(bytes calldata data) external;
   }
   ```

2. **IFacet Pattern:**
   ```solidity
   function facetFuncs() external pure returns (bytes4[] memory) {
       bytes4[] memory selectors = new bytes4[](N);
       selectors[0] = this.functionName.selector;  // Use this., not Interface.
       // ...
       return selectors;
   }
   ```

3. **Selector Reference Fix:**
   - WRONG: `IVaultMain.swap.selector`
   - RIGHT: `this.swap.selector`

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.sol`
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultLoupeFacet.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.t.sol`

**Delete Files:**
- `contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDiamond.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDiamond.t.sol`

**Modified Files:**
- All 9 existing facets in `facets/` - Add IFacet, fix selectors
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.t.sol` - Use real Vault

## Inventory Check

Before starting, verify:
- [ ] CRANE-142 Router DFPkg exists at `contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.sol`
- [ ] Understand `IFacet` interface pattern from Router facets
- [ ] Have access to Balancer V3 interfaces:
  - `lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/IVaultMain.sol`
  - `lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/IVaultExtension.sol`
  - `lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/IVaultAdmin.sol`
- [ ] Understand all missing functions from CRANE-141 review

## Completion Criteria

- [ ] All facets compile to <24KB each
- [ ] Vault DFPkg deploys successfully via factory
- [ ] Every selector from IVaultMain routes to a facet
- [ ] Every selector from IVaultExtension routes to a facet
- [ ] Every selector from IVaultAdmin routes to a facet
- [ ] All IFacet implementations correct
- [ ] DiamondLoupe functions work
- [ ] Vault tests pass (interface completeness)
- [ ] Router tests pass with real Vault
- [ ] CRANE-155, 156, 157, 158 marked as superseded

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
