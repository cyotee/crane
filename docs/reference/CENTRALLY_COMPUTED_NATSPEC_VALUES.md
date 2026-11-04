# Centrally computed NatSpec values

Canonical **function selectors** and **interface IDs** used in Crane NatSpec (`@custom:selector`, `@custom:interfaceid`, `@custom:signature`). Agents and docs must use these values instead of inventing hex strings.

Source of truth for many symbols: interfaces under `contracts/interfaces/` and implementations such as `contracts/factories/diamondPkg/DFPkgBase.sol` and CREATE3 factory interfaces.

## IDiamondFactoryPackage / DFPkg

| Symbol | Signature | Selector |
|--------|-----------|----------|
| `packageName` | `packageName()` | `0xabc8b346` |
| `facetInterfaces` | `facetInterfaces()` | `0x2ea80826` |
| `facetAddresses` | `facetAddresses()` | `0x52ef6b2c` |
| `packageMetadata` | `packageMetadata()` | `0xf45469e7` |
| `facetCuts` | `facetCuts()` | `0xa4b3ad35` |
| `diamondConfig` | `diamondConfig()` | `0x65d375b3` |
| `calcSalt` | `calcSalt(bytes)` | `0xd82be56e` |
| `processArgs` | `processArgs(bytes)` | `0x87c3adb3` |
| `updatePkg` | `updatePkg(address,bytes)` | `0xa9089235` |
| `initAccount` | `initAccount(bytes)` | `0x870d4838` |
| `postDeploy` | `postDeploy(address)` | `0x70068fcf` |

## IDiamondPackageCallBackFactory

| Item | Value |
|------|--------|
| Interface ID | `0x949da331` |
| Example `deploy` selector | `0xe97fac05` |

Confirm against `IDiamondPackageCallBackFactory` in `contracts/interfaces/` when adding new symbols.

## IFacet (common metadata surface)

| Symbol | Selector (typical) |
|--------|---------------------|
| Facet metadata helpers | `0x5b6f4d01`, `0x2ea80826`, `0x574a4cff`, `0xf10d7a75` |

See `Create3FactoryFacet` / `IFacet` for the authoritative list.

## ICreate3Factory (sample)

| Symbol | Signature | Selector |
|--------|-----------|----------|
| (see interface) | `ICreate3Factory` | `0x0fe96d13`, `0x1cdca5df`, `0xa7b62a7f`, `0x1f7fe4db` |

## Policy

1. Prefer values computed from source (`cast sig "fn()"` or NatSpec already on interfaces).
2. Do not invent interface IDs; XOR of declared selectors when documenting a new interface.
3. Historical copies under the external [crane-archive](https://github.com/cyotee/crane-archive) repo are not the public SoT.

## PairToken Standard Exchange stage one (2026-10-28)

Verified by `forge script lib/crane/scripts/foundry/ComputeNatSpecValues.s.sol --sig "run()" -vvv` from the IndexedEx root, following artifact preparation. Exit 0; script gas 968,084. The added checks import actual product interfaces and assert each typed selector/event against its canonical signature. Historical simplified core mirrors above were not used for the product checks.

| Interface or namespace | Value |
| --- | --- |
| IUniswapV4PairTokenStandardExchangeVault | `0x8be92db3` |
| IUniswapV4PairTokenStandardExchangeVaultDFPkg (own methods) | `0xc283faa9` |
| IStandardizedYield (own methods) | `0x73363918` |
| PairToken Repo ERC1967 slot | `0x3218600e922762d007aa211c0ce9f8363c69f8febb941e30467d0a7475fbf532` |

### Sixty package-owned product methods

| Signature | Selector |
| --- | --- |
| `name()` | `0x06fdde03` |
| `symbol()` | `0x95d89b41` |
| `decimals()` | `0x313ce567` |
| `totalSupply()` | `0x18160ddd` |
| `balanceOf(address)` | `0x70a08231` |
| `allowance(address,address)` | `0xdd62ed3e` |
| `approve(address,uint256)` | `0x095ea7b3` |
| `transfer(address,uint256)` | `0xa9059cbb` |
| `transferFrom(address,address,uint256)` | `0x23b872dd` |
| `permit(address,address,uint256,uint256,uint8,bytes32,bytes32)` | `0xd505accf` |
| `nonces(address)` | `0x7ecebe00` |
| `DOMAIN_SEPARATOR()` | `0x3644e515` |
| `eip712Domain()` | `0x84b0196e` |
| `vaultTokens()` | `0x69722233` |
| `reserveOfToken(address)` | `0x46f910ac` |
| `reserves()` | `0x75172a8b` |
| `vaultFeeTypeIds()` | `0x6a4d3f12` |
| `contentsId()` | `0xf5ee7c5b` |
| `vaultTypes()` | `0x36abf3dc` |
| `vaultConfig()` | `0x7cc34bb4` |
| `exchangeIn(address,uint256,address,uint256,address,bool,uint256)` | `0xd02d3063` |
| `depositPair(uint256,uint256,uint256,address,uint256)` | `0x047adf08` |
| `redeemPair(uint256,uint256,uint256,address,uint256)` | `0xd43ad6e4` |
| `donate(address,uint256)` | `0xe69d849d` |
| `compound()` | `0xf69e2046` |
| `previewExchangeIn(address,uint256,address)` | `0x89d61912` |
| `previewDepositPair(uint256,uint256)` | `0xfa5f0790` |
| `previewRedeemPair(uint256)` | `0x2d8c09d6` |
| `previewWithdrawalMode(uint256,bool,address)` | `0xe378544f` |
| `previewZapCredit(address,uint256)` | `0x73cd027d` |
| `previewExchangeOut(address,address,uint256)` | `0xdb149bc5` |
| `exchangeOut(address,uint256,address,uint256,address,bool,uint256)` | `0xbbac8477` |
| `poolManager()` | `0xdc4c90d3` |
| `poolKey()` | `0x182148ef` |
| `wrappedNative()` | `0xeb6d3a11` |
| `rateAsset()` | `0xcf77880f` |
| `tickLower()` | `0x59c4f905` |
| `tickUpper()` | `0x55b812a8` |
| `positionLiquidity()` | `0x7211dc36` |
| `localReserves()` | `0x765d889f` |
| `basket()` | `0xedc832b3` |
| `maxZapBps()` | `0x6e2abc14` |
| `maxZapTickMove()` | `0x67698371` |
| `deposit(address,address,uint256,uint256)` | `0x20e8c565` |
| `redeem(address,uint256,address,uint256,bool)` | `0x769f8e5d` |
| `rewardIndexesCurrent()` | `0xf8b2f991` |
| `claimRewards(address)` | `0xef5cfb8c` |
| `previewDeposit(address,uint256)` | `0xb8f82b26` |
| `previewRedeem(address,uint256)` | `0xcbe52ae3` |
| `getTokensIn()` | `0x213cae63` |
| `getTokensOut()` | `0x071bc3c9` |
| `yieldToken()` | `0x76d5de85` |
| `assetInfo()` | `0xa40bee50` |
| `exchangeRate()` | `0x3ba0b9a9` |
| `isValidTokenIn(address)` | `0xfa5a4f06` |
| `isValidTokenOut(address)` | `0x784367d6` |
| `getRewardTokens()` | `0xc4f59f9b` |
| `accruedRewards(address)` | `0x128fced1` |
| `rewardIndexesStored()` | `0xda88ecb4` |
| `unlockCallback(bytes)` | `0x91dd7346` |

### Family/package errors and package methods

| Signature | Selector |
| --- | --- |
| `ReentrantOperation()` | `0xe1bcc005` |
| `ManagerAlreadyUnlocked()` | `0x7665c9da` |
| `EconomicStateChanged()` | `0x2952373b` |
| `InvalidAccountingState()` | `0x997ede0a` |
| `ZeroPayout()` | `0xaf110036` |
| `QuoteWorkExceeded(uint256,uint256)` | `0xd149652c` |
| `QuoteTickCrossingsExceeded(uint256,uint256)` | `0x7dfd6581` |
| `QuoteBitmapWordsExceeded(uint256,uint256)` | `0x0af3219e` |
| `IssuanceDisabled()` | `0x42db6a65` |
| `InvalidComponent()` | `0xb03ac0b6` |
| `InvalidPoolKey()` | `0xc256622b` |
| `InvalidRateAsset()` | `0x41ef82fd` |
| `InvalidZapLimits()` | `0x70965b62` |
| `InvalidWrappedNative()` | `0x5e66e44d` |
| `NotCalledByRegistry()` | `0xd8af869a` |
| `InvalidInitializationContext()` | `0x0bda07c4` |
| `AlreadyInitialized()` | `0x0dc149f0` |
| `bindingHash()` | `0xd727562b` |
| `vaultDeclaration()` | `0xf4efa66f` |
| `deployVault(((address,address,uint24,int24,address),address,string,string,uint16,int24))` | `0x15a4ac82` |

### Stage-one linked-library errors

The bounded-execution amendment's two work errors were verified against the real
interface by `ComputeNatSpecValues.s.sol` on 2026-10-29, exit 0, script gas
22,021,456. The 60 product selectors and family/package/SY interface IDs are
unchanged; errors do not contribute to ERC-165 interface IDs.

Verified by `ComputeNatSpecValues.s.sol` on 2026-10-28, exit 0,
script gas 1,084,474. Duplicate declarations of DirectCallNotAllowed in
Math, Projection and Planner were independently checked against typed selectors.

| Signature | Selector |
| --- | --- |
| `DirectCallNotAllowed()` | `0x3921c703` |
| `InvalidPrice()` | `0x00bfc921` |
| `ZeroShares()` | `0x9811e0c7` |
| `InvalidAllocation()` | `0x0baf7432` |
| `LiquidityOverflow()` | `0xb03425ae` |
| `ArithmeticOverflow()` | `0xe47ec074` |
| `ZapSizeExceeded(uint256,uint256)` | `0x63413124` |
| `ZapTickMoveExceeded(uint256,uint256)` | `0x7c4645c4` |
| `IncompleteExitSale(uint256,uint256)` | `0xf31ce201` |
| `InvalidCallback()` | `0xf7a632f5` |
| `InvalidNativeValue(uint256,uint256)` | `0x1fa0ca33` |
| `NativeTransferFailed()` | `0xf4b3b1bc` |
| `SettlementMismatch()` | `0xd5e2090b` |
| `RuntimeArtifactMismatch(address)` | `0xf130eea1` |
| `PackageBindingMismatch(address)` | `0xec284267` |

### Stage-one linked entry points

Verified by the canonical script; library struct parameters retain Solidity's qualified names. These are implementation calls, not additional product cuts.

| Signature | Selector |
| --- | --- |
| `accountingRate(uint160,uint256,uint256,uint256,bool)` | `0x1755f7e8` |
| `allocation(uint256,uint256,uint128,uint256,uint256)` | `0x09eb2862` |
| `compoundSwap(uint160,uint160,uint160,uint256,uint256,uint128,uint16)` | `0x7d0bcdae` |
| `costs(uint160,uint160,uint160,uint128)` | `0xf1db97db` |
| `credit(uint256,uint256,uint256,uint256,uint256,uint256)` | `0x0be88eff` |
| `liquidityForAmounts(uint160,uint160,uint160,uint256,uint256)` | `0xc12baa75` |
| `pairedQuote(uint256,uint256,uint256,uint256,uint256)` | `0xd1bd57b3` |
| `principal(uint160,uint160,uint160,uint128)` | `0x6dae28b5` |
| `tryCompoundSwap(uint160,uint160,uint160,uint256,uint256,uint128,uint16)` | `0x81a5d1ff` |
| `tryLiquidityForAmounts(uint160,uint160,uint160,uint256,uint256)` | `0xf4ab04d0` |
| `zapCredit(uint256,uint256,uint256,uint256,uint256)` | `0x68b3eb2d` |
| `capture(UniswapV4PairTokenStandardExchangeVaultTypes.ProjectedState)` | `0x9acbbb2d` |
| `check(UniswapV4PairTokenStandardExchangeVaultTypes.Snapshot,address,int24[],int16[],UniswapV4PairTokenStandardExchangeVaultTypes.Witness)` | `0xcf5cbc23` |
| `witness(UniswapV4PairTokenStandardExchangeVaultTypes.ProjectedState)` | `0x28f43d6f` |
| `witness(UniswapV4PairTokenStandardExchangeVaultTypes.ProjectedState,UniswapV4PairTokenStandardExchangeVaultTypes.ProjectedState)` | `0x13c62e10` |
| `projectSwap(UniswapV4PairTokenStandardExchangeVaultTypes.ProjectedState,bool,uint256,uint160,UniswapV4PairTokenStandardExchangeVaultTypes.Phase)` | `0xdd1a6086` |
| `plan(UniswapV4PairTokenStandardExchangeVaultTypes.Snapshot,UniswapV4PairTokenStandardExchangeVaultTypes.Operation)` | `0x64309acc` |
| `donate(address,uint256)` | `0xe69d849d` |
| `prepare(UniswapV4PairTokenStandardExchangeVaultExecution.Request)` | `0x075f9b34` |
| `linkedComponents()` | `0x21e1016f` |


### Bounded-execution test selectors (2026-10-29)

Typed against the actual WorkBudget test contract by the canonical script; final
script exit 0, gas 22,117,435. These selectors document tests, not product cuts.

| Signature | Selector |
| --- | --- |
| `test_BUD_Crossing12Allowed13RejectedWithoutFetchingTick()` | `0x814942a6` |
| `test_BUD_RepeatCrossingsShareTheWholeCandidateBudget()` | `0x2c381933` |
| `test_BUD_DistinctWord16Allowed17RejectedAndRepeatReadFree()` | `0x8eb4d377` |
| `test_BUD_Iteration64Allowed65RejectedComponentGuard()` | `0x25e8bcb9` |
| `test_BUD_DenseSingleExitRejectedBeforeBurnAndPairRemainsAffordable()` | `0xb2e0a694` |
| `test_BUD_BitmapExhaustionPreservesPairedEscapeAndRejectsZap()` | `0xd1c96f53` |
| `test_BUD_MaximumCrossingFallbackWithBothFeeCurrencies()` | `0x1ed332fa` |
| `test_BUD_MaintenanceFitsButFinalSaleExhaustsSharedBudget()` | `0x49dcc879` |
| `test_BUD_MaximumSupportedEntryAcrossMaintenanceAndZap()` | `0xbdfc7ab9` |
| `test_BUD_MaximumSupportedToken1Entry()` | `0xa7305fee` |
| `test_BUD_MaximumSupportedNativeEntry()` | `0xd4a3cc1f` |
| `test_BUD_MaximumSupportedWrappedEntry()` | `0x0cdfe6ca` |
| `test_BUD_MaximumSupportedNativePoolToken1Entry()` | `0x81e65409` |
| `test_BUD_MaximumFullCompoundPairedAndTerminalExits()` | `0x5a784ad8` |
| `test_BUD_MaximumNativeFullCompoundPairedAndTerminalExits()` | `0x8c8cc7d1` |


### Family event topics

| Signature | Topic zero |
| --- | --- |
| `PairDeposited(address,address,uint256,uint256,uint256,uint256,uint256)` | `0xda511ab31decab85347cbb009c5eca7dc93d42b9f88235638cd32fbd92397cd1` |
| `PairRedeemed(address,address,uint256,uint128,uint256,uint256,uint256,uint256)` | `0x1041784b75731e1e018f6ff62269b1c675ebff629872d9e3510d59eab6931040` |
| `WithdrawalSale(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)` | `0x99c8779dc66b56fb994f4b1935a5ff2970acedea61f8d3717e7c08a125f8e6ff` |
| `Donated(address,address,uint256)` | `0x4dfff917e1fbb261a082e98cc7d43029621f6a6eb05ff3fef1510d5f1eb4857c` |
| `Compounded(uint256,uint256,uint256,uint256,uint128)` | `0xd647af60afd6acb3de3950c5efee508cd33b161a8ce220490ef95ff9b6ed1c9a` |
| `ZapCredit(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)` | `0xcbdc4d639de961501e542b2dea1fce82598f64c856fc39a80f4dc0c620cce6f5` |
| `WithdrawalMaintenanceSelected(uint8,uint8)` | `0xe1f72370b8fab295c65894b097631f2ed03ef54d2308b57f390c07c1e8838f2d` |

The compiled selectors for vaultTokens(), exchangeIn and exchangeOut above differ from stale NatSpec literals in the existing canonical interfaces. Product code uses typed selectors; the unrelated shared interfaces were not edited.

