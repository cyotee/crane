# Crane Framework Development Plan

## Document Purpose

This plan tracks development tasks across the Crane framework. It is version controlled to enable tracking across sessions and repository clones.

---

# Part 1: Test Coverage Improvement Plan ✅ COMPLETE

## Status: ALL PHASES COMPLETE

**Last Updated:** 2024-12-31
**Starting Test Count:** 386 tests
**Final Test Count:** 532 tests (+ 188 existing integration tests)
**Tests Added:** 146 new tests

---

## Overview

Improvements to Crane framework test coverage across three phases:
1. Protocol Service Library Tests
2. Token Implementation Tests
3. Protocol Math Utils Integration Tests

---

## Phase 1: Protocol Service Library Tests ✅ COMPLETE

### 1.1 CamelotV2Service Tests ✅

**File:** `test/foundry/spec/protocols/dexes/camelot/v2/services/CamelotV2Service.t.sol`
**Tests:** 20

- Basic swap functionality
- Reverse direction swaps
- Price impact handling
- Zap-in (balanced/unbalanced/single-sided)
- Standard and unbalanced deposits
- Full and partial withdrawals
- Zap-out operations
- Asset balancing
- Reserve ordering
- Integration round-trip tests

### 1.2 UniswapV2Service Tests ✅

**File:** `test/foundry/spec/protocols/dexes/uniswap/v2/services/UniswapV2Service.t.sol`
**Tests:** 20

- Same coverage as CamelotV2Service
- Exact input/output swap variants

### 1.3 AerodromeService Tests ✅

**File:** `test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromService.t.sol`
**Tests:** 12

**Bugs Fixed:**
1. `Route.to` was set to pool address instead of output token
2. `addLiquidity` was called with pool address instead of opposing token

**Changes to `AerodromService.sol`:**
- Added `IERC20 tokenOut` to `SwapParams` struct
- Fixed `Route.to` to use `params.tokenOut`
- Fixed `addLiquidity` to use `params.opposingToken`

---

## Phase 2: Token Implementation Tests ✅ COMPLETE

### 2.1 ERC20 Edge Case Tests ✅

**File:** `test/foundry/spec/tokens/ERC20/ERC20Target_EdgeCases.t.sol`
**Tests:** 24

### 2.2 ERC4626 Invariant Tests ✅

**Files Created:**
- `contracts/tokens/ERC4626/ERC4626TargetStubHandler.sol`
- `contracts/tokens/ERC4626/TestBase_ERC4626.sol`
- `test/foundry/spec/tokens/ERC4626/ERC4626Invariant.t.sol`

**Tests:** 8 invariants (50 runs × 250 calls each)

### 2.3 ERC4626 Rounding Edge Cases ✅

**File:** `test/foundry/spec/tokens/ERC4626/ERC4626_Rounding.t.sol`
**Tests:** 21

### 2.4 ERC721 Tests ✅

**Files Created:**
- `contracts/tokens/ERC721/ERC721Target.sol`
- `contracts/tokens/ERC721/ERC721TargetStub.sol`
- `contracts/tokens/ERC721/ERC721TargetStubHandler.sol`
- `contracts/tokens/ERC721/TestBase_ERC721.sol`
- `contracts/tokens/ERC721/Behavior_IERC721.sol`
- `test/foundry/spec/tokens/ERC721/ERC721Invariant.t.sol`
- `test/foundry/spec/tokens/ERC721/ERC721TargetStub.t.sol`
- `test/foundry/spec/tokens/ERC721/ERC721Facet_IFacet.t.sol`

**Tests:** 41

---

## Phase 3: Protocol Math Utils Integration Tests ✅ COMPLETE

**Note:** These tests already existed in `test/foundry/spec/utils/math/constProdUtils/`

**Total Tests:** 188 tests across 27 test suites

### 3.1 CamelotV2Utils Integration ✅ (55 tests)
### 3.2 AerodromeUtils Integration ✅ (46 tests)
### 3.3 UniswapV2Utils Integration ✅ (87 tests)

---

## Progress Summary

| Phase | Item | Status | Tests |
|-------|------|--------|-------|
| 1.1 | CamelotV2Service | ✅ Complete | 20 |
| 1.2 | UniswapV2Service | ✅ Complete | 20 |
| 1.3 | AerodromeService | ✅ Complete | 12 |
| 2.1 | ERC20 Edge Cases | ✅ Complete | 24 |
| 2.2 | ERC4626 Invariants | ✅ Complete | 8 |
| 2.3 | ERC4626 Rounding | ✅ Complete | 21 |
| 2.4 | ERC721 Tests | ✅ Complete | 41 |
| 3.1 | CamelotV2Utils Integration | ✅ Complete | 55 |
| 3.2 | AerodromeUtils Integration | ✅ Complete | 46 |
| 3.3 | UniswapV2Utils Integration | ✅ Complete | 87 |

---

# Part 2: Aerodrome Standard Exchange Test Plan 🔄 IN PROGRESS

## Overview

Test implementation strategy for `AerodromeStandardExchangeDFPkg` vaults in IndexedEx. Tests validate all exchange routes, ensuring preview functions match execution, token balances change correctly, and edge cases are handled properly.

---

## Architecture

### Test Base Inheritance

```
CraneTest (lib/daosys/lib/crane)
    └── IndexedexTest
        └── TestBase_VaultComponents
            └── TestBase_AerodromeStandardExchange
                ├── TestBase_Permit2 (mixin)
                ├── TestBase_Aerodrome (mixin, includes TestBase_Aerodrome_Pools)
                └── TestBase_AerodromeStandardExchange_MultiPool (NEW)
                    └── Individual test contracts
```

---

## Initialization Flow

### Stage 1: CraneTest.setUp() - Core Factory Infrastructure

**Source:** `lib/daosys/lib/crane/contracts/test/CraneTest.sol`

```solidity
ICreate3Factory create3Factory;
IDiamondPackageCallBackFactory diamondPackageFactory;
IDiamondFactory diamondFactory;
```

### Stage 2: IndexedexTest.setUp() - Manager & Fee Collector

**Source:** `contracts/test/IndexedexTest.sol`

**Factory Service Libraries:**
- `AccessFacetFactoryService`
- `IntrospectionFacetFactoryService`
- `FeeCollectorFactoryService`
- `IndexedexManagerFactoryService`

**Key Variables:**
- `IIndexedexManagerProxy indexedexManager`
- `IFeeCollectorProxy feeCollector`
- `address owner`

### Stage 3: TestBase_VaultComponents.setUp() - Core Vault Facets

**Source:** `contracts/vaults/TestBase_VaultComponents.sol`

**Key Variables:**
- `IFacet erc20Facet`
- `IFacet erc2612Facet`
- `IFacet erc5267Facet`
- `IFacet erc4626Facet`
- `IFacet erc4626BasicVaultFacet`
- `IFacet erc4626StandardVaultFacet`

### Stage 4: TestBase_Permit2.setUp() - Permit2 Infrastructure

**Source:** `lib/daosys/lib/crane/contracts/protocols/utils/permit2/test/bases/TestBase_Permit2.sol`

### Stage 5: TestBase_Aerodrome.setUp() - Aerodrome Protocol

**Source:** `lib/daosys/lib/crane/contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome.sol`

**Key Variables:**
- `IRouter aerodromeRouter`
- `PoolFactory aerodromePoolFactory`
- `FactoryRegistry aerodromePoolFactoryRegistry`

### Stage 6: TestBase_Aerodrome_Pools - Test Tokens & Pools

**Source:** `lib/daosys/lib/crane/contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol`

### Stage 7: TestBase_AerodromeStandardExchange.setUp() - DFPkg & Facets

**Source:** `contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_AerodromeStandardExchange.sol`

**Key Variables:**
- `IFacet aerodromeStandardExchangeInFacet`
- `IFacet aerodromeStandardExchangeOutFacet`
- `IAerodromeStandardExchangeDFPkg aerodromeStandardExchangeDFPkg`

### Stage 8: TestBase_AerodromeStandardExchange_MultiPool.setUp() - NEW (3 Vaults)

```solidity
IStandardExchangeProxy balancedVault;
IStandardExchangeProxy unbalancedVault;
IStandardExchangeProxy extremeVault;
```

---

## Multi-Pool Configuration

| Configuration | Ratio | Token A Amount | Token B Amount | Purpose |
|---------------|-------|----------------|----------------|---------|
| Balanced | 1:1 | 10,000e18 | 10,000e18 | Normal operation |
| Unbalanced | 10:1 | 10,000e18 | 1,000e18 | Asymmetric liquidity |
| Extreme | 100:1 | 10,000e18 | 100e18 | Edge case pricing |

---

## Routes to Test

### InTarget Routes (7 total)

| Route | tokenIn | tokenOut | Description |
|-------|---------|----------|-------------|
| 1 | token0/token1 | token1/token0 | Pass-through Swap |
| 2 | token0/token1 | LP token | Pass-through ZapIn |
| 3 | LP token | token0/token1 | Pass-through ZapOut |
| 4 | LP token | vault shares | Underlying Pool Vault Deposit |
| 5 | vault shares | LP token | Underlying Pool Vault Withdrawal |
| 6 | token0/token1 | vault shares | ZapIn Vault Deposit |
| 7 | vault shares | token0/token1 | ZapOut Vault Withdrawal |

---

## Test File Structure

```
contracts/protocols/dexes/aerodrome/v1/test/
├── bases/
│   ├── TestBase_AerodromeStandardExchange.sol
│   └── TestBase_AerodromeStandardExchange_MultiPool.sol  # NEW
└── spec/
    ├── AerodromeStandardExchangeIn_Swap.t.sol           # Route 1
    ├── AerodromeStandardExchangeIn_ZapIn.t.sol          # Route 2
    ├── AerodromeStandardExchangeIn_ZapOut.t.sol         # Route 3
    ├── AerodromeStandardExchangeIn_VaultDeposit.t.sol   # Route 4
    ├── AerodromeStandardExchangeIn_VaultWithdraw.t.sol  # Route 5
    ├── AerodromeStandardExchangeIn_ZapInDeposit.t.sol   # Route 6
    ├── AerodromeStandardExchangeIn_ZapOutWithdraw.t.sol # Route 7
    ├── AerodromeStandardExchangeIn_Reverts.t.sol        # Error cases
    ├── AerodromeStandardExchangeIn_Fuzz.t.sol           # Fuzzing
    └── AerodromeStandardExchangeDFPkg_IFacet.t.sol      # Interface compliance
```

---

## Test Categories per Route

### 1. Preview vs Math Validation
Verify `previewExchangeIn` matches expected mathematical calculation.

### 2. Execution vs Preview Validation
Verify `exchangeIn` returns the exact amount previewed.

### 3. Balance Change Validation
Verify token balances change by expected amounts.

### 4. Slippage Protection
Verify minAmountOut enforcement.

### 5. Deadline Enforcement
Verify expired deadline reverts.

### 6. Direction Tests (A→B and B→A)
Test both swap directions where applicable.

### 7. Pool Configuration Tests
Repeat for all three pool configurations.

---

## Fuzzing Strategy

```solidity
uint256 constant MIN_AMOUNT = 1e12;      // Avoid dust rounding to zero
uint256 constant MAX_SWAP_RATIO = 10;    // Max 10% of reserve per swap
```

| Route | Fuzz Parameters | Constraints |
|-------|-----------------|-------------|
| 1 (Swap) | amountIn | 1e12 to 10% of reserve |
| 2 (ZapIn) | amountIn | 1e12 to 10% of reserve |
| 3 (ZapOut) | lpAmount | 1e12 to 10% of LP supply |
| 4 (VaultDeposit) | lpAmount | 1e12 to 10% of LP supply |
| 5 (VaultWithdraw) | shares | 1e12 to 10% of share supply |
| 6 (ZapInDeposit) | amountIn | 1e12 to 10% of reserve |
| 7 (ZapOutWithdraw) | shares | 1e12 to 10% of share supply |

---

## Implementation Order

### Phase 1: Test Infrastructure
- [ ] Create `TestBase_AerodromeStandardExchange_MultiPool.sol`
- [ ] Add vault deployment for each pool configuration
- [ ] Add helper functions for common operations

### Phase 2: Core Route Tests (InTarget)
- [ ] Route 1: Pass-through Swap
- [ ] Route 4: Vault Deposit (simplest vault interaction)
- [ ] Route 5: Vault Withdrawal
- [ ] Route 2: ZapIn (adds swap complexity)
- [ ] Route 3: ZapOut
- [ ] Route 6: ZapIn + Deposit (compound operation)
- [ ] Route 7: ZapOut + Withdrawal (compound operation)

### Phase 3: Error & Edge Cases
- [ ] Invalid route reverts
- [ ] Slippage protection
- [ ] Deadline enforcement
- [ ] Zero amount handling

### Phase 4: Fuzzing
- [ ] Add fuzz tests for each route
- [ ] Validate bounds are appropriate

### Phase 5: Interface Compliance
- [ ] IFacet tests for InFacet
- [ ] IFacet tests for OutFacet
- [ ] IDiamondLoupe tests for DFPkg

---

## Test Naming Convention

```
test_<Route>_<TestType>_<PoolConfig>[_<Direction>]()

Examples:
test_Route1Swap_previewVsMath_balanced()
test_Route1Swap_execVsPreview_unbalanced_AtoB()
test_Route6ZapInDeposit_balanceChanges_extreme()
testFuzz_Route1Swap_balanced(uint256 amountIn)
```

---

## Success Criteria

- All 7 InTarget routes pass preview-vs-execution validation
- All routes pass across all 3 pool configurations
- Fuzz tests run with 1000+ iterations without failure
- Edge cases (zero amounts, expired deadlines, invalid routes) revert correctly
- Fee collection verified for vault routes
- IFacet compliance tests pass

---

---

# Part 3: ERC8109 Introspection Facet ✅ COMPLETE

## Status: COMPLETE

**Last Updated:** 2024-12-31

## Overview

Add ERC8109 Introspection as a default facet for all Diamond proxies, alongside ERC165 and ERC2535 Diamond Loupe.

## Changes Made

### New Files Created

1. **`contracts/introspection/ERC8109/ERC8109IntrospectionFacet.sol`**
   - Implements `IFacet` interface
   - Inherits from `ERC8109IntrospectionTarget`
   - Exposes `facetAddress()` and `functionFacetPairs()` functions

### Files Modified

1. **`contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol`**
   - Added `IERC8109Introspection` import
   - Added `erc8109IntrospectionFacet` to `InitArgs` struct
   - Added `ERC8109_INTROSPECTION_FACET` immutable variable
   - Updated `facetInterfaces()` to return 3 interfaces (added IERC8109Introspection)
   - Updated `facetCuts()` to return 4 cuts (added ERC8109 facet)
   - Added override for `facetAddress()` function that is declared by both ERC2535 and ERC8109

2. **`contracts/InitDevService.sol`**
   - Added deployment of `ERC8109IntrospectionFacet`
   - Updated `InitArgs` to include new facet

## Result

All Diamond proxies now include by default:
- ERC165 Facet (interface detection)
- ERC2535 Diamond Loupe Facet (facet introspection)
- ERC8109 Introspection Facet (function-to-facet mapping)

---

# Part 4: Stack Too Deep Fixes 🔄 IN PROGRESS

## Status: IN PROGRESS

**Last Updated:** 2024-12-31

## Overview

After disabling `viaIR` compilation (per project standards), several test files have "stack too deep" compiler errors. These are being fixed by refactoring functions to use structs for bundling local variables.

## Approach

Use memory structs to bundle related local variables, reducing stack depth without enabling viaIR compilation.

## Files Fixed

| File | Status |
|------|--------|
| `ConstProdUtils_purchaseQuote_Aerodrome.t.sol` | ✅ Fixed |
| `ConstProdUtils_purchaseQuote_Camelot.t.sol` | ✅ Fixed |
| `ConstProdUtils_purchaseQuote_Uniswap.t.sol` | ✅ Fixed |
| `ConstProdUtils_quoteSwapDepositWithFee_Aerodrome.t.sol` | ✅ Fixed |
| `ConstProdUtils_quoteSwapDepositWithFee_Camelot.t.sol` | ✅ Fixed |
| `ConstProdUtils_quoteWithdrawSwapWithFee_Aerodrome.t.sol` | ✅ Fixed |

## Files Remaining

Run `forge build` to identify any remaining stack too deep errors.

## Pattern Used

```solidity
// Before (stack too deep)
function _testFunction(...) internal {
    uint256 reserveA = ...;
    uint256 reserveB = ...;
    uint256 desiredOutput = ...;
    // ... many more local variables
}

// After (fixed with struct)
struct TestData {
    uint256 reserveA;
    uint256 reserveB;
    uint256 desiredOutput;
    // ... bundle related variables
}

function _testFunction(...) internal {
    TestData memory data;
    {
        // Initialize in a scoped block to limit stack usage
        data.reserveA = ...;
        data.reserveB = ...;
    }
    // Use data.* throughout
}
```

---

# Verification Commands

```bash
# Run all Crane tests
forge test

# Expected: 532 tests passed

# Run math utils integration tests
forge test --match-path "test/foundry/spec/utils/math/constProdUtils/*"

# Expected: 188 tests passed

# Run protocol service tests
forge test --match-path "test/foundry/spec/protocols/dexes/*/services/*"
```
