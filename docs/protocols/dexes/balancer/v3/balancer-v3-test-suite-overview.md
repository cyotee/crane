# Balancer V3 Test Suite Overview

## Test Suite Structure

The Balancer V3 test suite is organized into several key components:

### 1. Base Test Classes

The test hierarchy follows this structure:

```
BaseTest (from v3-solidity-utils)
    └── BaseVaultTest (from v3-vault)
        └── BasePoolTest
            └── Specific Pool Tests (WeightedPoolTest, ConstantProductPoolTest, etc.)
```

Each level provides specific functionality:

- `BaseTest`: Core testing utilities from Foundry and basic setup
- `BaseVaultTest`: Vault infrastructure, token management, and balance utilities
- `BasePoolTest`: Pool-specific testing functionality and common pool operations
- Pool-specific test contracts: Individual pool type implementations and tests

### 2. Pool-Specific Test Suites

Each pool type has its own test suite inheriting from BasePoolTest:

```
test/foundry/
├── pools/
│   ├── weighted/
│   │   ├── WeightedPool.t.sol
│   │   └── WeightedPoolFactory.t.sol
│   ├── constant-product/
│   │   ├── ConstantProductPool.t.sol
│   │   └── ConstantProductPoolFactory.t.sol
│   └── stable/
│       ├── StablePool.t.sol
│       └── StablePoolFactory.t.sol
```

## Test Categories

### 1. Unit Tests

Individual component testing:

```solidity
contract WeightedPoolTest is BasePoolTest {
    function test_pool_initialization() public {
        assertEq(address(BalancerPoolToken(pool).getVault()), address(vault));
        assertEq(pool.getMinimumSwapFeePercentage(), MIN_SWAP_FEE_PERCENTAGE);
    }
    
    function test_onSwap_exact_in() public {
        // Test specific swap function
        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 100e18,
            balancesScaled18: tokenAmounts,
            indexIn: 0,
            indexOut: 1,
            router: address(this),
            userData: ""
        });
        uint256 amountOut = pool.onSwap(params);
        assertGt(amountOut, 0);
    }
}
```

### 2. Integration Tests

Testing component interactions:

```solidity
contract PoolIntegrationTest is BasePoolTest {
    function testAddLiquidity() public {
        vm.startPrank(bob);
        router.addLiquidityUnbalanced(
            pool,
            tokenAmounts,
            tokenAmountIn - DELTA,
            false,
            bytes("")
        );

        // Verify balances and state
        (, , uint256[] memory balances, ) = vault.getPoolTokenInfo(address(pool));
        for (uint256 i = 0; i < poolTokens.length; ++i) {
            assertEq(
                balances[i],
                tokenAmounts[i] * 2,
                string.concat("Pool: Wrong token balance for ", Strings.toString(i))
            );
        }
    }
}
```

## Test Environment Setup

### 1. BaseVaultTest Setup

The `BaseVaultTest` handles core infrastructure setup:

```solidity
function setUp() public virtual override {
    BaseTest.setUp();  // From v3-solidity-utils

    // Deploy main contracts
    vault = deployVaultMock(...);
    router = deployRouterMock(IVault(address(vault)), weth, permit2);
    authorizer = BasicAuthorizerMock(address(vault.getAuthorizer()));
    
    // Set up other components
    vaultExtension = IVaultExtension(vault.getVaultExtension());
    vaultAdmin = IVaultAdmin(vault.getVaultAdmin());
    feeController = vault.getProtocolFeeController();
}
```

### 2. BasePoolTest Setup

The `BasePoolTest` adds pool-specific setup:

```solidity
function setUp() public virtual override {
    BaseVaultTest.setUp();

    // Create and initialize pool
    poolFactory = createPoolFactory();
    poolHooksContract = createHook();
    (pool, poolArguments) = createPool();

    if (pool != address(0)) {
        approveForPool(IERC20(pool));
    }

    // Add initial liquidity
    initPool();
}
```

### 3. Test Constants

Important constants from `BasePoolTest`:

```solidity
uint256 internal constant POOL_MINIMUM_TOTAL_SUPPLY = 1e6;
uint256 internal constant DEFAULT_AMOUNT = 1e3 * 1e18;
uint256 internal constant DEFAULT_SWAP_FEE_PERCENTAGE = 1e16; // 1%
uint256 internal constant DELTA = 1e9; // For approximate equality checks
```

## Common Test Utilities

### 1. Balance Checking

`BaseVaultTest` provides comprehensive balance checking:

```solidity
function getBalances(address user) internal view returns (Balances memory) {
    return getBalances(user, Rounding.ROUND_DOWN);
}

struct Balances {
    uint256[] userTokens;
    uint256 userEth;
    uint256 userBpt;
    uint256[] vaultTokens;
    uint256 vaultEth;
    uint256[] poolTokens;
    uint256 poolEth;
    uint256 poolSupply;
    uint256 poolInvariant;
    // ... other balance tracking fields
}
```

### 2. Pool Operations

`BasePoolTest` provides standard pool operation tests:

```solidity
function testSwap() public virtual {
    // Standard swap test implementation
    // Handles swap fee configuration
    // Verifies token transfers
    // Checks pool balances
}

function testAddLiquidity() public virtual {
    // Standard liquidity addition test
    // Verifies token transfers
    // Checks BPT minting
    // Verifies pool balances
}
```

## Best Practices

1. **Test Organization**
   - Inherit from the appropriate base test contract
   - Override virtual functions when needed
   - Use the provided test utilities and helpers

2. **Balance Verification**
   - Use the `getBalances()` helper for comprehensive balance checks
   - Account for the `DELTA` constant in floating-point comparisons
   - Verify both token and ETH balances when relevant

3. **Pool Testing**
   - Test both success and failure cases
   - Verify pool invariants after operations
   - Check protocol and swap fees are handled correctly
   - Test with different token decimals and configurations

4. **Error Handling**
   - Test all revert conditions
   - Verify error messages match interface definitions
   - Test permission and access control using the authorizer

## Common Pitfalls

1. **Token Setup**
   - Always sort tokens by address before pool creation
   - Account for different token decimals
   - Set up proper approvals for all users

2. **State Management**
   - Use `vm.startPrank()` and `vm.stopPrank()` appropriately
   - Reset state between tests if needed
   - Be aware of shared state in base test contracts

3. **Precision Handling**
   - Use `DELTA` for approximate equality checks
   - Account for rounding in pool math
   - Test with both small and large amounts

## References

- [Balancer V3 WeightedPool Tests](https://github.com/balancer/balancer-v3-monorepo/blob/master/pkg/pool-weighted/test/foundry/WeightedPool.t.sol)
- [Balancer V3 BasePoolTest](https://github.com/balancer/balancer-v3-monorepo/blob/master/pkg/vault/test/foundry/utils/BasePoolTest.sol)
- [Balancer V3 BaseVaultTest](https://github.com/balancer/balancer-v3-monorepo/blob/master/pkg/vault/test/foundry/utils/BaseVaultTest.sol) 