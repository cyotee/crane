# Progress Log: CRANE-205

## Current Checkpoint

**Last checkpoint:** Not started
**Next step:** Read TASK.md and begin implementation
**Build status:** ⏳ Not checked
**Test status:** ⏳ Not checked

---

## Session Log

### 2026-02-02 - Task Created

- Task designed via /design:design
- TASK.md populated with requirements for Uniswap V4 ported contract parity tests
- Scope: Ethereum + Base mainnet forks comparing our ported V4 stack vs deployed contracts
- Differs from existing V4 fork tests which validate quote utilities
- This task validates our ported PoolManager/V4Router/PositionManager/Hooks implementations
- Test token decimals: 18, 6, 8 (WETH, USDC, WBTC style)
- Includes hooks parity testing (WETHHook, WstETHHook, WstETHRoutingHook)
- Ready for agent assignment via /backlog:launch

### Implementation Notes

**Key distinction from existing tests:**
- Existing `UniswapV4Utils_Fork.t.sol` → validates quote utilities against mainnet pools
- This task → validates our ported contracts against mainnet equivalents

**V4 Architecture Considerations:**
1. Singleton PoolManager (all pools in one contract)
2. Flash accounting with EIP-1153 transient storage
3. Unlock callback pattern for all state-changing operations
4. PoolKey identifies pools vs V3's separate pool contracts

**Comparison approach:**
1. Fork mainnet at post-Cancun block
2. Deploy test tokens
3. Deploy our local V4 stack (PoolManager, V4Router, PositionManager)
4. Initialize pools on BOTH mainnet PoolManager AND our local PoolManager
5. Execute same operations on both (via unlock callbacks)
6. Assert outputs match exactly

**Local stack deployment pattern:**
```solidity
// Deploy our ported PoolManager
PoolManager localPoolManager = new PoolManager();

// Create PoolKey for test tokens
PoolKey memory poolKey = PoolKey({
    currency0: Currency.wrap(address(tokenA)),
    currency1: Currency.wrap(address(tokenB)),
    fee: FEE_MEDIUM,
    tickSpacing: TICK_SPACING_60,
    hooks: IHooks(address(0))
});

// Initialize on our local PoolManager
localPoolManager.initialize(poolKey, sqrtPriceX96);

// Initialize on mainnet PoolManager (same pool key with test tokens)
mainnetPoolManager.initialize(poolKey, sqrtPriceX96);

// Execute same operation on both via unlock callbacks
// Assert results match
```

**Fee tiers to test:**
- 100 (0.01%) - tick spacing 1
- 500 (0.05%) - tick spacing 10
- 3000 (0.3%) - tick spacing 60
- 10000 (1%) - tick spacing 200

**Decimal combinations:**
- 18/18: Standard ERC20 pair
- 18/6: WETH/USDC style
- 6/6: Stablecoin pair
- 8/18: WBTC/WETH style

**Hooks to test:**
- WETHHook: Native ETH wrapping
- WstETHHook: wstETH wrapping
- WstETHRoutingHook: wstETH routing simulation
- BaseTokenWrapperHook: Base functionality
