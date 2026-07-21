# Rocket Pool (integration port)

| Item | Value |
|------|-------|
| Upstream pin | rocket-pool/rocketpool (deposit/rate surface) |
| rETH | `0xae78736Cd615f374D3085123A210448E74Fc6393` |
| RocketStorage | `0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46` |

## Surface

- `IRETH`, `IRocketDepositPool`, `IRocketStorage`
- `RocketPoolService` — deposit (capacity-checked), burn, exchange rate
- `RETHRateProvider`

## Notes

Deposit reverts when the deposit pool has no capacity (`getMaximumDepositAmount`). Fork tests assert rate > 0 always and deposit only when capacity allows.

## Deferred

Minipool / RPL / network balances full domain vendor.
