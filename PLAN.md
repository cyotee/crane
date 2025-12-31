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

# Part 2: ERC8109 Introspection Facet ✅ COMPLETE

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

# Part 3: Stack Too Deep Fixes ✅ COMPLETE

## Status: COMPLETE

**Last Updated:** 2024-12-31

## Overview

After disabling `viaIR` compilation (per project standards), several test files had "stack too deep" compiler errors. These were fixed by refactoring functions to use structs for bundling local variables.

## Approach

Used memory structs to bundle related local variables, reducing stack depth without enabling viaIR compilation.

## Files Fixed

| File | Status |
|------|--------|
| `ConstProdUtils_purchaseQuote_Aerodrome.t.sol` | ✅ Fixed |
| `ConstProdUtils_purchaseQuote_Camelot.t.sol` | ✅ Fixed |
| `ConstProdUtils_purchaseQuote_Uniswap.t.sol` | ✅ Fixed |
| `ConstProdUtils_quoteSwapDepositWithFee_Aerodrome.t.sol` | ✅ Fixed |
| `ConstProdUtils_quoteSwapDepositWithFee_Camelot.t.sol` | ✅ Fixed |
| `ConstProdUtils_quoteWithdrawSwapWithFee_Aerodrome.t.sol` | ✅ Fixed |

## Result

All stack too deep errors resolved. Full test suite passes (532 tests).

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

# Part 4: Test Coverage Improvement Plan (Phase 2) 🔄 IN PROGRESS

## Status: IN PROGRESS

**Last Updated:** 2024-12-31
**Current Test Count:** 597 tests
**Target Line Coverage:** 60%+

---

## Overview

Analysis of `forge coverage` output identified critical gaps in test coverage. This plan prioritizes:
1. Core framework components with 0% coverage
2. Access control and security-critical code
3. Utility libraries with low coverage
4. Protocol integrations

---

## Priority 1: Core Framework Components ✅ COMPLETE

### 1.1 ERC8109 Introspection Behavior Tests ✅ COMPLETE

**Files Created:**
- `contracts/introspection/ERC8109/Behavior_IERC8109Introspection.sol`
- `contracts/introspection/ERC8109/TestBase_IERC8109Introspection.sol`
- `test/foundry/spec/introspection/ERC8109/Behavior_IERC8109Introspection_Test.sol`

**Tests Added:** 13 new tests

**Tests Implemented:**
- [x] `facetAddress()` returns correct facet for registered functions
- [x] `facetAddress()` returns zero for unregistered functions
- [x] `functionFacetPairs()` returns all registered pairs
- [x] Behavior validation with valid implementation
- [x] Behavior validation with missing pairs (negative test)
- [x] Behavior validation with wrong facet (negative test)
- [x] Behavior validation with extra pairs (negative test)
- [x] Behavior validation with inconsistent data (negative test)
- [x] Empty implementation edge case
- [x] Single pair edge case
- [x] Full interface validation

### 1.2 Diamond Cut Tests ✅ COMPLETE

**Files Created:**
- `contracts/introspection/ERC2535/DiamondCutTargetStub.sol` - Test stub with ownership and loupe
- `contracts/test/stubs/MockFacet.sol` - Mock facets for testing (MockFacet, MockFacetV2, MockFacetC, MockInitTarget)
- `test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol` - 19 tests

**Tests Implemented:**
- [x] Add facet with new functions
- [x] Add multiple facets at once
- [x] Add facet emits DiamondCut event
- [x] Replace facet functions with new implementation
- [x] Remove facet functions
- [x] Batch cut operations (add + replace + remove)
- [x] Revert on adding duplicate selectors (FunctionAlreadyPresent)
- [x] Revert on replacing non-existent selectors (FunctionNotPresent)
- [x] Revert on replacing with same facet (FacetAlreadyPresent)
- [x] Revert on removing non-existent selectors (FunctionNotPresent)
- [x] Init function execution during cut
- [x] Init function revert propagates
- [x] No init with zero address target
- [x] Access control (onlyOwner blocks non-owner)
- [x] Owner can cut
- [x] Empty cuts succeeds
- [x] Zero address facet is skipped
- [x] Fuzz: random selector registration
- [x] Fuzz: non-owner always reverts

### 1.3 Operable Access Control Tests ✅ COMPLETE

**Files Created:**
- `contracts/access/operable/OperableTargetStub.sol` - Test stub with modifier-protected functions
- `test/foundry/spec/access/operable/Operable.t.sol` - 24 tests

**Tests Implemented:**
- [x] `setOperator()` grants operator role (with event)
- [x] `setOperator()` revokes operator role (with event)
- [x] `setOperator()` reverts when not owner
- [x] `isOperator()` returns correct status
- [x] `setOperatorFor()` grants function-specific access (with event)
- [x] `setOperatorFor()` revokes function-specific access (with event)
- [x] `setOperatorFor()` reverts when not owner
- [x] `isOperatorFor()` returns correct status
- [x] `onlyOperator` modifier allows global operators
- [x] `onlyOperator` modifier allows function operators
- [x] `onlyOperator` modifier blocks non-operators
- [x] Function operator limited to specific function only
- [x] `onlyOwnerOrOperator` allows owner
- [x] `onlyOwnerOrOperator` allows global operator
- [x] `onlyOwnerOrOperator` allows function operator
- [x] `onlyOwnerOrOperator` blocks non-operators
- [x] Multiple global operators work correctly
- [x] Multiple function operators work correctly
- [x] Owner is not automatically a global operator
- [x] Revoked operator cannot call restricted functions
- [x] Public functions allow anyone
- [x] Fuzz: any address can become operator (via owner)
- [x] Fuzz: non-owner cannot set operator
- [x] Fuzz: non-operator cannot call restricted

### 1.4 MultiStepOwnable Facet Tests ✅ COMPLETE

**Existing Tests:** `test/foundry/spec/access/ERC8023/MultiStepOwnableFacet.t.sol` (invariant tests already exist)

**New Files Created:**
- `test/foundry/spec/access/ERC8023/MultiStepOwnableFacet_IFacet.t.sol` - 3 IFacet compliance tests
- `test/foundry/spec/access/operable/OperableFacet_IFacet.t.sol` - 3 IFacet compliance tests
- `test/foundry/spec/introspection/ERC2535/DiamondCutFacet_IFacet.t.sol` - 3 IFacet compliance tests

**Tests Implemented:**
- [x] MultiStepOwnableFacet IFacet compliance (facetName, facetInterfaces, facetFuncs)
- [x] OperableFacet IFacet compliance (facetName, facetInterfaces, facetFuncs)
- [x] DiamondCutFacet IFacet compliance (facetName, facetInterfaces, facetFuncs)

**Note:** The `TestBase_IMultiStepOwnable` already provides comprehensive invariant testing for the ownership transfer functionality (initiateOwnershipTransfer, confirmOwnershipTransfer, acceptOwnershipTransfer, cancelPendingOwnershipTransfer, events, and access control)

---

## Priority 2: Utility Libraries (Low Coverage) 🟡

### 2.1 BetterMath Tests

**File:** `contracts/utils/math/BetterMath.sol` (27.61%)

**Test File:** `test/foundry/spec/utils/math/BetterMath.t.sol`

**Tests Needed:**
- [ ] `_sqrt()` for perfect squares
- [ ] `_sqrt()` for non-perfect squares
- [ ] `_sqrt()` edge cases (0, 1, max uint256)
- [ ] `_mulDiv()` standard cases
- [ ] `_mulDiv()` with rounding modes
- [ ] `_mulDiv()` overflow protection
- [ ] `_log2()` and `_log10()` functions
- [ ] `_exp2()` function
- [ ] `_max()` and `_min()` functions
- [ ] Uint512 operations

### 2.2 BetterSafeERC20 Tests

**File:** `contracts/tokens/ERC20/utils/BetterSafeERC20.sol` (31.67%)

**Test File:** `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol`

**Tests Needed:**
- [ ] `safeTransfer()` with compliant token
- [ ] `safeTransfer()` with non-returning token
- [ ] `safeTransfer()` with reverting token
- [ ] `safeTransferFrom()` variants
- [ ] `safeApprove()` variants
- [ ] `safeIncreaseAllowance()`
- [ ] `safeDecreaseAllowance()`
- [ ] `forceApprove()` with USDT-like tokens

### 2.3 BetterBytes Tests

**File:** `contracts/utils/BetterBytes.sol` (48.33%)

**Test File:** `test/foundry/spec/utils/BetterBytes.t.sol` (expand existing)

**Tests Needed:**
- [ ] `slice()` edge cases
- [ ] `concat()` operations
- [ ] Type conversions (toAddress, toUint, toBytes32)
- [ ] `equal()` for various lengths
- [ ] Out-of-bounds handling

### 2.4 BetterArrays Tests

**File:** `contracts/utils/collections/BetterArrays.sol` (43.02%)

**Test File:** `test/foundry/spec/utils/collections/BetterArrays.t.sol` (expand existing)

**Tests Needed:**
- [ ] All `toLength_fixedN` variants
- [ ] `bounds()` edge cases
- [ ] `unsafeMemoryAccess()` variants
- [ ] Dynamic array operations

### 2.5 Creation Library Tests

**File:** `contracts/utils/Creation.sol` (40%)

**Test File:** `test/foundry/spec/utils/Creation.t.sol`

**Tests Needed:**
- [ ] `create()` deployment
- [ ] `create2()` deterministic deployment
- [ ] `create3()` via proxy deployment
- [ ] Address prediction functions
- [ ] Failure cases (insufficient balance, bad code)

### 2.6 EIP712Repo Tests

**File:** `contracts/utils/cryptography/EIP712/EIP712Repo.sol` (40.54%)

**Test File:** `test/foundry/spec/utils/cryptography/EIP712Repo.t.sol`

**Tests Needed:**
- [ ] `_domainSeparatorV4()` computation
- [ ] `_hashTypedDataV4()` hash generation
- [ ] Domain parameters storage and retrieval
- [ ] Chain ID handling

---

## Priority 3: Protocol Integrations 🟠

### 3.1 Balancer V3 Constant Product Pool

**Files:**
- `contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol` (0%)
- `contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol` (0%)
- `contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol` (0%)

**Test File:** `test/foundry/spec/protocols/dexes/balancer/v3/BalancerV3ConstantProductPool.t.sol`

**Tests Needed:**
- [ ] Pool registration with Vault
- [ ] `onSwap()` callback
- [ ] `computeInvariant()` calculation
- [ ] `computeBalance()` calculation
- [ ] Fee handling
- [ ] IFacet compliance

### 3.2 Balancer V3 Base Pool Factory

**Files:**
- `contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol` (0%)
- `contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol` (0%)

**Test File:** `test/foundry/spec/protocols/dexes/balancer/v3/BalancerV3BasePoolFactory.t.sol`

**Tests Needed:**
- [ ] Pool creation
- [ ] Pool registration tracking
- [ ] Pause window handling
- [ ] Access control

### 3.3 Aware Repos (Dependency Injection)

**Files:**
- `contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol` (0%)
- `contracts/protocols/dexes/uniswap/v2/aware/UniswapV2RouterAwareRepo.sol` (0%)
- `contracts/protocols/dexes/aerodrome/v1/aware/AerodromeRouterAwareRepo.sol` (0%)
- `contracts/factories/create3/Create3FactoryAwareRepo.sol` (0%)
- `contracts/factories/diamondPkg/DiamondPackageCallBackFactoryAwareRepo.sol` (0%)

**Test Pattern:** Each Aware Repo needs:
- [ ] `_initialize()` stores reference correctly
- [ ] `_get*()` returns stored reference
- [ ] Dual function overloads work (parameterized and default)
- [ ] Storage slot isolation

---

## Priority 4: Improve Branch Coverage 🔵

### 4.1 ConstProdUtils Branch Coverage

**File:** `contracts/utils/math/ConstProdUtils.sol` (29.79% branch)

**Focus Areas:**
- [ ] Edge case branches in `_swapDepositSaleAmt()`
- [ ] Rounding direction branches
- [ ] Zero amount handling branches
- [ ] Fee calculation branches

### 4.2 ERC721Facet Coverage

**File:** `contracts/tokens/ERC721/ERC721Facet.sol` (42.11%)

**Tests Needed:**
- [ ] All ERC721 standard functions via facet
- [ ] Metadata functions
- [ ] Enumerable extension (if applicable)
- [ ] IFacet compliance

### 4.3 Create3Factory Coverage

**File:** `contracts/factories/create3/Create3Factory.sol` (55.95%)

**Tests Needed:**
- [ ] `deployFacet()` function
- [ ] `deployPackage()` function
- [ ] `deployPackageWithArgs()` function
- [ ] Registry queries
- [ ] Access control paths

---

## Implementation Order

### Phase 1: Core Framework (Weeks 1-2)
1. ERC8109 Repo tests
2. Diamond Cut tests
3. Operable tests
4. MultiStepOwnable Facet tests

### Phase 2: Utilities (Weeks 3-4)
1. BetterMath tests
2. BetterSafeERC20 tests
3. Creation tests
4. EIP712Repo tests
5. Expand BetterBytes and BetterArrays tests

### Phase 3: Protocols (Weeks 5-6)
1. Balancer V3 pool tests
2. Aware Repo tests
3. Branch coverage improvements

---

## Success Criteria

| Metric | Current | Target |
|--------|---------|--------|
| Line Coverage | 34.87% | 60%+ |
| Branch Coverage | 34.41% | 50%+ |
| Function Coverage | 11.10% | 40%+ |
| Test Count | 532 | 700+ |

---

## Test Naming Convention

```
test_<Component>_<Function>_<Scenario>()

Examples:
test_ERC8109Repo_facetAddress_returnsCorrectFacet()
test_DiamondCut_addFacet_registersSelectors()
test_Operable_onlyOperator_blocksNonOperators()
testFuzz_BetterMath_sqrt_matchesReference(uint256)
```

---

# Verification Commands

```bash
# Run all Crane tests
forge test

# Expected: 597 tests passed

# Run coverage report
forge coverage

# Run ERC8109 behavior tests
forge test --match-path "test/foundry/spec/introspection/ERC8109/*"

# Expected: 13 tests passed

# Run math utils integration tests
forge test --match-path "test/foundry/spec/utils/math/constProdUtils/*"

# Expected: 188 tests passed

# Run protocol service tests
forge test --match-path "test/foundry/spec/protocols/dexes/*/services/*"
```
