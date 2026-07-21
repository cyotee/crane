# Lido (integration port)

| Item | Value |
|------|-------|
| Upstream pin | lidofinance/core (interfaces only; no Aragon vendor) |
| stETH | `0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84` |
| wstETH | `0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0` |

## Surface

- `IStETH` / `IWstETH` — canonical mint/wrap
- `LidoService` — submit, wrap, unwrap, submitAndWrap
- `WstETHRateProvider` — `getRate()` = `stEthPerToken()`

## Deferred

Aragon OS / apps, AccountingOracle, WithdrawalQueue, VaultHub, DSM, full domain vendor.
Pendle/Liquity `IWstETH` import cleanup is a follow-on.
