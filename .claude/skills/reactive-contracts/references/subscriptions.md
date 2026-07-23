# Event Subscriptions

Source: https://dev.reactive.network/subscriptions

## API

```solidity
SYSTEM.subscribe(
    uint256 chainId_,
    address contract_,
    uint256 topic0_,
    uint256 topic1_,
    uint256 topic2_,
    uint256 topic3_
);

SYSTEM.unsubscribe(
    uint256 chainId_,
    address contract_,
    uint256 topic0_,
    uint256 topic1_,
    uint256 topic2_,
    uint256 topic3_
);
```

When a match is found, the system contract calls `react(LogRecord)`.

## Wildcards

| Parameter | Wildcard | Meaning |
|-----------|----------|---------|
| topic0–3 | `REACTIVE_IGNORE` | any topic value |
| chainId | `uint256(0)` | any chain |
| contract | `address(0)` | any contract |

`REACTIVE_IGNORE` value (docs):

```text
0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad
```

**Rule:** at least one criterion must be non-wildcard. Global “all events on all chains” is not allowed.

## Examples

### All events from one contract

```solidity
SYSTEM.subscribe(
    CHAIN_ID,
    0x7E0987E5b3a30e3f2828572Bb659A548460a3003,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE
);
```

### Specific event type, any contract (Uniswap V2 Sync)

```solidity
// topic0 = Sync(uint112,uint112)
SYSTEM.subscribe(
    CHAIN_ID,
    address(0),
    0x1c411e9a96e071241c2f21f7726b17ae89e3cab4c78be50e062b03a9fffbbad1,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE
);
```

### Specific contract + event

```solidity
SYSTEM.subscribe(
    CHAIN_ID,
    0x7E0987E5b3a30e3f2828572Bb659A548460a3003,
    0x1c411e9a96e071241c2f21f7726b17ae89e3cab4c78be50e062b03a9fffbbad1,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE
);
```

### Multiple subscriptions

Call `subscribe()` once per criteria set (OR via multiple registrations).

## Dynamic subscribe / unsubscribe

From [Xfers micro-demo](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/omni/src/micro-demos/Xfers.sol) (docs quote pattern):

- Constructor sets limit and `_sub()` to Sepolia ERC-20 `Transfer` topic0.
- Each `react` decrements limit; at zero calls `_unsub()`.
- `updateLimit` may `_coverDebt()` then `_sub()` again.

```solidity
uint256 private constant SEPOLIA_CHAIN_ID = 11155111;
uint256 private constant ERC20_TRANSFER_TOPIC_0 =
    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
```

## Limitations

1. **Equality only** — no range or bitwise filters.
2. **One criteria set per subscribe** — no in-filter OR.
3. **No fully global subscriptions**.
4. **Duplicate subscriptions** — allowed, behave as one, still pay gas per call.

## Dual-state caveat

If using legacy ReactVM dual deployment, subscription calls from inside ReactVM do nothing — manage on the RNK instance (`skill:reactive-architecture`).
