# Camelot V2 Pool Lifecycle & Architecture Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Deployment & Initialization Flow](#deployment--initialization-flow)
4. [Pool Lifecycle](#pool-lifecycle)
5. [Special Features & Notes](#special-features--notes)
6. [References](#references)

---

## Introduction

This guide provides a comprehensive overview of the Camelot V2 implementation in the Crane framework. It covers the core architecture, deployment flow, and the lifecycle of a liquidity pool, including adding/removing liquidity, swaps, and unique Camelot features.

---

## Architecture Overview

- **Factory (`CamelotFactory`)**: Deploys and tracks all pairs. Responsible for creating new pools for token pairs and managing fee/owner controls.
- **Pair (`CamelotPair`)**: The core AMM contract. Holds reserves, manages swaps, issues LP tokens, and supports both stable and volatile pairs.
- **Router (`CamelotRouter`)**: User-facing contract for adding/removing liquidity and performing swaps. Handles ETH wrapping/unwrapping and multi-hop routes.
- **ERC20 (`UniswapV2ERC20`)**: LP tokens are ERC20-compliant and represent a share of the pool.

**Contract Relationships:**

```text
CamelotFactory
  └── deploys CamelotPair(s)
CamelotRouter
  └── interacts with CamelotPair(s) via the Factory
Users
  └── interact with Router for all pool operations
```

---

## Deployment & Initialization Flow

1. **Factory Deployment**: Deploy the `CamelotFactory` contract.
2. **Pair Creation**: Call `createPair(tokenA, tokenB)` on the Factory. This deploys a new `CamelotPair` contract for the token pair.
3. **Pair Initialization**: The Pair contract is initialized with the two token addresses and sets up LP token metadata and precision multipliers.
4. **Router Deployment**: Deploy the `CamelotRouter` contract, passing the Factory and WETH addresses.

---

## Pool Lifecycle

### 1. Add Liquidity

- User calls `addLiquidity` or `addLiquidityETH` on the Router.
- Router transfers tokens to the Pair contract.
- Pair mints LP tokens to the user, representing their share.

### 2. Swap

- User calls `swapExactTokensForTokens` (or similar) on the Router.
- Router calculates optimal path and interacts with the Pair(s).
- Pair updates reserves and transfers output tokens to the user.

### 3. Remove Liquidity

- User calls `removeLiquidity` or `removeLiquidityETH` on the Router.
- Router transfers LP tokens to the Pair contract.
- Pair burns LP tokens and returns the underlying assets to the user.

### 4. Stable/Volatile Toggle

- Owner can toggle a pair between stable and volatile modes (if not immutable) via the Pair contract, affecting swap math and fee logic.

---

## Special Features & Notes

- **Fee Flexibility**: Each pair can have independent fee settings for token0 and token1, up to a maximum.
- **Stable/Volatile Pairs**: Pairs can be toggled between stable and volatile modes, with different swap math and fee logic.
- **Owner Controls**: Factory owner can set fees, toggle stable/volatile, and make pair type immutable.
- **Precision Multipliers**: Each token's decimals are handled via precision multipliers for accurate math.
- **Reentrancy Protection**: Pair contract uses a lock modifier to prevent reentrancy.
- **Math Libraries**: Uses `SafeMath` and custom libraries for precision and safety.

---

## References

- [Camelot V2 Core Docs](https://docs.camelot.exchange/)
- [Crane Camelot V2 Contracts](../../../contracts/protocols/dexes/camelot/v2/)
- [Crane Camelot V2 Testing Guide](camelot-v2-testing-guide.md) 