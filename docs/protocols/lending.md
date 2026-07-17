# Lending Protocol Integrations

Crane ports major lending protocols with full fidelity (faithful source mirrors) alongside Crane-native patterns for reuse.

- Aave v3.6 and Aave v4 (Hub/Spoke + TokenizationSpoke + PositionManager + gateways + dynamic config + risk).
- Euler (EVC batching, modular EVault, rich periphery, sophisticated oracles).

See dedicated skills: aave-*, euler-* (and subskills like aave-v3-pool, aave-v3-stata-token, euler-evc, euler-evk-*).

Native Crane pieces include `Permit2Aware` (IPermit2Aware + Repo/Target) and rate provider patterns (IERC4626RateProvider) usable across lending and yield.

Ports are structured for reuse via `*AwareRepo` + `*Service` patterns (where Crane wrappers added) and direct integration with core (DFPkgs, registries, factories).

See [Codebase Map](../CODEBASE_MAP.md), [Testing Patterns](../development/testing.md), lifecycle notes under `protocols/lending/`, and internal port history under `docs/archive/internal-plans/` (not part of primary GitBook nav).

## Aave Ports

### Aave v3.6
Full upstream port of Aave V3.6 (Pool, PoolConfigurator, AToken/VariableDebtToken, AaveOracle, PriceOracleSentinel, incentives/rewards, stata-token extensions (ERC4626), v3-config-engine, helpers like ProtocolDataProvider/WrappedTokenGatewayV3, and supporting libraries).

Key directories:
- `contracts/protocols/lending/aave/v3.6/protocol/` — core pool logic, tokenization, configuration, libraries (logic + math).
- `contracts/protocols/lending/aave/v3.6/misc/`, `helpers/`, `extensions/`, `rewards/`, `treasury/`.
- Deployments use procedures under `deployments/procedures/`.

### Aave v4 (Hub/Spoke)
Deep port of Aave V4 architecture:
- Hub (`Hub.sol`, `HubConfigurator`, `AssetInterestRateStrategy`, `HubStorage`): central liquidity and accounting.
- Spoke (`Spoke.sol`, `SpokeConfigurator`, `AaveOracle`, `TokenizationSpoke` (ERC4626), `TreasurySpoke`): risk, positions, tokenization.
- PositionManager layer (`PositionManagerBase`, `ConfigPositionManager`, `Giver/TakerPositionManager`, `SignatureGateway`, `NativeTokenGateway`): intent-based and EIP-712 flows.
- Config engine, deployments/orchestration (batches + procedures), extensive math (WadRayMath, MathUtils, PercentageMath, SharesMath) and spoke utils (SpokeUtils, LiquidationLogic, UserPositionUtils, etc.).

Key files:
- `contracts/protocols/lending/aave/v4/hub/Hub.sol`
- `contracts/protocols/lending/aave/v4/spoke/TokenizationSpoke.sol`
- `contracts/protocols/lending/aave/v4/position-manager/*`
- Deployment orchestration: `AaveV4TestOrchestration` / procedures (see deployments/).

Vendor provenance and port details: `docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md`.

Both Aave versions emphasize exact fidelity; upstream interfaces preserved (imports remapped to @crane/).

## Euler Port (v1)

Full EVC + EVK + periphery port (see `docs/protocols/lending/euler/v1/` and dedicated lifecycle docs):

- **EVC** (`evc/EthereumVaultConnector.sol`, `TransientStorage.sol`, `Set.sol`, `ExecutionContext.sol`): batching, deferred checks, onBehalfOf, controllers. Core of all authenticated flows.
- **EVault** (`vault/EVault/`): modular via Dispatch + modules (Vault, Borrowing, Liquidation, RiskManager, Governance, Token, Initialize). Uses `initOperation`, cache, LTV, liquidity utils, hooks.
- **Periphery**: Lens (AccountLens, VaultLens, OracleLens, IRMLens), IRM factories (adaptive, kink, etc.), Perspectives (for validation/whitelisting), Swaps handlers, Governor patterns, ERC4626EVC wrappers/collateral variants, PublicAllocator (for EulerEarn).
- **Oracle**: `EulerRouter` + rich adapters (chainlink, pyth, redstone, rate, uniswap, fixed, pendle, lido, chronicle, etc. incl. `RateProviderOracle`).
- **EulerEarn** / **EulerSwap**: allocator vaults and concentrated swap surfaces backed by EVaults.

Lifecycle emphasis (from `EulerV1_Lifecycle.md`): custody/accounting in EVault/Earn/Swap; auth + deferred health in EVC. `callThroughEVC`, `initOperation` boundary.

Wrapper value design note: `EulerV1_Wrapper_Value_Design.md`.

## How to Integrate and Use

- Direct: import interfaces from `contracts/protocols/lending/{aave,euler}/.../interfaces/` and call (e.g. `IPool.supply`, `IEVault.deposit`, `IEthereumVaultConnector.batch`).
- Crane-structured: Use native `Permit2AwareRepo` / `Permit2AwareTarget` for gasless approvals (see tokens/ERC4626/* and l2s relayers for examples). Rate providers via `IERC4626RateProvider` for yield-bearing assets in lending contexts.
- With DFPkgs / Diamonds (for your own faceted layers): attach custom facets that use the ported lending primitives via injection. Registries help resolve shared facets (see central `IDiamondFactoryPackage` selectors e.g. `facetCuts() : 0xa4b3ad35`).
- Oracles/risk: EulerRouter or AaveOracle plugged via adapters; combine with Crane oracles.

See AGENTS.md: "*AwareRepo for dependency injection", "*Service for business logic", and DFPkg pattern for composing.

## Test Usage (TestBases, Stubs, Handlers, Invariants)

Lending ports include comprehensive test suites directly under `test/foundry/spec/protocols/lending/` (vendored + extensions). They are executable via:

```bash
forge test --match-path "test/foundry/spec/protocols/lending/aave/**" --offline
```

### Aave v3.6 Tests
- `ProtocolV3TestBase` (in `utils/ProtocolV3TestBase.sol`): base for config snapshots, reserve setup, pool operations tests. Used by Pool.*.t.sol, tokenization tests, rewards, etc.
- Extensive per-area tests: Pool (supply, borrow, repay, liquidations, flashloans, eMode, rounding), AToken/DebtToken behaviors, ACLManager, oracle, rates, invariants (handler-based + echidna/crytic).
- Invariants: `invariants/` with BaseHandler, ProtocolAssertions, HFPostconditionsSpec, full setup in Setup.t.sol + SpecAggregator.
- Gas + edge tests in gas/ and protocol/.

Inheritors call parent setups; use mocks under `utils/mocks/`.

### Aave v4 Tests
- `Base` (in `setup/Base.t.sol`): inherits BaseHelpers + BatchTestProcedures. setUp does `_etchSetup`, `_initTokenList`, `_setupFixtures`, `_initEnvironment`.
- Orchestration-driven deployment:
  ```solidity
  report = AaveV4TestOrchestration.deployTestEnv({ admin: ADMIN, ... });
  hub1 = IHub(report.hubReports[0].hub);
  // then spokes, oracles, etc.
  ```
- Separate coverage: hub (supply/withdraw/borrow/repay/configuration/liquidation/risk-premium), spoke, tokenization-spoke (ERC4626 compliance, permits, max getters), position-manager, config-engine, treasury-spoke, access.
- Gas snapshots, fork verification (`deployments/fork/`), helpers/mocks for actions and wrappers.
- Uses deployment procedures + roles procedures for realistic full-init state (aligns LR-7: no address(0) facets/impls).

See `AaveV4BatchDeployment.t.sol`, procedure tests, and per-feature .t.sol.

### Euler Tests
Euler tests are primarily in the ported structure + certora specs (see `certora/`); direct usage in Crane tests leverages the EVC harnesses and periphery lens for assertions. Combine with `CraneTest` (from AGENTS) when your test also bootstraps Crane factories/registries:

Inheritance example (pattern from dexes/TestBases, adaptable):
```
CraneTest
    └── YourLendingTest (attach ports or use direct constructors from port test utils)
```

Key LR-7 expectations (from PRD): full init before asserts, exact deltas (not just "changed"), Behavior where applicable (for any Crane IFacet layers), registry assertions post-deploy, fork parity (where mainnet oracles/pools exercised).

Use stubs in `euler/v1/stubs/` and periphery for mocking. Handlers for stateful (similar to Aave invariants pattern).

Always inherit order correctly and call parent `setUp` (see AGENTS.md crane-testing patterns).

Example invocation for Aave v4 specific:
`forge test --match-path "test/foundry/spec/protocols/lending/aave/v4/contracts/spoke/supply/Spoke.Supply.t.sol"`

## Protocol Utilities

### Aave Math + Helpers
- `WadRayMath`, `MathUtils`, `PercentageMath`, `SharesMath` (precise interest/liquidity math; used everywhere in accounting).
- Spoke: `SpokeUtils`, `LiquidationLogic`, `UserPositionUtils`, `PositionStatusMap`, `ReserveFlagsMap`, `KeyValueList`.
- Hub: `AssetLogic`, `Premium`.
- Other: EIP712 helpers, bytecode utils in deployments.

### Euler Math + Periphery
- EVC: `Set.sol` (transient set impl), transient storage.
- Vault: `RPow`, `SafeERC20Lib`, `LTVUtils`, `LiquidityUtils`, shared cache/snapshot types.
- Oracle adapters + `ScaleUtils`.
- Periphery Lens: `AccountLens`, `VaultLens`, `OracleLens`, `UtilsLens` (for onchain inspection without side effects).
- IRM libs, swap `QuoteLib`/`FundsLib`/`SwapLib`.
- Perspectives + governors for production gating.

### Crane-Native Cross-Cutting (usable with lending)
- Permit2Aware (see `contracts/protocols/utils/permit2/aware/` and `IPermit2Aware`): for signed approvals in deposits etc.
- IERC4626RateProvider + IRateProvider: for yield tokens (stata, wrappers) in Aave/Euler contexts.
- General: use with ConstProdUtils where DEX+lending composes; Sets (AddressSet etc) for collections in custom services.
- From central NatSpec (use ONLY these values in examples/docs):
  - IFacet: `facetName() : 0x5b6f4d01`, `facetInterfaces() : 0x2ea80826`, `supportsInterface(bytes4) : 0x01ffc9a7`
  - IDiamondPackageCallBackFactory interfaceId: `0x949da331`
  - Common DFPkg: `packageName() : 0xabc8b346`, `initAccount(bytes) : 0x870d4838`, `postDeploy(address) : 0x70068fcf`

Ports exercise these in their test harnesses (e.g. TokenizationSpoke as ERC4626).

## Agent / Consumer Usage + Value (LR-2 / LR-4)

See `getting-started.md`, `deployment/*.md`, `concepts/*.md` for bootstrap.

- Reuse already-deployed verified lending code (via direct or custom facets) eliminates agent-introduced bugs.
- Avoid re-deploying heavy protocol bytecode (cost savings).
- Bootstrap via Create3FactoryDFPkg + reusable DiamondPackageCallBackFactory (central interfaceId 0x949da331; see `diamondPackageFactory() : 0x0fe96d13` from ICreate3Factory).
- Registries (Facet/Package) populated at InitDevService / factory bootstrap allow resolving shared components without hardcoding.
- Test via CraneTest + port TestBases/handlers; assert exact values + full lifecycle.

Cross-links: AGENTS.md (TestBase chains, Behavior libs, FactoryService salt), PRD LR-2/LR-4/LR-7, CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY source for @custom values), docs/protocols/lending/* subdocs.

For GitBook: this surfaces port details, test usage, and utilities as required.

## Verification
After updates, `forge build` and targeted lending tests (as above). All NatSpec examples use ONLY values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md. No viaIR. Full init in examples/tests.

## See also

- [DEX Integrations](dexes.md)
- [Testing Patterns](../development/testing.md)
- [CREATE3 & New Chain Setup](../deployment/create3.md)
- [Getting Started](../getting-started.md)
- [Codebase Map](../CODEBASE_MAP.md)
