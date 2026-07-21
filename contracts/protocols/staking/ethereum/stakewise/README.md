# StakeWise V3 (integration port)

| Item | Value |
|------|-------|
| Upstream pin | stakewise/v3-core (interfaces + Service) |
| osETH | `0xf1C9acDc66974dFB6dEcB12aA385b9cD01190E38` |
| OsTokenVaultController | `0x2A261e60FB14586B474C208b1B7AC6D0f5000306` |
| Genesis EthVault (verify) | see fork TestBase constants |

## Surface

- `IEthVault`, `IOsETH`, `IOsTokenVaultController`
- `StakeWiseService` — vault deposit/redeem, osETH rate
- `OsETHRateProvider`

## Deferred

Vault factory governance, private vault whitelist operators, full upgradeable domain vendor.
