# Lido (integration + domain vendor)

| Item | Value |
|------|-------|
| Upstream | `lidofinance/core` |
| **Pinned commit** | `372b02e197df61fdf1a443de18acb514804b828d` |
| Domain vendor path | `contracts/external/lido/` |
| Domain surface | `WstETH.sol` (wrap/unwrap) + `IStETH.sol`; upstream 0.6.12 source kept as `WstETH.upstream.sol.txt` |
| stETH | `0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84` |
| wstETH | `0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0` |

## Cuts
- Full Aragon DAO / AccountingOracle / WithdrawalQueue **not vendored**
- StETH 0.4.24 core kept as provenance `.txt` only (pragma era); live stETH exercised via mainnet fork Services
- WstETH adapted to Solidity 0.8 + Crane OZ ERC20Permit; wrap/unwrap math from upstream

## Surface
- `IStETH`/`IWstETH` + `LidoService` + `WstETHRateProvider`

## D2-FULL vendor
Full upstream Solidity tree under `contracts/external/` — see `VENDOR.md` there. Prior mint/wrap slice superseded.
