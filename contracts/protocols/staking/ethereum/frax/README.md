# FraxETH (thin staking port)

**Mode:** Thin wrappers only (D3). Bulk remains under `contracts/protocols/tokens/stable/frax/FraxETH/`.

| Item | Value |
|------|-------|
| Upstream | Frax monorepo (already in Crane) |
| frxETH | `0x5E8422345238F34275888049021821E8E08CAa1f` |
| frxETHMinter | `0xbAFA44EFE7901E04E39Dad13167D089C559c1138` |
| sfrxETH | `0xac3E018457B222d93114458476f3E3416Abbe38F` |

## Surface

- `services/FraxETHService.sol` — submit, submitAndDeposit, sfrx deposit/redeem + previews
- `rate/SfrxETHRateProvider.sol` — `getRate()` = `convertToAssets(1e18)`
- `interfaces/IFraxETH.sol` — re-exports of existing FraxETH interfaces

## Deferred

Full MiniRouter monorepo relocation, Curve pool adapters.
