# Uniswap V2 Pool Lifecycle & Architecture Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Deployment & Initialization Flow](#deployment--initialization-flow)
4. [Pool Lifecycle](#pool-lifecycle)
5. [Special Features & Notes](#special-features--notes)
6. [References](#references)

---

## Introduction

This guide provides a comprehensive overview of the Uniswap V2 implementation in the Crane framework. It covers the core architecture, deployment flow, and the lifecycle of a liquidity pool, including adding/removing liquidity and swaps.

---

## Architecture Overview

- **Factory (`UniV2Factory`)**: Deploys and tracks all pairs. Responsible for creating new pools for token pairs.
- **Pair (`UniV2Pair`)**: The core AMM contract. Holds reserves, manages swaps, and issues LP tokens.
- **Router (`UniV2Router02`)**: User-facing contract for adding/removing liquidity and performing swaps. Handles ETH wrapping/unwrapping and multi-hop routes.
- **ERC20 (`BetterERC20`)**: LP tokens are ERC20-compliant and represent a share of the pool.

**Contract Relationships:**

```text
UniV2Factory
  └── deploys UniV2Pair(s)
UniV2Router02
  └── interacts with UniV2Pair(s) via the Factory
Users
  └── interact with Router for all pool operations
```

---

## Deployment & Initialization Flow

1. **Factory Deployment**: Deploy the `UniV2Factory` contract.
2. **Pair Creation**: Call `createPair(tokenA, tokenB)` on the Factory. This deploys a new `UniV2Pair` contract for the token pair.
3. **Pair Initialization**: The Pair contract is initialized with the two token addresses and sets up LP token metadata.
4. **Router Deployment**: Deploy the `UniV2Router02` contract, passing the Factory and WETH addresses.

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

---

## Special Features & Notes

- **Permit Support**: LP tokens support EIP-2612 permits for gasless approvals.
- **Fee-on-Transfer Support**: The Router includes functions to support tokens with transfer fees.
- **Reentrancy Protection**: Pair contract uses a lock modifier to prevent reentrancy.
- **Math Libraries**: Uses `SafeMath`, `UQ112x112`, and custom libraries for precision and safety.

---

## References

- [Uniswap V2 Core Docs](https://docs.uniswap.org/contracts/v2)
- [Uniswap V2 Router Docs](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02)
- [Crane Uniswap V2 Contracts](../../../contracts/protocols/dexes/uniswap/v2/)
- [Crane Uniswap V2 Testing Guide](uniswap-v2-testing-guide.md) 