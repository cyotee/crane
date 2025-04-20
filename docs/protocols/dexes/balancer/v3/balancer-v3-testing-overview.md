# Balancer V3 Testing Guide

## Overview

This guide provides comprehensive information about testing Balancer V3 pools in the Crane framework. It covers test setup, pool creation, common test patterns, and best practices derived from both the official Balancer V3 test suite and our custom implementations.

## Table of Contents

1. [Test Environment Setup](#test-environment-setup)
2. [Pool Creation and Initialization](#pool-creation-and-initialization)
3. [Common Test Scenarios](#common-test-scenarios)
4. [Best Practices](#best-practices)

## Test Environment Setup

### Base Test Classes

Balancer V3 tests in Crane extend from several base test classes that provide essential functionality:

```solidity
contract ConstantProductPoolTest is BasePoolTest {
    using CastingHelpers for address[];
    using ArrayHelpers for *;
}
```

The inheritance chain provides:
- `BasePoolTest`: Core pool testing functionality
- `BaseVaultTest`: Vault interaction testing
- `Test`: Foundry's test framework

### Key Components

Every Balancer V3 pool test requires:

1. **Vault**: The central Balancer V3 Vault contract
2. **Router**: For executing pool operations
3. **Factory**: For deploying new pools
4. **Test Tokens**: ERC20 tokens for pool assets

### Standard Test Constants

```solidity
string constant POOL_VERSION = "Pool v1";
uint256 constant DEFAULT_SWAP_FEE = 1e15; // 0.1%
uint256 constant MIN_SWAP_FEE_PERCENTAGE = 1e12; // 0.0001%
uint256 constant MAX_SWAP_FEE_PERCENTAGE = 0.10e18; // 10%
uint256 constant INITIAL_BALANCE = 100e18;
```

## Pool Creation and Initialization

### Factory Setup

```solidity
function createPoolFactory() internal override returns (address) {
    return address(deployConstantProductPoolFactory(
        IVault(address(vault)),
        365 days
    ));
}
```

### Pool Creation

```solidity
function createPool() internal override returns (address newPool, bytes memory poolArgs) {
    string memory name = "Constant Product Pool";
    string memory symbol = "CPP";

    // Sort tokens by address
    IERC20[] memory sortedTokens = InputHelpers.sortTokens(
        [address(token0), address(token1)].toMemoryArray().asIERC20()
    );

    // Configure tokens
    TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
    tokenConfigs[0] = TokenConfig({
        token: sortedTokens[0],
        tokenType: TokenType.STANDARD,
        rateProvider: IRateProvider(address(0)),
        paysYieldFees: false
    });
    tokenConfigs[1] = TokenConfig({
        token: sortedTokens[1],
        tokenType: TokenType.STANDARD,
        rateProvider: IRateProvider(address(0)),
        paysYieldFees: false
    });

    // Create pool using factory
    newPool = ConstantProductFactory(poolFactory).create(
        name,
        symbol,
        ZERO_BYTES32,
        tokenConfigs,
        MIN_SWAP_FEE_PERCENTAGE,
        false,
        roleAccounts,
        address(0),
        liquidityManagement
    );

    poolArgs = abi.encode(IVault(address(vault)), name, symbol);
}
```

## Common Test Scenarios

### 1. Pool Initialization Test

```solidity
function test_pool_initialization() public {
    assertEq(address(BalancerPoolToken(pool).getVault()), address(vault));
    assertEq(ConstantProductPool(pool).getMinimumSwapFeePercentage(), MIN_SWAP_FEE_PERCENTAGE);
    assertEq(ConstantProductPool(pool).getMaximumSwapFeePercentage(), MAX_SWAP_FEE_PERCENTAGE);
}
```

### 2. Swap Testing

```solidity
function test_onSwap_exact_in() public {
    PoolSwapParams memory params = PoolSwapParams({
        kind: SwapKind.EXACT_IN,
        amountGivenScaled18: 100e18,
        balancesScaled18: tokenAmounts,
        indexIn: 0,
        indexOut: 1,
        router: address(this),
        userData: ""
    });

    uint256 amountOut = ConstantProductPool(pool).onSwap(params);
    assertGt(amountOut, 0);
}
```

### 3. Liquidity Operations

```solidity
function testAddLiquidity() public {
    vm.startPrank(bob);
    router.addLiquidityUnbalanced(
        pool,
        tokenAmounts,
        tokenAmountIn - DELTA,
        false,
        bytes("")
    );

    // Verify balances
    (, , uint256[] memory balances, ) = vault.getPoolTokenInfo(address(pool));
    for (uint256 i = 0; i < poolTokens.length; ++i) {
        assertEq(
            balances[i],
            tokenAmounts[i] * 2,
            string.concat("Pool: Wrong token balance for ", Strings.toString(i))
        );
    }
}
```

## Best Practices

1. **Token Sorting**: Always sort tokens by address before pool creation
   ```solidity
   IERC20[] memory sortedTokens = InputHelpers.sortTokens(tokens.asIERC20());
   ```

2. **Balance Verification**: Use helper functions for balance checks
   ```solidity
   assertApproxEqAbs(
       poolTokens[i].balanceOf(address(vault)),
       expectedAmount,
       DELTA,
       "Balance mismatch"
   );
   ```

3. **Permission Management**: Set up proper permissions in test setup
   ```solidity
   authorizer.grantRole(vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector), alice);
   ```

4. **Error Handling**: Test for expected errors
   ```solidity
   vm.expectRevert(IVaultErrors.SwapFeePercentageTooLow.selector);
   vault.setStaticSwapFeePercentage(pool, MIN_SWAP_FEE_PERCENTAGE - 1);
   ```

## References

- [Balancer V3 WeightedPool Tests](https://github.com/balancer/balancer-v3-monorepo/blob/master/pkg/pool-weighted/test/foundry/WeightedPool.t.sol)
- [Balancer V3 BasePoolTest](https://github.com/balancer/balancer-v3-monorepo/blob/master/pkg/vault/test/foundry/utils/BasePoolTest.sol) 