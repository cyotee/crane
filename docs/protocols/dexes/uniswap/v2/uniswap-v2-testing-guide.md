# Uniswap V2 Pool Testing Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Test Suite Structure & Environment Setup](#test-suite-structure--environment-setup)
3. [Common Test Scenarios & Patterns](#common-test-scenarios--patterns)
4. [Best Practices & Common Pitfalls](#best-practices--common-pitfalls)
5. [References & Further Reading](#references--further-reading)

---

## Introduction

This guide provides best practices and patterns for testing Uniswap V2 pools in the Crane framework. It covers suite structure, reusable test patterns, and common pitfalls. Use this as your primary reference for writing and maintaining robust Uniswap V2 pool tests.

---

## Test Suite Structure & Environment Setup

- Tests are organized by service and utility (e.g., `UniswapV2Service_swapTest.sol`, `UniswapV2Service_depositTest.sol`).
- Each test imports the relevant contracts: Factory, Pair, Router, and ERC20 tokens.
- Use helper functions for token setup, approvals, and balance checks.
- Standard test constants:

  ```solidity
  uint256 internal constant DEFAULT_SWAP_FEE = 1e15; // 0.1%
  uint256 internal constant DELTA = 1e9; // For approximate equality
  ```
  
- Use `assertApproxEqAbs()` for balance verification and `vm.expectRevert()` for error cases.

---

## Common Test Scenarios & Patterns

### Pool Creation

```solidity
function testPoolCreation() public {
    address pair = factory.createPair(tokenA, tokenB);
    assertTrue(pair != address(0));
}
```

### Liquidity Addition

```solidity
function testAddLiquidity() public {
    (,, uint liquidity) = router.addLiquidity(
        tokenA, tokenB, 1e18, 1e18, 1e17, 1e17, address(this), block.timestamp
    );
    assertGt(liquidity, 0);
}
```

### Swaps

```solidity
function testSwapExactTokensForTokens() public {
    // Approve and add liquidity first
    // ...
    uint[] memory amounts = router.swapExactTokensForTokens(
        1e18, 0, path, address(this), block.timestamp
    );
    assertGt(amounts[amounts.length - 1], 0);
}
```

### Remove Liquidity

```solidity
function testRemoveLiquidity() public {
    // Add liquidity first
    // ...
    (uint amountA, uint amountB) = router.removeLiquidity(
        tokenA, tokenB, liquidity, 1e17, 1e17, address(this), block.timestamp
    );
    assertGt(amountA, 0);
    assertGt(amountB, 0);
}
```

### Error Cases

```solidity
function testRevertOnExpiredDeadline() public {
    vm.expectRevert("UniswapV2Router: EXPIRED");
    router.addLiquidity(
        tokenA, tokenB, 1e18, 1e18, 1e17, 1e17, address(this), block.timestamp - 1
    );
}
```

---

## Best Practices & Common Pitfalls

### Best Practices

- Always approve tokens before adding liquidity or swapping.
- Use helper functions for balance and invariant checks.
- Test both success and failure cases, including permission and access control.
- Include gas usage assertions for key operations.
- Use fuzzing for edge cases.

### Common Pitfalls

- Forgetting to settle all token balances after operations.
- Incorrect token index/order in pool setup.
- Not resetting state between tests (use `vm.startPrank()`/`vm.stopPrank()` appropriately).
- Overlooking rounding/precision issues (use `DELTA` for approximate checks).
- Not testing with both standard and non-standard tokens.

---

## References & Further Reading

- [Uniswap V2 Pool Lifecycle & Architecture Guide](uniswap-v2-pool-lifecycle.md)
- [Uniswap V2 Core Docs](https://docs.uniswap.org/contracts/v2)
- [Uniswap V2 Router Docs](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02)
- [Crane Uniswap V2 Contracts](../../../contracts/protocols/dexes/uniswap/v2/) 