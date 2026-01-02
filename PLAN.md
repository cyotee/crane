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

# Part 4: Test Coverage Improvement Plan (Phase 2) ✅ COMPLETE

## Status: COMPLETE

**Last Updated:** 2024-12-31
**Current Test Count:** 907 tests
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

### 2.1 BetterMath Tests ⏸️ DEFERRED

**File:** `contracts/utils/math/BetterMath.sol` (27.61%)

**Status:** Deferred - requires differential testing approach

**Rationale:** Testing math functions by reimplementing the same logic in Solidity tests is circular and provides no validation. Math functions require comparison against an external reference implementation.

**Differential Testing Options for Later:**

1. **Hardhat + TypeScript** - Use ethers.js BigNumber or bn.js with TypeScript to compute expected values, compare against Solidity results
   ```typescript
   it("sqrt matches JS implementation", async () => {
     const x = BigInt("12345678901234567890");
     const expected = sqrt(x); // JS implementation
     const actual = await betterMath.sqrt(x);
     expect(actual).to.equal(expected);
   });
   ```

2. **Foundry FFI + Python** - Call Python's math library via FFI
   ```solidity
   function testFuzz_sqrt(uint256 x) public {
       string[] memory cmd = new string[](3);
       cmd[0] = "python3";
       cmd[1] = "-c";
       cmd[2] = string.concat("import math; print(int(math.isqrt(", vm.toString(x), ")))");
       uint256 expected = vm.parseUint(string(vm.ffi(cmd)));
       assertEq(BetterMath._sqrt(x), expected);
   }
   ```

3. **Compare against trusted Solidity libraries** - Differential test against Solady, PRBMath, or OpenZeppelin implementations

4. **Property-based invariant testing** - Test mathematical properties that must hold:
   - `sqrt(x)² ≤ x < (sqrt(x)+1)²`
   - `mulDiv(a, b, c) * c ≈ a * b` (within rounding)
   - `exp2(log2(x)) ≈ x`

**Note:** Many BetterMath functions may already be tested transitively through ConstProdUtils (188 tests) which compares calculated results against actual DEX execution.

**Tests Needed (when implemented):**
- [ ] `_sqrt()` - perfect squares, non-perfect, edge cases (0, 1, max)
- [ ] `_mulDiv()` - standard cases, rounding modes, overflow protection
- [ ] `_log2()` and `_log10()` functions
- [ ] `_exp2()` function
- [ ] `_max()` and `_min()` functions
- [ ] Uint512 operations

### 2.2 BetterSafeERC20 Tests ✅ COMPLETE

**File:** `contracts/tokens/ERC20/utils/BetterSafeERC20.sol`

**Files Created:**
- `contracts/test/stubs/MockERC20Variants.sol` - 6 mock token variants (Standard, NonReturning, Reverting, FalseReturning, NoMetadata, USDTApproval)
- `contracts/test/stubs/BetterSafeERC20Harness.sol` - Test harness exposing library functions
- `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol` - 37 tests

**Tests Implemented:**
- [x] `safeTransfer()` with standard token (returns true)
- [x] `safeTransfer()` with non-returning token (USDT-like)
- [x] `safeTransfer()` with reverting token
- [x] `safeTransfer()` with false-returning token
- [x] `safeTransfer()` insufficient balance reverts
- [x] `safeTransferFrom()` with standard token
- [x] `safeTransferFrom()` with non-returning token
- [x] `safeTransferFrom()` insufficient allowance reverts
- [x] `trySafeTransfer()` returns true on success
- [x] `trySafeTransfer()` returns false on false-returning token
- [x] `trySafeTransfer()` returns false on reverting token
- [x] `trySafeTransferFrom()` returns true on success
- [x] `trySafeTransferFrom()` returns false on insufficient allowance
- [x] `safeIncreaseAllowance()` with standard token
- [x] `safeIncreaseAllowance()` with non-returning token
- [x] `safeDecreaseAllowance()` with standard token
- [x] `safeDecreaseAllowance()` with non-returning token
- [x] `forceApprove()` with standard token
- [x] `forceApprove()` with non-returning token
- [x] `forceApprove()` with USDT-approval token (overwrites existing)
- [x] `safeApprove()` with standard token
- [x] `safeApprove()` with non-returning token
- [x] `safeApprove()` with false-returning token reverts
- [x] `safeName()` returns name for standard token
- [x] `safeName()` returns fallback for no-metadata token
- [x] `safeName()` returns fallback for non-contract address
- [x] `safeSymbol()` returns symbol for standard token
- [x] `safeSymbol()` returns fallback for no-metadata token
- [x] `safeSymbol()` returns fallback for non-contract address
- [x] `safeDecimals()` returns decimals for standard token (18)
- [x] `safeDecimals()` returns decimals for non-returning token (6)
- [x] `safeDecimals()` returns fallback for no-metadata token (18)
- [x] `safeDecimals()` returns fallback for non-contract address (18)
- [x] `cast()` converts IERC20 array to BetterIERC20 array
- [x] `cast()` empty array returns empty array
- [x] Fuzz: `safeTransfer()` any amount transfers or reverts
- [x] Fuzz: `safeIncreaseAllowance()` any amount increases

### 2.3 BetterBytes Tests ✅ COMPLETE

**File:** `contracts/utils/BetterBytes.sol`

**Test File:** `test/foundry/spec/utils/BetterBytes.t.sol` - 39 tests (14 existing + 25 new)

**Tests Implemented:**
- [x] `indexOf()` - find first occurrence, from position, not found, empty bytes
- [x] `lastIndexOf()` - find last occurrence, from position, not found
- [x] `slice()` - from start, from zero, from end, range, same start/end
- [x] `prependToArray()` - prepend value, empty array
- [x] `toAddress()` - roundtrip, with offset, out of bounds reverts
- [x] `toHexString()` - conversion, empty bytes, leading zeros
- [x] `toUint` variants (8, 16, 32, 64, 96, 128, 256) - roundtrip, out of bounds
- [x] `toBytes32()` - roundtrip, with offset, out of bounds
- [x] `equal()` - identical, different, different lengths, empty, long bytes
- [x] `equalStorage()` - identical, different, empty, short (<32), long (>32)
- [x] Fuzz: toHexString length, equal reflexive, slice range, roundtrips

### 2.4 BetterArrays Tests ✅ COMPLETE

**File:** `contracts/utils/collections/BetterArrays.sol`

**Test File:** `test/foundry/spec/utils/collections/BetterArrays.t.sol` - 30 tests (14 existing + 16 new)

**Tests Implemented:**
- [x] `_isValidIndex()` - valid indices, invalid reverts, zero length reverts
- [x] `_toLength()` fixed[5,10,100,1000] - expansion and revert on smaller
- [x] `_toLength()` dynamic - expansion, same length, smaller length reverts
- [x] `_sort()` - uint256, address, bytes32, with comparator, empty, single element
- [x] `_lowerBoundMemory()` / `_upperBoundMemory()` - basic, empty array, single element
- [x] `_unsafeMemoryAccess()` - address, bytes32, uint256, bytes, string
- [x] Fuzz: sort is sorted, toLength expands, unsafeMemoryAccess returns correct, lowerBound finds position

### 2.5 Creation Library Tests ✅ COMPLETE

**File:** `contracts/utils/Creation.sol`

**Test File:** `test/foundry/spec/utils/Creation.t.sol` - 19 tests

**Tests Implemented:**
- [x] `create()` - deploys contract, empty code, invalid code reverts
- [x] `_create2()` - deploys to predicted address, different salts, same salt
- [x] `_create2Address()` / `_create2AddressFromOf()` - address prediction
- [x] `create2WithArgs()` - deploys with constructor args
- [x] `_create2WithArgsAddress()` / `_create2WithArgsAddressFromOf()` - prediction with args
- [x] `create3()` - deploys to predicted address, address independent of initCode
- [x] `_create3AddressOf()` / `_create3AddressFromOf()` - CREATE3 address prediction
- [x] `create3WithArgs()` - deploys with constructor args
- [x] Duplicate deployment to same salt reverts (TargetAlreadyExists)
- [x] Fuzz: salt determines address, deployer affects address

### 2.6 EIP712Repo Tests ✅ COMPLETE

**File:** `contracts/utils/cryptography/EIP712/EIP712Repo.sol`

**Test File:** `test/foundry/spec/utils/cryptography/EIP712Repo.t.sol` - 20 tests

**Tests Implemented:**
- [x] `_initialize()` stores name and version
- [x] `_initialize()` computes domain separator
- [x] `_initialize()` handles long name (>31 bytes for ShortString)
- [x] `_initialize()` handles long version (>31 bytes for ShortString)
- [x] `_domainSeparatorV4()` returns cached value
- [x] `_domainSeparatorV4()` includes correct components (typeHash, name, version, chainId, address)
- [x] `_domainSeparatorV4()` different contracts produce different separators
- [x] `_domainSeparatorV4()` different names produce different separators
- [x] `_domainSeparatorV4()` different versions produce different separators
- [x] Chain ID change rebuilds separator
- [x] Chain ID change back uses cached value again
- [x] Multiple chain IDs produce different separators
- [x] `_hashTypedDataV4()` produces consistent hash
- [x] `_hashTypedDataV4()` different struct hashes produce different results
- [x] `_hashTypedDataV4()` matches manual EIP-712 computation
- [x] `_hashTypedDataV4()` can be used for signature verification (ECDSA recovery)
- [x] Chain ID change invalidates signature (replay protection)
- [x] Fuzz: chain ID affects separator
- [x] Fuzz: struct hash affects result
- [x] Fuzz: any name/version initializes correctly

### 2.7 ERC20 Permit Integration Tests ✅ COMPLETE

**File:** `test/foundry/spec/tokens/ERC20/ERC20Permit_Integration.t.sol` - 19 tests

**Tests Implemented:**
- [x] Valid permit updates allowance correctly
- [x] Permit allows subsequent `transferFrom`
- [x] Expired signature reverts with `ERC2612ExpiredSignature`
- [x] Wrong signer reverts with `ERC2612InvalidSigner`
- [x] Replay attack fails (nonce incremented)
- [x] Double-use of same signature fails
- [x] `DOMAIN_SEPARATOR()` matches expected computation
- [x] `DOMAIN_SEPARATOR()` different on different chain
- [x] `nonces()` starts at 0 and increments correctly
- [x] Chain ID change invalidates previously valid signatures
- [x] Chain ID change back works with original signature
- [x] Zero value permit works
- [x] Max uint256 value permit works
- [x] Permit overwrites existing allowance
- [x] Multiple spenders work with independent nonces
- [x] Fuzz: any valid signature updates allowance
- [x] Fuzz: any spender works
- [x] Fuzz: chain ID change invalidates

### 2.8 ERC4626 Permit Integration Tests ✅ COMPLETE

**File:** `test/foundry/spec/tokens/ERC4626/ERC4626Permit_Integration.t.sol` - 11 tests

**Tests Implemented:**
- [x] Deposit with prior permit approval on asset
- [x] Mint with prior permit approval on asset
- [x] Deposit without approval reverts
- [x] Redeem without approval reverts
- [x] Permit on vault shares token enables share transfers
- [x] Permit on vault shares enables redeem
- [x] Asset permit: chain ID change invalidates
- [x] Share permit: chain ID change invalidates
- [x] Full round-trip: permit asset → deposit → permit shares → transfer → redeem
- [x] Fuzz: any deposit amount works with permit
- [x] Fuzz: any recipient works for share permit

---

## Priority 3: Protocol Integrations 🟠

### 3.1 Balancer V3 Constant Product Pool ✅ COMPLETE

**Source Files:**
- `contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol`
- `contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol`

**Test Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.t.sol` - 19 tests
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet_IFacet.t.sol` - 11 tests

**Tests Implemented (30 total):**
- [x] `computeInvariant()` - balanced pool, unbalanced pool, zero balance, rounding direction
- [x] `computeInvariant()` - single token edge case, linear scaling property
- [x] `computeBalance()` - invariant ratio tests, token index selection
- [x] `onSwap()` EXACT_IN - correct output, reverse direction, small amounts, large amounts
- [x] `onSwap()` EXACT_OUT - correct input calculation
- [x] `onSwap()` invariant preservation after swap
- [x] IFacet compliance - facetName, facetInterfaces, facetFuncs, facetMetadata
- [x] Fuzz tests for invariant calculation and swap operations

### 3.2 Balancer V3 Base Pool Factory ✅ COMPLETE

**Source Files:**
- `contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol`
- `contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol`

**Test File:**
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.t.sol` - 24 tests

**Tests Implemented (24 total):**
- [x] Storage slot hash verification
- [x] Initialization - pause window duration, pool manager, end time calculation
- [x] Overflow handling on pause window initialization
- [x] Disable/enable functionality with proper error handling
- [x] Pool registry - addPool, isPoolFromFactory, getPoolCount, getPools, getPoolsInRange
- [x] Token configs - setTokenConfigs, getTokenConfigs, tokenType preservation
- [x] Hooks contract - setHooksContract, getHooksContract
- [x] Pause window end time - before/after expiry behavior
- [x] Fuzz tests for pool addresses, durations, and manager addresses

### 3.3 Aware Repos (Dependency Injection) ✅ COMPLETE

**Source Files:**
- `contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol`
- `contracts/protocols/dexes/uniswap/v2/aware/UniswapV2RouterAwareRepo.sol`
- `contracts/protocols/dexes/aerodrome/v1/aware/AerodromeRouterAwareRepo.sol`
- `contracts/factories/create3/Create3FactoryAwareRepo.sol`
- `contracts/factories/diamondPkg/DiamondPackageCallBackFactoryAwareRepo.sol`

**Test Files (one per Aware Repo - 7 tests each, 35 total):**
- `test/foundry/spec/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.t.sol` - 7 tests
- `test/foundry/spec/protocols/dexes/uniswap/v2/aware/UniswapV2RouterAwareRepo.t.sol` - 7 tests
- `test/foundry/spec/protocols/dexes/aerodrome/v1/aware/AerodromeRouterAwareRepo.t.sol` - 7 tests
- `test/foundry/spec/factories/create3/Create3FactoryAwareRepo.t.sol` - 7 tests
- `test/foundry/spec/factories/diamondPkg/DiamondPackageCallBackFactoryAwareRepo.t.sol` - 7 tests

**Tests Implemented (per Aware Repo - 7 tests each):**
- [x] `test_storageSlot_isCorrectHash()` - verifies STORAGE_SLOT matches expected keccak256 hash
- [x] `test_initialize_storesReference()` - basic initialization stores reference correctly
- [x] `test_initialize_canOverwrite()` - re-initialization overwrites existing value
- [x] `test_initializeWithSlot_storesAtCustomSlot()` - custom slot initialization works
- [x] `test_slotIsolation_differentSlotsAreIndependent()` - different slots are isolated
- [x] `test_get*_returnsZeroBeforeInit()` - returns zero address before initialization
- [x] `testFuzz_initialize_anyAddress()` - fuzz test for any non-zero address

---

## Priority 4: Improve Branch Coverage ✅ COMPLETE

### 4.1 ConstProdUtils Edge Case Tests ✅ COMPLETE

**File:** `contracts/utils/math/ConstProdUtils.sol`

**Test File:** `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_EdgeCases.t.sol` - 39 tests

**Tests Implemented:**
- [x] `purchaseQuote()` - zero fee, small amounts, ceiling division, reverts on invalid inputs
- [x] `saleQuote()` - zero fee, max fee, zero amount in
- [x] `depositQuote()` - first deposit (minimum liquidity), normal deposits (various ratios)
- [x] `quoteWithdrawWithFee()` - zero owned, zero supply, zero reserves, full withdrawal
- [x] `quoteSwapDepositWithFee()` - protocol fee enabled/disabled, kLast zero, fee percent boundaries
- [x] `sortReserves()` - known token ordering with and without fees
- [x] `swapDepositSaleAmt()` - normal case, zero fee, low denominator, fallback branch, capped at input
- [x] Fuzz tests for bounds validation

### 4.2 ERC721Facet Coverage ✅ ALREADY COVERED

**Existing Test Files:**
- `test/foundry/spec/tokens/ERC721/ERC721Facet_IFacet.t.sol` - 3 IFacet compliance tests
- `test/foundry/spec/tokens/ERC721/ERC721TargetStub.t.sol` - 34 unit tests
- `test/foundry/spec/tokens/ERC721/ERC721Invariant.t.sol` - 4 invariant tests

**Total:** 41 ERC721 tests already exist

### 4.3 Create3Factory Coverage ✅ COMPLETE

**File:** `contracts/factories/create3/Create3Factory.sol`

**Test File:** `test/foundry/spec/factories/create3/Create3Factory.t.sol` - 30 tests

**Tests Implemented:**
- [x] Constructor - owner setup
- [x] `setDiamondPackageFactory()` - owner succeeds, non-owner/operator reverts
- [x] `create3()` - owner/operator deploy, non-authorized reverts, existing returns same
- [x] `deployFacet()` - deploys and registers, stores name
- [x] `deployFacetWithArgs()` - deploys with args and registers
- [x] `deployPackage()` - deploys and registers
- [x] `deployPackageWithArgs()` - deploys with args and registers
- [x] `registerFacet()` - manual registration, indexes by interface, indexes by function
- [x] `registerPackage()` - manual registration, indexes by facet
- [x] Query functions - allFacets, allPackages, facetsOfName, packagesByName, packagesByInterface
- [x] Access control - non-authorized reverts for all write operations
- [x] Fuzz tests for salt uniqueness and name registration

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

| Metric | Start | Final | Target |
|--------|-------|-------|--------|
| Test Count | 838 | 905 | 700+ ✅ |
| Tests Added | - | 67 | - |

**Tests Added in This Phase:**
- ConstProdUtils Edge Cases: 39 tests
- Create3Factory: 30 tests

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

# Part 5: Next Steps - Coverage Improvement Opportunities

## Status: PLANNING

**Last Updated:** 2024-12-31
**Current Test Count:** 905 tests (2 flaky tests excluded)
**Current Coverage:** 39.85% lines, 12.57% branches, 40.28% functions

---

## Coverage Summary

| Metric | Current | Target |
|--------|---------|--------|
| Lines | 39.85% (5,376/13,492) | 50%+ |
| Statements | 38.56% (5,513/14,296) | 50%+ |
| Branches | 12.57% (348/2,768) | 30%+ |
| Functions | 40.28% (1,249/3,101) | 50%+ |

---

## Option 1: Improve Branch Coverage (HIGH IMPACT)

**Priority:** HIGH
**Current:** 12.57% → **Target:** 30%+

Branch coverage is notably low, meaning many conditional paths aren't exercised. This is the highest-impact improvement for code quality.

### Focus Areas

| File | Current Branch | Priority |
|------|----------------|----------|
| `ConstProdUtils.sol` | Low | HIGH - AMM math edge cases |
| `ERC2535Repo.sol` | Low | HIGH - Diamond cut error paths |
| `CamelotV2Service.sol` | Medium | MEDIUM - Error conditions |
| `UniswapV2Service.sol` | Medium | MEDIUM - Error conditions |
| `AerodromService.sol` | Medium | MEDIUM - Error conditions |

### Approach
1. Identify uncovered branches with `forge coverage --report lcov`
2. Add targeted tests for error paths and edge conditions
3. Focus on revert conditions and boundary cases

---

## Option 2: Cover Untested Production Code (MEDIUM IMPACT)

**Priority:** MEDIUM

### Files Needing Coverage

| File | Lines | Functions | Notes |
|------|-------|-----------|-------|
| `BetterVM.sol` | 52.83% | 61.54% | Test utility - partial coverage acceptable |
| `UniswapV2Utils.sol` | 79.31% | 25.00% | Only 2/8 functions tested |
| `AerodromeUtils.sol` | ~70% | ~50% | Additional edge cases needed |
| `CamelotV2Utils.sol` | ~70% | ~50% | Additional edge cases needed |

### Files to Consider Removing (0% coverage)

| File | Coverage | Recommendation |
|------|----------|----------------|
| `betterconsole.sol` | 4.13% | Consider removing if unused |
| `terminal.sol` | 0.00% | Consider removing if unused |
| `ArbOwnerPublicStub.sol` | 0.00% | Stub - coverage not needed |
| `script/Counter.s.sol` | 0.00% | Example script - remove or test |

---

## Option 3: BetterMath Differential Testing (DEFERRED)

**Priority:** DEFERRED
**Current Coverage:** 27.61%

### Challenge
Testing math functions by reimplementing logic in Solidity is circular. Requires external reference implementation.

### Approaches (for future implementation)

1. **Hardhat + TypeScript**
   ```typescript
   it("sqrt matches JS implementation", async () => {
     const x = BigInt("12345678901234567890");
     const expected = sqrt(x); // JS implementation
     const actual = await betterMath.sqrt(x);
     expect(actual).to.equal(expected);
   });
   ```

2. **Foundry FFI + Python**
   ```solidity
   function testFuzz_sqrt(uint256 x) public {
       string[] memory cmd = new string[](3);
       cmd[0] = "python3";
       cmd[1] = "-c";
       cmd[2] = string.concat("import math; print(int(math.isqrt(", vm.toString(x), ")))");
       uint256 expected = vm.parseUint(string(vm.ffi(cmd)));
       assertEq(BetterMath._sqrt(x), expected);
   }
   ```

3. **Compare against trusted libraries** (Solady, PRBMath, OpenZeppelin)

4. **Property-based invariant testing**
   - `sqrt(x)² ≤ x < (sqrt(x)+1)²`
   - `mulDiv(a, b, c) * c ≈ a * b`

---

## Option 4: Move to New Features

**Priority:** DEPENDS ON PROJECT NEEDS

If current coverage is acceptable, shift focus to:
- New protocol integrations
- Feature development for IndexedEx parent project
- Balancer V3 integration completion
- Additional DEX protocol support

---

## Recommended Priority Order

1. **Option 1: Branch Coverage** - Highest impact on code quality
2. **Option 2: Production Code** - Fill remaining gaps
3. **Option 4: New Features** - If coverage targets met
4. **Option 3: BetterMath** - Deferred, requires infrastructure

---

# Verification Commands

```bash
# Run all Crane tests
forge test

# Expected: 905 tests passed

# Run coverage report
forge coverage

# Run ERC8109 behavior tests
forge test --match-path "test/foundry/spec/introspection/ERC8109/*"

# Expected: 13 tests passed

# Run math utils integration tests
forge test --match-path "test/foundry/spec/utils/math/constProdUtils/*"

# Expected: 227 tests passed (188 + 39 edge cases)

# Run Create3Factory tests
forge test --match-path "test/foundry/spec/factories/create3/Create3Factory.t.sol"

# Expected: 30 tests passed

# Run protocol service tests
forge test --match-path "test/foundry/spec/protocols/dexes/*/services/*"
```
