# Rocket Pool (integration + domain vendor)

| Item | Value |
|------|-------|
| Upstream | `rocket-pool/rocketpool` |
| **Pinned commit** | `fef41a4f7cf99d7d66313c0ba04deb8ba2dabf88` |
| Domain vendor path | `contracts/external/rocketpool/` |
| Domain surface | `RocketStorage` + `RocketBase` + `RocketTokenRETH` + `RocketDepositPool` (deposit→mint, exchange-rate formulas, `onlyLatestContract` mint gate) |
| rETH mainnet | `0xae78736Cd615f374D3085123A210448E74Fc6393` |
| RocketStorage mainnet | `0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46` |

## Structure (upstream-aligned)

- Address book via `keccak256(abi.encodePacked("contract.address", name))` (same key layout as upstream)
- rETH mint only from registered `rocketDepositPool`
- Rate: `getEthValue` / `getRethValue` / `getExchangeRate` read `rocketNetworkBalances` (upstream formulas)
- Deposit path: settings gates (enabled, min, max pool size, fee) → mint net amount

## Cuts

- Full minipool/megapool assignment, RocketVault accounting, node credit queues, RPL auction recycle **not** vendored
- Upstream `.sol` snapshots kept as `*.upstream.sol.txt` where useful

## Surface

- Integration interfaces + `RocketPoolService` + `RETHRateProvider` (mainnet fork)
- Domain unit tests under `RocketTokenRETH_Domain.t.sol`

## D2-FULL vendor
Full upstream Solidity tree under `contracts/external/` — see `VENDOR.md` there. Prior mint/wrap slice superseded.
