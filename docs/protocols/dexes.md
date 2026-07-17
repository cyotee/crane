# DEX Protocol Integrations

Crane provides deep, agent-ready integrations for major DEXes using the same Facet-Target-Repo (FTR) + Service + DFPkg patterns as the core framework. Integrations emphasize:

- Shared constant-product math via `ConstProdUtils` (for V2-style and volatile pools across Camelot, Uniswap V2, Aerodrome V1).
- Protocol-specific `AwareRepo` libraries for dependency injection (routers, factories, vaults).
- Stateless `*Service` libraries for complex operations (swaps, deposits, quotes) using structs to avoid stack-too-deep.
- Stubs and TestBases for isolated unit tests; separate fork bases for mainnet parity.
- Where DEX components are themselves upgradeable (primarily Balancer V3), full use of Crane's DFPkg + DiamondPackageCallBackFactory infrastructure.

See the protocol-specific skills for deeper agent guidance:
- `crane-balancer` + `balancer-v3-*` (deepest port: full Vault as a Diamond, multiple pool types as DFPkgs/facets, router Diamond, hooks, rate providers, buffer support).
- `crane-uniswap` + `uniswap-v*-*` (V2 simple AMM, V3 concentrated, full V4 PoolManager/PositionManager/hooks/Quoter with flash accounting and hooks).
- `crane-aerodrome` + `slipstream-*` + `aerodrome-*` (volatile/stable + concentrated liquidity (Slipstream), gauges, voter, ve-tokenomics, rewards, bribes).
- `crane-camelot`.

Cross-reference:
- Architecture: [Codebase Map](../CODEBASE_MAP.md) and AGENTS.md (protocol structure + TestBase inheritance).
- Lifecycle details: [Balancer V3 Lifecycle](balancer/v3/Balancer_V3_Lifecycle.md), [Uniswap V4 Lifecycle](uniswap/v4/Uniswap_V4_Lifecycle.md).
- Testing patterns: [Testing Patterns](../development/testing.md), crane-testing skill.
- Shared math: [ConstProdUtils & Math](../utilities/math-const-prod.md).
- Deployment reuse: DiamondPackageCallBackFactory (interfaceId `0x949da331`) is intended for public reuse across chains; see [CREATE3](../deployment/create3.md) and [DFPkg](../deployment/dfpkg.md) (e.g. `packageName()` selector `0xabc8b346`).

## Protocol Directory Structure

Each DEX lives under `contracts/protocols/dexes/{protocol}/{version}/`:

```
protocols/dexes/{protocol}/{version}/
├── *AwareRepo.sol          # DI for router/factory/vault (e.g. CamelotV2RouterAwareRepo)
├── services/               # Business logic (CamelotV2Service, AerodromeServiceVolatile, UniswapV2Service)
├── stubs/                  # Local mock implementations of protocol contracts (for unit tests)
├── interfaces/             # (some protocols)
└── test/
    └── bases/
        └── TestBase_*.sol  # Shared setup (unit + separate *Fork for mainnet)
```

Stubs and TestBases are **test infrastructure only** (live in `contracts/` alongside prod code per Crane conventions). Actual specs live in `test/foundry/spec/protocols/dexes/...`.

All follow deterministic deployment where applicable (CREATE3 for facets/packages when using DFPkgs; direct deployment for stubs in tests).

## Shared Protocol-Specific Utilities: ConstProdUtils

`ConstProdUtils` (in `contracts/utils/math/ConstProdUtils.sol`) is the foundational math library for constant-product (xy=k) AMMs and is used by Camelot V2, Uniswap V2, Aerodrome volatile pools, and related services.

Key capabilities (used for quoting without side effects, plus deposit/withdraw calcs):

- `_sortReserves(...)` (overloads for fees too)
- `_depositQuote(...)`, `_withdrawQuote(...)`
- `_saleQuote(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 feePercent)`
- `_purchaseQuote(...)` (exact in for desired out)
- `_swapDepositSaleAmt(...)` (optimal swap amount before addLiquidity for single-sided)
- `_equivLiquidity(...)`

Usage in services (see AGENTS.md example):

```solidity
// In CamelotV2Service / UniswapV2Service / AerodromeServiceVolatile
using ConstProdUtils for uint256;

uint256 expectedOut = ConstProdUtils._saleQuote(amountIn, reserveIn, reserveOut, fee);
```

See dedicated tests exercising parity between quotes and live execution:
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_purchaseQuote_Camelot.t.sol`
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_calculateFeePortionForPosition_Aerodrome.t.sol`
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol`

TestBases for these inherit protocol setup (see below) then create real pairs/pools via stubs + services and assert `ConstProdUtils` results == actual router/pool outputs and state deltas.

## Camelot V2

**Location**: `contracts/protocols/dexes/camelot/v2/`

- `CamelotV2FactoryAwareRepo.sol`, `CamelotV2RouterAwareRepo.sol` (slot: `crane.camelot.v2.router.aware`)
- `services/CamelotV2Service.sol` — `_deposit`, `_withdrawDirect`, `_swap` (and overloads), `_prepareSwap`, balance/sale helpers. Uses `ConstProdUtils`, referrer support, fee-on-transfer handling.
- `stubs/`: `CamelotFactory`, `CamelotRouter`, `CamelotPair` (plus UniswapV2ERC20 + libs).

**Test usage**:
- Inherit `TestBase_CamelotV2` (which inherits `TestBase_Weth9`).
- Calls `TestBase_Weth9.setUp()` then deploys `CamelotFactory(feeToSetter)` + `CamelotRouter(factory, weth)` if not pre-set.
- Provides: `camelotV2Factory`, `camelotV2Router`, `weth`.

Example inheritance chain (unit tests):
```
CraneTest (optional, for diamond consumers)
  └── TestBase_Weth9
        └── TestBase_CamelotV2
              └── TestBase_ConstProdUtils_Camelot (or your test)
```

Specialized:
- `TestBase_ConstProdUtils_Camelot` creates balanced/unbalanced/extreme pools + tokens using `ERC20PermitMintableStub`, then exercises service vs. ConstProdUtils.
- Direct specs: `test/foundry/spec/protocols/dexes/camelot/v2/services/CamelotV2Service.t.sol`, invariant tests, fee variants, multihop, referrer, stableSwap, asymmetric fees.
- Handler for fuzz: `handlers/CamelotV2Handler.sol` (tracks expected K for `invariant_*` checks on swaps/mints/burns).

Usage pattern in tests:
```solidity
import {TestBase_CamelotV2} from "@crane/contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";

contract MyCamelotTest is TestBase_CamelotV2 {
    function setUp() public virtual override {
        TestBase_CamelotV2.setUp();
        // mint/deal tokens, then CamelotV2Service._deposit(...) or router calls
    }
}
```

Stubs are used automatically by the TestBase. For fork tests, use separate fork bases + network constants (e.g. from `contracts/constants/networks/`).

## Uniswap V2

**Location**: `contracts/protocols/dexes/uniswap/v2/`

- `aware/`: `UniswapV2FactoryAwareRepo.sol`, `UniswapV2RouterAwareRepo.sol`
- `services/UniswapV2Service.sol` — swap/quote helpers using `ConstProdUtils._saleQuote`, deposit/sale helpers.
- `libraries/TransferHelper.sol`; `stubs/`: `UniV2Factory`, `UniV2Router02`, `UniV2Pair` + deps.

**Test usage**:
- `TestBase_UniswapV2` (inherits `TestBase_Weth9`) deploys fee setter + stubs for factory/router.
- Provides `addBalancedUniswapLiquidity(...)` helper (uses `ConstProdUtils._equivLiquidity` + `sortedReserves` + deal/approve).
- `TestBase_UniswapV2_Pools` extends for pool creation helpers.

Example test base usage mirrors Camelot. Specs live under `test/foundry/spec/protocols/dexes/uniswap/v2/services/...` and `aware/...`. Fork support via `test/foundry/fork/ethereum_main/uniswapV2/`.

## Uniswap V3 + V4

**Uniswap V3**:
- Full core (`UniswapV3Factory`, `UniswapV3Pool`, `UniswapV3PoolDeployer`) + extensive periphery (SwapRouter, NonfungiblePositionManager, etc.) + libraries.
- `test/bases/TestBase_UniswapV3` (inherits `TestBase_Weth9` + callbacks) provides factory + fee/tick constants.
- Periphery TestBase: `TestBase_UniswapV3Periphery`.
- Tests: tick/swap math, periphery descriptor, etc. Fork tests separate.

**Uniswap V4** (deepest):
- Complete `PoolManager`, `PositionManager`, `V4Router`, `Quoter`, hooks base + examples (WETHHook, etc.), ERC6909 claims, Permit2 integration, EIP712, multicall.
- Many public hook examples and aggregator patterns in `hooks/public/`.
- Uses extensive shared libs under `uniswap/libraries/`.
- Tests include heavy fuzz/fork for hooks + full e2e (many under `test/foundry/spec/protocols/dexes/uniswap/v4/...` and aggregator subdirs).
- Lifecycle details in dedicated doc (cross-link above).

**Shared math** (used by V3 + Slipstream + others): `TickMath`, `FullMath`, `SqrtPriceMath`, `SwapMath`, `LiquidityMath`, `FixedPoint96`, etc.

## Aerodrome V1 + Slipstream

**Aerodrome V1** (volatile + stable + full governance):
- `aware/`: `AerodromeRouterAwareRepo.sol`, `AerodromePoolMetadataRepo.sol`
- `services/`: `AerodromeService.sol`, `AerodromeServiceVolatile.sol`, `AerodromeServiceStable.sol` (use `ConstProdUtils` for volatile; separate stable math).
- Full stubs for: Pool, Router, Voter, VotingEscrow, Gauge(s), Minter, Rewards (various), Factories (pool/gauge/voting/managed), AirdropDistributor, governors, etc. + libs (SafeCastLibrary).
- `TestBase_Aerodrome` (inherits `TestBase_Weth9`): deploys the entire protocol stack (AERO token first, factories, voter, distributor, minter, router, art proxy, esrow, gauges, rewards, governors). Sets labels.
- `TestBase_Aerodrome_Pools` extends for balanced/unbalanced/stable test pools + tokens (similar structure to Camelot ConstProd base).

Specs: `test/foundry/spec/protocols/dexes/aerodrome/v1/services/*`, aware tests. Fork tests: `test/foundry/fork/base_main/aerodrome/` using `TestBase_AerodromeFork`.

**Slipstream (Concentrated Liquidity)**:
- CL implementation (CLFactory, CLPool, Position/Tick libs) + fee modules (custom swap/unstaked) + callbacks.
- Reward utils: `SlipstreamRewardUtils.sol`.
- `TestBase_Slipstream` (abstract, uses mock CLPool due to solc version): constants for FEE_LOW/MED/HIGH + TICK_SPACING; imports Uniswap V3 math libs.
- `TestBase_SlipstreamFork` for live Base mainnet.
- Usage/tests: reward utils, gas, swap utils under fork + spec. Shares math with Uniswap V3.

See Aerodrome README.md in source for port notes + ConstProdUtils integration.

## Balancer V3 (Diamond-Native Port)

The most advanced port — Balancer V3 Vault, pools, and router are built with Crane's own Diamond/DFPkg machinery:

- `vault/diamond/`: Full Vault facets (swap, liquidity, transient accounting, auth, pool, etc.) + DFPkg (`BalancerV3VaultDFPkg`).
- Pool types as DFPkgs/facets + targets/repos (weighted, stable, constant-product, gyro 2CLP/ECLP, LBP, ReClamm, cow pools).
- Rate providers as facets/DFPkg + factory service (`ERC4626RateProviderFacetDFPkg`).
- Router as its own Diamond + DFPkg.
- Hooks examples (BaseHooksTarget, StableSurgeHook, MevCaptureHook, etc.) + buffer/composite routers.
- Utils: `TokenConfigUtils`, weighted math, `BalancerV3WeightedPoolQuote`, etc.
- Aware: `BalancerV3VaultAwareRepo.sol` (slot example in AGENTS.md: `"protocols.dexes.balancer.v3.vault.aware"`).

**Test usage** (critical LR-2 / LR-7 area):
- `TestBase_BalancerV3` → `BaseTest` (ported minimal Balancer test utils for tokens, timestamps, helpers).
- `TestBase_BalancerV3Vault` (uses `CraneTest` indirectly via deployers + mocks, deploys real `BalancerV3VaultDFPkg` in some paths, RouterMock/Buffer/etc., `VaultContractsDeployer`).
- Specialized: `TestBase_BalancerV3_WeightedPool`, `TestBase_BalancerV3_8020WeightedPool`, router base.
- Mocks (dozens): `ERC20TestToken`, `PoolHooksMock`, `RateProviderMock`, `RouterMock`, `ArrayHelpers`, etc. live in `test/mocks/`.
- Utils/Deployers: `VaultContractsDeployer`, pool-specific deployers.
- Declaration tests for facets (following IFacet + Behavior patterns):
  - Many `...Facet_IFacet.t.sol` (e.g. `BalancerV3WeightedPoolFacet_IFacet.t.sol`, `BalancerV3StablePoolFacet_IFacet.t.sol`, gyro, constprod, LBP, etc.).
  - Use direct asserts or core `Behavior_IFacet.areValid_IFacet_facetInterfaces(...)` + `TestBase_IFacet` patterns (see `contracts/factories/diamondPkg/{TestBase_IFacet,Behavior_IFacet}.sol` and `test/foundry/spec/factories/diamondPlg/IFacet_Behavior_Test.sol`).
  - Verify `facetName()` (selector `0x5b6f4d01`), `facetInterfaces()` (`0x2ea80826`), `facetFuncs()` (`0x574a4cff`), `facetMetadata()` (`0xf10d7a75`), plus protocol interfaces.
- DFPkg tests: `...DFPkg.t.sol`, `...DFPkg_Integration.t.sol`, `...DFPkg_RealFacets.t.sol` (full init with real facets, no address(0)).
- E2E + invariants: rounding, reClamm, hooks, swap/liquidity flows.
- Vault integration example: `BalancerV3RouterVaultIntegration.t.sol` (deploys real `BalancerV3VaultDFPkg` via `new` + pkg init using `IBalancerV3VaultDFPkg.PkgInit`).

Inheritance example for vault/pool tests:
```
Test (or CraneTest)
  └── TestBase_BalancerV3
        └── TestBase_BalancerV3Vault
              └── TestBase_BalancerV3_WeightedPool (or 8020)
```

See also `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.t.sol` and pool DFPkg specs. Use `InitDevService` / `CraneTest` factories when full deterministic DFPkg proxy deployment is needed.

## Using DEX Integrations in Tests (Summary + Best Practices)

1. **Choose the right base**:
   - Unit/isolated: `TestBase_CamelotV2`, `TestBase_UniswapV2`, `TestBase_Aerodrome`, `TestBase_UniswapV3`, `TestBase_Slipstream`, Balancer `*Vault`/pool bases.
   - Always call `Super.setUp()` first.
   - Fork: `TestBase_*Fork` variants (use with `vm.createSelectFork` + network consts).

2. **Stubs vs real**:
   - Stubs (in `*/stubs/`) for fast, hermetic tests. Deployed inside TestBase if `address(xxx) == address(0)`.
   - Never use stubs on fork.

3. **Behavior / declaration testing for facetized DEX parts**:
   - Balancer pools/vault/router facets declare IFacet surface.
   - Prefer `Behavior_IFacet` helpers + `expect_*` / `hasValid_*` (or direct parity tests in *IFacet.t.sol).
   - Full initialization required (real facet addresses passed to DFPkgs, never 0).

4. **Services + quoting**:
   - Use `*Service._xxx(...)` for expected behavior in tests (compare to direct router + `ConstProdUtils`).
   - Example from Camelot tests: compute via `_saleQuote` then execute and assert equality + events/balances.

5. **Invariant / handler testing**:
   - Camelot example: `CamelotV2Handler` + `targetContract` + `invariant_*` (K tracking).

6. **Consumers using AwareRepos + DFPkgs**:
   - In your Diamond consumer: `CamelotV2RouterAwareRepo._initialize(routerFromTestBase);`
   - Deploy consumer via `diamondPackageFactory` from `CraneTest`.
   - For Balancer: pass vault-aware facets into pool DFPkg `PkgInit`.

7. **Cross-protocol**:
   - All V2/volatile use `ConstProdUtils`.
   - CL (UniswapV3/Slipstream) share tick/sqrt math.
   - Balancer has its own fixed-point + scaling (ported).

See concrete examples in:
- `test/foundry/spec/protocols/dexes/camelot/v2/`
- `test/foundry/spec/protocols/dexes/aerodrome/...`
- `test/foundry/spec/protocols/dexes/balancer/v3/...` (esp. DFPkg + IFacet + integration)
- `test/foundry/spec/protocols/dexes/uniswap/...`
- ConstProdUtils tests (inherit protocol TestBases)

## Cross-Links & Next Steps

- Full Crane test inheritance: AGENTS.md "TestBase Inheritance Chain Example".
- DFPkg + factory flow for DEX pool wrappers: [docs/deployment/dfpkg.md](docs/deployment/dfpkg.md), IDiamondFactoryPackage (central selectors: `facetCuts()` `0xa4b3ad35`, `initAccount()` `0x870d4838`, `postDeploy()` `0x70068fcf`).
- General utilities (Sets, other math): referenced in PRD LR-2; see `contracts/utils/collections/`, `contracts/utils/math/`.
- Registries + CREATE3: deployment docs (registries track facets/packages for reuse).
- Agent skills: `reference/agent-skills.md`.

Consult individual skills and the source `contracts/protocols/dexes/*/README.md` (where present) for integration recipes. All tests follow LR-7 rules (full init before asserts, exact vs side-effect, Behavior where applicable).

This surface enables safe, reusable DEX logic inside upgradeable Diamonds with minimal redeployment cost.

## See also

- [Lending Protocols](lending.md)
- [ConstProdUtils & Math](../utilities/math-const-prod.md)
- [Testing Patterns](../development/testing.md)
- [CREATE3 & New Chain Setup](../deployment/create3.md)
- [Getting Started](../getting-started.md)
