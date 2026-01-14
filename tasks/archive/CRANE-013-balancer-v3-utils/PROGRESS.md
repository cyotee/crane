# Progress Log: CRANE-013

## Current Checkpoint

**Last checkpoint:** Review complete - findings documented
**Next step:** Review doc sync (PROGRESS/REVIEW)
**Build status:** PASS (`forge build`)
**Test status:** PASS (Balancer V3 suites run; see below)

> **Build/Tests Note:** `forge build` succeeded in this worktree. Balancer V3-focused specs also ran successfully; full-suite `forge test` was not exhaustively re-run as part of this review pass.

---

## Balancer V3 Correctness Memo

### Executive Summary

Crane's Balancer V3 utilities provide a Diamond-pattern (ERC2535) integration with Balancer V3's vault singleton. The implementation follows correct architectural patterns but has **zero dedicated test coverage** for Balancer V3 functionality, representing a significant gap.

Update: there *is* initial Balancer V3 test coverage (constant product pool target + factory repo + 80/20 weighted math). The gap remains for TokenConfig sorting, package deployment, vault-aware facets, and rounding/edge-case invariants.

---

## 1. Key Invariants for Balancer V3

### 1.1 Swap Invariant Preservation

**Location:** `BalancerV3ConstantProductPoolTarget.sol:94-113`

The constant product AMM implements the standard x*y=k formula:
- **EXACT_IN:** `dy = (Y * dx) / (X + dx)`
- **EXACT_OUT:** `dx = (X * dy) / (Y - dy)`

**Critical invariants:**
1. Pool invariant must never decrease from swaps (can increase due to fees)
2. The invariant formula `sqrt(X * Y) * 1e9` must be linear: `inv(a*n, b*n) = inv(a,b) * n`

**Correctness assessment:**
- The `computeInvariant()` function correctly uses `mulDown`/`mulUp` based on rounding direction
- The `onSwap()` function uses pure integer division without rounding protection
- **RISK:** Integer division in `onSwap()` can cause rounding in pool's disfavor for small amounts

### 1.2 Balance Computation Invariant

**Location:** `BalancerV3ConstantProductPoolTarget.sol:75-85`

```solidity
newBalance = ((newInvariant * newInvariant) / balancesLiveScaled18[otherTokenIndex]);
```

**Issue:** Uses raw division without `divUp()` which could allow extraction of value from the pool. The Vault expects pools to round up when computing new balances.

### 1.3 Rate Provider Integration

**Location:** `ERC4626RateProviderTarget.sol:43-49`

```solidity
rate = ERC4626RateProviderRepo._erc4626Vault().previewRedeem(1e18);
return rate * (10 ** (18 - ERC4626RateProviderRepo._assetDecimals()));
```

**Correctness:**
- Deliberately uses `previewRedeem()` instead of `convertToAssets()` to capture actual redeemable value including fees
- Properly scales to 18 decimals for Balancer V3 compatibility

### 1.4 80/20 Weighted Pool Math

**Location:** `BalancerV38020WeightedPoolMath.sol`

The library provides comprehensive calculations for 80/20 weighted pools:
- Proportional deposits/withdrawals
- Single-sided deposits/withdrawals with fee calculation
- Price impact and delta calculations
- Properly uses Balancer's `WeightedMath` library

**Key bounds enforced:**
- `_MAX_IN_RATIO`: Maximum input relative to pool balance
- `_MAX_OUT_RATIO`: Maximum output relative to pool balance
- `_MAX_INVARIANT_RATIO`: Maximum invariant growth per operation
- `_POOL_MINIMUM_TOTAL_SUPPLY = 1e6`: Dead share protection

---

## 2. Vault Singleton Interactions

### 2.1 Vault Awareness Pattern

**Files:**
- `BalancerV3VaultAwareRepo.sol` - Diamond storage for vault reference
- `BalancerV3VaultAwareTarget.sol` - Exposes vault via `getVault()`, `balV3Vault()`
- `BalancerV3VaultAwareFacet.sol` - IFacet metadata

**Storage slot:** `keccak256("protocols.dexes.balancer.v3.vault.aware")`

All pool token operations delegate to the vault singleton:
- `totalSupply()` -> `vault.totalSupply(address(this))`
- `balanceOf()` -> `vault.balanceOf(address(this), account)`
- `transfer()` -> `vault.transfer(msg.sender, recipient, amount)`
- `approve()` -> `vault.approve(msg.sender, spender, amount)`

This is **correct** - Balancer V3 uses a multi-token approach where the vault manages all BPT accounting.

### 2.2 Pool Registration

**Location:** `BalancerV3BasePoolFactory.sol:115-136`

Pools are registered with the vault via `_registerPoolWithBalV3Vault()`:
```solidity
vault.registerPool(
    pool,
    tokens,
    swapFeePercentage,
    getNewPoolPauseWindowEndTime(),
    protocolFeeExempt,
    roleAccounts,
    poolHooksContract,
    liquidityManagement
)
```

**Correctness:** Follows Balancer V3's expected registration flow.

### 2.3 Vault Guard Pattern

**Location:** `BalancerV3VaultGuardModifiers.sol`

```solidity
modifier onlyBalancerV3Vault() {
    if (msg.sender != address(BalancerV3VaultAwareRepo._balancerV3Vault())) {
        revert NotBalancerV3Vault(msg.sender);
    }
    _;
}
```

Used to protect vault-only callbacks like `emitTransfer()` and `emitApproval()`.

### 2.4 Sender Guard (Transient Storage)

**Location:** `SenderGuardCommon.sol`

Uses EIP-1153 transient storage to track the original sender through router calls:
```solidity
bytes32 private immutable _SENDER_SLOT = TransientStorageHelpers.calculateSlot("SenderGuard", "sender");
```

**Purpose:** Routers obscure `msg.sender`; this preserves the original caller identity.

---

## 3. Pool Type Differences

### 3.1 Constant Product Pool (Implemented)

**Files:** `contracts/protocols/dexes/balancer/v3/pool-constProd/`

- Simple x*y=k AMM (like Uniswap V2)
- 2 tokens only
- No weights (50/50 implied)
- Invariant: `sqrt(X * Y) * 1e9`

**Bounds:**
- `_MIN_SWAP_FEE_PERCENTAGE = 1e12` (0.0001%)
- `_MAX_SWAP_FEE_PERCENTAGE = 0.1e18` (10%)
- `_MIN_INVARIANT_RATIO = 70e16` (70%)
- `_MAX_INVARIANT_RATIO = 300e16` (300%)

### 3.2 80/20 Weighted Pool (Math Only)

**File:** `BalancerV38020WeightedPoolMath.sol`

Provides calculation utilities but **no facet/target implementation exists**. This is a math library only.

**Differences from Constant Product:**
- Supports non-equal weights (80/20 configured)
- Uses Balancer's `WeightedMath` library for invariant calculations
- More complex fee calculations for unbalanced operations

### 3.3 Missing Pool Types

The following Balancer V3 pool types have **no Crane implementation**:
- Composable Stable Pools
- Boosted Pools (with nested linear pools)
- Custom Hook Pools

---

## 4. Missing Tests and Recommendations

### 4.1 Current Test Coverage

**Balancer V3 specific tests: present (non-zero)**

Balancer V3 currently has a small but meaningful spec suite under `test/foundry/spec/protocols/dexes/balancer/v3/` (e.g. constant product pool target, base pool factory repo, and 80/20 weighted math).

Additional test infrastructure exists in `contracts/protocols/dexes/balancer/v3/test/bases/`:
- `TestBase_BalancerV3.sol` - Minimal, extends Balancer's BaseTest
- `TestBase_BalancerV3Vault.sol` - Comprehensive test harness with vault mock setup
- `TestBase_BalancerV3_WeightedPool.sol` - Empty file
- `TestBase_BalancerV3_8020WeightedPool.sol` - Not reviewed (empty)

### 4.2 Recommended Unit Tests

**Priority: HIGH**

| Test Suite | Target | Type |
|------------|--------|------|
| `ConstantProductPool_computeInvariant.t.sol` | Invariant calculation | Fuzz |
| `ConstantProductPool_computeBalance.t.sol` | Balance computation | Fuzz |
| `ConstantProductPool_onSwap.t.sol` | Swap execution | Fuzz |
| `ERC4626RateProvider_getRate.t.sol` | Rate calculation | Unit |
| `TokenConfigUtils_sort.t.sol` | Token sorting | Unit |

### 4.3 Recommended Spec Tests

**Priority: HIGH**

| Test Suite | Description |
|------------|-------------|
| `BalancerV3PoolFacet_IFacet.t.sol` | Verify facet metadata correctness |
| `BalancerV3VaultAwareFacet_IFacet.t.sol` | Verify vault-aware facet |
| `BalancerV3ConstantProductPoolDFPkg_deploy.t.sol` | End-to-end pool deployment |

### 4.4 Recommended Fuzz/Invariant Tests

**Priority: CRITICAL**

| Invariant | Description |
|-----------|-------------|
| `invariant_swapPreservesOrIncreasesInvariant` | Swaps never decrease pool value |
| `invariant_linearScalingOfInvariant` | Invariant scales linearly with balances |
| `invariant_roundingNeverFavorsUser` | Pool-favorable rounding throughout |
| `invariant_rateProviderNeverDecreases` | ERC4626 rate is monotonically increasing |

### 4.5 Recommended Fork Tests

**Priority: MEDIUM**

| Test Suite | Network | Description |
|------------|---------|-------------|
| `BalancerV3Integration_Mainnet.t.sol` | Ethereum | Test against live Balancer V3 vault |
| `BalancerV3Integration_Arbitrum.t.sol` | Arbitrum | Test against live deployment |

### 4.6 Known Issues to Test

1. **Integer division in `onSwap()`** - May round in user's favor for small amounts
2. **`computeBalance()` rounding** - Should use `divUp()` but doesn't
3. **`TokenConfigUtils._sort()` correctness** - Only swaps tokens, not full TokenConfig struct
4. **ActionId disambiguation** - Verify unique per-contract

---

## 5. Architecture Assessment

### 5.1 Strengths

1. **Clean Facet-Target-Repo pattern** - Follows Crane conventions
2. **Proper vault delegation** - All BPT operations correctly route through vault
3. **Comprehensive 80/20 math** - Well-tested math library with edge case handling
4. **Guard modifiers** - Proper access control for vault-only functions
5. **Transient storage sender tracking** - Correct implementation

### 5.2 Concerns

1. **No test coverage** - Critical gap
2. **Rounding in swap calculations** - May leak value
3. **Incomplete TokenConfig sorting** - Bug in `_sort()` function
4. **No weighted pool facet** - Math exists but no deployable implementation
5. **Hardcoded pool name/symbol** - `BalancerV3PoolTarget.sol:79,86` returns fixed strings

### 5.3 TokenConfigUtils Bug

**Location:** `TokenConfigUtils.sol:22-26`

```solidity
if (next < actual) {
    array[j].token = next;
    array[j + 1].token = actual;
    swapped = true;
}
```

This only swaps the `token` field, not the entire `TokenConfig` struct. The `rateProvider`, `tokenType`, and `paysYieldFees` fields are NOT swapped, causing data corruption when sorting is needed.

---

## 6. Files Reviewed

### Core Implementation (35 files)
- `vault/BalancerV3VaultAwareRepo.sol`
- `vault/BalancerV3VaultAwareTarget.sol`
- `vault/BalancerV3VaultAwareFacet.sol`
- `vault/BalancerV3PoolRepo.sol`
- `vault/BalancerV3PoolTarget.sol`
- `vault/BalancerV3PoolFacet.sol`
- `vault/BalancerV3AuthenticationRepo.sol`
- `vault/BalancerV3AuthenticationService.sol`
- `vault/BalancerV3AuthenticationModifiers.sol`
- `vault/BalancerV3AuthenticationTarget.sol`
- `vault/BalancerV3AuthenticationFacet.sol`
- `vault/BalancerV3VaultGuardModifiers.sol`
- `vault/VaultGuardModifiers.sol`
- `vault/SenderGuardCommon.sol`
- `vault/SenderGuardTarget.sol`
- `vault/SenderGuardFacet.sol`
- `vault/SenderGuardModifiers.sol`
- `vault/BetterBalancerV3PoolTokenFacet.sol`
- `pool-constProd/BalancerV3ConstantProductPoolTarget.sol`
- `pool-constProd/BalancerV3ConstantProductPoolFacet.sol`
- `pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol`
- `pool-utils/BalancerV3BasePoolFactory.sol`
- `pool-utils/BalancerV3BasePoolFactoryRepo.sol`
- `pool-utils/FactoryWidePauseWindowTarget.sol`
- `rateProviders/ERC4626RateProviderRepo.sol`
- `rateProviders/ERC4626RateProviderTarget.sol`
- `rateProviders/ERC4626RateProviderFacet.sol`
- `rateProviders/ERC4626RateProviderFacetDFPkg.sol`
- `rateProviders/ERC4626RateProviderFactoryService.sol`
- `utils/BalancerV38020WeightedPoolMath.sol`
- `utils/TokenConfigUtils.sol`

### Test Infrastructure (4 files)
- `test/bases/TestBase_BalancerV3.sol`
- `test/bases/TestBase_BalancerV3Vault.sol`
- `test/bases/TestBase_BalancerV3_WeightedPool.sol`
- `test/bases/TestBase_BalancerV3_8020WeightedPool.sol`

### Interfaces (13 files in `contracts/interfaces/protocols/dexes/balancer/v3/`)
- `IAuthentication.sol`
- `IAuthorizer.sol`
- `IBalancerPoolToken.sol`
- `IBalancerV3Pool.sol`
- `IBasePoolFactory.sol`
- `IPoolInfo.sol`
- `IRateProvider.sol`
- `IRouter.sol`
- `ISenderGuard.sol`
- `ISwapFeePercentageBounds.sol`
- `IUnbalancedLiquidityInvariantRatioBounds.sol`
- `IVault.sol` (re-export)
- `IWeightedPool.sol`
- `IWeightedPool8020Factory.sol`
- `RouterTypes.sol`
- `VaultTypes.sol`

---

## Session Log

### 2026-01-13 - Review Complete

- Completed comprehensive code review of Balancer V3 utilities
- Documented key invariants and correctness assumptions
- Documented vault singleton interaction patterns
- Documented pool type implementations and differences
- Identified critical test coverage gap (0 tests)
- Identified TokenConfigUtils._sort() bug (data corruption on sort)
- Identified rounding concerns in swap calculations
- Compiled recommended test suites (unit, spec, fuzz, fork)
- Build verification BLOCKED by recursive submodule initialization
- Build verification PASS in this worktree (`forge build`)
- Balancer V3-focused specs PASS (see task logs)

**Key Findings Summary:**
1. Architecture is sound - follows Crane Facet-Target-Repo pattern correctly
2. Vault integration is correct - all BPT operations delegate to vault singleton
3. **Test coverage exists but is incomplete** - core surfaces still need more coverage
4. **BUG FOUND: TokenConfigUtils._sort()** - corrupts struct data when sorting
5. **RISK: onSwap() rounding** - may favor users over pool in edge cases
6. **RISK: computeBalance() rounding** - raw division instead of divUp()

### 2026-01-13 - Task Launched

- Task launched via /backlog:launch
- Agent worktree created
- Ready to begin implementation
