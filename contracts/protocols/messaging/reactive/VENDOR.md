# reactive demos (Crane port)

| Item | Value |
|------|-------|
| Upstream demos | Reactive-Network/reactive-smart-contract-demos |
| Pin | `f1f85ab2a0a8f917b9b37a57c00be2ffc8ad5ad4` |
| SDK | `@crane/contracts/external/reactive` (from Reactive-Network/reactive-lib @ `f6990ce3526928d039fec78855b2004ff8d65c9f`) |
| Copy date | 2026-07-22 |
| License | Upstream mix of `GPL-2.0-or-later` and `UNLICENSED`; vendored under Fair Use / research clause |
| Scope | All 10 active demos under `src/demos/` (legacy demos not ported) |

## Layout

```
demos/
├── basic/
├── cron/
├── uniswap-v2-stop-order/
├── uniswap-v2-stop-take-profit-order/
├── approval-magic/
├── hyperlane/
├── aave-liquidation-protection/
├── leverage-loop/
├── automated-prediction-market/
└── gasless-cross-chain-atomic-swap/
```

## Import remaps

| Upstream | Crane |
|----------|--------|
| `lib/reactive-lib/src/...` | `@crane/contracts/external/reactive/...` |
| `lib/openzeppelin-contracts/...` / `@openzeppelin/contracts/...` | `@crane/contracts/external/openzeppelin-contracts/...` |
| `lib/v2-core/...` | `@crane/contracts/external/uniswap/v2-core/...` |
| `lib/v2-periphery/...` | `@crane/contracts/external/uniswap/v2-periphery/...` |
| Sibling `./RescuableBase.sol` etc. | unchanged (local) |

## Adaptations

- Faithful port of demo domain logic; no Diamond Service / Aware / DFPkg wrappers in this pass.
- Shared deps remapped to Crane `external/` (no private OZ or Uni trees under this package).
- Aave / Hyperlane surfaces remain as inline interfaces in the demos (as upstream).
- `uniswap-v2-stop-take-profit-order/UniswapDemoStopTakeProfitCallback.createStopOrder` split into helpers (`_assertPairLiquidity`, `_storeStopOrder`) to compile under Crane `viaIR=false` (stack-too-deep). Behavior unchanged.

## Out of scope (this pass)

- Crane Facet / Target / Repo / DFPkg productization
- `src/legacy/` demos from upstream
- Hermetic TestBase / fork suites (follow-up)
