---
project: BattleChain greenfield — script usage guide (agents + operators)
version: 1.0
status: active
created: 2026-07-26
last_updated: 2026-07-26
purpose: How to run BC greenfield Foundry scripts and what each phase deploys
authority:
  - docs/deployment/BC_GREENFIELD_DEPLOYMENT_PRD.md
  - docs/deployment/BC_GREENFIELD_GAP_REPORT.md
  - docs/deployment/BC_GREENFIELD_COMMANDS.md
related:
  - contracts/constants/networks/BC_TESTNET.sol
  - scripts/foundry/bc/
  - test/foundry/spec/scripts/bc/
---

# BC greenfield — script usage guide

**Audience:** agents and operators who need to **run, verify, or extend** the BattleChain greenfield deploy suite without re-deriving intent from the PRD.

**Repo root (all commands):** Crane workspace root (this package).

**Status (gap report v1.9):** All phase scripts **exist**, **compile**, and have **local/hermetic or fork** smoke. **Live BC broadcast is blocked** until GATE-5/6 (X review + real security contact). See [`BC_GREENFIELD_GAP_REPORT.md`](./BC_GREENFIELD_GAP_REPORT.md).

---

## 1. Quick orientation

| What | Where |
|------|--------|
| Operator scripts | `scripts/foundry/bc/Script_BC_Phase*.s.sol` |
| Shared deploy helpers (testable) | `scripts/foundry/bc/Bc*Phase*Deploy.sol` |
| Shared base (binds, guards, manifests) | `scripts/foundry/bc/BCPhaseScriptBase.s.sol` |
| Network constants / BC binds | `contracts/constants/networks/BC_TESTNET.sol` |
| Local/fork tests | `test/foundry/spec/scripts/bc/` |
| Address manifests (docs) | `docs/deployment/addresses/battlechain-sepolia*.json` |
| Runtime copies | `script/output/battlechain-sepolia/*.latest.json` |
| Frozen one-liners | [`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md) |
| What *must* deploy (authoritative) | [`BC_GREENFIELD_DEPLOYMENT_PRD.md`](./BC_GREENFIELD_DEPLOYMENT_PRD.md) §6 |
| Conformance / open gates | [`BC_GREENFIELD_GAP_REPORT.md`](./BC_GREENFIELD_GAP_REPORT.md) |

### 1.1 Policy (do not ignore)

1. **No live** `forge script --broadcast` to BattleChain testnet (chain **627**) until §0 live gate is green (all scripts tested + GATE-5/6).
2. **No product knobs** — salts, markets, Timelock delay, token lists are **hardcoded**. Do not add `vm.env*` for product choices.
3. **Bind, never redeploy** BC-provided contracts (WETH, Uni V3, Euler mock, Venus mock, Chainlink mocks, SafeHarbor stack, etc.).
4. **Never bind** abandoned Wave A Create3Factory `0xC8E93C3c…AD3A` as the greenfield root (`ABANDONED_CREATE3_FACTORY` guard).
5. **Phase 11 Resupply is dropped** — no script.
6. Greenfield **intentionally overwrites** shared `battlechain-sepolia*.json` paths when live eventually runs (`generation: greenfield`).

### 1.2 Deploy modes

| Mode | When to use | How |
|------|-------------|-----|
| **Hermetic / unit** | Always-on CI DoD; no RPC | `forge test --match-path test/foundry/spec/scripts/bc/…_Hermetic.t.sol` |
| **BC fork in-process** | Prove against real BC code | `forge test` + `vm.createSelectFork` (preferred) |
| **Anvil fork + script** | Bind scripts / operator dry-run | `anvil --fork-url …` then `forge script --broadcast` to **local** Anvil only |
| **Live broadcast** | Tier D only | `forge script --rpc-url battlechain-sepolia --broadcast …` |

Prefer **`createSelectFork` tests** over multi-tx Anvil `--broadcast` for DoD (agent environments often fail multi-tx broadcast with OS errors).

---

## 2. Architecture agents must know

```
Script_BC_PhaseN_*.s.sol     ← operator entry: run(), broadcast, manifests
        │
        ├── BCPhaseScriptBase  ← sender guard, abandoned-factory guard,
        │                         Phase1 bind, manifest helpers, contacts
        │
        └── Bc*Phase*Deploy    ← pure deploy graph (also driven by hermetic/fork tests)
```

**Bind sources (G-3):**

1. **FullStack / `deployForFullStack` handoff** — preferred for multi-phase local composition.
2. **`BC_TESTNET` greenfield constants** — after live Phase 1 fills zeros (`CREATE3_FACTORY`, `DIAMOND_PACKAGE_CALLBACK_FACTORY`, `BETTER_PERMIT2`, …).

Until Phase 1 is live, greenfield CREATE3 roots in `BC_TESTNET` are `address(0)`.

**Lineage flavors:**

| Phases | How contracts land on chain |
|--------|-----------------------------|
| 1–2 | CREATE3 + Diamond packages under **new** Create3Factory |
| 3 | CREATE2 via Path A (canonical Safe Singleton) or **Path B** (BC Deployer `deployCreate2` — **no `vm.etch`**) |
| 4–5 | **Bind only** (no deploy) |
| 6–10, 12–13 | Mostly plain CREATE / helpers (Sky multi-root **waived** vs CREATE3) |

---

## 3. Shared setup

```bash
cd /path/to/crane   # this repo root

# Compile DoD
forge build --contracts scripts/foundry/bc/

# Operator identity (live / Anvil with keystore)
export DEPLOYER=$(cast wallet address --account deployer)
echo "DEPLOYER=$DEPLOYER"
```

**Live / Anvil flags (template):**

```text
--rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

| Flag | Why |
|------|-----|
| `--sender "$DEPLOYER"` | Required — base reverts on Foundry default sender `0x1804…` |
| `--skip-simulation` | Common on BC; scripts assume operator path |
| `-g 400` | Gas multiplier; raise on OOG only (not a product option) |
| RPC alias | `battlechain-sepolia` → `https://testnet.battlechain.com` (`foundry.toml`) |

**Chain / explorer:**

| Item | Value |
|------|--------|
| Chain ID | `627` |
| RPC | `https://testnet.battlechain.com` |
| Explorer | `https://explorer.testnet.battlechain.com` |
| BC Deployer | `BC_TESTNET.DEPLOYER` |
| BC WETH | `0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42` |

**Pre-live checklist (blocks broadcast):**

- [ ] Security contact not placeholder (`REPLACE_BEFORE_BROADCAST@example.com` in `BCPhaseScriptBase` / Phase 1)
- [ ] X drafts reviewed ([`BC_GREENFIELD_X_POSTS.md`](./BC_GREENFIELD_X_POSTS.md))
- [ ] Local smoke green for the phases you will broadcast (gap report §20)

---

## 4. Local verify — full suite

Run from repo root. Hermetic suites do **not** need BC RPC.

```bash
# Compile
forge build --contracts scripts/foundry/bc/

# CREATE3 with-args idempotency (Phase 0)
forge test --match-contract Create3Factory_Test --match-test idempotent -vv

# Bind base unit
forge test --match-path test/foundry/spec/scripts/bc/BCPhaseScriptBase_Bind.t.sol -vv

# Phase 1–3 fork (needs BC RPC or env used by tests)
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase1_Factories_Fork.t.sol -vv
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase2_Balancer_Fork.t.sol -vv
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase3_Aave_Fork.t.sol -vv

# Phase 6–8, 10, 12 hermetic
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase6_Aerodrome_Hermetic.t.sol -vv
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase7_Uniswap_Hermetic.t.sol -vv
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase8_Camelot_Hermetic.t.sol -vv
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase10_Sky_Hermetic.t.sol -vv
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase12_Reliquary_Hermetic.t.sol -vv

# Phase 9 / 13a / 13b hermetic (always-on)
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase9_Liquity_Hermetic.t.sol -vv
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase13a_Pendle_Hermetic.t.sol -vv
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase13b_Frax_Hermetic.t.sol -vv

# Optional fork when BC RPC up (some suites skip cleanly if down)
BC_FORK_RPC=https://testnet.battlechain.com \
  forge test --match-path test/foundry/fork/scripts/bc/BC_Phase9_Liquity_Fork.t.sol -vv
BC_FORK_RPC=https://testnet.battlechain.com \
  forge test --match-path test/foundry/fork/scripts/bc/BC_Phase13a_Pendle_Fork.t.sol -vv
BC_FORK_RPC=https://testnet.battlechain.com \
  forge test --match-path test/foundry/fork/scripts/bc/BC_Phase13b_Frax_Fork.t.sol -vv
```

**Anvil BC fork (optional operator dry-run):**

```bash
anvil --fork-url https://testnet.battlechain.com --chain-id 627 --port 8545
# Use Anvil #0 key only for local broadcast; never for live BC
```

---

## 5. File map

| Script | Helper | Role |
|--------|--------|------|
| `BCPhaseScriptBase.s.sol` | — | Guards + binds + manifest helpers |
| `Script_BC_Phase1_Factories.s.sol` | (inline + `InitBcService`) | CREATE3 root, ERC20Permit, Uni V2/V4, Permit2, agreement |
| `Script_BC_Phase2_BalancerV3.s.sol` | (inline) | Full Balancer V3 vault/router/pools + Timelock |
| `Script_BC_FullStack.s.sol` | Phase1/2 `deployForFullStack` | One broadcast: 1 then 2 |
| `Script_BC_Phase3_Aave.s.sol` | `BcAavePhase3Deploy.sol` | Aave V3 market + V4 core/configure |
| `Script_BC_Phase3b_AaveV4_LibraryPreCompile.s.sol` | — | Optional library precompile path |
| `Script_BC_Phase3b_AaveV4_Configure.s.sol` | `BcAavePhase3Deploy` | V4 core+configure only |
| `Script_BC_Phase4_Euler.s.sol` | — | Bind EVC / eUSDC / eWETH |
| `Script_BC_Phase5_Compound.s.sol` | — | Bind Venus Comptroller + vTokens |
| `Script_BC_Phase6_Aerodrome.s.sol` | `BcAerodromePhase6Deploy.sol` | Aerodrome ve(3,3) + Slipstream CL |
| `Script_BC_Phase7_Uniswap.s.sol` | `BcUniswapPhase7Deploy.sol` | V4 periphery + `BcV4Router` |
| `Script_BC_Phase8_Camelot.s.sol` | `BcCamelotPhase8Deploy.sol` | Camelot V2 factory + router |
| `Script_BC_Phase9_Liquity.s.sol` | `BcLiquityPhase9Deploy.sol` | BOLD full WETH branch |
| `Script_BC_Phase10_Sky.s.sol` | `BcSkyPhase10Deploy.sol` | Sky/DSS + one ilk |
| `Script_BC_Phase12_Reliquary.s.sol` | `BcReliquaryPhase12Deploy.sol` | Reliquary + curves + fund |
| `Script_BC_Phase13a_Pendle.s.sol` | `BcPendlePhase13aDeploy.sol` | Pendle seed market |
| `Script_BC_Phase13b_Frax.s.sol` | `BcFraxPhase13bDeploy.sol` | Fraxswap + full BAMM graph |

---

## 6. Per-phase: what deploys + how to run

Commands below use the live template. For local-only work, use the **Verify** section of each phase instead of `--broadcast` to BC.

### Phase 0 — Prerequisites (not a live phase)

| Deploys | Nothing on-chain |
|---------|------------------|
| Ensures | CREATE3 `*WithArgs` early-return idempotency; shared base; `BC_TESTNET` bind constants for Euler/Venus/Morpho/etc. |

```bash
forge test --match-contract Create3Factory_Test --match-test idempotent -vv
forge build --contracts scripts/foundry/bc/
```

---

### Phase 1 — Factories (CREATE3 greenfield root)

**Script:** `Script_BC_Phase1_Factories.s.sol`  
**Agreement salt:** `crane-indexedex-bc-greenfield-v1`  
**Manifests:**

- `docs/deployment/addresses/battlechain-sepolia.json`
- `docs/deployment/addresses/battlechain-sepolia.table.md`
- `script/output/battlechain-sepolia/greenfield-phase1.latest.json`

| Action | Surface |
|--------|---------|
| **Deploy** | Create3Factory + DiamondPackageCallBackFactory (`InitBcService.initEnvBc`) |
| **Deploy** | ERC20Facet, ERC5267Facet, ERC2612Facet, ERC20PermitDFPkg |
| **Deploy** | Sample ERC20Permit diamond (CBCP-style: name/symbol CBCG) |
| **Deploy** | Uni V2 Factory + Router02, Uni V4 PoolManager, BetterPermit2 (CREATE3) |
| **Deploy** | Safe Harbor agreement on Create3Factory (`ChildContractScope.All`) |
| **Live only** | `requestAttackMode` on that agreement |
| **Bind** | BC WETH, Uni V3 Factory / SwapRouter / NPM |

**Do not** redeploy WETH or Uni V3. **Do not** reuse Wave A factory.

```bash
# Verify (preferred)
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase1_Factories_Fork.t.sol -vv

# Live (Tier D only)
forge script scripts/foundry/bc/Script_BC_Phase1_Factories.s.sol:Script_BC_Phase1_Factories \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

**After live Phase 1:** agent must write real addresses into `BC_TESTNET` greenfield zeros (`CREATE3_FACTORY`, diamond factory, Permit2, facets, sample token, Uni V2/V4, …) and refresh `docs/deployment/deployed-addresses.md`.

**In-process API:** `deployForFullStack(deployer)` — no broadcast / no attack mode (used by FullStack + fork tests).

---

### Phase 2 — Balancer V3

**Script:** `Script_BC_Phase2_BalancerV3.s.sol`  
**Needs:** Phase 1 CREATE3 + diamond factory + WETH + Permit2 (handoff or `BC_TESTNET`).  
**Manifests:** `battlechain-sepolia-balancer-v3.json` / `.table.md` + `greenfield-phase2-balancer-v3.latest.json`

| Action | Surface |
|--------|---------|
| **Deploy** | Vault facets + VaultDFPkg + vault instance |
| **Deploy** | ProtocolFeeController + set on vault |
| **Deploy** | Router facets + RouterDFPkg + router |
| **Deploy** | Pool packages: Weighted, Stable, ConstProd, Gyro 2-CLP / E-CLP, LBP, CoW pool+router, ReClamm |
| **Deploy** | ERC4626RateProviderFacetDFPkg |
| **Deploy** | TimelockAuthorizer (`minDelay = 1 hours`, admin = deployer); hard-require `getAuthorizer() == timelock` |
| **Not** | New agreement / attack mode; NullAuthorizer as final auth |

```bash
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase2_Balancer_Fork.t.sol -vv

forge script scripts/foundry/bc/Script_BC_Phase2_BalancerV3.s.sol:Script_BC_Phase2_BalancerV3 \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

**FullStack (1→2 one broadcast):**

```bash
forge script scripts/foundry/bc/Script_BC_FullStack.s.sol:Script_BC_FullStack \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

Standalone Phase 1 / 2 remain primary for **resume** after partial failure (CREATE3 idempotent).

---

### Phase 3 — Aave V3 + V4

**Script:** `Script_BC_Phase3_Aave.s.sol` (+ optional 3b LibraryPreCompile / Configure)  
**Helper:** `BcAavePhase3Deploy.sol`  
**Manifests:** `battlechain-sepolia-aave.json` / `.table.md` + `phase-3-aave.latest.json`

| Action | Surface |
|--------|---------|
| **CREATE2 Path A** | Use canonical Safe Singleton `0x914d…` if code exists |
| **CREATE2 Path B** | Else deploy Safe Singleton **runtime** via `IBattleChainDeployer.deployCreate2` (**forbidden:** `vm.etch`) |
| **Deploy V3** | Provider, pool, oracle, IR strategy; `initReserves` for BC WETH / USDC / DAI |
| **Deploy V4** | AccessManager, Hub, Spoke, LiquidationLogic (linked), configure reserves; optional supply smoke in tests |
| **Bind** | BC WETH/USDC/DAI + Chainlink mocks |
| **Optional** | Phase 1 CREATE3 bind if constants set (Aave does not require CREATE3) |

**Lineage note:** Aave uses CREATE2/`new`, not Phase 1 CREATE3 root (tracked as optional DEBT P3a-10).

```bash
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase3_Aave_Fork.t.sol -vv
# Expect 6/6: binds, Path B no-etch, V3, V4 core+configure, full, supply smoke

forge script scripts/foundry/bc/Script_BC_Phase3_Aave.s.sol:Script_BC_Phase3_Aave \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

Optional operators:

```bash
# Library precompile helper (prints FOUNDRY_LIBRARIES path when needed)
forge script scripts/foundry/bc/Script_BC_Phase3b_AaveV4_LibraryPreCompile.s.sol:Script_BC_Phase3b_AaveV4_LibraryPreCompile \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400

# V4 only
forge script scripts/foundry/bc/Script_BC_Phase3b_AaveV4_Configure.s.sol:Script_BC_Phase3b_AaveV4_Configure \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

---

### Phase 4 — Euler (bind only)

**Script:** `Script_BC_Phase4_Euler.s.sol`  
**Deploys:** nothing. **Binds** BC mock Euler:

| Label | Constant |
|-------|----------|
| EVC | `BC_TESTNET.EULER_EVC` |
| eUSDC | `BC_TESTNET.EULER_EUSDC` |
| eWETH | `BC_TESTNET.EULER_EWETH` |

**Manifests:** `battlechain-sepolia-euler.json` / `.table.md` + `phase-4-euler.latest.json`

```bash
forge script scripts/foundry/bc/Script_BC_Phase4_Euler.s.sol:Script_BC_Phase4_Euler \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

On chain 627, script `_requireCode` on each bind. Safe for Anvil fork smoke.

---

### Phase 5 — Venus / Compound-style (bind only)

**Script:** `Script_BC_Phase5_Compound.s.sol`  
**Deploys:** nothing. **Binds** BC Venus mock:

| Label | Constant |
|-------|----------|
| Comptroller | `VENUS_COMPTROLLER` |
| vTokens | vUSDC, vWETH, vWBTC, vDAI, vBNB, vUSDT |

**Manifests:** `battlechain-sepolia-compound.json` / `.table.md` + `phase-5-compound.latest.json`

```bash
forge script scripts/foundry/bc/Script_BC_Phase5_Compound.s.sol:Script_BC_Phase5_Compound \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

No Comet deploy (PRD default is Venus bind).

---

### Phase 6 — Aerodrome + Slipstream

**Script:** `Script_BC_Phase6_Aerodrome.s.sol`  
**Helper:** `BcAerodromePhase6Deploy.sol`  
**Lineage:** plain CREATE  
**Waived:** CLGauge path (not in Crane Slipstream port — P6-7)

| Deploy (core) | Aero, Pool impl/factory, VotingRewards/Gauge/Managed factories, FactoryRegistry |
| Deploy (ve) | Forwarder, VotingEscrow, VeArtProxy, RewardsDistributor, Voter, Router, Minter, Airdrop |
| Deploy (gov) | ProtocolGovernor, EpochGovernor + `Voter.setGovernor` / `setEpochGovernor` |
| Deploy (CL) | CLPool impl, CLFactory, CustomSwapFeeModule, CustomUnstakedFeeModule |
| Smoke | Hermetic volatile `PoolFactory.createPool` |

**Manifests:** `battlechain-sepolia-aerodrome.json` (and greenfield runtime copy if script writes both)

```bash
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase6_Aerodrome_Hermetic.t.sol -vv

forge script scripts/foundry/bc/Script_BC_Phase6_Aerodrome.s.sol:Script_BC_Phase6_Aerodrome \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

---

### Phase 7 — Uniswap extras (V4 periphery)

**Script:** `Script_BC_Phase7_Uniswap.s.sol`  
**Helper:** `BcUniswapPhase7Deploy.sol` (+ concrete `BcV4Router`)

| Action | Surface |
|--------|---------|
| **Bind** | BC Uni V3 factory (operator path) |
| **Bind / handoff** | Phase 1 PoolManager + Permit2 + WETH when filled; hermetic deploys own PM/P2/WETH |
| **Deploy** | PositionDescriptor, PositionManager, StateView, V4Quoter, `BcV4Router` |

```bash
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase7_Uniswap_Hermetic.t.sol -vv

forge script scripts/foundry/bc/Script_BC_Phase7_Uniswap.s.sol:Script_BC_Phase7_Uniswap \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

---

### Phase 8 — Camelot V2

**Script:** `Script_BC_Phase8_Camelot.s.sol`  
**Helper:** `BcCamelotPhase8Deploy.sol`

| Deploy | Camelot Factory + Router |
| Smoke | Hermetic `createPair` |

```bash
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase8_Camelot_Hermetic.t.sol -vv

forge script scripts/foundry/bc/Script_BC_Phase8_Camelot.s.sol:Script_BC_Phase8_Camelot \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

---

### Phase 9 — Liquity / BOLD (WETH branch)

**Script:** `Script_BC_Phase9_Liquity.s.sol`  
**Helper:** `BcLiquityPhase9Deploy.sol` (CREATE2 salt graph + full `setAddresses`)  
**Out of scope:** Zappers

| Deploy | BoldToken, CollateralRegistry, AddressesRegistry |
| Deploy | Active/Default/Gas/CollSurplus pools, StabilityPool, SortedTroves, TroveManager, TroveNFT, MetadataNFT |
| Deploy | BorrowerOperations, WETHPriceFeed (BC ETH/USD or hermetic mock), HintHelpers, MultiTroveGetter, RedemptionHelper, DebtInFrontHelper, InterestRouter |
| Smoke | Hermetic `openTrove` |

**Open-trove constraints:** `MIN_DEBT = 2000e18` BOLD; `ETH_GAS_COMPENSATION = 0.0375e18` WETH to gas pool.

```bash
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase9_Liquity_Hermetic.t.sol -vv

forge script scripts/foundry/bc/Script_BC_Phase9_Liquity.s.sol:Script_BC_Phase9_Liquity \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

---

### Phase 10 — Sky / DSS

**Script:** `Script_BC_Phase10_Sky.s.sol`  
**Helper:** `BcSkyPhase10Deploy.sol` via `SkyDssFactoryService`  
**Lineage:** multi-root plain `new` — **CREATE3 under Phase 1 waived** (P10-2); manifest may label `"lineage": "multi-root-safe-harbor-plain-new"`

| Deploy | Vat, Dai, DaiJoin, Jug, Pot, Spotter, Vow, Dog, Flapper, Flopper, End, Chainlog |
| Deploy | One ilk (e.g. WETH-A): GemJoin + DSValue pip seed (not Chainlink aggregator ABI) |
| Smoke | Hermetic join + frob + exit DAI (`openCdp`) |

```bash
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase10_Sky_Hermetic.t.sol -vv

forge script scripts/foundry/bc/Script_BC_Phase10_Sky.s.sol:Script_BC_Phase10_Sky \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

---

### Phase 11 — Resupply

**Dropped.** No script. Do not invent one for greenfield.

---

### Phase 12 — Reliquary

**Script:** `Script_BC_Phase12_Reliquary.s.sol`  
**Helper:** `BcReliquaryPhase12Deploy.sol`

| Deploy | Reliquary, LinearCurve, LinearPlateauCurve, PolynomialPlateauCurve |
| Deploy | Reward + pool tokens; fund rewards; addPool |
| Smoke | Hermetic `createRelicAndDeposit` |

```bash
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase12_Reliquary_Hermetic.t.sol -vv

forge script scripts/foundry/bc/Script_BC_Phase12_Reliquary.s.sol:Script_BC_Phase12_Reliquary \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

---

### Phase 13a — Pendle (seed)

**Script:** `Script_BC_Phase13a_Pendle.s.sol`  
**Helper:** `BcPendlePhase13aDeploy.sol`  
**Out of scope:** optional seed liquidity as product goal

| Deploy | PendleRouterV4 + AllAction facets, YieldContractFactory, MarketFactoryV3, PoolDeployHelper |
| Deploy | One SY (`PendleERC20SY` on WETH or hermetic ERC20), createYieldContract (PT/YT), createNewMarket |
| Deploy | PendlePYLpOracle behind ERC1967Proxy |

```bash
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase13a_Pendle_Hermetic.t.sol -vv

forge script scripts/foundry/bc/Script_BC_Phase13a_Pendle.s.sol:Script_BC_Phase13a_Pendle \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

---

### Phase 13b — Frax BAMM

**Script:** `Script_BC_Phase13b_Frax.s.sol`  
**Helper:** `BcFraxPhase13bDeploy.sol`  
**Exact graph** (matches `BAMMTest._deployBamm`):

1. FraxswapFactory  
2. FraxswapPair (`createPair`)  
3. FraxswapDummyRouter  
4. BAMMHelper  
5. FraxswapOracle  
6. BAMM  

Hermetic uses mintable DummyTokens; live/fork uses BC WETH/USDC when available. **Out of scope:** TWAMM / Range.

```bash
forge test --match-path test/foundry/fork/scripts/bc/BC_Phase13b_Frax_Hermetic.t.sol -vv

forge script scripts/foundry/bc/Script_BC_Phase13b_Frax.s.sol:Script_BC_Phase13b_Frax \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

---

## 7. Live sequence (Tier D only)

**Do not start until** GATE-1/2/7 green **and** GATE-5/6 (X review + security contact).

1. Replace placeholder security contact in base / Phase 1.  
2. Phase 1 live → fill `BC_TESTNET` greenfield zeros → docs handoff.  
3. Phase 2 (or FullStack if starting fresh and 1 not yet on chain in this session).  
4. Phases 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 12 → 13a → 13b **in order** (4/5 are binds only; still run for manifests).  
5. After **each** phase:  
   - Agent: refresh manifests / `deployed-addresses.md` / `BC_TESTNET` as needed.  
   - Operator or agent: post matching draft from [`BC_GREENFIELD_X_POSTS.md`](./BC_GREENFIELD_X_POSTS.md) (**docs links only, no hex**).  
6. Re-run same phase command on partial failure (CREATE3 resume-safe for 1–2; others re-check manifests).

**Never** treat Wave A/B manifests or abandoned factory as greenfield complete.

---

## 8. Post-phase agent duties

When told “Phase N greenfield deployed”:

1. Read console **Docs handoff** paths (JSON + table + runtime).  
2. Prefer `docs/deployment/addresses/battlechain-sepolia*.json` as source of truth.  
3. Update `docs/deployment/deployed-addresses.md` if the site consumes it.  
4. After Phase 1: patch `contracts/constants/networks/BC_TESTNET.sol` greenfield `address(0)` slots with live addresses.  
5. Confirm `generation: greenfield` in JSON; do not reintroduce Wave A roots.  
6. Do **not** invent hex addresses for X posts — link docs only.

---

## 9. Always-bind reference (never deploy)

From `BC_TESTNET` / PRD §5:

| Category | Examples |
|----------|----------|
| BC core | Registry, AgreementFactory, AttackRegistry, Deployer, CreateX |
| Tokens | WETH, USDC, USDT, DAI, WBTC, LINK, MTK |
| Oracles | CHAINLINK_ETH_USD, BTC/USD, LINK/USD, USDC/USD (mock aggregators) |
| Uni V3 | Factory, SwapRouter, NPM |
| Euler mock | EVC, eUSDC, eWETH (Phase 4) |
| Venus mock | Comptroller + vTokens (Phase 5) |
| Other mocks | Morpho, Kyber router, CCIP router (bind if needed) |

---

## 10. Common failures

| Symptom | Cause / fix |
|---------|-------------|
| `BCPhase: broadcaster is Foundry default sender` | Pass `--sender $DEPLOYER` |
| `refused abandoned gen-1 Create3Factory` | Pointed at Wave A `0xC8E9…` — use greenfield Phase 1 root only |
| `create3 factory is zero` | Phase 1 not live / constants not filled — use FullStack handoff or deploy Phase 1 first |
| Phase 3 etch / Path A empty | Path B via BC Deployer is correct; **do not** reintroduce `vm.etch` |
| Multi-tx Anvil broadcast 0 receipts | Tooling issue — use `createSelectFork` tests for DoD |
| Fork tests skip | BC RPC down — hermetic suites are the always-on gate |
| Stack too deep / viaIR | **Never enable viaIR** — refactor with structs per AGENTS.md |
| Manifest has sim addresses | Fork/sim may write docs JSON — discard before live; prefer runtime `script/output/` for non-live |

---

## 11. Formal waivers (do not “fix” as missing scripts)

| ID | Item | Status |
|----|------|--------|
| G-8 / Phase 11 | Resupply | Dropped |
| P6-7 | CL gauge | Not in port |
| P10-2 | Sky under CREATE3 | Multi-root plain `new` intentional |
| P3a-9 | Aave optional periphery | Waived |
| G-12 | Preserve Wave A manifests | Greenfield replace intentional |

---

## 12. Related docs

| Doc | Use |
|-----|-----|
| [`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md) | Frozen one-liner commands |
| [`BC_GREENFIELD_DEPLOYMENT_PRD.md`](./BC_GREENFIELD_DEPLOYMENT_PRD.md) | Authoritative deploy lists |
| [`BC_GREENFIELD_PHASE_DEPLOY_STEPS.md`](./BC_GREENFIELD_PHASE_DEPLOY_STEPS.md) | Operator step detail |
| [`BC_AAVE_V4_DEPLOY_STEPS.md`](./BC_AAVE_V4_DEPLOY_STEPS.md) | Aave V4 A–F |
| [`BC_GREENFIELD_GAP_REPORT.md`](./BC_GREENFIELD_GAP_REPORT.md) | Conformance + next gates |
| [`BC_GREENFIELD_MASTER_PLAN.md`](./BC_GREENFIELD_MASTER_PLAN.md) | Checklist (may lag; prefer gap report) |
| [`BC_GREENFIELD_X_POSTS.md`](./BC_GREENFIELD_X_POSTS.md) | Pre-drafted announcements |
| [`battlechain.md`](./battlechain.md) | BC network context |

---

*When adding a phase or changing a deploy graph: update this guide, `BC_GREENFIELD_COMMANDS.md`, gap report §20, and PRD if scope changes. Prefer driving helpers from tests so scripts and smoke never diverge.*
