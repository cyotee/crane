# ConstProdUtils & Math

## ConstProdUtils

`ConstProdUtils` (`contracts/utils/math/ConstProdUtils.sol`) is Crane’s shared **constant-product AMM** math library. DEX ports and tests use it so quote/swap math is not reimplemented per protocol.

### Typical operations

- **Reserve sorting:** `_sortReserves` (with/without fee variants)
- **Liquidity:** mint amounts on deposit; burn/withdraw amounts on exit
- **Quotes:** `getPurchaseQuote` and overloads for exact-in/out with fees and price impact

Usage style (from framework conventions):

```solidity
using ConstProdUtils for uint256;

uint256 amountOut = amountIn.getPurchaseQuote(reserveIn, reserveOut);
```

### Who consumes it

- Camelot V2 services and utils
- Aerodrome / Uniswap V2-style paths
- Parity tests under `test/foundry/spec/utils/math/constProdUtils/` (e.g. purchase quote vs Camelot)

Protocol-specific quoters for concentrated liquidity (Uniswap V3/V4, Slipstream) live with those ports; still prefer shared helpers where math overlaps.

## Other math libraries

| Library | Role |
|---------|------|
| `BetterMath` | Wider math helpers (including large int support) |
| Fixed-point libs | WAD/ray-style fixed point where used |
| `SafeCast` / variants | Safe downcasts |

## Testing guidance

Prefer **exact** quote parity against protocol ports or live fork routers rather than approximate tolerances unless the port documents rounding differences. See [Testing Patterns](../development/testing.md) and [DEX Integrations](../protocols/dexes.md).

## See also

- [Utilities Overview](overview.md)
- [DEX Integrations](../protocols/dexes.md)
- [Testing Patterns](../development/testing.md)
- [Codebase Map](../CODEBASE_MAP.md)
