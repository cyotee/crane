# Implementation plan: Port NetNet Capital into Crane (`protocols/pol/net`)

- **PRD:** `contracts/protocols/pol/net/2026-08-28-netnet-pol-port-prd.md`
- **Created:** 2026-08-28
- **Status:** ready for `/goal`

This file is the execute artifact. `/goal` is given **this path**. Implementors follow this plan and the PRD. They do not invent requirements.

## Objective

Crane has a faithful NetNet domain tree at `contracts/protocols/pol/net/`, four flow-split Service libraries, one `NetNetAwareRepo`, Behavior libraries, hermetic and fork TestBases, path-scoped Foundry specs, a `crane-netnet` skill (Claude + Grok mirrors), and CODEBASE_MAP / protocols-status notes. Hermetic boot is real `wire()` plus `GenesisBond.finalize()` against Crane Uniswap V2, a real Morpho Vault V2 as the Treasury ERC-4626, and real Morpho Blue for Loopback. Default `forge test` stays green because fork specs live under `**/fork/**`.

## In scope

- P0 domain copy from `scripts/netnet/dump/by-address/` into `contracts/protocols/pol/net/src/`
- `@crane/` remaps for every import (shared IERC20 / IERC4626 / Uni V2 / Uni V3 factory / Morpho Blue)
- `VENDOR.md`
- `NetNetSpotService`, `NetNetStakingService`, `NetNetBondService`, `NetNetTurboService`
- `NetNetAwareRepo` (slot `protocols.pol.net.aware`)
- `Behavior_I{Interface}` libraries listed in the PRD
- `TestBase_NetNet` (inherits `TestBase_UniswapV2`) and `TestBase_NetNetFork`
- Hermetic, comparative-hermetic, and fork specs at the PRD paths
- `.claude/skills/crane-netnet/` and `.grok/skills/crane-netnet/`
- CODEBASE_MAP + `docs/protocols/status.md` rows
- Bump `ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK` only if NET / Staking / Treasury have no code at `20_714_383`

## Out of scope

- `contracts/external/netnet/`
- Diamond FTR / DFPkg
- `[profile.netnet_port]` or `NETNET_FORK_BLOCK`
- `viaIR`
- Bytecode/`extcodehash` match vs mainnet
- `etch` of port bytecode onto live addresses
- RwaDesk / Rialto (P1)
- Arcade, WinNET, Superstore, CLIMB, TURBO cards, futures/CASHCAT desks (P2)
- `netnet-architecture` / `netnet-operations` skill family
- Bond market 1 as a P0 test gate
- Live InverseBond fills while NET trades above NAV
- Olympus contracts as NetNet
- Inventing sources for unverified addresses
- New Foundry remapping aliases
- Relicensing dumped domain files

## Decisions (locked)

Copy of PRD Decisions (all **Decided**). Do not reopen.

| ID | Decision |
|----|----------|
| D1 | Domain home is `contracts/protocols/pol/net/` only. No `contracts/external/netnet/`. |
| D2 | Product name NetNet / token NET / path `pol/net` / constants `NETNET_*`. |
| D3 | Domain license AGPL-3.0-only as dumped. Wrappers AGPL-3.0-or-later. |
| D4 | Upstream pin is the 2026-08-28 Sourcify/Blockscout dump. No public git. |
| D5 | Do not treat Olympus as this protocol. |
| D6 | P0 = domain + four services + AwareRepo + Behaviors + both TestBases + hermetic/fork/comparative tests + `crane-netnet` skill. No DFPkg. |
| D7 | P0 user flows: FoT buy/sell, stake/unstake/rebase, BondDepository discount bond, TurboRouter + Morpho Blue, plus convert, pTEAM, InverseBond, PremiumSeller. |
| D8 | Services split per flow; pTEAM lives on `NetNetBondService` with inverse and premium. Spot owns convert. |
| D9 | One `NetNetAwareRepo`, slot `protocols.pol.net.aware`. |
| D10 | Hermetic Morpho: real Vault V2 (Treasury IERC4626) and real Morpho Blue (Loopback). No ERC-4626 fake of steakUSDG. |
| D11 | Hermetic boot: real `wire()` + `GenesisBond.finalize()` on Crane Uni V2. No skip path. |
| D12 | Comparative tests: invariants + revert selectors. No `assertEq(portOut, forkOut)` for market amounts. Fork comparative file lives under `**/fork/**`. |
| D13 | Fork pin is `DEFAULT_FORK_BLOCK`. Bump it if NetNet has no code. No `NETNET_FORK_BLOCK`. |
| D14 | RwaDesk is P1. Arcade / WinNET / Superstore / futures desks are P2. |
| D15 | viaIR forbidden. |
| D16 | No new Foundry profile. Use `default` + `fork` only. |
| D17 | Compile vs live: behavioral parity, not `extcodehash`. |
| D18 | Convert every dumped import to `@crane/`. Remap shared deps to the Crane targets below. |
| D19 | Fork CI is opt-in. Hermetic suite must pass without RPC. |
| D20 | Greenfield redeploy is hermetic and testnets only. |
| D21 | Copy P0 files from `dump/by-address/`, not wholesale `dump/tree/`. |
| D22 | Behavior files are `Behavior_I{Interface}` matching dumped interfaces. |
| D23 | This plan is `contracts/protocols/pol/net/PLAN.md`. |
| D24 | P0 ships `.claude/skills/crane-netnet/SKILL.md` and `.grok/skills/crane-netnet/`. |
| D25 | `TestBase_NetNet` inherits `TestBase_UniswapV2` and deploys Morpho Blue / Vault V2 itself. It does not inherit `TestBase_MorphoBlue`. |
| D26 | `Constants.sol` wins over stale interface comments (tax team start 400 bps, bond vest 2 days). |

### Remap table (D18, including dump imports the PRD table named plus NET.sol’s V3 factory)

| Dump import | Crane target |
|-------------|--------------|
| `IERC20` | `@crane/contracts/interfaces/IERC20.sol` |
| `IERC20Metadata` | `@crane/contracts/interfaces/IERC20Metadata.sol` |
| `IERC4626` | `@crane/contracts/external/openzeppelin-contracts/interfaces/IERC4626.sol` |
| `IUniswapV2Factory` | `@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol` |
| `IUniswapV2Pair` | `@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol` |
| `IUniswapV2Router02` | `@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol` |
| `IUniswapV3Factory` | `@crane/contracts/external/uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol` |
| `IMorphoBlue` / `IMorphoBlue.MarketParams` | `@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol` (`IMorpho`, file-level `MarketParams`) and `@crane/contracts/external/morpho/blue/interfaces/IMorphoCallbacks.sol` |
| NetNet sibling (`./Staking.sol`, `./interfaces/INET.sol`, …) | `@crane/contracts/protocols/pol/net/src/...` |

Do not copy `src/interfaces/external/IERC20.sol`, `IERC4626.sol`, `IUniswapV2.sol`, `IUniswapV3.sol`, `src/lending/interfaces/IMorphoBlue.sol`, `src/interfaces/IRwaDesk.sol`, or dump `lib/openzeppelin-contracts/`.

`WrappedStakedNET.sol` imports unused `PerpConstants.sol`: drop that import (no logic change). Replace `IPerpExternal` types with `IsNET` / `IStaking` / Crane `IERC20` so `perp/interfaces/IPerpExternal.sol` and `perp/PerpConstants.sol` are not copied (P2 desk files).

## Work order

Dump directories use lowercase addresses under `scripts/netnet/dump/by-address/<addr>/files/src/`.

### Step 1: Copy P0 domain + VENDOR.md

- **Files (create):**
  - `contracts/protocols/pol/net/VENDOR.md` (new)
  - `contracts/protocols/pol/net/src/**` from the table below (new)
- **Do:** Copy only these sources from `by-address`, then keep NetNet `I*` interfaces (not `IRwaDesk`, not `interfaces/external/*`):

| Dest under `src/` | Copy from `dump/by-address/<addr>/files/` |
|-------------------|-------------------------------------------|
| `NET.sol` + `interfaces/INET.sol` + `Constants.sol` + `abstract/Wired.sol` + `libraries/FixedPointMath.sol` + NetNet `interfaces/*.sol` except `IRwaDesk.sol` | `0xca9c78dd337a67f6e0077f65f5e9218719d30edf` (NET) |
| `StakedNET.sol` + `interfaces/IsNET.sol` if not already from NET | `0xb773ec2c326b7f98a5a83fc098825492f020a4c7` |
| `Staking.sol` + `interfaces/IStaking.sol` | `0xb078cc304a0b264c5f3680dc0488954accd02e87` |
| `Treasury.sol` + `interfaces/ITreasury.sol` | `0x04822ea321a0dee6f40656172f29312104855d66` |
| `Distributor.sol` + `interfaces/IDistributor.sol` | `0x79e71f8a8a2912e40687a8820b2dc0fdd2f686b3` |
| `BondDepository.sol` + `interfaces/IBondDepository.sol` | `0xff32a969a0c567129eecd926d04657728e1980c1` |
| `InverseBond.sol` + `interfaces/IInverseBond.sol` | `0x92166e94eea5b7799b761653881692f881dfc4c9` |
| `PremiumSeller.sol` + `interfaces/IPremiumSeller.sol` | `0x346e1a31171a0f7ac73909010b5435768d3b5462` |
| `PairOracle.sol` + `interfaces/IPairOracle.sol` | `0x929631b33f4070d6f54477fba3fd27566567daca` |
| `TaxCollector.sol` + `interfaces/ITaxCollector.sol` | `0x086c58400b8708ef993f256e12e752dcf0ac918e` |
| `PTeam.sol` + `interfaces/IPTEAM.sol` | `0x650f58079daa17ee28928c2f92d22291d038b2b0` |
| `GenesisBond.sol` + `interfaces/IGenesisBond.sol` | `0x575b7b7c97ef3e21c82daeb427899d583e1e913f` |
| `ShareCertificate.sol` | `0xfb8058769063519f26fb114631919c0e5254068e` |
| `lending/LoopbackOracle.sol` + `lending/LendingConstants.sol` | `0xcde9599059f8ae6d6b9f33a0af7877827ec75f16` |
| `lending/TurboRouter.sol` | `0x4638617808e3f1cf237c0d33ae818126d5c77e17` |
| `perp/WrappedStakedNET.sol` | `0x63c12667638f2ae6fc6ae09b43d98ec84a8586ea` |
| `perp/Zap.sol` | `0xa1ee052ec32532304a7522bd9a4b594ec28ff1b1` |

If `Constants.sol` / `Wired.sol` differ across dumps, keep the NET and Treasury copies (core). `LendingConstants.sol` from Loopback/Turbo only.

`VENDOR.md` fields: dump date `2026-08-28`, `state.json` done/unverified/skipped counts, AGPL-3.0-only, live compiler `0.8.30+commit.73712a01` / optimizer 800 / EVM osaka / `viaIR: false`, Crane compile 0.8.35 / runs 1 / Prague / `viaIR: false`, the by-address map above, Official Channels URL, and a placeholder for the fork block (filled in Step 9).

- **Tests:** none yet
- **Done when:** Every P0 dest path exists. `rwa/`, `winnet/`, `play/`, `climb/`, `superstore/`, `v1/`, other `perp/` files, dump OZ, dump `interfaces/external/`, `IMorphoBlue.sol`, and `IRwaDesk.sol` are absent.

### Step 2: Remap imports

- **Files (modify):** every `.sol` copied in Step 1
- **Do:** Rewrite imports per the remap table. Domain SPDX stays `AGPL-3.0-only`, pragma stays `^0.8.24`. In `TurboRouter.sol`, `IMorphoBlue` becomes `IMorpho` and `IMorphoBlue.MarketParams` becomes `MarketParams`. Drop unused `PerpConstants` import on `WrappedStakedNET`. Point Zap/wsNET at `IsNET` / `IStaking` / Crane `IERC20`.
- **Tests:** none yet
- **Done when:** `rg "interfaces/external" contracts/protocols/pol/net` is empty. `rg "IMorphoBlue" contracts/protocols/pol/net` is empty. `rg "PerpConstants" contracts/protocols/pol/net` is empty. No relative `../` or `./` imports remain in the ported tree.

### Step 3: Domain compile

- **Files:** none new
- **Do:** `forge build` compiling the ported tree via a one-file import (Step 4’s TestBase is enough once it exists). Until then, `forge build --match-contract` is unavailable; use `forge build` after adding a throwaway import in a test file is not allowed. Compile by creating Step 4’s `TestBase_NetNet.sol` skeleton that imports `NET` / `Treasury` / `TurboRouter` and run `forge build`. Fix stack-too-deep with structs, not `viaIR`. Do not edit `foundry.toml`.
- **Tests:** `forge build`
- **Done when:** `forge build` succeeds with `viaIR = false`. Domain files still AGPL-3.0-only.

### Step 4: Hermetic TestBase boot

- **Files (create):**
  - `contracts/protocols/pol/net/test/bases/NetNetUsdg.sol` (new): mintable ERC-20, `name = "USD Gold"`, `symbol = "USDG"`, `decimals = 6`, `mint(address,uint256)`. Test double for Paxos USDG, not an SUT mock.
  - `contracts/protocols/pol/net/test/bases/TestBase_NetNet.sol` (new)
- **Do:** Inherit `TestBase_UniswapV2` from `contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol`. Do not inherit `TestBase_MorphoBlue`.

Hermetic `setUp` after `TestBase_UniswapV2.setUp()`:

1. `usdg = new NetNetUsdg()`. `morpho = IMorpho(address(new Morpho(address(this))))`. `irm = new AdaptiveCurveIrm(address(morpho))`. `vault = new VaultV2(address(this), address(usdg))` from `contracts/external/morpho/vault-v2/VaultV2.sol`.
2. `pTeamHolder = address(this)`. `guardian = address(this)`. `teamWallet = address(this)`.
3. Deploy `NET(guardian)`, `StakedNET()`, create Crane pair `uniswapV2Factory.createPair(address(net), address(usdg))` **before** Treasury/GenesisBond constructors.
4. Deploy `Treasury(net, usdg, vault, pair)`, `PairOracle(pair, net, usdg)`, `Staking(net, sNet, Constants.STAKING_WARMUP_EPOCHS)` (must be 0 so Zap constructs), `GenesisBond(net, usdg, treasury, staking, pair, oracle)`, `ShareCertificate(genesisBond)`, remaining P0 contracts with dumped constructor arities (TaxCollector takes router = `uniswapV2Router` cast to `IUniswapV2Router02`; PTeam holder = `pTeamHolder`; TurboRouter morpho/usdg/net/sNet/staking/wsNet/zap/router/oracle/irm).
5. `wire()` every `Wired` contract in the same deploy batch. `NET.wire` `uniswapV3Factory_` = `makeAddr("netnetUniV3Factory")` (non-zero; unused in P0 flows). `Treasury.wire` minters = Distributor, GenesisBond, BondDepository, PremiumSeller, PTeam; spenders = InverseBond. `PTeam.wire` excludedFromFloat = Treasury, InverseBond, TaxCollector, GenesisBond, BondDepository. `GenesisBond.wire(bondDepository, certificate)`.
6. `founder[0..7] = makeAddr`. Mint each `2_000e6` USDG (wallet cap `GENESIS_WALLET_CAP_WAD`). Each `purchase` that amount. Raised WAD = 16_000e18 ≥ `GENESIS_MIN_RAISE_WAD` (15_000e18).
7. `vm.warp(block.timestamp + Constants.GENESIS_DEADLINE + 1)` then `genesisBond.finalize()`.
8. Two oracle observations so TWAP is in band: `vm.warp(+CHECKPOINT_MIN_INTERVAL); oracle.checkpoint(); vm.warp(+TWAP_MIN_WINDOW); oracle.checkpoint()`.
9. `vm.startPrank(address(this)); morpho.enableIrm(address(irm)); morpho.enableLltv(LendingConstants.LLTV); vm.stopPrank();` then `createMarket` loan=USDG collateral=wsNET oracle=LoopbackOracle irm=irm lltv=`LendingConstants.LLTV`. Mint USDG to `address(this)` and `morpho.supply` as credit participant for Turbo.
10. Call `NetNetAwareRepo._initialize` with the deployed addresses (`router` = Uni V2 router, `morphoVault` = Vault V2, `loopbackMarketId` = `marketParams.id()`).

No `vm.mockCall` on the SUT list in PRD requirement 3.

- **Tests (create):** `test/foundry/spec/protocols/pol/net/hermetic/NetNet_Boot.t.sol` (new) asserting the PRD boot checks: `finalized`, staking/bonds/tax enabled, `canonicalPair` taxed, `certificateOf(founder[0]) != 0`, `ShareCertificate.transferFrom` reverts `Soulbound`, `rebalanceToMorpho` increases `morphoAssets()`.
- **Done when:** `forge test --match-path 'test/foundry/spec/protocols/pol/net/hermetic/NetNet_Boot.t.sol'` passes with no RPC.

### Step 5: AwareRepo + four Services

- **Files (create):**
  - `contracts/protocols/pol/net/aware/NetNetAwareRepo.sol` (new)
  - `contracts/protocols/pol/net/services/NetNetSpotService.sol` (new)
  - `contracts/protocols/pol/net/services/NetNetStakingService.sol` (new)
  - `contracts/protocols/pol/net/services/NetNetBondService.sol` (new)
  - `contracts/protocols/pol/net/services/NetNetTurboService.sol` (new)
- **Do:** SPDX `AGPL-3.0-or-later`, pragma `^0.8.35`. Follow `MorphoBlueAwareRepo` / `MorphoBlueService` (structs, `internal` `_` functions, dual `_layoutStruct`).

`NetNetAwareRepo`:
- `STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("protocols.pol.net.aware"))) - 1)`
- `struct NetNetAwareInit` with PRD field list
- `_initialize(Init)` + `_initialize(Storage, Init)`
- getter pair per field

Services (caller context = token holder):

| Library | Functions |
|---------|-----------|
| Spot | `_buyNetWithUsdg(BuyParams)` path `[usdg,net]` FoT swap; `_sellNetForUsdg(SellParams)` path `[net,usdg]`; `_convert(ConvertParams)` → `ITaxCollector.convert` |
| Staking | `_stake(StakeParams)` → `IStaking.stake`; `_unstake` → `unstake`; `_rebase(IStaking)` |
| Bond | `_deposit` → `deposit` (P0 tests use `marketId == 0`); `_redeem`; `_inverseSwap`; `_premiumExecute`; `_exercisePTeam` |
| Turbo | `_setMorphoAuthorization` → `IMorpho.setAuthorization`; `_turbo(wsIn, borrowAssets, minWsFromLoop)`; `_unwind(repayShares, wsCollateralOut, minUsdgFromSale)` |

`BuyParams`/`SellParams`: `router`, `tokenIn`, `tokenOut`, `amountIn`, `amountOutMin`, `to`, `deadline`. NatSpec + include-tags on public library functions; compute `@custom:selector` with `cast sig` when the function is external (internal library fns still get `@custom:signature`).

A fifth Service file is forbidden.

- **Tests:** compile via TestBase imports
- **Done when:** The five files exist (one Aware + four Services). `forge build` still green.

### Step 6: Behavior libraries

- **Files (create)** under `contracts/protocols/pol/net/test/bases/` (new):
  - `Behavior_INET.sol`
  - `Behavior_IStaking.sol`
  - `Behavior_IBondDepository.sol`
  - `Behavior_IInverseBond.sol`
  - `Behavior_IPremiumSeller.sol`
  - `Behavior_ITaxCollector.sol`
  - `Behavior_IPTEAM.sol`
  - `Behavior_ITurboRouter.sol`
- **Do:** `expect_*` / `isValid_*` / `hasValid_*` like `Behavior_IMorpho`. Cover FoT bps and `TaxCollected`; stake/unstake/rebase events; bond deposit/redeem; inverse/premium active+errors; convert split vs `Constants.TAX_TEAM_START_BPS`; `NotHolder` / `ExceedsVestedCap`; `AboveTargetLtv`. Do not name them `Behavior_NetNet*`.
- **Tests:** used starting Step 7
- **Done when:** All eight files exist and compile.

### Step 7: Hermetic flow specs

- **Files (create)** under `test/foundry/spec/protocols/pol/net/hermetic/` (new):
  - `NetNet_SpotFoT.t.sol`
  - `NetNet_Stake.t.sol`
  - `NetNet_Bond.t.sol`
  - `NetNet_InversePremium.t.sol`
  - `NetNet_PTeam.t.sol`
  - `NetNet_Turbo.t.sol`
- **Do:** Inherit `TestBase_NetNet`. Happy paths call the Service libraries from `address(this)` (tokens sit on the test contract). Revert tests may call domain contracts directly to assert selectors. Exact numbers vs hermetic seeds / `ConstProdUtils` / `Constants.*` / `LendingConstants.*`.

Helpers on TestBase (not new architecture): `_buyNet`, `_sellNet` wrap SpotService; `_crashTwapBelowBacking` sells NET and re-checkpoints until `twapNetUsdg() < backingPerToken * (BPS - INVERSE_SPREAD_BPS) / BPS`; `_liftTwapAbovePremium` buys until TWAP > backing × `PREMIUM_THRESHOLD_WAD`.

Proof table is PRD requirement 7. Bond vest warp is `Constants.BOND_VEST` (2 days). Convert uses `TAX_TEAM_START_BPS` (400), not 300. Epoch rebase after `EPOCH_LENGTH` (8 hours). Turbo `AboveTargetLtv` at `TARGET_LTV_WAD` (0.53125e18).

- **Tests:** the files above
- **Done when:** `forge test --match-path 'test/foundry/spec/protocols/pol/net/hermetic/**'` passes with no RPC.

### Step 8: Comparative hermetic

- **Files (create):**
  - `contracts/protocols/pol/net/test/bases/NetNet_ComparativeScenarios.sol` (new)
  - `test/foundry/spec/protocols/pol/net/comparative/NetNet_ComparativeHermetic.t.sol` (new)
- **Do:** Scenario library holds invariant + selector helpers from PRD requirement 9 (FoT 500 bps, 0 tax on stake/bond, sNET 1:1 backing, Turbo LTV cap, bond price = max(discounted TWAP, backing), zero-amount / not-enabled / `NotHolder` / `AboveTargetLtv` selectors). Thin hermetic contract inherits `TestBase_NetNet` and calls the library. No `assertEq(portOut, forkOut)`.
- **Tests:** `forge test --match-path 'test/foundry/spec/protocols/pol/net/comparative/**'`
- **Done when:** That command passes with no RPC.

### Step 9: Fork TestBase + bind specs

- **Files (create):**
  - `contracts/protocols/pol/net/test/bases/TestBase_NetNetFork.sol` (new)
  - `test/foundry/spec/protocols/pol/net/fork/NetNetFork_Bind.t.sol` (new)
  - `test/foundry/spec/protocols/pol/net/fork/NetNetFork_SpotFoT.t.sol` (new)
  - `test/foundry/spec/protocols/pol/net/fork/NetNetFork_Stake.t.sol` (new)
  - `test/foundry/spec/protocols/pol/net/fork/NetNetFork_Bond.t.sol` (new)
  - `test/foundry/spec/protocols/pol/net/fork/NetNetFork_PTeam.t.sol` (new)
  - `test/foundry/spec/protocols/pol/net/fork/NetNetFork_Turbo.t.sol` (new)
- **Files (modify if needed):** `contracts/constants/networks/ROBINHOOD_MAIN.sol`, `contracts/protocols/pol/net/VENDOR.md`
- **Do:** `vm.createSelectFork(vm.rpcUrl("robinhood_mainnet"), ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK)`. Bind `ROBINHOOD_MAIN.NET`, `SNET`, `NETNET_*`, `USDG`, `UNISWAP_V2_ROUTER02`, `UNISWAP_V2_FACTORY`, `MORPHO`, `NETNET_STEAK_USDG`. `NetNetAwareRepo._initialize` with those live addresses.

If `code.length == 0` at NET / `NETNET_STAKING` / `NETNET_TREASURY` on `20_714_383`, bump `DEFAULT_FORK_BLOCK` to the earliest later block where those three have code. Record the block in `VENDOR.md`. Do not add `NETNET_FORK_BLOCK`.

Fork proofs: PRD requirement 8. Live amounts vs a local quote from live reserves/oracle (`ConstProdUtils` / `PairOracle.twapNetUsdg` / `bondPrice`). InverseBond live fill is not required while TWAP > backing: assert `active() == false` or the live revert selector. Live `PTeam.exercise` only if the test can `prank(NETNET_TEAM_SAFE)` and fund USDG; otherwise view `exercisableNow`. `TaxCollector.convert` when `pendingNet()` and clip allow; otherwise view `pendingNet` / `teamBps`.

- **Tests:** `FOUNDRY_PROFILE=fork forge test --match-path 'test/foundry/spec/protocols/pol/net/fork/**'`
- **Done when:** Bind test proves `code.length > 0` on NET, sNET, Staking, Treasury, BondDepository, TaxCollector, PTeam, TurboRouter, pair, Morpho, steakUSDG. Default `forge test --match-path 'test/foundry/spec/protocols/pol/net/**'` still runs without RPC (fork files skipped).

### Step 10: Comparative fork

- **Files (create):** `test/foundry/spec/protocols/pol/net/fork/NetNet_ComparativeFork.t.sol` (new)
- **Do:** Thin contract inherits `TestBase_NetNetFork`, imports `NetNet_ComparativeScenarios`. Same invariants/selectors as Step 8 on the live subject. Path must contain `/fork/`.
- **Tests:** included in the Step 9 fork command
- **Done when:** `rg "assertEq\\(portOut, forkOut\\)" test/foundry/spec/protocols/pol/net` is empty. File path contains `/fork/`.

### Step 11: Skill + docs

- **Files (create):**
  - `.claude/skills/crane-netnet/SKILL.md` (new)
  - `.claude/skills/crane-netnet/references/services.md` (new)
  - `.claude/skills/crane-netnet/references/testbases.md` (new)
  - `.claude/skills/crane-netnet/references/commands.md` (new)
  - `.grok/skills/crane-netnet/SKILL.md` and the same three references (copy of the Claude tree)
- **Files (modify):**
  - `docs/CODEBASE_MAP.md` (add `pol/` under protocols layout; add a High-value ports row: NetNet / `contracts/protocols/pol/net/` / `crane-netnet`)
  - `docs/protocols/status.md` (Lending table: NetNet **experimental**, P0 port + TestBases, no DFPkg)
- **Do:** Skill `name: crane-netnet`. Description triggers: `"Crane NetNet"`, `"TestBase_NetNet"`, `"protocols/pol/net"`, `"NetNetSpotService"`, `"NET FoT"`. Body under 500 lines. List the four services, both TestBases, and:

```bash
forge test --match-path 'test/foundry/spec/protocols/pol/net/**'
FOUNDRY_PROFILE=fork forge test --match-path 'test/foundry/spec/protocols/pol/net/fork/**'
```

See also: `crane-porting`, `crane-testing`, `crane-morpho`, `crane-uniswap`. One integration skill, not a protocol-architecture family.

- **Tests:** none
- **Done when:** Both skill trees exist. CODEBASE_MAP and `docs/protocols/status.md` mention `protocols/pol/net`.

### Step 12: Isolation and repo green

- **Files:** none unless a hermetic test leaked into `**/fork/**` or the reverse
- **Do:** Confirm `foundry.toml` has no `[profile.netnet_port]`. Confirm `viaIR` is false. Confirm default `no_match_path = "**/fork/**"` still excludes NetNet fork specs.
- **Tests:** commands in Verification
- **Done when:** Hermetic NetNet path passes without RPC. Default `forge test` (full repo) still passes without RPC.

## Acceptance criteria

Flattened from the PRD.

- [ ] Every P0 domain file in PRD requirement 1 is present and compiles.
- [ ] `rwa/`, `winnet/`, `play/`, `climb/`, `superstore/`, `v1/DangerDelegator.sol`, and perp files other than `WrappedStakedNET.sol` / `Zap.sol` are absent from `contracts/protocols/pol/net/`.
- [ ] Dump `IERC20.sol`, `IERC4626.sol`, `IUniswapV2.sol`, `IUniswapV3.sol`, `IMorphoBlue.sol`, dump OZ, and `IRwaDesk.sol` are not in the port tree.
- [ ] `VENDOR.md` records dump pin, AGPL-3.0-only, compilers, by-address map, and the Robinhood fork block actually used.
- [ ] `rg "interfaces/external" contracts/protocols/pol/net` returns no matches.
- [ ] `rg "lending/interfaces/IMorphoBlue|IMorphoBlue" contracts/protocols/pol/net` returns no matches.
- [ ] No OZ / Solady / Morpho / Uni source trees under `pol/net/`.
- [ ] Domain files keep `AGPL-3.0-only` and `pragma solidity ^0.8.24`.
- [ ] Wrappers use `AGPL-3.0-or-later` and `pragma solidity ^0.8.35`.
- [ ] After hermetic `setUp`, `GenesisBond.finalized()`, `Staking.enabled()`, `BondDepository.enabled()`, and `NET.taxEnabled()` are true.
- [ ] `Treasury.canonicalPair()` equals the Crane-created NET/USDG pair and `NET.isTaxedPair(pair)` is true.
- [ ] `ShareCertificate.certificateOf(founder) != 0`; `transferFrom` reverts `Soulbound()`.
- [ ] `Treasury.morphoVault()` is the hermetic Vault V2; `rebalanceToMorpho` increases `morphoAssets()`.
- [ ] No `vm.mockCall` on NET, Staking, Treasury, BondDepository, TaxCollector, PTeam, TurboRouter, LoopbackOracle, Zap, wsNET, Uni pair/router, Morpho Blue, or Vault V2.
- [ ] Four Service files exist at the PRD paths; a fifth Service does not.
- [ ] Hermetic buy/sell/convert/stake/unstake/rebase/deposit/redeem/inverse/premium/pTEAM/turbo/unwind go through those libraries (except selector-only revert tests).
- [ ] `NetNetAwareRepo.sol` exists; `STORAGE_SLOT` is `keccak256(abi.encode("protocols.pol.net.aware")) - 1`; both TestBases call `_initialize`.
- [ ] Eight `Behavior_I*` files exist; hermetic specs call them.
- [ ] `forge test --match-path 'test/foundry/spec/protocols/pol/net/hermetic/**'` passes with no RPC.
- [ ] `forge test --match-path 'test/foundry/spec/protocols/pol/net/**'` (default profile) passes with no RPC.
- [ ] Fork specs live under `test/foundry/spec/protocols/pol/net/fork/` and are the only NetNet tests that need RPC.
- [ ] `FOUNDRY_PROFILE=fork forge test --match-path 'test/foundry/spec/protocols/pol/net/fork/**'` is the command that runs fork specs.
- [ ] `NetNet_ComparativeScenarios.sol` is imported by both thin comparative contracts.
- [ ] `rg "assertEq\\(portOut, forkOut\\)" test/foundry/spec/protocols/pol/net` returns no matches.
- [ ] Comparative fork path contains `/fork/`.
- [ ] `foundry.toml` has no `[profile.netnet_port]`.
- [ ] `viaIR` remains false.
- [ ] Default `forge test` (repo suite) still passes with no RPC.
- [ ] `.claude/skills/crane-netnet/SKILL.md` and `.grok/skills/crane-netnet/SKILL.md` list the four services, both TestBases, and the two forge commands.
- [ ] `docs/CODEBASE_MAP.md` and `docs/protocols/status.md` mention `protocols/pol/net`.

## Verification

Run in order. Stop on the first failure.

```bash
# 1. Compile (viaIR must stay false in foundry.toml)
forge build

# 2. Hermetic NetNet (no RPC)
forge test --match-path 'test/foundry/spec/protocols/pol/net/hermetic/**' -vv

# 3. All default-profile NetNet paths (fork dir skipped by no_match_path)
forge test --match-path 'test/foundry/spec/protocols/pol/net/**' -vv

# 4. Grep gates
rg "interfaces/external" contracts/protocols/pol/net
rg "IMorphoBlue" contracts/protocols/pol/net
rg "assertEq\\(portOut, forkOut\\)" test/foundry/spec/protocols/pol/net
rg "\\[profile\\.netnet_port\\]" foundry.toml

# 5. Fork (opt-in; needs robinhood_mainnet RPC)
FOUNDRY_PROFILE=fork forge test --match-path 'test/foundry/spec/protocols/pol/net/fork/**' -vv

# 6. Repo default suite still green (no RPC)
forge test
```

Command 5 may be skipped in an environment with no Robinhood RPC only after command 3 has proven fork files are not collected. Command 6 is still required before merge.

## Do not

- Do not change files outside a step’s Files list without a PRD update (allowed extras: none)
- Do not reopen locked decisions
- Do not add `[profile.netnet_port]`, `NETNET_FORK_BLOCK`, DFPkg, FTR, or `viaIR`
- Do not copy P1/P2 dump trees or dump IERC20/Uni/Morpho interfaces
- Do not inherit `TestBase_MorphoBlue`
- Do not `vm.mockCall` the SUT
- Do not `assertEq(portOut, forkOut)` for market-dependent amounts
- Do not write `docs/superpowers/plans/2026-08-28-netnet-pol-port.md`
- Do not treat Olympus as NetNet
