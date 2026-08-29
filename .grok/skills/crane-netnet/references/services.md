# NetNet Service + Aware API

## NetNetAwareRepo

- Slot: `bytes32(uint256(keccak256(abi.encode("protocols.pol.net.aware"))) - 1)`
- `_initialize(NetNetAwareInit)` and `_initialize(Storage, Init)`
- Fields: `usdg`, `net`, `sNet`, `staking`, `treasury`, `bondDepository`, `inverseBond`, `premiumSeller`, `taxCollector`, `pteam`, `canonicalPair`, `router`, `turboRouter`, `wsNet`, `zap`, `morpho`, `loopbackMarketId`, `morphoVault`, `pTeamHolder`
- Getter pair per field (`_net()`, `_net(Storage)`)

## NetNetSpotService

- `_buyNetWithUsdg(BuyParams)` — FoT router path `[usdg, net]`
- `_sellNetForUsdg(SellParams)` — FoT router path `[net, usdg]`
- `_convert(ConvertParams)` — `ITaxCollector.convert`

`BuyParams` / `SellParams`: `router`, `tokenIn`, `tokenOut`, `amountIn`, `amountOutMin`, `to`, `deadline`.

## NetNetStakingService

- `_stake(StakeParams)` → `IStaking.stake`
- `_unstake(UnstakeParams)` → `IStaking.unstake`
- `_rebase(IStaking)`

## NetNetBondService

- `_deposit` / `_redeem` — P0 tests use `marketId == 0`
- `_inverseSwap` / `_premiumExecute` / `_exercisePTeam`

## NetNetTurboService

- `_setMorphoAuthorization` → `IMorpho.setAuthorization`
- `_turbo(wsIn, borrowAssets, minWsFromLoop)` (struct also carries `wsNet` for approve)
- `_unwind(repayShares, wsCollateralOut, minUsdgFromSale)`

Exact files: `contracts/protocols/pol/net/services/NetNet*Service.sol`, `aware/NetNetAwareRepo.sol`.
