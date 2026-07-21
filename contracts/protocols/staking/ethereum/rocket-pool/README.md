# Rocket Pool (integration + domain vendor)

| Item | Value |
|------|-------|
| Upstream | `rocket-pool/rocketpool` |
| **Pinned commit** | `fef41a4f7cf99d7d66313c0ba04deb8ba2dabf88` |
| Domain vendor path | `contracts/external/rocketpool/` |
| Domain surface | `token/RocketTokenRETH.sol`, `deposit/RocketDepositPool.sol`; full upstream sources as `*.upstream.sol.txt` |
| rETH mainnet | `0xae78736Cd615f374D3085123A210448E74Fc6393` |
| RocketStorage | `0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46` |

## Cuts
- Full minipool / RPL / network balances contracts **not** fully vendored (0.7.6 monorepo)
- Exchange-rate formulas (`getEthValue`/`getRethValue`/`getExchangeRate`) and deposit→mint path preserved from upstream
- Mainnet deposit pool capacity edge-case documented in fork tests

## Surface
- Interfaces + `RocketPoolService` + `RETHRateProvider`
