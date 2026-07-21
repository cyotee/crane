# StakeWise V3 (integration + domain vendor)

| Item | Value |
|------|-------|
| Upstream | `stakewise/v3-core` |
| **Pinned commit** | `fc70cbe1b3d41bc5f78434830d837aa270ca33bc` |
| Domain vendor path | `contracts/external/stakewise/` |
| Domain surface | `OsToken.sol`, `OsTokenVaultController.sol` (+ interfaces/Errors) |
| osETH mainnet | `0xf1C9acDc66974dFB6dEcB12aA385b9cD01190E38` |
| OsTokenVaultController | `0x2A261e60FB14586B474C208b1B7AC6D0f5000306` |

## Surface
- Canonical interfaces under `staking/ethereum/stakewise/interfaces/`
- `StakeWiseService` + `OsETHRateProvider`
- Domain mint/burn of osETH via vendored `OsToken`

## Deferred
Full EthVault module tree, private vault operators, Gnosis vaults.

## D2-FULL vendor
Full upstream Solidity tree under `contracts/external/` — see `VENDOR.md` there. Prior mint/wrap slice superseded.
