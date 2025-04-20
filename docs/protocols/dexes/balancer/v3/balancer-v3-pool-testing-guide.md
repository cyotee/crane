# Balancer V3 Pool Testing Guide

## Pool Types

Balancer V3 supports multiple pool types, each with unique characteristics and testing requirements:

1. **Weighted Pools**
   - Fixed weights for each token
   - Up to 8 tokens per pool
   - Normalized weights must sum to 1
   - Minimum weight of 1%

2. **Constant Product Pools**
   - Two tokens only
   - Equal weights (50/50)
   - Similar to Uniswap V2 math

3. **Stable Pools**
   - For tokens that should maintain close to a 1:1 ratio
   - Optimized for minimal price impact near parity
   - Supports rate providers for non-18 decimal tokens

## Test Setup Requirements

### 1. Weighted Pools

```solidity
contract WeightedPoolTest is BasePoolTest {
    uint256[] internal weights;
    
    function setUp() public override {
        weights = [uint256(50e16), uint256(50e16)];  // 50-50 weights
        super.setUp();
    }
}
```

### 2. Constant Product Pools

```solidity
contract ConstantProductPoolTest is BasePoolTest {
    uint256 constant DEFAULT_SWAP_FEE = 1e15; // 0.1%
    
    function setUp() public override {
        super.setUp();
        poolMinSwapFeePercentage = 1e12; // 0.0001%
        poolMaxSwapFeePercentage = 0.10e18; // 10%
    }
}
```

### 3. Stable Pools

```solidity
contract StablePoolTest is BasePoolTest {
    IRateProvider[] internal rateProviders;
    
    function setUp() public override {
        // Set up rate providers for tokens with != 18 decimals
        rateProviders = [
            IRateProvider(address(0)),  // No rate provider needed
            new RateProviderMock(1e12)  // For 6 decimal token
        ];
        super.setUp();
    }
}
```

## Common Test Cases

### 1. Pool Creation

Test that pools are created with correct parameters:

```solidity
function testPoolCreation() public {
    assertEq(pool.getVault(), address(vault));
    assertEq(pool.getSwapFeePercentage(), DEFAULT_SWAP_FEE);
    // Test pool-specific parameters
}
```

### 2. Liquidity Addition

Test both balanced and unbalanced liquidity addition:

```solidity
function testAddLiquidity() public {
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 1e18;
    amounts[1] = 1e18;
    
    vm.startPrank(lp);
    uint256 bptOut = router.addLiquidity(
        pool,
        amounts,
        0,  // minBPTOut
        false,  // unbalanced
        ""  // userData
    );
    vm.stopPrank();
    
    assertGt(bptOut, 0);
}
```

### 3. Swaps

Test both exact input and exact output swaps:

```solidity
function testExactInputSwap() public {
    vm.startPrank(trader);
    uint256 amountOut = router.swap(
        pool,
        SwapKind.EXACT_IN,
        tokens[0],
        tokens[1],
        1e18,  // amountIn
        0,     // minAmountOut
        ""     // userData
    );
    vm.stopPrank();
    
    assertGt(amountOut, 0);
}
```

## Pool-Specific Test Considerations

### Weighted Pools

1. **Weight Validation**
   ```solidity
   function testWeightValidation() public {
       // Test minimum weight requirement
       uint256[] memory invalidWeights = [0.5e18, 0.5e18];
       vm.expectRevert("BAL#001"); // MIN_WEIGHT
       factory.create(..., invalidWeights, ...);
   }
   ```

2. **Weight Ratios**
   ```solidity
   function testWeightRatios() public {
       uint256[] memory weights = pool.getNormalizedWeights();
       assertEq(weights[0] + weights[1], FixedPoint.ONE);
   }
   ```

### Constant Product Pools

1. **Price Impact**
   ```solidity
   function testPriceImpact() public {
       uint256 priceImpact = pool.calculatePriceImpact(
           tokens[0],
           1e18,  // amountIn
           true   // exactIn
       );
       assertLt(priceImpact, maxAcceptablePriceImpact);
   }
   ```

2. **Invariant Maintenance**
   ```solidity
   function testInvariant() public {
       uint256 k = pool.getLastInvariant();
       // Perform swap
       router.swap(...);
       uint256 newK = pool.getLastInvariant();
       assertGe(newK, k);
   }
   ```

### Stable Pools

1. **Rate Provider Integration**
   ```solidity
   function testRateProviderIntegration() public {
       uint256[] memory rates = new uint256[](2);
       rates[0] = rateProviders[0].getRate();
       rates[1] = rateProviders[1].getRate();
       
       assertEq(rates[1], 1e12, "Incorrect rate for 6 decimal token");
   }
   ```

2. **Amplification Parameter**
   ```solidity
   function testAmplificationParameter() public {
       uint256 amp = pool.getAmplificationParameter();
       assertGe(amp, MIN_AMP);
       assertLe(amp, MAX_AMP);
   }
   ```

## Best Practices

1. **Token Setup**
   - Always use tokens with different decimals in tests
   - Include at least one rate provider test
   - Test with both standard and non-standard tokens

2. **Parameter Boundaries**
   - Test at minimum and maximum swap fee values
   - Test at minimum and maximum weight values (Weighted Pools)
   - Test at minimum and maximum amplification values (Stable Pools)

3. **Error Cases**
   - Test all possible revert conditions
   - Include fuzzing tests for numerical edge cases
   - Test permission and access control

4. **Gas Optimization**
   - Include gas usage assertions for key operations
   - Compare gas usage across different pool types
   - Monitor gas usage changes in updates

## References

- [Balancer V3 Core Concepts](https://docs.balancer.fi/concepts/pools)
- [Pool Types Documentation](https://docs.balancer.fi/concepts/pools/pool-types)
- [Testing Best Practices](https://docs.balancer.fi/guides/testing) 