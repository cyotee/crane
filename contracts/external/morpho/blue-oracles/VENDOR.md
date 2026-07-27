# morpho-blue-oracles vendor (ChainlinkOracle V2)

| Item | Value |
|------|-------|
| Upstream | morpho-org/morpho-blue-oracles |
| Pin | `v2.0.0` (`07a9a6988b0e1b316ac2fa97ec62ad485fbd0041`) |
| Solidity files (this tree) | 12 (morpho-chainlink + wsteth adapter) |
| Copy date | 2026-07-27 |
| License | Dual **GPL-2.0-or-later** / historical BUSL choice (upstream LICENSE) |
| Import policy | `IOracle` → `@crane/contracts/external/morpho/blue/...`; OZ `Math` → `@crane/contracts/external/openzeppelin-contracts/utils/math/Math.sol`. No private OZ under Morpho. |

## Live factories

| Chain | Factory constant | Address |
|-------|------------------|---------|
| Ethereum | `ETHEREUM_MAIN.MORPHO_CHAINLINK_ORACLE_V2_FACTORY` | `0x3A7bB36Ee3f3eE32A60e9f2b33c1e5f2E83ad766` |
| Base | `BASE_MAIN.MORPHO_CHAINLINK_ORACLE_V2_FACTORY` | `0x2DC205F24BCb6B311E5cdf0745B0741648Aebd3d` |

## Adaptations

- Tree layout: upstream `src/morpho-chainlink/*` flattened to package root; wstETH adapter under `wsteth-exchange-rate-adapter/`.
- Exact pragmas → `^0.8.35` on implementation contracts.
- Cross-package imports remapped to `@crane/`.
- Upstream default profile uses `via_ir = true`; Crane compiles without viaIR.

## Inventory

```
MorphoChainlinkOracleV2.sol
MorphoChainlinkOracleV2Factory.sol
interfaces/{AggregatorV3Interface,IERC4626,IMorphoChainlinkOracleV2,IMorphoChainlinkOracleV2Factory}.sol
libraries/{ChainlinkDataFeedLib,ErrorsLib,VaultLib}.sol
wsteth-exchange-rate-adapter/WstEthStEthExchangeRateChainlinkAdapter.sol (+ interfaces)
```
