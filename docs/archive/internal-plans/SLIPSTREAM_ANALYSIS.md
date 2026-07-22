# Slipstream Analysis

## Overview

Slipstream is Aerodrome's concentrated liquidity AMM, deployed on Base. It is a fork of Uniswap V3 with modifications for gauge/staking integration (Velodrome-style tokenomics).

## Pragma Versions

| Library | Pragma | 0.8+ Compatible |
|---------|--------|-----------------|
| FullMath.sol | `>=0.4.0 <0.8.0` | No |
| TickMath.sol | `>=0.5.0 <0.8.0` | No |
| Oracle.sol | `>=0.5.0 <0.8.0` | No |
| Position.sol | `>=0.5.0 <0.8.0` | No |
| Tick.sol | `>=0.5.0 <0.8.0` | No |
| CLPool.sol | `=0.7.6` | No |
| SwapMath.sol | `>=0.5.0` | Yes (no overflow) |
| SqrtPriceMath.sol | `>=0.5.0` | Yes (no overflow) |
| TickBitmap.sol | `>=0.5.0` | Yes (no overflow) |
| BitMath.sol | `>=0.5.0` | Yes (no overflow) |

**Conclusion**: Libraries with modular arithmetic (FullMath, TickMath, etc.) need porting with `unchecked` blocks. The existing Uniswap V3 ports in `contracts/protocols/dexes/uniswap/v3/libraries/` can be reused since the math is identical.

## Key Differences from Uniswap V3

### 1. Pool Interface (`ICLPool` vs `IUniswapV3Pool`)

**slot0 differences:**
```solidity
// Uniswap V3 slot0
(sqrtPriceX96, tick, observationIndex, observationCardinality, observationCardinalityNext, feeProtocol, unlocked)

// Slipstream slot0 - NO feeProtocol field
(sqrtPriceX96, tick, observationIndex, observationCardinality, observationCardinalityNext, unlocked)
```

**Fee access:**
```solidity
// Uniswap V3: fee is stored in slot0 or as immutable
uint24 fee = pool.fee();

// Slipstream: dynamic fees via factory lookup
uint24 fee = pool.fee();  // calls ICLFactory(factory).getSwapFee(address(this))
uint24 unstakedFee = pool.unstakedFee();  // additional fee on unstaked liquidity
```

### 2. Staking/Gauge Integration

Slipstream pools have deep integration with Velodrome-style gauges:

```solidity
// New state variables in CLPool
uint128 public stakedLiquidity;  // Staked liquidity in current tick
address public gauge;            // Associated gauge contract
address public nft;              // NonfungiblePositionManager

// New functions
function stake(int128 stakedLiquidityDelta, int24 tickLower, int24 tickUpper, bool positionUpdate) external;
function updateRewardsGrowthGlobal() external;
function syncReward(uint256 _rewardRate, uint256 _rewardReserve, uint256 _periodFinish) external;
function collectFees() external returns (uint128 amount0, uint128 amount1);  // Gauge fees

// Reward tracking
uint256 public rewardGrowthGlobalX128;
uint256 public rewardRate;
uint256 public rewardReserve;
uint256 public periodFinish;
uint256 public rollover;
uint32 public lastUpdated;
```

### 3. Tick Data Structure

```solidity
// Slipstream ticks() returns additional fields
function ticks(int24 tick) external view returns (
    uint128 liquidityGross,
    int128 liquidityNet,
    int128 stakedLiquidityNet,        // NEW: staked liquidity delta
    uint256 feeGrowthOutside0X128,
    uint256 feeGrowthOutside1X128,
    uint256 rewardGrowthOutsideX128,  // NEW: reward tracking
    int56 tickCumulativeOutside,
    uint160 secondsPerLiquidityOutsideX128,
    uint32 secondsOutside,
    bool initialized
);
```

### 4. Fee Calculation

Slipstream has a more complex fee structure:
- `fee()` - Standard swap fee (like Uniswap V3)
- `unstakedFee()` - Additional fee applied to unstaked liquidity portion
- Fees are split between staked/unstaked LPs and gauge

### 5. Factory (`ICLFactory` vs `IUniswapV3Factory`)

```solidity
// Slipstream factory has custom fee modules
function getSwapFee(address pool) external view returns (uint24);
function getUnstakedFee(address pool) external view returns (uint24);
function setSwapFeeModule(address swapFeeModule) external;
function setUnstakedFeeModule(address unstakedFeeModule) external;
```

### 6. Naming Conventions

| Uniswap V3 | Slipstream |
|------------|------------|
| `IUniswapV3Pool` | `ICLPool` |
| `IUniswapV3Factory` | `ICLFactory` |
| `UniswapV3Pool` | `CLPool` |
| `uniswapV3MintCallback` | `uniswapV3MintCallback` (same) |
| `uniswapV3SwapCallback` | `uniswapV3SwapCallback` (same) |

## Libraries to Port

**Not needed - can reuse existing Uniswap V3 ports:**
- FullMath (identical math)
- TickMath (identical math)
- SqrtPriceMath (identical math)
- SwapMath (identical math)
- TickBitmap (identical logic)
- BitMath (identical logic)
- LiquidityMath (identical math)
- FixedPoint96/128 (constants only)

**Required - Slipstream-specific interfaces:**
- ICLPool.sol (different slot0, new staking methods)
- ICLFactory.sol (fee module methods)
- ICLPoolState.sol (stakedLiquidity, rewardGrowthGlobalX128, etc.)

## Implementation Strategy

1. **SlipstreamUtils.sol**: Use existing V3 math libraries, only difference is the pool interface for reading state
2. **SlipstreamQuoter.sol**: Same swap math as V3, but:
   - Use ICLPool interface instead of IUniswapV3Pool
   - Handle different slot0 return values
   - Account for unstaked fee in fee calculations (optional, for accuracy)
3. **SlipstreamZapQuoter.sol**: Same logic as V3, wraps SlipstreamQuoter + SlipstreamUtils

## Tick Spacing

Slipstream supports the same tick spacings as Uniswap V3 but may have different defaults per factory configuration. Common values:
- 1 (stable pairs)
- 50 (0.05% fee tier)
- 100 (0.3% fee tier)
- 200 (1% fee tier)

## Notes for Implementation

1. **Fee handling**: For quoting purposes, we can use `pool.fee()` directly as Slipstream exposes this. The unstaked fee affects actual execution but not the swap math.

2. **Liquidity reading**: Use `pool.liquidity()` for total liquidity. `pool.stakedLiquidity()` is for gauge rewards only.

3. **Tick data**: When crossing ticks in the quoter, use `liquidityNet` (not `stakedLiquidityNet`) for swap calculations.

4. **Callbacks**: Slipstream uses the same callback signatures as Uniswap V3 for compatibility.
