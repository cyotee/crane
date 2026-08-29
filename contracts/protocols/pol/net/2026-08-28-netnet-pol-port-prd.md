---
project: NetNet Capital ($NET) reserve-protocol port into Crane under protocols/pol/net
version: 0.4
status: planned
created: 2026-08-28
last_updated: 2026-08-28
owner: Crane core
decisions_locked: 2026-08-28
related:
  - .claude/skills/crane-porting/SKILL.md
  - .claude/skills/crane-porting-verification/SKILL.md
  - .claude/skills/crane-testing/SKILL.md
  - .claude/skills/crane-morpho/SKILL.md
  - contracts/constants/networks/ROBINHOOD_MAIN.sol
  - contracts/protocols/lending/morpho/blue/
  - contracts/protocols/dexes/uniswap/v2/
  - scripts/netnet/README.md
  - scripts/netnet/contracts.json
  - scripts/netnet/dump/tree/
upstream:
  - none (no public git repo)
  - pin: verified sources dumped 2026-08-28 (Sourcify + Blockscout PRO)
official_docs:
  - https://docs.netnet.capital/
  - https://docs.netnet.capital/official-channels
  - https://docs.netnet.capital/llms.txt
  - https://app.netnet.capital/
---

# PRD: Port NetNet Capital into Crane (`protocols/pol/net`)

- **Status:** planned
- **Created:** 2026-08-28
- **Updated:** 2026-08-28
- **Source request:** Port NetNet Capital Management (reserve token NET on Robinhood Chain, chain id 4663) into Crane as a faithful domain port under `contracts/protocols/pol/net/` so hermetic tests deploy our copy of the dumped contracts, fork tests bind live Official Channels addresses, and comparative tests assert matching invariants and revert selectors.

## Summary

When this PRD is done, Crane has a faithful NetNet domain tree at `contracts/protocols/pol/net/`, four flow-split Service libraries, one `NetNetAwareRepo`, Behavior libraries, hermetic and fork TestBases, path-scoped Foundry specs, a `crane-netnet` skill, and a CODEBASE_MAP note. Hermetic boot is real `GenesisBond.wire()` plus `GenesisBond.finalize()` against Crane Uniswap V2, a real Morpho Vault V2 as the Treasury ERC-4626, and real Morpho Blue for Loopback. Default `forge test` stays green because fork specs live under `**/fork/**`. P0 does not add a Foundry profile, a Diamond DFPkg, or RwaDesk / arcade / futures desks.

## Requirements

### 1. P0 domain sources live only under `contracts/protocols/pol/net/`

Copy P0 contracts from `scripts/netnet/dump/by-address/<addr>/files/` (not blindly from `dump/tree/`, which last-write-wins). Use the live address in `scripts/netnet/contracts.json` / `ROBINHOOD_MAIN` for each file. Core `Constants.sol` / `Wired.sol` come from the NET/Treasury dumps. `LendingConstants.sol` comes from the Loopback/Turbo dumps.

P0 domain files (and no others):

```text
contracts/protocols/pol/net/
├── 2026-08-28-netnet-pol-port-prd.md
├── PLAN.md                          # written by /prd-plan; not this PRD
├── VENDOR.md
├── src/
│   ├── NET.sol
│   ├── StakedNET.sol
│   ├── Staking.sol
│   ├── Treasury.sol
│   ├── Distributor.sol
│   ├── BondDepository.sol
│   ├── InverseBond.sol
│   ├── PremiumSeller.sol
│   ├── PairOracle.sol
│   ├── TaxCollector.sol
│   ├── PTeam.sol
│   ├── GenesisBond.sol
│   ├── ShareCertificate.sol
│   ├── Constants.sol
│   ├── abstract/Wired.sol
│   ├── libraries/FixedPointMath.sol
│   ├── interfaces/                  # NetNet I* only (INET, IStaking, …)
│   ├── lending/
│   │   ├── LoopbackOracle.sol
│   │   ├── TurboRouter.sol
│   │   └── LendingConstants.sol
│   └── perp/
│       ├── WrappedStakedNET.sol
│       └── Zap.sol
├── services/
├── aware/
└── test/bases/
```

- [ ] Every file in the P0 list is present and compiles.
- [ ] `rwa/`, `winnet/`, `play/`, `climb/`, `superstore/`, `v1/DangerDelegator.sol`, and perp files other than `WrappedStakedNET.sol` / `Zap.sol` are absent from `contracts/protocols/pol/net/`.
- [ ] `src/interfaces/external/IERC20.sol`, `IERC4626.sol`, `IUniswapV2.sol`, and `src/lending/interfaces/IMorphoBlue.sol` are not copied.
- [ ] `lib/openzeppelin-contracts/` from the dump is not copied.
- [ ] `VENDOR.md` records dump date `2026-08-28`, `scripts/netnet/dump/state.json` counts, AGPL-3.0-only, live compiler `0.8.30+commit.73712a01` / optimizer 800 / EVM osaka / `viaIR: false`, the by-address source of each P0 file, and the Robinhood fork block actually used.

### 2. Every import uses `@crane/`; shared deps remap to existing Crane trees

Convert dumped relative imports to `@crane/contracts/...`. Domain siblings import `@crane/contracts/protocols/pol/net/src/...`. Crane wrappers use `@crane/` only. Substitution map:

| Dump import | Crane target |
|-------------|--------------|
| `IERC20` | `@crane/contracts/interfaces/IERC20.sol` |
| `IERC20Metadata` | `@crane/contracts/interfaces/IERC20Metadata.sol` |
| `IERC4626` | `@crane/contracts/external/openzeppelin-contracts/interfaces/IERC4626.sol` |
| `IUniswapV2Factory` | `@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol` |
| `IUniswapV2Pair` | `@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol` |
| `IUniswapV2Router02` | `@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol` |
| `IMorphoBlue` + nested `IMorphoBlue.MarketParams` | `@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol` (`IMorpho`, file-level `MarketParams`) plus `@crane/contracts/external/morpho/blue/interfaces/IMorphoCallbacks.sol` for supply/repay callbacks |

- [ ] `rg "interfaces/external" contracts/protocols/pol/net` returns no files.
- [ ] `rg "lending/interfaces/IMorphoBlue" contracts/protocols/pol/net` returns no matches.
- [ ] No `openzeppelin-contracts`, Solady, Morpho, or Uniswap source trees exist under `pol/net/`.
- [ ] Domain files keep `SPDX-License-Identifier: AGPL-3.0-only` and `pragma solidity ^0.8.24` (Crane solc 0.8.35 compiles them). Do not relicense domain files.
- [ ] Crane wrappers (`services/`, `aware/`, `test/bases/`) use `SPDX-License-Identifier: AGPL-3.0-or-later` and `pragma solidity ^0.8.35`.

### 3. Hermetic boot is real `wire()` then `GenesisBond.finalize()`

`TestBase_NetNet` inherits `TestBase_UniswapV2` (Crane `UniV2Factory` + `UniV2Router02`). It does not inherit `TestBase_MorphoBlue` (that base deploys mock loan/collateral tokens). It deploys Morpho Blue and AdaptiveCurveIRM the same way `TestBase_MorphoBlue` does: `new Morpho(...)`, `new AdaptiveCurveIrm(...)`. Treasury vault is real `VaultV2` from `contracts/external/morpho/vault-v2/` with the hermetic USDG as asset. Adapters on that vault are not required in P0. USDG is a mintable ERC-20 test double with 6 decimals. Hermetic `PTeam` `holder` is a TestBase address (`pTeamHolder`), not the live Safe.

Required boot sequence:

1. Deploy Uni V2 factory + router, mintable USDG (6 decimals), Morpho Blue, AdaptiveCurveIRM, Vault V2 (USDG asset).
2. Deploy P0 domain contracts. Create the NET/USDG pair via the Crane factory before Treasury/GenesisBond constructors that take the pair.
3. Call `wire()` on every `Wired` contract. GenesisBond `wire(bondDepository, certificate)` is required. Do not skip `wire()`.
4. Mint USDG to a founder and `GenesisBond.purchase` until `raisedRaw * usdgWadFactor >= Constants.GENESIS_MIN_RAISE_WAD` (15_000e18).
5. `vm.warp` past `saleDeadline` (`Constants.GENESIS_DEADLINE` = 7 days) unless the hard cap was hit, then `GenesisBond.finalize()`.
6. `finalize()` must transfer 70% USDG to Treasury, seed POL with the remaining 30% via `pair.mint` to Treasury (not the router), enable staking, enable BondDepository, `NET.enableTax(pair)`, and `oracle.checkpoint()`.
7. Create the Loopback Morpho Blue market: loan USDG, collateral wsNET, `LoopbackOracle`, AdaptiveCurveIRM, LLTV `LendingConstants.LLTV` (0.625e18). Supply USDG as a credit participant for Turbo tests.

- [ ] After `setUp`, `GenesisBond.finalized()` is true and `Staking.enabled()`, `BondDepository.enabled()`, and `NET.taxEnabled()` are true.
- [ ] `Treasury.canonicalPair()` equals the Crane-created NET/USDG pair and `NET.isTaxedPair(pair)` is true.
- [ ] `ShareCertificate.certificateOf(founder) != 0` after genesis purchase; `transferFrom` reverts `Soulbound()`.
- [ ] `Treasury.morphoVault()` is the hermetic Vault V2. `rebalanceToMorpho` deposits USDG and increases `morphoAssets()`.
- [ ] No `vm.mockCall` on NET, Staking, Treasury, BondDepository, TaxCollector, PTeam, TurboRouter, LoopbackOracle, Zap, wsNET, Uni pair/router, Morpho Blue, or Vault V2.

### 4. Four Service libraries wrap every P0 tested entrypoint

Libraries are stateless. Functions are `internal` with `_` prefix. Params live in structs. Service execution context is the caller (same rule as `MorphoBlueService`).

**`NetNetSpotService`**

| Function | Calls |
|----------|--------|
| `_buyNetWithUsdg(BuyParams)` | `IUniswapV2Router02.swapExactTokensForTokensSupportingFeeOnTransferTokens` path `[usdg, net]` |
| `_sellNetForUsdg(SellParams)` | same router, path `[net, usdg]` |
| `_convert(ConvertParams)` | `ITaxCollector.convert(netAmount, minUsdgOutRaw)` |

`BuyParams` / `SellParams`: `router`, `tokenIn`, `tokenOut`, `amountIn`, `amountOutMin`, `to`, `deadline`. `ConvertParams`: `taxCollector`, `netAmount`, `minUsdgOutRaw`.

**`NetNetStakingService`**

| Function | Calls |
|----------|--------|
| `_stake(StakeParams)` | `IStaking.stake(to, amount)` |
| `_unstake(UnstakeParams)` | `IStaking.unstake(to, amount)` |
| `_rebase(IStaking staking)` | `IStaking.rebase()` |

**`NetNetBondService`** (includes pTEAM)

| Function | Calls |
|----------|--------|
| `_deposit(DepositParams)` | `IBondDepository.deposit(marketId, amount, maxPriceWad, to)` |
| `_redeem(RedeemParams)` | `IBondDepository.redeem(to)` |
| `_inverseSwap(InverseSwapParams)` | `IInverseBond.swap(netAmount, minUsdgOutRaw)` |
| `_premiumExecute(PremiumExecuteParams)` | `IPremiumSeller.execute(minUsdgOutRaw)` |
| `_exercisePTeam(PTeamExerciseParams)` | `IPTEAM.exercise(netAmount)` |

P0 tests call `_deposit` with `marketId == 0` (USDG reserve). `marketId == 1` (LP) is not a P0 test gate.

**`NetNetTurboService`**

| Function | Calls |
|----------|--------|
| `_setMorphoAuthorization(AuthParams)` | `IMorpho.setAuthorization(router, authorized)` |
| `_turbo(TurboParams)` | `TurboRouter.turbo(wsIn, borrowAssets, minWsFromLoop)` |
| `_unwind(UnwindParams)` | `TurboRouter.unwind(repayShares, wsCollateralOut, minUsdgFromSale)` |

- [ ] The four files exist at `contracts/protocols/pol/net/services/NetNet{Spot,Staking,Bond,Turbo}Service.sol`.
- [ ] A fifth Service library does not exist.
- [ ] Hermetic tests for buy/sell/convert/stake/unstake/rebase/deposit/redeem/inverse/premium/pTEAM/turbo/unwind go through these library functions (not only raw domain calls), except where a test is asserting a revert before the Service would be used.

### 5. One `NetNetAwareRepo` holds P0 protocol addresses

Slot string: `"protocols.pol.net.aware"`. Dual `_layoutStruct` overloads. `Storage` and `_initialize` take `NetNetAwareInit` (struct, not a long arg list):

`usdg`, `net`, `sNet`, `staking`, `treasury`, `bondDepository`, `inverseBond`, `premiumSeller`, `taxCollector`, `pteam`, `canonicalPair`, `router`, `turboRouter`, `wsNet`, `zap`, `morpho`, `loopbackMarketId`, `morphoVault`, `pTeamHolder`.

One getter pair per field (`_net()`, `_net(Storage)`).

- [ ] File exists at `contracts/protocols/pol/net/aware/NetNetAwareRepo.sol`.
- [ ] `STORAGE_SLOT` is `bytes32(uint256(keccak256(abi.encode("protocols.pol.net.aware"))) - 1)`.
- [ ] Hermetic and fork TestBases call `_initialize` with the subject’s addresses (deployed vs `ROBINHOOD_MAIN`).

### 6. Behavior libraries match dumped interface names

Files under `contracts/protocols/pol/net/test/bases/`:

- `Behavior_INET.sol` (FoT bps, taxed pair, exempt, `TaxCollected`)
- `Behavior_IStaking.sol`
- `Behavior_IBondDepository.sol`
- `Behavior_IInverseBond.sol`
- `Behavior_IPremiumSeller.sol`
- `Behavior_ITaxCollector.sol`
- `Behavior_IPTEAM.sol`
- `Behavior_ITurboRouter.sol`

Use `expect_*` / `isValid_*` / `hasValid_*` per `crane-testing`. Do not name them `Behavior_NetNet*`.

- [ ] Each listed file exists.
- [ ] Hermetic specs call the matching Behavior for the flow they test.

### 7. Hermetic specs cover every P0 flow with exact seeded asserts

Location: `test/foundry/spec/protocols/pol/net/hermetic/` (not under `**/fork/**`).

| File | Must prove |
|------|------------|
| `NetNet_SpotFoT.t.sol` | Buy and sell via FoT router; tax 500 bps (`Constants.TAX_TOTAL_BPS`) on the mapped pair; wallet-to-wallet transfer untaxed; protocol ops (stake/bond) untaxed; `TaxCollector.convert` after accrual uses `Constants.TAX_TEAM_START_BPS` (400) decaying with `pTEAM.vestedFraction()`, not the stale 300 bps interface comment; `Converted` event; clip / TWAP deviation reverts |
| `NetNet_Stake.t.sol` | `stake` / `unstake` 1:1; `totalStaked` backs sNET; `rebase` after `EPOCH_LENGTH` (8 hours) is monotonic on index; unstaked NET returns |
| `NetNet_Bond.t.sol` | Market 0 `deposit` then warp `Constants.BOND_VEST` (2 days) then `redeem`; price = max(discounted TWAP, backing); epoch cap revert; vest linear |
| `NetNet_InversePremium.t.sol` | Inverse: sell NET into the pair and warp at least `TWAP_MIN_WINDOW` until TWAP is below backing × (1 − `INVERSE_SPREAD_BPS`), then `_inverseSwap` burns NET and pays USDG; out of band / capacity reverts. Premium: buy until TWAP > backing × `PREMIUM_THRESHOLD_WAD` (2e18), warp `PREMIUM_MIN_INTERVAL`, `_premiumExecute` mints/sells clip and sweeps USDG to Treasury; inactive reverts |
| `NetNet_PTeam.t.sol` | `prank(pTeamHolder)` after warp of vest; strike 1 USDG/NET paid into Treasury; `NotHolder` and `ExceedsVestedCap` selectors |
| `NetNet_Turbo.t.sol` | `setAuthorization` then `_turbo` increases wsNET collateral; LTV above `TARGET_LTV_WAD` (0.53125e18) reverts `AboveTargetLtv`; `_unwind` reduces debt |

Numeric asserts are against the hermetic seed and local quotes (`ConstProdUtils`, oracle reads, `Constants.*`). Bond vest is 2 days (`Constants.BOND_VEST`), not the stale 5-day sentence on `IBondDepository`.

- [ ] `forge test --match-path 'test/foundry/spec/protocols/pol/net/hermetic/**'` passes with no RPC.
- [ ] `forge test --match-path 'test/foundry/spec/protocols/pol/net/**'` (default profile) passes with no RPC (fork paths excluded by `no_match_path = "**/fork/**"`).

### 8. Fork specs bind `ROBINHOOD_MAIN` at `DEFAULT_FORK_BLOCK`

`TestBase_NetNetFork` does `vm.createSelectFork(vm.rpcUrl("robinhood_mainnet"), ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK)` and binds `NET`, `NETNET_*` constants. Do not add `NETNET_FORK_BLOCK`.

If `code.length == 0` at `NET` / `NETNET_STAKING` / `NETNET_TREASURY` on the current pin (`20_714_383`), bump `ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK` to a block where those three have code. Record the new block in `VENDOR.md`. That pin is shared with other Robinhood fork suites.

Fork specs live under `test/foundry/spec/protocols/pol/net/fork/` so the default profile skips them.

| File | Must prove |
|------|------------|
| `NetNetFork_Bind.t.sol` | `code.length > 0` on NET, sNET, Staking, Treasury, BondDepository, TaxCollector, PTeam, TurboRouter, pair, Morpho, steakUSDG |
| `NetNetFork_SpotFoT.t.sol` | Live buy/sell via `UNISWAP_V2_ROUTER02`; tax bps; `convert` when `pendingNet()` and clip allow, otherwise view `pendingNet` / `teamBps` |
| `NetNetFork_Stake.t.sol` | Live stake/unstake/rebase against a precomputed local quote |
| `NetNetFork_Bond.t.sol` | Live market 0 deposit+redeem against live `bondPrice`; InverseBond live fill is not required while TWAP > backing; then assert `active()` false or the live revert selector |
| `NetNetFork_PTeam.t.sol` | View `exercisableNow`; live `exercise` only if the test can `prank(NETNET_TEAM_SAFE)` and fund USDG; otherwise view-only |
| `NetNetFork_Turbo.t.sol` | Live authorization / target LTV revert / turbo against live Loopback market |
| `NetNet_ComparativeFork.t.sol` | See requirement 9 |

Live amounts assert against a precomputed local quote from live reserves/oracle, not against the hermetic run.

- [ ] `FOUNDRY_PROFILE=fork forge test --match-path 'test/foundry/spec/protocols/pol/net/fork/**'` is the only command that runs these files.
- [ ] Default `forge test` does not execute them (no RPC required).

### 9. Comparative tests share a scenario library; no cross-subject amount equality

`NetNet_ComparativeScenarios.sol` in `contracts/protocols/pol/net/test/bases/` holds invariant + selector helpers. Two thin contracts:

- `test/foundry/spec/protocols/pol/net/comparative/NetNet_ComparativeHermetic.t.sol` (default profile)
- `test/foundry/spec/protocols/pol/net/fork/NetNet_ComparativeFork.t.sol` (fork profile)

Same-behavior rules:

| Class | Rule |
|-------|------|
| Protocol invariants | Both subjects: FoT 500 bps on mapped pair; 0 tax on stake/bond; sNET fragments backed 1:1 by staked NET; Turbo refuses LTV > target; BondDepository price = max(discounted TWAP, backing) |
| Selector / revert | Same custom error selector on both for the same bad input (zero amount, not enabled, price above max, `NotHolder`, `AboveTargetLtv`) |
| Events | Same event signatures; indexed fields match roles (addresses may differ) |
| Numeric equality | Not required across subjects for AMM output or rebase size |
| Forbidden | `assertEq(portOut, forkOut)` for market-dependent amounts unless both runs are on the same fork |

Do not `etch` port bytecode onto live addresses in P0. Do not `vm.mockCall` either SUT.

- [ ] Scenario library compiles and is imported by both thin contracts.
- [ ] `rg "assertEq\\(portOut, forkOut\\)" test/foundry/spec/protocols/pol/net` returns no matches.
- [ ] Comparative fork file path contains `/fork/` so default `forge test` skips it.

### 10. Foundry isolation uses existing `default` and `fork` profiles only

Do not add `[profile.netnet_port]`. Hermetic + comparative-hermetic specs sit outside `**/fork/**`. Fork specs sit under `**/fork/**`. Path filter for agents: `--match-path 'test/foundry/spec/protocols/pol/net/**'`.

- [ ] `foundry.toml` has no `[profile.netnet_port]`.
- [ ] Default `forge test` (repo suite) still passes after this port lands, with no RPC.
- [ ] `viaIR` remains false. Stack-too-deep is fixed with param structs, not IR.

### 11. Docs and `crane-netnet` skill ship in P0

- Canonical skill: `.claude/skills/crane-netnet/SKILL.md` (name `crane-netnet`). Mirror the same tree at `.grok/skills/crane-netnet/` (same layout as `crane-morpho`). Follow `skill-authoring`: body under 500 lines; `references/` for service API, TestBase boot, and fork commands. Description triggers include `"Crane NetNet"`, `"TestBase_NetNet"`, `"protocols/pol/net"`, `"NetNetSpotService"`, `"NET FoT"`. This is one Crane-integration skill, not a `netnet-architecture` / `netnet-operations` family.
- `docs/CODEBASE_MAP.md` gains a NetNet row pointing at `contracts/protocols/pol/net/`.
- `docs/protocols/status.md` gains a NetNet row labeled **experimental** (P0 port + TestBases; no DFPkg).

- [ ] `.claude/skills/crane-netnet/SKILL.md` and `.grok/skills/crane-netnet/SKILL.md` exist and list the four services, both TestBases, and the two forge commands in requirements 7–8.
- [ ] CODEBASE_MAP and protocols/status mention `protocols/pol/net`.

### 12. Architecture testers must implement (not invent)

```text
User USDG
  ├─ Uniswap V2 NET/USDG (canonical pair) ── 5% FoT ── TaxCollector
  ├─ BondDepository.deposit(0) ── vest 2d ── NET
  └─ (P1, out of scope) RwaDesk.bond

NET ── Staking.stake ── sNET ── WrappedStakedNET.wrap ── wsNET
                                              │
                    Morpho Blue Loopback ─────┘ collateral
                    USDG loan ── TurboRouter.turbo ── buy NET ── Zap ── more wsNET
```

Reuse: `ROBINHOOD_MAIN.USDG` (fork), `UNISWAP_V2_*`, `MORPHO` / `NETNET_LOOPBACK_*`, `NETNET_STEAK_USDG` (fork bind only). Hermetic AMM is Crane Uni V2 stubs. Hermetic Treasury vault is Crane-vendored Vault V2. Hermetic Loopback is Crane-vendored Morpho Blue + AdaptiveCurveIRM + ported `LoopbackOracle`.

## Non-goals

- Public git submodule of NetNet (no public repo).
- `contracts/external/netnet/` tree.
- Vendoring steakUSDG, Morpho Blue, Uni V2 pair, Gnosis Safe, or AdaptiveCurveIRM (bind or reuse Crane trees).
- Bytecode-identical compile vs mainnet in P0 (`extcodehash` / matching 0.8.30/800/osaka profile is a later optional gate).
- `etch` of port bytecode onto live addresses.
- Redeploying $NET on Robinhood mainnet.
- Diamond Facet-Target-Repo / DFPkg.
- `viaIR`.
- Adding `[profile.netnet_port]` or `NETNET_FORK_BLOCK`.
- Treating Olympus v2/v3 contracts as NetNet.
- Inventing sources for unverified addresses (`NETNET_PERP_ORACLE`, `NETNET_DRAND_SIG_REGISTRY`, on-chain `NETNET_BLACKJACK_LOGIC`, THE BUTTON).
- RwaDesk + Rialto equity fill (P1, later PRD).
- Arcade, WinNET, Superstore, CLIMB, TURBO cards, futures/CASHCAT desks (P2, later PRD).
- A `netnet-architecture` / `netnet-operations` skill family (follow-up after `crane-netnet`).
- Bond market 1 (LP bond) as a P0 test gate.
- Live InverseBond fills while NET trades above NAV.

## Constraints

- Solidity 0.8.35, optimizer runs 1, EVM Prague, `viaIR = false` for Crane compile. Live NetNet is 0.8.30 / 800 / osaka / viaIR false. P0 gate is behavioral parity, not matching bytecode.
- Crane `foundry.toml` has two profiles only: `default` skips `**/fork/**`; `fork` runs only `**/fork/**`.
- Production-first: Uni V2 and Morpho in hermetic tests are Crane ports, not interface mocks of the SUT. USDG may be a mintable 6-decimal double because Paxos USDG is not the SUT.
- Domain license AGPL-3.0-only as dumped. Crane wrappers AGPL-3.0-or-later.
- Dump refresh: `python3 scripts/netnet/dump_verified_sources.py`. Pin is the 2026-08-28 dump unless a later dump is recorded in `VENDOR.md` before copy.
- Tax split, bond vest, genesis caps, and FoT bps come from `src/Constants.sol` / `LendingConstants.sol`, not from stale NatSpec on dumped interfaces.
- FoT swaps use only `swapExactTokensForTokensSupportingFeeOnTransferTokens` on Uni V2 Router02. Exact-output routers are out of scope.
- `TestBase_NetNetFork` uses `ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK`. Bump that constant if NetNet has no code at the current pin.
- No new Foundry remapping aliases for this port.

## Actors

| Actor | Role |
|-------|------|
| FoT trader | Buys/sells NET on the canonical Uni V2 pair; pays 5% tax on mapped-pair legs |
| Staker | `stake` / `unstake` / permissionless `rebase` |
| Bonder | `BondDepository.deposit(0)` and `redeem` after 2-day vest |
| Inverse seller | `InverseBond.swap` when TWAP is below backing minus spread |
| Premium keeper | Permissionless `PremiumSeller.execute` when TWAP ≥ 2× backing |
| Tax keeper | Permissionless `TaxCollector.convert` after FoT accrual |
| pTEAM holder | Sole `PTeam.exercise` caller (hermetic: `pTeamHolder`; fork: `NETNET_TEAM_SAFE`) |
| Turbo user | `morpho.setAuthorization(router, true)` then `turbo` / `unwind` |
| Genesis founder | Hermetic `GenesisBond.purchase` then `finalize` (test boot only) |
| Fork CI | Opt-in `FOUNDRY_PROFILE=fork` with Robinhood RPC |

## Decisions

| ID | Decision | Status | Rationale |
|----|----------|--------|-----------|
| D1 | Domain home is `contracts/protocols/pol/net/` only. No `contracts/external/netnet/`. | Decided | Locked 2026-08-28; confirmed on review |
| D2 | Product name NetNet / token NET / path `pol/net` / constants `NETNET_*`. | Decided | Official Channels + `ROBINHOOD_MAIN` |
| D3 | Domain license AGPL-3.0-only as dumped. Wrappers AGPL-3.0-or-later. | Decided | Dump SPDX + Crane wrapper convention |
| D4 | Upstream pin is the 2026-08-28 Sourcify/Blockscout dump. No public git. | Decided | No public repo |
| D5 | Do not treat Olympus as this protocol. | Decided | Different bytecode |
| D6 | P0 = domain + four services + AwareRepo + Behaviors + both TestBases + hermetic/fork/comparative tests + `crane-netnet` skill. No DFPkg. | Decided | Review Q&A 2026-08-28 |
| D7 | P0 user flows: FoT buy/sell, stake/unstake/rebase, BondDepository discount bond, TurboRouter + Morpho Blue, plus convert, pTEAM, InverseBond, PremiumSeller. | Decided | Review Q&A: wrap all extras |
| D8 | Services split per flow; pTEAM lives on `NetNetBondService` with inverse and premium. Spot owns convert. | Decided | Review Q&A 2026-08-28 |
| D9 | One `NetNetAwareRepo`, slot `protocols.pol.net.aware`. | Decided | Crane Aware pattern |
| D10 | Hermetic Morpho: real Vault V2 (Treasury IERC4626) and real Morpho Blue (Loopback). No ERC-4626 fake of steakUSDG. | Decided | Locked 2026-08-28 |
| D11 | Hermetic boot: real `wire()` + `GenesisBond.finalize()` on Crane Uni V2. No equivalent skip path. | Decided | Locked; review removed “or equivalent” |
| D12 | Comparative tests: shared invariants + revert selectors. No `assertEq(portOut, forkOut)` for market amounts. Scenario library + two thin contracts. Fork comparative file lives under `**/fork/**`. | Decided | Locked + foundry two-profile rule |
| D13 | Fork pin is `DEFAULT_FORK_BLOCK`. Bump it if NetNet has no code. No `NETNET_FORK_BLOCK`. | Decided | Locked 2026-08-28 |
| D14 | RwaDesk is P1. Arcade / WinNET / Superstore / futures desks are P2. | Decided | Locked 2026-08-28 |
| D15 | viaIR forbidden. | Decided | Crane law |
| D16 | No new Foundry profile. Use `default` + `fork` only. | Decided | Review Q&A; `foundry.toml` documents two profiles |
| D17 | Compile vs live: behavioral parity, not `extcodehash`. | Decided | solc/optimizer differ |
| D18 | Convert every dumped import to `@crane/`. Remap shared IERC20/IERC4626/Uni/Morpho to the Crane targets in requirement 2. | Decided | Review Q&A 2026-08-28 |
| D19 | Fork CI is opt-in. Hermetic suite must pass without RPC. | Decided | `no_match_path = "**/fork/**"` |
| D20 | Greenfield redeploy is hermetic and testnets only. | Decided | Locked |
| D21 | Copy P0 files from `dump/by-address/`, not wholesale `dump/tree/` (conflicts + P1/P2 sources). | Decided | Dump README + conflict dir |
| D22 | Behavior files are `Behavior_I{Interface}` matching dumped interfaces. | Decided | `crane-testing` / Olympus / Morpho convention |
| D23 | `/prd-plan` writes sibling `contracts/protocols/pol/net/PLAN.md`. Do not write `docs/superpowers/plans/2026-08-28-netnet-pol-port.md`. | Decided | Review Q&A; PRD pipeline |
| D24 | P0 ships `.claude/skills/crane-netnet/SKILL.md` and a mirror at `.grok/skills/crane-netnet/` (single integration skill). | Decided | Review Q&A 2026-08-28 |
| D25 | `TestBase_NetNet` inherits `TestBase_UniswapV2` and deploys Morpho Blue / Vault V2 itself; it does not inherit `TestBase_MorphoBlue`. | Decided | Morpho Blue TestBase owns mock tokens that are not NET/USDG |
| D26 | Constants win over stale interface comments (tax team start 400 bps, bond vest 2 days). | Decided | `Constants.sol` is the dumped source of truth |

## Execute

Implementation plan: `./PLAN.md`
Run: `/goal contracts/protocols/pol/net/PLAN.md`
