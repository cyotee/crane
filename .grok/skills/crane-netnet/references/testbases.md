# NetNet TestBases

## TestBase_NetNet (hermetic)

Path: `contracts/protocols/pol/net/test/bases/TestBase_NetNet.sol`

- Inherits `TestBase_UniswapV2` only (not `TestBase_MorphoBlue`).
- Deploys `Morpho(address(this))`, `AdaptiveCurveIrm`, `VaultV2(address(this), usdg)`.
- USDG: `NetNetUsdg` (6 decimals, mintable).
- Creates Crane Uni V2 NET/USDG pair **before** Treasury / GenesisBond.
- `wire()` every `Wired` contract, then 8 founders buy `2_000e6` USDG each, warp past `GENESIS_DEADLINE`, `genesisBond.finalize()`.
- Two extra oracle checkpoints (`CHECKPOINT_MIN_INTERVAL`, `TWAP_MIN_WINDOW`).
- Enables IRM + LLTV, `createMarket` wsNET/USDG with `LoopbackOracle`, supplies USDG credit.
- `NetNetAwareRepo._initialize` with deployed addresses.
- Helpers: `_buyNet`, `_sellNet`, `_crashTwapBelowBacking`, `_liftTwapAbovePremium`.

## TestBase_NetNetFork

Path: `contracts/protocols/pol/net/test/bases/TestBase_NetNetFork.sol`

- `vm.createSelectFork(vm.rpcUrl("robinhood_mainnet"), ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK)`
- Binds `NET`, `SNET`, `NETNET_*`, `USDG`, Uni V2 router/factory, `MORPHO`, `NETNET_STEAK_USDG`.
- Same `_initialize` with live addresses.

## Behaviors

Eight `Behavior_I*` files under `contracts/protocols/pol/net/test/bases/` matching dumped interfaces (`Behavior_INET`, `Behavior_IStaking`, `Behavior_IBondDepository`, `Behavior_IInverseBond`, `Behavior_IPremiumSeller`, `Behavior_ITaxCollector`, `Behavior_IPTEAM`, `Behavior_ITurboRouter`).
