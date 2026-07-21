# ether.fi (integration + domain vendor)

| Item | Value |
|------|-------|
| Upstream | `etherfi-protocol/smart-contracts` |
| **Pinned commit** | `b4a0968087b178bc346cdf6bee6c0597bf4c42c7` |
| Domain vendor path | `contracts/external/etherfi/` |
| Domain surface | `core/WeETH.sol` + wrap deps (no EigenLayer/Uni/LZ) |
| eETH | `0x35fA164735182de50811E8e2E824cFb9B6118ac2` |
| weETH | `0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee` |
| LiquidityPool | `0x308861A430be4cce5502d0A12724771Fc6DaF216` |

## Cuts
- EigenLayer restaking, Uniswap V3 periphery, LayerZero bridge **not vendored**
- OZ v5 adaptations: `_update` hook (was `_before/_afterTokenTransfer`), `ERC1967Utils.getImplementation`

## Surface
- Interfaces + `EtherFiService` + `WeETHRateProvider`

## D2-FULL vendor
Full upstream Solidity tree under `contracts/external/` — see `VENDOR.md` there. Prior mint/wrap slice superseded.
