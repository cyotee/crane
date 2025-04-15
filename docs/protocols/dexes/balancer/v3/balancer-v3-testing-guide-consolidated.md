# Balancer V3 Pool Testing Guide (Consolidated)

## Table of Contents
1. [Introduction](#introduction)
2. [Test Suite Structure & Environment Setup](#test-suite-structure--environment-setup)
3. [Pool-Type-Specific Setup & Considerations](#pool-type-specific-setup--considerations)
4. [Common Test Scenarios & Patterns](#common-test-scenarios--patterns)
5. [Best Practices & Common Pitfalls](#best-practices--common-pitfalls)
6. [References & Further Reading](#references--further-reading)

---

## Introduction

This guide consolidates all best practices, setup, and patterns for testing Balancer V3 pools in the Crane framework. It covers suite structure, pool-type-specific requirements, reusable test patterns, and common pitfalls. Use this as your primary reference for writing and maintaining robust pool tests.

---

## Test Suite Structure & Environment Setup

### Test Hierarchy

```text
BaseTest (from v3-solidity-utils)
    └── BaseVaultTest (from v3-vault)
        └── BasePoolTest
            └── Specific Pool Tests (WeightedPoolTest, ConstantProductPoolTest, StablePoolTest, etc.)
```

- **BaseTest**: Core Foundry utilities and setup
- **BaseVaultTest**: Vault infrastructure, token management, balance helpers
- **BasePoolTest**: Pool-specific operations, common pool logic
- **Pool Test Contracts**: Implement pool-type-specific tests

### Environment Setup

- Deploy Vault, Router, Authorizer, and supporting contracts
- Use helper functions for token setup, approvals, and balance checks
- Standard test constants:

  ```solidity
  uint256 internal constant DEFAULT_SWAP_FEE = 1e15; // 0.1%
  uint256 internal constant DELTA = 1e9; // For approximate equality
  ```

- Use `getBalances()` and `assertApproxEqAbs()` for balance verification

---

## Pool-Type-Specific Setup & Considerations

### Weighted Pools

- Up to 8 tokens, fixed weights (must sum to 1)
- Minimum weight: 1%
- Example setup:

  ```solidity
  contract WeightedPoolTest is BasePoolTest {
      uint256[] internal weights;
      function setUp() public override {
          weights = [uint256(50e16), uint256(50e16)];
          super.setUp();
      }
  }
  ```

- Test weight validation and ratios

### Constant Product Pools

- Two tokens, 50/50 weights, Uniswap V2 math
- Example setup:

  ```solidity
  contract ConstantProductPoolTest is BasePoolTest {
      function setUp() public override {
          super.setUp();
          poolMinSwapFeePercentage = 1e12;
          poolMaxSwapFeePercentage = 0.10e18;
      }
  }
  ```

- Test price impact and invariant maintenance

### Stable Pools

- For near-parity tokens, supports rate providers
- Example setup:

  ```solidity
  contract StablePoolTest is BasePoolTest {
      IRateProvider[] internal rateProviders;
      function setUp() public override {
          rateProviders = [IRateProvider(address(0)), new RateProviderMock(1e12)];
          super.setUp();
      }
  }
  ```

- Test rate provider integration and amplification parameter

---

## Common Test Scenarios & Patterns

### Pool Creation

```solidity
function testPoolCreation() public {
    assertEq(pool.getVault(), address(vault));
    assertEq(pool.getSwapFeePercentage(), DEFAULT_SWAP_FEE);
}
```

### Liquidity Addition

```solidity
function testAddLiquidity() public {
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 1e18;
    amounts[1] = 1e18;
    vm.startPrank(lp);
    uint256 bptOut = router.addLiquidity(pool, amounts, 0, false, "");
    vm.stopPrank();
    assertGt(bptOut, 0);
}
```

### Swaps

```solidity
function testExactInputSwap() public {
    vm.startPrank(trader);
    uint256 amountOut = router.swap(pool, SwapKind.EXACT_IN, tokens[0], tokens[1], 1e18, 0, "");
    vm.stopPrank();
    assertGt(amountOut, 0);
}
```

### Invariant Maintenance

```solidity
function testInvariant() public {
    uint256 k = pool.getLastInvariant();
    router.swap(...);
    uint256 newK = pool.getLastInvariant();
    assertGe(newK, k);
}
```

### Error Cases

```solidity
function testWeightValidation() public {
    uint256[] memory invalidWeights = [0.5e18, 0.5e18];
    vm.expectRevert("BAL#001");
    factory.create(..., invalidWeights, ...);
}
```

---

## Best Practices & Common Pitfalls

### Best Practices

- Always sort tokens by address before pool creation
- Use tokens with different decimals in tests
- Test at parameter boundaries (min/max swap fee, weights, amplification)
- Use helper functions for balance and invariant checks
- Test both success and failure cases, including permission and access control
- Include gas usage assertions for key operations
- Use fuzzing for edge cases

### Common Pitfalls

- Forgetting to settle all token balances after operations
- Incorrect token index/order in pool setup
- Not resetting state between tests (use `vm.startPrank()`/`vm.stopPrank()` appropriately)
- Overlooking rounding/precision issues (use `DELTA` for approximate checks)
- Not testing with both standard and non-standard tokens

---

## References & Further Reading

- [Balancer V3 Pool Lifecycle (Consolidated)](balancer-v3-pool-lifecycle-consolidated.md)
- [Balancer V3 Core Concepts](https://docs.balancer.fi/concepts/pools)
- [Pool Types Documentation](https://docs.balancer.fi/concepts/pools/pool-types)
- [Testing Best Practices](https://docs.balancer.fi/guides/testing)
- [Balancer V3 WeightedPool Tests](https://github.com/balancer/balancer-v3-monorepo/blob/master/pkg/pool-weighted/test/foundry/WeightedPool.t.sol)
- [Balancer V3 BasePoolTest](https://github.com/balancer/balancer-v3-monorepo/blob/master/pkg/vault/test/foundry/utils/BasePoolTest.sol)
- [Balancer V3 BaseVaultTest](https://github.com/balancer/balancer-v3-monorepo/blob/master/pkg/vault/test/foundry/utils/BaseVaultTest.sol) 