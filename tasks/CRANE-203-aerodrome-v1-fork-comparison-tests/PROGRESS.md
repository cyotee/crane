# Progress Log: CRANE-203

## Current Checkpoint

**Last checkpoint:** Not started
**Next step:** Read TASK.md and begin implementation
**Build status:** ⏳ Not checked
**Test status:** ⏳ Not checked

---

## Session Log

### 2026-02-02 - Task Created

- Task designed via /design:design
- TASK.md populated with requirements for Aerodrome V1 fork comparison tests
- Scope: Base mainnet fork comparing local service libraries vs deployed contracts
- Pool types: Both volatile (xy=k) AND stable (x³y+xy³=k) pools
- Test token approach: Deploy ERC20PermitMintableStub with 18 and 6 decimals
- Comparison method: Execute same operations on both, assert exact output match
- Ready for agent assignment via /backlog:launch

### Implementation Notes

**Key patterns to follow:**
- Reference `TestBase_UniswapV3Fork.sol` for fork test structure
- Reference `TestBase_SlipstreamFork.sol` for Base mainnet fork setup
- Reference existing `AerodromServiceVolatile.sol` and `AerodromServiceStable.sol` for service patterns

**Aerodrome-specific considerations:**
- Fee denominator is 10,000 (not 100,000 like Uniswap)
- Pools have `stable` boolean flag
- Get fee via `factory.getFee(pool, isStable)`
- Pool metadata: `pool.metadata()` returns tuple
- Stable pools use Newton-Raphson solver (4-6 iterations typical)

**Test token deployment:**
```solidity
ERC20PermitMintableStub tokenA = new ERC20PermitMintableStub(
    "TestToken18", "TT18", 18, address(this), 0
);
ERC20PermitMintableStub tokenB = new ERC20PermitMintableStub(
    "TestToken6", "TT6", 6, address(this), 0
);
```

**Pool creation on mainnet factory:**
```solidity
IPoolFactory factory = IPoolFactory(BASE_MAIN.AERODROME_POOL_FACTORY);

// Volatile pool (stable = false)
address volatilePool = factory.createPool(address(tokenA), address(tokenB), false);

// Stable pool (stable = true)
address stablePool = factory.createPool(address(tokenC), address(tokenD), true);
```

**Comparison assertion pattern:**
```solidity
// Using mainnet router
uint256 mainnetOutput = router.swapExactTokensForTokens(...);

// Using our service library
uint256 serviceOutput = AerodromServiceVolatile._swapVolatile(params);

assertEq(mainnetOutput, serviceOutput, "Swap outputs must match exactly");
```

**Stable pool K invariant:**
```solidity
// k = x³y + xy³ (for stable pools)
function _k(uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 _a = (x * y) / 1e18;
    uint256 _b = ((x * x) / 1e18 + (y * y) / 1e18);
    return (_a * _b) / 1e18;
}
```
