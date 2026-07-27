# morpho-blue vendor

| Item | Value |
|------|-------|
| Upstream | morpho-org/morpho-blue |
| Pin | `v1.0.0` (`55d2d99304fb3fb930c688462ae2ccabb1d533ad`) |
| Solidity files (this tree) | 22 |
| Copy date | 2026-07-27 |
| License | **BUSL-1.1** at pin (file SPDX). Upstream `main` later re-licensed to **GPL-2.0-or-later**. Live deploys match this release era. |
| Import policy | Self-contained domain (no OZ). Relative imports within package retained; cross-package consumers use `@crane/contracts/external/morpho/blue/...`. |

## Live bytecode reference (runtime codehash)

| Chain | Address | Codesize | `keccak256(code)` (Alchemy, 2026-07-27) |
|-------|---------|----------|------------------------------------------|
| Ethereum | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` | 15623 | `0xfa259fa317198f88f5fa3c119f06c066295dbcd47d715e0a30e1bcf94c02ef8c` |
| Base | same CREATE2 address | 15623 | `0xaa76348c0b91e5dfcece228ef6847b0c5081656d2def05c5617bcab659f0b819` |

Note: ETH vs Base runtime codehashes differ (immutables / deploy-time args such as owner). Source pin is the same release.

## Adaptations

- Imports: domain-only; no private OZ/Solady tree.
- `pragma solidity 0.8.19` on `Morpho.sol` relaxed to `^0.8.35` for Crane multi-version compile.
- Upstream production builds used `via-ir = true` + high optimizer runs; **Crane forbids viaIR** — hermetic recompile is logic-faithful, not bytecode-identical to live. Fork parity tests compare **state after ops**, not codehash equality of local deploy.
- Mocks under `mocks/` retained for ported upstream tests.

## Inventory

```
Morpho.sol
interfaces/{IERC20,IIrm,IMorpho,IMorphoCallbacks,IOracle}.sol
libraries/{ConstantsLib,ErrorsLib,EventsLib,MarketParamsLib,MathLib,SafeTransferLib,SharesMathLib,UtilsLib}.sol
libraries/periphery/{MorphoBalancesLib,MorphoLib,MorphoStorageLib}.sol
mocks/{ERC20Mock,FlashBorrowerMock,IrmMock,OracleMock}.sol + mocks/interfaces/IERC20.sol
```
