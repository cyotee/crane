# ether.fi (integration port)

| Item | Value |
|------|-------|
| Upstream pin | etherfi-protocol/smart-contracts (mint/wrap subgraph only) |
| eETH | `0x35fA164735182de50811E8e2E824cFb9B6118ac2` |
| weETH | `0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee` |
| LiquidityPool | `0x308861A430be4cce5502d0A12724771Fc6DaF216` |

## Surface

- `IEETH`, `IWeETH`, `IEtherFiLiquidityPool`
- `EtherFiService` — deposit, wrap, unwrap, depositAndWrap
- `WeETHRateProvider`

## Deferred

EigenLayer AVS stack, Uniswap V3 periphery, LayerZero weETH bridge, BNFT/TNFT operator trees.
