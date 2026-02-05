# Gauge Integration Guide

A comprehensive reference for integrating vault contracts with LP staking gauges across DeFi protocols.

## Overview

Gauges are staking contracts where liquidity providers (LPs) deposit their LP tokens to earn protocol emissions. This guide covers gauge systems for:

- **Aerodrome V1** (Uniswap V2 fork, ERC-20 LP tokens)
- **Slipstream** (Aerodrome's concentrated liquidity, ERC-721 NFT positions)
- **Balancer V3** (ERC-20 BPT tokens)
- **Uniswap** (No native gauges)

---

## Quick Reference: Protocol Comparison

| Feature | Aerodrome V1 | Slipstream | Balancer V3 | Uniswap V2/V3 |
|---------|--------------|------------|-------------|---------------|
| **LP Token Type** | ERC-20 | ERC-721 NFT | ERC-20 BPT | ERC-20 / ERC-721 |
| **Native Gauges** | Yes | Yes | Yes | No |
| **Emissions Token** | AERO | AERO | BAL | None |
| **Vote-Escrow** | veAERO | veAERO | veBAL | None |
| **Add to Stake** | Yes (seamless) | No (unstake first) | Yes (seamless) | N/A |
| **Partial Withdraw** | Yes | No (whole NFT) | Yes | N/A |
| **Unstaked Fee** | No | Yes | No | No |

---

## Aerodrome V1 Gauges (ERC-20)

### Architecture

```
User deposits tokens → Router adds liquidity → Pool mints ERC-20 LP → Gauge stakes LP

┌──────────-┐    ┌─────────--─┐    ┌──────────┐    ┌──────────┐
│  Tokens   │───►│  Router    │───►│   Pool   │───►│  Gauge   │
│(WETH+USDC)│    │addLiquidity│    │(LP token)│    │(staking) │
└──────────-┘    └──────────--┘    └──────────┘    └──────────┘
                                      │               │
                                      │               ▼
                                      │         AERO emissions
                                      │         proportional to
                                      └────────►LP staked
```

### Key Contracts

| Contract | Purpose |
|----------|---------|
| `IVoter` | Gauge registry, voting, gauge lifecycle |
| `IPool` | AMM pool, mints/burns LP tokens |
| `IGauge` | Staking contract for LP tokens |
| `IVotingEscrow` | veAERO lock management |

### Gauge Interface

```solidity
interface IAerodromeV1Gauge {
    /// @notice Deposit LP tokens - ADDS to existing stake
    /// @param amount Amount of LP tokens to stake
    function deposit(uint256 amount) external;

    /// @notice Withdraw LP tokens - PARTIAL withdrawals OK
    /// @param amount Amount of LP tokens to unstake
    function withdraw(uint256 amount) external;

    /// @notice Claim AERO rewards
    /// @param account Address to claim for
    /// @return Amount of AERO claimed
    function getReward(address account) external returns (uint256);

    /// @notice Check staked balance
    function balanceOf(address account) external view returns (uint256);

    /// @notice Check pending rewards
    function earned(address account) external view returns (uint256);

    /// @notice Total LP staked in gauge
    function totalSupply() external view returns (uint256);

    /// @notice AERO per second distributed
    function rewardRate() external view returns (uint256);
}
```

### Voter Interface (Gauge Registry)

```solidity
interface IVoter {
    /// @notice Get gauge address for a pool (address(0) if none)
    function gauges(address pool) external view returns (address);

    /// @notice Check if gauge is active (receiving emissions)
    function isAlive(address gauge) external view returns (bool);

    /// @notice Verify address is a registered gauge
    function isGauge(address gauge) external view returns (bool);

    /// @notice Reverse lookup: gauge → pool
    function poolForGauge(address gauge) external view returns (address);

    /// @notice Create gauge for pool (governance only)
    function createGauge(address pool) external returns (address);

    /// @notice Kill gauge - stops emissions
    function killGauge(address gauge) external;

    /// @notice Revive killed gauge
    function reviveGauge(address gauge) external;
}
```

### Vault Implementation Pattern

```solidity
contract AerodromeV1Vault is ERC20 {
    IVoter public immutable voter;
    IPool public immutable pool;
    IERC20 public immutable lpToken;
    address public gauge;

    constructor(address _voter, address _pool) {
        voter = IVoter(_voter);
        pool = IPool(_pool);
        lpToken = IERC20(_pool);  // Pool IS the LP token
        gauge = voter.gauges(_pool);
    }

    // ─────────────────────────────────────────────────────────
    // Gauge Status Checks
    // ─────────────────────────────────────────────────────────

    function hasGauge() public view returns (bool) {
        return gauge != address(0);
    }

    function isGaugeActive() public view returns (bool) {
        return hasGauge() && voter.isAlive(gauge);
    }

    /// @notice Adopt gauge if one was created after vault deployment
    function adoptGauge() external {
        require(gauge == address(0), "Gauge already set");
        address newGauge = voter.gauges(address(pool));
        require(newGauge != address(0), "No gauge exists");
        gauge = newGauge;

        // Stake any existing LP balance
        uint256 balance = lpToken.balanceOf(address(this));
        if (balance > 0 && voter.isAlive(gauge)) {
            lpToken.approve(gauge, balance);
            IAerodromeV1Gauge(gauge).deposit(balance);
        }
    }

    // ─────────────────────────────────────────────────────────
    // Deposit / Withdraw
    // ─────────────────────────────────────────────────────────

    function deposit(uint256 lpAmount) external returns (uint256 shares) {
        lpToken.transferFrom(msg.sender, address(this), lpAmount);

        // Auto-stake if gauge active - just deposit, adds to existing
        if (isGaugeActive()) {
            lpToken.approve(gauge, lpAmount);
            IAerodromeV1Gauge(gauge).deposit(lpAmount);
        }

        shares = _calculateShares(lpAmount);
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 shares) external returns (uint256 lpAmount) {
        lpAmount = _calculateLpAmount(shares);
        _burn(msg.sender, shares);

        // Partial unstake - no problem with ERC-20!
        if (isGaugeActive()) {
            IAerodromeV1Gauge(gauge).withdraw(lpAmount);
        }

        lpToken.transfer(msg.sender, lpAmount);
    }

    // ─────────────────────────────────────────────────────────
    // Rewards
    // ─────────────────────────────────────────────────────────

    function claimRewards() external returns (uint256 aeroAmount) {
        if (!isGaugeActive()) return 0;
        return IAerodromeV1Gauge(gauge).getReward(address(this));
    }

    function pendingRewards() external view returns (uint256) {
        if (!isGaugeActive()) return 0;
        return IAerodromeV1Gauge(gauge).earned(address(this));
    }

    /// @notice Compound rewards - no unstake needed!
    function compound() external {
        uint256 aero = claimRewards();
        if (aero == 0) return;

        // Swap AERO → LP tokens via router
        uint256 newLp = _swapAeroForLp(aero);

        // Just deposit more - seamlessly adds to stake
        lpToken.approve(gauge, newLp);
        IAerodromeV1Gauge(gauge).deposit(newLp);
    }

    // ─────────────────────────────────────────────────────────
    // Gauge Lifecycle Handlers
    // ─────────────────────────────────────────────────────────

    function handleGaugeKilled() external {
        require(hasGauge() && !voter.isAlive(gauge), "Gauge still alive");

        // Unstake everything
        uint256 staked = IAerodromeV1Gauge(gauge).balanceOf(address(this));
        if (staked > 0) {
            IAerodromeV1Gauge(gauge).withdraw(staked);
        }
    }

    function handleGaugeRevived() external {
        require(isGaugeActive(), "Gauge not active");

        // Re-stake everything
        uint256 balance = lpToken.balanceOf(address(this));
        if (balance > 0) {
            lpToken.approve(gauge, balance);
            IAerodromeV1Gauge(gauge).deposit(balance);
        }
    }
}
```

### Key Points: Aerodrome V1

1. **Adding to stake**: Just call `deposit(amount)` - accumulates automatically
2. **Partial withdrawals**: Call `withdraw(amount)` for any amount up to balance
3. **No unstake dance**: Modify stake freely without withdraw/re-deposit cycles
4. **Gauge lifecycle**: Gauges can be killed/revived - handle gracefully

---

## Slipstream Gauges (ERC-721 NFT)

### Architecture

```
User creates position → NFT Manager mints ERC-721 → Gauge takes custody of NFT

┌──────────┐    ┌──────────────────────┐    ┌──────────┐
│  Tokens  │───►│ NonfungiblePosition  │───►│ CLGauge  │
│(WETH+USDC)│    │      Manager         │    │(staking) │
└──────────┘    │   (mints NFT)        │    └──────────┘
                └──────────────────────┘          │
                         │                        ▼
                         │                  AERO emissions
                         │                  by liquidity weight
                         └───────────────────────────┘
                              NFT represents position
                              with specific tick range
```

### Key Difference: NFT Custody

When staked, the **gauge owns the NFT**. You cannot modify the position without unstaking first.

### Gauge Interface

```solidity
interface ISlipstreamGauge {
    /// @notice Stake an NFT position - gauge takes custody
    /// @param tokenId The NFT tokenId to stake
    function deposit(uint256 tokenId) external;

    /// @notice Unstake an NFT position - returns NFT to caller
    /// @param tokenId The NFT tokenId to unstake
    function withdraw(uint256 tokenId) external;

    /// @notice Claim AERO rewards for a specific position
    /// @param tokenId The NFT tokenId to claim for
    /// @return Amount of AERO claimed
    function getReward(uint256 tokenId) external returns (uint256);

    /// @notice Get all staked tokenIds for an address
    function stakedValues(address owner) external view returns (uint256[] memory);

    /// @notice Check if tokenId is staked by owner
    function stakedContains(address owner, uint256 tokenId) external view returns (bool);

    /// @notice Get depositor of a tokenId
    function stakedByIndex(uint256 tokenId) external view returns (address);

    /// @notice Pending rewards for a position
    function earned(uint256 tokenId) external view returns (uint256);

    /// @notice Total liquidity staked (not count of NFTs)
    function totalSupply() external view returns (uint256);

    /// @notice AERO per second
    function rewardRate() external view returns (uint256);
}
```

### Unstaked Fee Mechanism

Slipstream charges an **additional fee** when trading against unstaked liquidity:

```solidity
// Total swap fee = baseFee + (unstakedFee × unstakedLiquidityRatio)
//
// Example:
// - Base fee: 0.05%
// - Unstaked fee: 0.05%
// - 30% of liquidity is unstaked
// - Effective fee: 0.05% + (0.05% × 0.30) = 0.065%

// SlipstreamUtils has overloads for this:
function _quoteExactOutputSingle(
    uint256 amountOut,
    uint160 sqrtPriceX96,
    uint128 liquidity,
    uint24 feePips,
    uint24 unstakedFeePips,  // Additional fee for unstaked liquidity
    bool zeroForOne
) internal pure returns (uint256 amountIn);
```

### Vault Implementation Pattern

```solidity
contract SlipstreamVault is ERC20 {
    IVoter public immutable voter;
    INonfungiblePositionManager public immutable nftManager;
    ICLPool public immutable pool;
    address public gauge;

    // Track deposited NFTs
    mapping(uint256 tokenId => address depositor) public tokenDepositors;
    uint256[] public depositedTokenIds;

    // ─────────────────────────────────────────────────────────
    // CRITICAL: Modification requires unstake/re-stake
    // ─────────────────────────────────────────────────────────

    /// @notice Add liquidity to a staked position
    /// @dev MUST unstake → modify → re-stake
    function addLiquidity(
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    ) external {
        require(tokenDepositors[tokenId] == msg.sender, "Not your position");

        // Step 1: Unstake (claim rewards first)
        bool wasStaked = _isStakedInGauge(tokenId);
        if (wasStaked) {
            ISlipstreamGauge(gauge).getReward(tokenId);
            ISlipstreamGauge(gauge).withdraw(tokenId);
        }

        // Step 2: Modify position (now vault owns NFT again)
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);
        token0.approve(address(nftManager), amount0);
        token1.approve(address(nftManager), amount1);

        nftManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: tokenId,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        }));

        // Step 3: Re-stake
        if (wasStaked && isGaugeActive()) {
            nftManager.approve(gauge, tokenId);
            ISlipstreamGauge(gauge).deposit(tokenId);
        }
    }

    /// @notice Remove liquidity from a staked position
    /// @dev MUST unstake → modify → re-stake
    function removeLiquidity(
        uint256 tokenId,
        uint128 liquidityToRemove
    ) external returns (uint256 amount0, uint256 amount1) {
        require(tokenDepositors[tokenId] == msg.sender, "Not your position");

        // Step 1: Unstake
        bool wasStaked = _isStakedInGauge(tokenId);
        if (wasStaked) {
            ISlipstreamGauge(gauge).getReward(tokenId);
            ISlipstreamGauge(gauge).withdraw(tokenId);
        }

        // Step 2: Remove liquidity
        (amount0, amount1) = nftManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidityToRemove,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        // Step 3: Collect tokens
        nftManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: msg.sender,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        }));

        // Step 4: Re-stake (if position still has liquidity)
        (,,,,,,,uint128 remainingLiquidity,,,,) = nftManager.positions(tokenId);
        if (wasStaked && isGaugeActive() && remainingLiquidity > 0) {
            nftManager.approve(gauge, tokenId);
            ISlipstreamGauge(gauge).deposit(tokenId);
        }
    }

    // ─────────────────────────────────────────────────────────
    // Deposit / Withdraw NFTs
    // ─────────────────────────────────────────────────────────

    /// @notice Deposit existing NFT position
    function depositNFT(uint256 tokenId) external {
        // Verify position is for our pool
        _validatePosition(tokenId);

        // Transfer NFT to vault
        nftManager.transferFrom(msg.sender, address(this), tokenId);
        tokenDepositors[tokenId] = msg.sender;
        depositedTokenIds.push(tokenId);

        // Auto-stake if gauge active
        if (isGaugeActive()) {
            nftManager.approve(gauge, tokenId);
            ISlipstreamGauge(gauge).deposit(tokenId);
        }
    }

    /// @notice Withdraw NFT - MUST withdraw entire position
    function withdrawNFT(uint256 tokenId) external {
        require(tokenDepositors[tokenId] == msg.sender, "Not your position");

        // Unstake if staked (claim rewards)
        if (_isStakedInGauge(tokenId)) {
            ISlipstreamGauge(gauge).getReward(tokenId);
            ISlipstreamGauge(gauge).withdraw(tokenId);
        }

        // Transfer NFT back
        nftManager.transferFrom(address(this), msg.sender, tokenId);

        delete tokenDepositors[tokenId];
        _removeFromArray(tokenId);
    }

    // ─────────────────────────────────────────────────────────
    // Rewards - can claim without unstaking
    // ─────────────────────────────────────────────────────────

    function claimRewards(uint256 tokenId) external returns (uint256) {
        if (!_isStakedInGauge(tokenId)) return 0;
        return ISlipstreamGauge(gauge).getReward(tokenId);
    }

    function claimAllRewards() external returns (uint256 total) {
        for (uint256 i = 0; i < depositedTokenIds.length; i++) {
            uint256 tokenId = depositedTokenIds[i];
            if (_isStakedInGauge(tokenId)) {
                total += ISlipstreamGauge(gauge).getReward(tokenId);
            }
        }
    }

    // ─────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────

    function _isStakedInGauge(uint256 tokenId) internal view returns (bool) {
        if (!isGaugeActive()) return false;
        return ISlipstreamGauge(gauge).stakedContains(address(this), tokenId);
    }

    function isGaugeActive() public view returns (bool) {
        return gauge != address(0) && voter.isAlive(gauge);
    }
}
```

### Key Points: Slipstream

1. **NFT custody**: Gauge owns the NFT while staked
2. **No partial operations**: Must withdraw entire NFT, cannot split
3. **Modification requires dance**: Unstake → modify → re-stake (3 steps)
4. **Rewards by tokenId**: Must claim per position, not per address
5. **Unstaked fee**: Additional trading fee on unstaked liquidity

### Gas Costs for Slipstream Operations

| Operation | Approximate Gas |
|-----------|-----------------|
| `gauge.deposit(tokenId)` | ~150k |
| `gauge.withdraw(tokenId)` | ~80k |
| `gauge.getReward(tokenId)` | ~50k |
| `nftManager.increaseLiquidity()` | ~150k |
| `nftManager.decreaseLiquidity()` | ~120k |
| `nftManager.collect()` | ~80k |
| **Full rebalance cycle** | ~800k-900k |

---

## Balancer V3 Gauges (ERC-20 BPT)

### Architecture

Balancer uses the same ve-tokenomics model as Aerodrome, with ERC-20 BPT (Balancer Pool Token):

```
User deposits tokens → Vault adds liquidity → Pool mints BPT → Gauge stakes BPT

┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Tokens  │───►│  Vault   │───►│   Pool   │───►│  Gauge   │
│          │    │(router)  │    │(BPT mint)│    │(staking) │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                                      │               │
                                      │               ▼
                                      │         BAL emissions
                                      └────────►+ extra rewards
```

### Gauge Interface

```solidity
interface IBalancerGauge {
    /// @notice Deposit BPT - adds to existing stake
    function deposit(uint256 amount) external;
    function deposit(uint256 amount, address recipient) external;

    /// @notice Withdraw BPT - partial OK
    function withdraw(uint256 amount) external;

    /// @notice Claim all reward tokens
    function claim_rewards() external;
    function claim_rewards(address addr) external;

    /// @notice Check staked balance
    function balanceOf(address addr) external view returns (uint256);

    /// @notice Check claimable amount for a specific reward token
    function claimable_reward(address user, address token) external view returns (uint256);

    /// @notice Total staked
    function totalSupply() external view returns (uint256);

    /// @notice List of reward tokens
    function reward_tokens(uint256 index) external view returns (address);
    function reward_count() external view returns (uint256);
}
```

### Vault Implementation Pattern

```solidity
contract BalancerV3Vault is ERC20 {
    IBalancerVault public immutable balancerVault;
    IBalancerGauge public gauge;
    IERC20 public immutable bpt;

    function deposit(uint256 bptAmount) external returns (uint256 shares) {
        bpt.transferFrom(msg.sender, address(this), bptAmount);

        // Just deposit - adds to existing stake (like Aerodrome V1)
        if (address(gauge) != address(0)) {
            bpt.approve(address(gauge), bptAmount);
            gauge.deposit(bptAmount);
        }

        shares = _calculateShares(bptAmount);
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 shares) external returns (uint256 bptAmount) {
        bptAmount = _calculateBptAmount(shares);
        _burn(msg.sender, shares);

        // Partial withdrawal OK (like Aerodrome V1)
        if (address(gauge) != address(0)) {
            gauge.withdraw(bptAmount);
        }

        bpt.transfer(msg.sender, bptAmount);
    }

    function claimRewards() external {
        if (address(gauge) != address(0)) {
            gauge.claim_rewards();
        }
    }
}
```

### Key Points: Balancer V3

1. **Identical to Aerodrome V1**: ERC-20 tokens, flexible staking
2. **Multi-reward**: Gauges can distribute multiple tokens (BAL + extras)
3. **Boost mechanism**: More veBAL = higher APR (up to 2.5x)
4. **No unstake dance**: Add/remove freely

---

## Uniswap: No Native Gauges

### Overview

Uniswap has **no built-in gauge system**. LPs earn only trading fees.

| Version | LP Token | Native Rewards |
|---------|----------|----------------|
| V2 | ERC-20 | Trading fees only |
| V3 | ERC-721 NFT | Trading fees only |
| V4 | ERC-6909 | Trading fees only |

### Third-Party Solutions

#### Merkl (Angle Protocol)

Off-chain reward distribution for Uniswap V3 positions:

```solidity
interface IMerkl {
    function claim(
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external;
}

// Projects deposit incentives → Merkl distributes via merkle proofs
```

#### MasterChef-style (for V2)

Traditional staking contract pattern:

```solidity
interface IMasterChef {
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function pendingReward(uint256 pid, address user) external view returns (uint256);
}
```

### Vault Design for Uniswap

```solidity
contract UniswapV3Vault {
    // No native gauge - just manage positions
    // Optionally integrate Merkl for incentives

    function claimMerklRewards(
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external {
        merkl.claim([address(this)], tokens, amounts, proofs);
        // Distribute to vault depositors
    }
}
```

---

## Gauge Lifecycle Management

### States

```
┌────────────┐     ┌────────────┐     ┌────────────┐
│  No Gauge  │────►│   Active   │────►│   Killed   │
│            │     │            │     │            │
└────────────┘     └────────────┘     └────────────┘
      │                  │                  │
      │                  │                  │
      │                  │                  ▼
      │                  │           ┌────────────┐
      │                  └──────────►│  Revived   │
      │                              │            │
      │                              └────────────┘
      │                                    │
      └────────────────────────────────────┘
             (gauge created later)
```

### Checking Gauge Status

```solidity
function getGaugeStatus(address pool) public view returns (
    bool exists,
    bool isActive,
    address gaugeAddress
) {
    gaugeAddress = voter.gauges(pool);
    exists = gaugeAddress != address(0);
    isActive = exists && voter.isAlive(gaugeAddress);
}
```

### Handling Lifecycle Events

```solidity
contract LifecycleAwareVault {
    event GaugeAdopted(address indexed gauge);
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);

    /// @notice Adopt newly created gauge
    function adoptGauge() external {
        require(gauge == address(0), "Already has gauge");
        address newGauge = voter.gauges(address(pool));
        require(newGauge != address(0) && voter.isAlive(newGauge), "No active gauge");

        gauge = newGauge;
        _stakeAllAssets();
        emit GaugeAdopted(newGauge);
    }

    /// @notice Handle gauge being killed
    function handleKilledGauge() external {
        require(gauge != address(0) && !voter.isAlive(gauge), "Gauge still alive");
        _unstakeAllAssets();
        emit GaugeKilled(gauge);
    }

    /// @notice Handle gauge revival
    function handleRevivedGauge() external {
        require(gauge != address(0) && voter.isAlive(gauge), "Gauge not alive");
        _stakeAllAssets();
        emit GaugeRevived(gauge);
    }
}
```

---

## Factory Pattern for Multi-Protocol Support

```solidity
contract UniversalVaultFactory {
    IVoter public aerodromeVoter;
    IGaugeController public balancerGaugeController;

    enum Protocol { AerodromeV1, Slipstream, BalancerV3, UniswapV2, UniswapV3 }

    struct PoolInfo {
        address pool;
        Protocol protocol;
        address gauge;
        bool gaugeActive;
        bool supportsPartialWithdraw;
        bool supportsAddToStake;
    }

    function getPoolInfo(address pool, Protocol protocol) public view returns (PoolInfo memory info) {
        info.pool = pool;
        info.protocol = protocol;

        if (protocol == Protocol.AerodromeV1 || protocol == Protocol.Slipstream) {
            info.gauge = aerodromeVoter.gauges(pool);
            info.gaugeActive = info.gauge != address(0) && aerodromeVoter.isAlive(info.gauge);
        } else if (protocol == Protocol.BalancerV3) {
            info.gauge = balancerGaugeController.gauges(pool);
            info.gaugeActive = info.gauge != address(0);
        }
        // Uniswap: no native gauge

        // Set capabilities
        info.supportsPartialWithdraw = (protocol != Protocol.Slipstream);
        info.supportsAddToStake = (protocol != Protocol.Slipstream);
    }

    function createVault(address pool, Protocol protocol) external returns (address vault) {
        PoolInfo memory info = getPoolInfo(pool, protocol);

        if (protocol == Protocol.AerodromeV1) {
            vault = address(new AerodromeV1Vault(pool, info.gauge));
        } else if (protocol == Protocol.Slipstream) {
            vault = address(new SlipstreamVault(pool, info.gauge));
        } else if (protocol == Protocol.BalancerV3) {
            vault = address(new BalancerV3Vault(pool, info.gauge));
        } else {
            vault = address(new UniswapVault(pool));  // No gauge
        }
    }
}
```

---

## Summary: Quick Decision Guide

### Can I add to a staked position without unstaking?

| Protocol | Answer |
|----------|--------|
| Aerodrome V1 | **Yes** - just call `deposit(amount)` |
| Slipstream | **No** - must unstake → modify → re-stake |
| Balancer V3 | **Yes** - just call `deposit(amount)` |
| Uniswap | N/A - no native staking |

### Can I do partial withdrawals?

| Protocol | Answer |
|----------|--------|
| Aerodrome V1 | **Yes** - call `withdraw(anyAmount)` |
| Slipstream | **No** - must withdraw entire NFT |
| Balancer V3 | **Yes** - call `withdraw(anyAmount)` |
| Uniswap | N/A - no native staking |

### How do I check if a gauge exists?

```solidity
// Aerodrome (V1 + Slipstream)
address gauge = voter.gauges(pool);
bool active = gauge != address(0) && voter.isAlive(gauge);

// Balancer V3
address gauge = gaugeController.gauges(pool);
bool active = gauge != address(0);

// Uniswap
// No native gauges - check third-party integrations
```

---

## Contract Addresses

### Base Mainnet

| Contract | Address |
|----------|---------|
| Aerodrome Voter | `0x16613524e02ad97eDfeF371bC883F2F5d6C480A5` |
| Aerodrome VotingEscrow | `0xeBf418Fe2512e7E6bd9b87a8F0f294aCDC67e6B4` |
| AERO Token | `0x940181a94A35A4569E4529A3CDfB74e38FD98631` |
| Slipstream NFT Manager | `0x827922686190790b37229fd06084350E74485b72` |

### Ethereum Mainnet

| Contract | Address |
|----------|---------|
| Balancer Vault | `0xBA12222222228d8Ba445958a75a0704d566BF2C8` |
| Balancer Gauge Controller | `0xC128468b7Ce63eA702C1f104D55A2566b13D3ABD` |
| veBAL | `0xC128a9954e6c874eA3d62ce62B468bA073093F25` |

---

## References

- [Aerodrome Documentation](https://aerodrome.finance/docs)
- [Balancer V3 Documentation](https://docs.balancer.fi/)
- [Uniswap V3 Documentation](https://docs.uniswap.org/)
- [Merkl Documentation](https://docs.merkl.xyz/)
