# NetNet Capital (`protocols/pol/net`) vendor

| Item | Value |
|------|-------|
| Upstream | No public git. Verified sources from Sourcify + Blockscout PRO on Robinhood Chain (4663). |
| Pin | Dump date `2026-08-28` (`scripts/netnet/dump/`) |
| Official Channels | https://docs.netnet.capital/official-channels |
| Solidity files (this tree) | P0 domain under `src/` only (see by-address map) |
| Copy date | 2026-08-28 |
| License (domain) | AGPL-3.0-only (as dumped) |
| License (wrappers) | AGPL-3.0-or-later (`aware/`, `services/`, `test/`) |
| Import policy | Shared IERC20 / IERC20Metadata / IERC4626 / Uni V2 / Uni V3 factory / Morpho remapped to `@crane/`; NetNet siblings to `@crane/contracts/protocols/pol/net/src/...`. No dump OZ, no dump ERC/Uni/Morpho interface copies, no RWA desk interface. |
| Dump `state.json` | 41 done / 6 skipped / 3 unverified (50 contracts inventoried) |
| Live compiler | `0.8.30+commit.73712a01` / optimizer 800 / EVM osaka / `viaIR: false` |
| Crane compile | Solidity 0.8.35 / optimizer runs 1 / EVM Prague / `viaIR: false` |
| Domain pragma | `^0.8.24` |
| Wrapper pragma | `^0.8.35` |
| Robinhood fork block | `ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK` = `20_714_383` |

## Adaptations

- Imports rewritten from dumped relative / dump-local ERC and Uni paths to `@crane/...`.
- `TurboRouter`: dump Morpho facade → Crane `IMorpho` + file-level `MarketParams`; callbacks from `IMorphoCallbacks`; oracle `price()` via Morpho `IOracle`. `_currentLtvWad` reads `Position` / `Market` structs and `Id.wrap(marketId)` (IMorpho consumer signatures).
- `WrappedStakedNET`: unused perp-constants import dropped; dump-local ERC/sNET views replaced with Crane `IERC20` / `IsNET` so P2 perp interface files are not copied.
- `Zap`: `IERC20Minimal` / `IStakingMinimal` replaced with Crane `IERC20` / `IStaking`.

## By-address map (P0 copy sources)

Dump directories: `scripts/netnet/dump/by-address/<addr>/files/`.

| Dest under `src/` | Copied from |
|-------------------|-------------|
| `NET.sol`, `interfaces/INET.sol`, `Constants.sol`, `abstract/Wired.sol` | `0xca9c78dd337a67f6e0077f65f5e9218719d30edf` (NET) |
| `StakedNET.sol`, `interfaces/IsNET.sol` | `0xb773ec2c326b7f98a5a83fc098825492f020a4c7` |
| `Staking.sol`, `interfaces/IStaking.sol` | `0xb078cc304a0b264c5f3680dc0488954accd02e87` |
| `Treasury.sol`, `interfaces/ITreasury.sol`, `libraries/FixedPointMath.sol` | `0x04822ea321a0dee6f40656172f29312104855d66` |
| `Distributor.sol`, `interfaces/IDistributor.sol` | `0x79e71f8a8a2912e40687a8820b2dc0fdd2f686b3` |
| `BondDepository.sol`, `interfaces/IBondDepository.sol` | `0xff32a969a0c567129eecd926d04657728e1980c1` |
| `InverseBond.sol`, `interfaces/IInverseBond.sol` | `0x92166e94eea5b7799b761653881692f881dfc4c9` |
| `PremiumSeller.sol`, `interfaces/IPremiumSeller.sol` | `0x346e1a31171a0f7ac73909010b5435768d3b5462` |
| `PairOracle.sol`, `interfaces/IPairOracle.sol` | `0x929631b33f4070d6f54477fba3fd27566567daca` |
| `TaxCollector.sol`, `interfaces/ITaxCollector.sol` | `0x086c58400b8708ef993f256e12e752dcf0ac918e` |
| `PTeam.sol`, `interfaces/IPTEAM.sol` | `0x650f58079daa17ee28928c2f92d22291d038b2b0` |
| `GenesisBond.sol`, `interfaces/IGenesisBond.sol` | `0x575b7b7c97ef3e21c82daeb427899d583e1e913f` |
| `ShareCertificate.sol` | `0xfb8058769063519f26fb114631919c0e5254068e` |
| `lending/LoopbackOracle.sol`, `lending/LendingConstants.sol` | `0xcde9599059f8ae6d6b9f33a0af7877827ec75f16` |
| `lending/TurboRouter.sol` | `0x4638617808e3f1cf237c0d33ae818126d5c77e17` |
| `perp/WrappedStakedNET.sol` | `0x63c12667638f2ae6fc6ae09b43d98ec84a8586ea` |
| `perp/Zap.sol` | `0xa1ee052ec32532304a7522bd9a4b594ec28ff1b1` |

`Constants.sol` / `Wired.sol` kept from NET; `FixedPointMath.sol` from Treasury. `LendingConstants.sol` from Loopback.

## Not copied (P1/P2 / shared deps)

`rwa/`, `winnet/`, `play/`, `climb/`, `superstore/`, `v1/`, extra `perp/` files (perp-constants, perp-external, desks), dump `lib/openzeppelin-contracts/`, dump-local ERC/Uni/Morpho interface files, RWA desk interface.
