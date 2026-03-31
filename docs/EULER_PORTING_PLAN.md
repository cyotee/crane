# Euler Protocol Porting Plan

## Overview

Port four Euler submodules into the Crane repository to enable removal of git submodules and use ported code in tests.

### Target Paths
- **Ported code**: `contracts/protocols/lending/euler/v1/`
- **EVC core**: `contracts/protocols/lending/euler/v1/evc/` (grouped with Euler protocol)
- **Transitive external deps**: `contracts/external/euler/{submodule}/`
- **Ported tests**: `test/foundry/spec/protocols/lending/euler/v1/`
- **Certora formal specs**: `certora/` at repo root

### Submodules to Port
| Submodule | Path in `lib/` | Description |
|-----------|---------------|-------------|
| ethereum-vault-connector | `lib/ethereum-vault-connector/` | EVC - core vault connector with auth, transient execution context, permit/call-through |
| euler-price-oracle | `lib/euler-price-oracle/` | Price oracle system with adapters (Chainlink, UniswapV3, Pyth, Pendle, Redstone, Lido) |
| euler-vault-kit | `lib/euler-vault-kit/` | EVault - core lending vault with modules (Vault, Token, Borrowing, Liquidation, Governance, RiskManager) |
| evk-periphery | `lib/evk-periphery/` | Periphery: ERC4626EVC vaults, Swapper, Lens, IRM, Governor, HookTargets |

---

## Phase 1: Analyze Submodule Structure

### 1.1 Ethereum Vault Connector (EVC)
**Path**: `lib/ethereum-vault-connector/`

**Core Files**:
```
src/
├── EthereumVaultConnector.sol       # Main EVC implementation
├── utils/EVCUtil.sol               # Adapter utilities for vaults
├── interfaces/
│   ├── IEthereumVaultConnector.sol  # Public interface
│   └── IVault.sol                  # Vault interface used by EVC
├── ExecutionContext.sol             # Transient execution context
├── TransientStorage.sol             # Transient storage helpers
├── Events.sol                      # EVC events
├── Errors.sol                      # Custom errors
└── Set.sol                         # Set storage utility
```

**External Dependencies**: OpenZeppelin (ERC165, Initializable)

**Tests**: `test/` and `certora/` directories present

### 1.2 Euler Price Oracle
**Path**: `lib/euler-price-oracle/`

**Core Files**:
```
src/
├── interfaces/
│   └── IPriceOracle.sol             # Public price oracle interface
├── EulerRouter.sol                 # Router/orchestration
├── adapter/
│   ├── BaseAdapter.sol             # Base adapter contract
│   ├── chronicle/ChronicleOracle.sol
│   ├── uniswap/UniswapV3Oracle.sol
│   ├── chainlink/ChainlinkOracle.sol
│   ├── pyth/PythOracle.sol
│   ├── pendle/PendleOracle.sol
│   ├── redstone/RedstoneCoreOracle.sol
│   ├── lido/LidoOracle.sol
│   ├── lido/LidoFundamentalOracle.sol
│   └── rate/RateProviderOracle.sol
├── lib/
│   ├── ScaleUtils.sol              # Price scaling utilities
│   ├── Errors.sol
│   └── Governable.sol
└── lib/                            # Vendored libs
    ├── openzeppelin-contracts/
    ├── solady/
    └── v3-core/
```

**External Dependencies**: OpenZeppelin, Uniswap V3 Core/Periphery, Pyth, Pendle, Redstone, Lido, Solady

**Transitive Dependencies**: ethereum-vault-connector (EVCUtil used in tests)

**Tests**: `test/` with adapter tests, harnesses

### 1.3 Euler Vault Kit (EVK)
**Path**: `lib/euler-vault-kit/`

**Core Files**:
```
src/
├── EVault/
│   ├── IEVault.sol                 # Full EVault interface
│   ├── EVault.sol                  # Main implementation
│   ├── DToken.sol                  # Debt token
│   ├── Dispatch.sol                 # Dispatch module
│   └── modules/
│       ├── Initialize.sol
│       ├── Token.sol               # ERC20 mint/burn
│       ├── Vault.sol               # Core vault logic
│       ├── Borrowing.sol           # Borrow logic
│       ├── Liquidation.sol         # Liquidation logic
│       ├── Governance.sol          # Governance
│       ├── RiskManager.sol         # Risk management
│       └── BalanceForwarder.sol    # Balance forwarding
├── EVault/shared/
│   ├── Base.sol                    # Shared base contract
│   ├── Cache.sol
│   ├── RPow.sol                    # Pow helper
│   ├── SafeERC20Lib.sol
│   ├── ProxyUtils.sol
│   ├── RevertBytes.sol
│   ├── Storage.sol
│   ├── Constants.sol
│   └── Types.sol                   # Type definitions
├── GenericFactory/
│   ├── GenericFactory.sol
│   ├── BeaconProxy.sol
│   └── MetaProxyDeployer.sol
├── SequenceRegistry/
│   └── SequenceRegistry.sol
├── ProtocolConfig/
│   └── ProtocolConfig.sol
├── Synths/
│   ├── ESynth.sol
│   ├── PegStabilityModule.sol
│   └── EulerSavingsRate.sol
└── interfaces/
    ├── ISequenceRegistry.sol
    ├── IPriceOracle.sol
    ├── IBalanceTracker.sol
    ├── IPermit2.sol
    ├── IFlashLoan.sol
    └── IHookTarget.sol
```

**External Dependencies**: OpenZeppelin (ERC20, Initializable, ReentrancyGuard, SafeERC20)

**Transitive Dependencies**: ethereum-vault-connector (EVCUtil, IVault/IEVC types)

**Tests**: `test/` with unit tests, invariants, Certora harnesses

### 1.4 EVK Periphery
**Path**: `lib/evk-periphery/`

**Core Files**:
```
src/
├── Vault/implementation/
│   ├── ERC4626EVC.sol              # ERC4626 vault with EVC integration
│   ├── ERC4626EVCCollateral.sol     # Collateral variant
│   └── deployed/
│       └── ERC4626EVCCollateralSecuritize.sol
├── Vault/freezable/
├── Vault/capped/
├── Swaps/
│   ├── Swapper.sol                 # Swap orchestration
│   ├── SwapVerifier.sol
│   └── handlers/
│       ├── UniswapV3Handler.sol
│       ├── UniswapV2Handler.sol
│       └── GenericHandler.sol
├── Lens/
│   ├── VaultLens.sol
│   ├── OracleLens.sol              # Imports IPriceOracle, Errors
│   ├── AccountLens.sol
│   ├── UtilsLens.sol
│   ├── IRMLens.sol
│   └── LensTypes.sol
├── Perspectives/implementation/
├── Perspectives/deployed/
├── OFT/                            # LayerZero OFT adapters
├── IRMFactory/                     # Interest rate model factories
├── IRM/                            # IRM implementations
│   ├── IRMAdaptiveCurve.sol
│   ├── IRMLinearKinky.sol
│   └── IRMFixedCyclicalBinary.sol
├── Governor/                       # Governance modules
├── HookTarget/                     # Hook implementations
│   ├── BaseHookTarget.sol
│   ├── HookTargetAccessControl*.sol
│   └── ...
├── SnapshotRegistry/
│   └── SnapshotRegistry.sol
├── FeeFlow/
│   └── FeeFlowControllerEVK.sol
├── Liquidator/
│   ├── SBLiquidator.sol
│   └── CustomLiquidatorBase.sol
├── BaseFactory/
├── EdgeFactory/
└── EulerRouterFactory/
```

**External Dependencies**: OpenZeppelin, Uniswap V2/V3, LayerZero, Pendle, Pyth, Redstone, Solady, Permit2

**Transitive Dependencies**:
- evk-periphery → euler-vault-kit (IEVault, types)
- evk-periphery → euler-price-oracle (IPriceOracle, Errors)

**Tests**: `test/` with many unit/integration/fork tests

---

## Phase 2: Dependency Mapping

### 2.1 Inter-Module Dependencies

```
contracts/protocols/lending/euler/v1/evc/  (EVC)
    ↑
    │  (EVCUtil, IVault/IEVC types)
    │
euler-vault-kit (EVK) ──────────→ evc/
    ↑
    │  (IEVault, EVault types, EVCUtil)
    │
evk-periphery ───────────────────→ euler-vault-kit
    │
    ├─────────────────────────────→ euler-price-oracle (IPriceOracle, Errors)
    │
    ├─────────────────────────────→ evc/
    │
    └─────────────────────────────→ euler-swap/ (nested in evk-periphery)

euler-price-oracle
    ↑
    │  (EVCUtil in tests)
    │
    └───────────────────────────────→ evc/
```

### 2.2 External Dependencies by Submodule (Exhaustive)

#### ethereum-vault-connector (`lib/ethereum-vault-connector/`)
| Dependency | Version | Import Path | Status in Crane |
|-----------|---------|-------------|----------------|
| OpenZeppelin Contracts | v4.9.3 | `openzeppelin/...` | **Already vendored** at `contracts/external/openzeppelin/` |
| forge-std | v1.5.6 | `forge-std/...` | **Already vendored** via `lib/forge-std/` |
| ds-test | — | `ds-test/...` | Provided by Foundry |
| erc4626-tests | — | `erc4626-tests/...` | N/A (test utility) |
| Uniswap | — | ❌ None | — |
| solmate | — | ❌ None | — |
| Permit2 | — | ❌ None | — |
| Solady | — | ❌ None | — |
| Pyth | — | ❌ None | — |
| Pendle | — | ❌ None | — |
| Redstone | — | ❌ None | — |
| LayerZero | — | ❌ None | — |

#### euler-price-oracle (`lib/euler-price-oracle/`)
| Dependency | Version | Import Path | Status in Crane |
|-----------|---------|-------------|----------------|
| OpenZeppelin Contracts | release-v4.9 | `@openzeppelin/contracts/...` | **Already vendored** at `contracts/external/openzeppelin/` |
| Uniswap V3 Core | 0.8 branch | `@uniswap/v3-core/...` | **Already vendored** at `contracts/external/balancer/v3/` (subset) — check full coverage |
| Uniswap V3 Periphery | 0.8 branch | `@uniswap/v3-periphery/...` | **Already vendored** at `contracts/external/balancer/v3/` (subset) — check full coverage |
| Solady | rev 0123b4c0 | `@solady/utils/FixedPointMathLib.sol` | **Already vendored** at `contracts/solady/` |
| Pyth SDK | rev c24b3e01 | `@pyth/IPyth.sol`, `@pyth/PythStructs.sol` | **NOT vendored** in Crane — needs vendor |
| Pendle Core V2 | rev a904c7d9 | `@pendle/core-v2/...` | **NOT vendored** in Crane — needs vendor |
| Redstone Evm Connector | v0.4.0 | `@redstone/evm-connector/...` | **NOT vendored** in Crane — needs vendor |
| forge-std | rev bf660614 | `forge-std/...` | **Already vendored** via `lib/forge-std/` |
| Lido | — | Inherit from oracle adapters | **NOT vendored** in Crane — needs vendor (optional, for Lido oracle adapter) |

#### euler-vault-kit (`lib/euler-vault-kit/`)
| Dependency | Version | Import Path | Status in Crane |
|-----------|---------|-------------|----------------|
| OpenZeppelin Contracts | v4.8.0 | `openzeppelin-contracts/...`, `@openzeppelin/contracts/...` | **Already vendored** at `contracts/external/openzeppelin/` |
| Permit2 | rev cc56ad0 | `permit2/src/interfaces/IAllowanceTransfer.sol`, `permit2/src/Permit2.sol` | **Already vendored** — Crane has integration at `contracts/protocols/utils/permit2/`, but **full Permit2 lib needed** for vault-kit |
| solmate | v6 | `solmate/src/tokens/ERC20.sol`, `solmate/src/utils/SafeTransferLib.sol` | **Already vendored** (subset in balancer/solidity-utils, full in `lib/evc-playground/lib/solmate`) |
| forge-std | rev b6a506d | `forge-std/...` | **Already vendored** via `lib/forge-std/` |
| ethereum-vault-connector | v1.0.0 | `ethereum-vault-connector/...` | **Being ported** first |
| ds-test | — | `ds-test/...` | Provided by Foundry |
| erc4626-tests | — | `erc4626-tests/...` | N/A (test utility) |
| Uniswap V3 | — | ❌ None (except via Permit2) | — |
| Uniswap V4 | — | ❌ None | — |
| Solady | — | ❌ None (comments only) | — |
| Pyth | — | ❌ None | — |
| Pendle | — | ❌ None | — |
| Redstone | — | ❌ None | — |
| LayerZero | — | ❌ None | — |

#### evk-periphery (`lib/evk-periphery/`) — Largest, Most Complex
**NOTE**: evk-periphery bundles its own copies of `euler-price-oracle` and `euler-vault-kit` as `lib/euler-price-oracle/` and `lib/euler-vault-kit/` inside its own `lib/` tree. These nested copies bring **their own transitive dependencies**.

| Dependency | Source | Import Path | Status in Crane |
|-----------|--------|-------------|----------------|
| OpenZeppelin Contracts | Nested `lib/euler-vault-kit/lib/openzeppelin-contracts/` + `lib/euler-price-oracle/lib/openzeppelin-contracts/` | `openzeppelin-contracts/...` | **Already vendored** at `contracts/external/openzeppelin/` |
| LayerZero Labs V2 | `src/OFT/` | `@layerzerolabs/lz-evm-oapp-v2/...`, `@layerzerolabs/lz-evm-protocol-v2/...` | **NOT vendored** — needs vendor under `contracts/external/layerzerolabs/` |
| Uniswap V4 Core | Nested `lib/euler-swap/lib/uniswap-v4-core/` | `@uniswap/v4-core/...` | **NOT vendored** in Crane — needs vendor |
| Uniswap V3 Core/Periphery | Nested `lib/euler-price-oracle/lib/v3-core/`, `lib/v3-periphery/` | `@uniswap/v3-core/...`, `@uniswap/v3-periphery/...` | **Already vendored** at `contracts/external/balancer/v3/` — check coverage |
| forge-std | Nested `lib/euler-vault-kit/lib/forge-std/`, `lib/euler-price-oracle/lib/forge-std/` | `forge-std/...` | **Already vendored** via `lib/forge-std/` |
| Permit2 | Nested `lib/euler-vault-kit/lib/permit2/` | `permit2/src/...` | **Already vendored** — check Crane's `contracts/protocols/utils/permit2/` |
| Solady | Nested `lib/euler-price-oracle/lib/solady/` | `@solady/...` | **Already vendored** at `contracts/solady/` |
| Pyth | Nested `lib/euler-price-oracle/lib/pyth-sdk-solidity/` | `@pyth/IPyth.sol` | **NOT vendored** in Crane — needs vendor |
| Pendle Core V2 | Nested `lib/euler-price-oracle/lib/pendle-core-v2-public/` | `@pendle/core-v2/...` | **NOT vendored** in Crane — needs vendor |
| Redstone | Nested `lib/euler-price-oracle/lib/redstone-oracles-monorepo/` | `@redstone/evm-connector/...` | **NOT vendored** in Crane — needs vendor |
| euler-price-oracle | Nested `lib/euler-price-oracle/` | Local Euler interfaces | **Being ported** |
| euler-vault-kit | Nested `lib/euler-vault-kit/` | Local Euler interfaces | **Being ported** |
| ethereum-vault-connector | Nested `lib/euler-vault-kit/lib/ethereum-vault-connector/` | Local EVC interfaces | **Being ported** |
| euler-swap | `lib/euler-swap/` | Local interfaces (not in original 4 submodules) | **Extra dependency discovered** |

### 2.3 Crane's Existing Vendored Libraries

Crane already has these at `contracts/external/`:
```
contracts/external/
├── openzeppelin/          ✅ Full OpenZeppelin v4.x
├── balancer/v3/          ✅ Balancer V3 interfaces + utilities (includes Uniswap V3 libs)
├── chainlink/             ✅ Chainlink AggregatorV3Interface
├── solady/                ✅ Solady (at contracts/solady/)
└── (permit2 wrappers at contracts/protocols/utils/permit2/)
```

**solmate**: Already vendored in multiple places:
- `contracts/external/balancer/v3/solidity-utils/contracts/solmate/` (small subset)
- `contracts/protocols/dexes/uniswap/v4/external/solmate/`
- `lib/evc-playground/lib/solmate/` (full)

**permit2**: Crane has integration wrappers at `contracts/protocols/utils/permit2/` but the full Permit2 lib (AllowanceTransfer, SignatureTransfer) exists in:
- `lib/euler-vault-kit/lib/permit2/`
- `lib/evk-periphery/lib/euler-vault-kit/lib/permit2/`

**NEW external deps needed** (not currently in Crane):
1. `@layerzerolabs/lz-evm-oapp-v2` + `@layerzerolabs/lz-evm-protocol-v2` — LayerZero V2 OFT
2. `@pyth/` — Pyth price oracle SDK
3. `@pendle/core-v2/` — Pendle core V2
4. `@redstone/evm-connector/` — Redstone oracle connector
5. `@uniswap/v4-core/` — Uniswap V4 core (used by euler-swap nested dep)
6. Lido oracle adapter (optional, if Lido adapter is needed)

### 2.4 Transitive Dependency Graph (Full)

```
Crane (contracts/external/)
├── openzeppelin/         ← ethereum-vault-connector ✅
│                        ← euler-price-oracle ✅
│                        ← euler-vault-kit ✅
│                        ← evk-periphery ✅ (via nested libs)
├── balancer/v3/           ← euler-price-oracle ✅ (Uniswap v3 libs)
├── solady/               ← euler-price-oracle ✅
├── chainlink/            ← evk-periphery (Chainlink/DataStreamsVerifier) ✅
│
├── ⚠️  layerzerolabs/     ← evk-periphery (OFTFeeCollector, FeeFlowControllerEVK) ❌ NEEDS VENDOR
├── ⚠️  pyth/              ← euler-price-oracle adapters ❌ NEEDS VENDOR
├── ⚠️  pendle/            ← euler-price-oracle adapters ❌ NEEDS VENDOR
├── ⚠️  redstone/          ← euler-price-oracle adapters ❌ NEEDS VENDOR
├── ⚠️  uniswap/v4-core/    ← euler-swap (nested in evk-periphery) ❌ NEEDS VENDOR
└── permit2 wrappers      ← euler-vault-kit (SafeERC20Lib) ✅ (Crane has wrappers)
```

### 2.5 Version Pin Table

| Library | Commit/Version | Source foundry.lock |
|---------|---------------|-------------------|
| OpenZeppelin Contracts | release-v4.9 (dc44c9f1) | euler-price-oracle |
| OpenZeppelin Contracts | v4.8.0 (e682c7e5) | euler-vault-kit |
| OpenZeppelin Contracts | v4.9.3 | ethereum-vault-connector |
| Uniswap V3 Core | 0.8 branch (6562c52e) | euler-price-oracle |
| Uniswap V3 Periphery | 0.8 branch (b325bb09) | euler-price-oracle |
| Solady | 0123b4c0509ce253 | euler-price-oracle |
| Pyth SDK | c24b3e0173a5715c | euler-price-oracle |
| Pendle Core V2 | a904c7d98ae3e41 | euler-price-oracle |
| Redstone Evm Connector | v0.4.0 (npm) | euler-price-oracle |
| forge-std | bf6606142994b1e | euler-price-oracle |
| Permit2 | cc56ad0f3439c50 | euler-vault-kit |
| solmate (in Permit2) | 8d910d876f51c3 | euler-vault-kit (via permit2) |
| LayerZero labs (V2) | Not in foundry.lock | Must vendor from npm |

---

## Phase 3: Porting Steps

### Step 1: Create Directory Structure

> **NOTE**: evk-periphery contains **nested copies** of euler-price-oracle and euler-vault-kit under `lib/evk-periphery/lib/`. These nested copies are the ones actually used by evk-periphery tests. When porting evk-periphery, port its nested copies together as a unit rather than the top-level submodule copies.

Create the following directory structure:

---

## Phase 3: Porting Steps

### Step 1: Create Directory Structure

Create the following directory structure:

```
contracts/
├── protocols/lending/euler/v1/
│   ├── evc/                      # EVC core (from ethereum-vault-connector)
│   │   ├── EthereumVaultConnector.sol
│   │   ├── IEthereumVaultConnector.sol
│   │   ├── IVault.sol
│   │   ├── EVCUtil.sol
│   │   ├── ExecutionContext.sol
│   │   ├── TransientStorage.sol
│   │   ├── Events.sol
│   │   ├── Errors.sol
│   │   └── Set.sol
│   ├── interfaces/               # Euler-specific interfaces
│   │   ├── IEVault.sol
│   │   └── IPriceOracle.sol
│   ├── vault/                   # EVault core (from euler-vault-kit)
│   │   ├── EVault.sol
│   │   ├── DToken.sol
│   │   ├── Dispatch.sol
│   │   └── modules/
│   │       ├── Initialize.sol
│   │       ├── Token.sol
│   │       ├── Vault.sol
│   │       ├── Borrowing.sol
│   │       ├── Liquidation.sol
│   │       ├── Governance.sol
│   │       ├── RiskManager.sol
│   │       └── BalanceForwarder.sol
│   ├── vault/shared/            # EVault shared utilities
│   │   ├── Base.sol
│   │   ├── Cache.sol
│   │   ├── RPow.sol
│   │   ├── SafeERC20Lib.sol
│   │   ├── ProxyUtils.sol
│   │   ├── RevertBytes.sol
│   │   ├── Storage.sol
│   │   ├── Constants.sol
│   │   └── Types.sol
│   ├── oracle/                  # Price oracle (from euler-price-oracle)
│   │   ├── EulerRouter.sol
│   │   ├── adapters/
│   │   │   ├── BaseAdapter.sol
│   │   │   ├── chronicle/ChronicleOracle.sol
│   │   │   ├── uniswap/UniswapV3Oracle.sol
│   │   │   ├── chainlink/ChainlinkOracle.sol
│   │   │   ├── pyth/PythOracle.sol
│   │   │   ├── pendle/PendleOracle.sol
│   │   │   ├── redstone/RedstoneCoreOracle.sol
│   │   │   ├── lido/LidoOracle.sol
│   │   │   └── rate/RateProviderOracle.sol
│   │   └── lib/
│   │       ├── ScaleUtils.sol
│   │       ├── Errors.sol
│   │       └── Governable.sol
│   ├── periphery/               # EVK Periphery (from evk-periphery)
│   │   ├── vault/
│   │   │   ├── ERC4626EVC.sol
│   │   │   └── ERC4626EVCCollateral.sol
│   │   ├── swaps/
│   │   │   ├── Swapper.sol
│   │   │   ├── SwapVerifier.sol
│   │   │   └── handlers/
│   │   │       ├── UniswapV3Handler.sol
│   │   │       ├── UniswapV2Handler.sol
│   │   │       └── GenericHandler.sol
│   │   ├── lens/
│   │   │   ├── VaultLens.sol
│   │   │   ├── OracleLens.sol
│   │   │   ├── AccountLens.sol
│   │   │   └── UtilsLens.sol
│   │   ├── irm/
│   │   │   ├── IRMAdaptiveCurve.sol
│   │   │   ├── IRMLinearKinky.sol
│   │   │   └── IRMFixedCyclicalBinary.sol
│   │   ├── governor/
│   │   ├── hooktarget/
│   │   ├── snapshot/
│   │   └── feeflow/
│   ├── factory/
│   │   ├── GenericFactory.sol
│   │   ├── BeaconProxy.sol
│   │   └── MetaProxyDeployer.sol
│   ├── sequence/
│   │   └── SequenceRegistry.sol
│   ├── synths/
│   │   ├── ESynth.sol
│   │   ├── PegStabilityModule.sol
│   │   └── EulerSavingsRate.sol
│   ├── euler-swap/              # Euler swap (nested in evk-periphery)
│   │   └── (from lib/evk-periphery/lib/euler-swap/)
│   └── protocol/
│       └── ProtocolConfig.sol
│
contracts/external/euler/
├── evc/                          # EVC (moved to protocol tree, kept for compatibility)
└── (other transitive deps if needed)

test/foundry/spec/protocols/lending/euler/v1/
├── EVault.t.sol
├── PriceOracle.t.sol
├── Periphery.t.sol
└── Integration.t.sol

certora/                           # Formal verification specs (at repo root)
├── EVC/                           # from ethereum-vault-connector
└── specs/                         # from euler-vault-kit
```

### Step 2: Port EVC

1. Create `contracts/protocols/lending/euler/v1/evc/`
2. Copy from `lib/ethereum-vault-connector/src/`:
   - `interfaces/IEthereumVaultConnector.sol`
   - `interfaces/IVault.sol`
   - `utils/EVCUtil.sol`
   - `ExecutionContext.sol`
   - `TransientStorage.sol`
   - `Events.sol`
   - `Errors.sol`
   - `Set.sol`
   - `EthereumVaultConnector.sol`
3. Update imports in ported files:
   - OpenZeppelin → use `@crane/contracts/external/openzeppelin/...`
   - Any internal imports → use `@euler/evc/...`
4. Port Certora specs: copy `lib/ethereum-vault-connector/certora/` → `certora/EVC/`

### Step 3: Port Price Oracle

1. Create `contracts/protocols/lending/euler/v1/oracle/`
2. Copy from `lib/euler-price-oracle/src/`:
   - `interfaces/IPriceOracle.sol`
   - `EulerRouter.sol`
   - `adapter/` directory (all adapters)
   - `lib/` (ScaleUtils, Errors, Governable)
3. Update imports to reference:
   - EVC: `@euler/evc/...`
   - OpenZeppelin: via existing remappings
   - Uniswap V3: existing at `contracts/external/balancer/v3/`
   - Solady: existing at `contracts/solady/`
4. Remove vendored libs (`lib/openzeppelin-contracts/`, `lib/solady/`, `lib/v3-core/`) - use Crane's existing vendored versions
5. Vendor new deps first: Pyth → `contracts/external/pyth/`, Pendle → `contracts/external/pendle/`, Redstone → `contracts/external/redstone/`

### Step 4: Port Vault Kit

1. Create `contracts/protocols/lending/euler/v1/vault/`
2. Copy from `lib/euler-vault-kit/src/EVault/`:
   - All modules
   - All shared utilities
3. Update imports to reference:
   - EVC: `@euler/evc/...`
   - OpenZeppelin: via existing remappings (rewrite from v4.8.0 paths to Crane's v4.9)
   - Permit2: full lib at `contracts/protocols/utils/permit2/` (Crane has wrappers; may need full lib)
4. Copy `GenericFactory/`, `SequenceRegistry/`, `ProtocolConfig/`, `Synths/`
5. Port Certora specs: copy `lib/euler-vault-kit/certora/` → `certora/specs/`

### Step 5: Port Periphery

1. Create `contracts/protocols/lending/euler/v1/periphery/`
2. Copy from `lib/evk-periphery/src/`:
   - `Vault/`, `Swaps/`, `Lens/`, `IRM/`, `Governor/`, `HookTarget/`, `FeeFlow/`, `Liquidator/`, `OFT/`, etc.
3. Port euler-swap: copy from `lib/evk-periphery/lib/euler-swap/` → `contracts/protocols/lending/euler/v1/euler-swap/`
4. Vendor new deps first: LayerZero → `contracts/external/layerzerolabs/`
5. Update imports to reference:
   - EVault: `@euler/contracts/vault/...`
   - PriceOracle: `@euler/contracts/oracle/...`
   - EVC: `@euler/evc/...`
   - Uniswap V4 Core: `@uniswap/v4-core/` (already at `contracts/protocols/dexes/uniswap/v4/`)
   - OpenZeppelin: via existing remappings (rewrite from v4.8.0 paths to Crane's v4.9)
   - LayerZero: `@layerzerolabs/...`

### Step 6: Port Tests (As-Is)

1. Create `test/foundry/spec/protocols/lending/euler/v1/`
2. Copy tests from each submodule's `test/` directory **as-is** (preserve original structure)
3. Update imports to reference ported code locations
4. Copy Certora specs: `lib/evk-periphery/certora/` → `certora/` (if any)

### Step 7: Update Remappings

Add to `remappings.txt`:
```
# Euler protocol code
@euler/contracts/=contracts/protocols/lending/euler/v1/
@euler/evc/=contracts/protocols/lending/euler/v1/evc/
@euler/vault/=contracts/protocols/lending/euler/v1/vault/
@euler/oracle/=contracts/protocols/lending/euler/v1/oracle/
@euler/periphery/=contracts/protocols/lending/euler/v1/periphery/
@euler/external/=contracts/external/euler/

# New external dependencies needed for Euler
@layerzerolabs/=contracts/external/layerzerolabs/
@pyth/=contracts/external/pyth/
@pendle/=contracts/external/pendle/
@redstone/=contracts/external/redstone/
```

Add to `foundry.toml` remappings if needed.

### Step 8: Verify Compilation

```bash
forge build
```

Fix any import path errors or compilation issues.

### Step 9: Run Tests

```bash
forge test --match-path test/foundry/spec/protocols/lending/euler/v1/
```

Fix any test failures due to porting.

---

## Phase 3.5: Per-File Porting Map

### File Counts
| Submodule | Files | Destination |
|----------|-------|--------------|
| ethereum-vault-connector | 10 | `contracts/external/euler/evc/` |
| euler-price-oracle | 28 | `contracts/protocols/lending/euler/v1/oracle/` |
| euler-vault-kit | 62 | `contracts/protocols/lending/euler/v1/vault/` |
| evk-periphery | 93 | `contracts/protocols/lending/euler/v1/periphery/` |
| **Total** | **193** | |

### Per-File Mapping

#### A. ethereum-vault-connector → `contracts/external/euler/evc/`

| Source File | Destination |
|-------------|-------------|
| `src/EthereumVaultConnector.sol` | `contracts/external/euler/evc/EthereumVaultConnector.sol` |
| `src/utils/EVCUtil.sol` | `contracts/external/euler/evc/EVCUtil.sol` |
| `src/interfaces/IEthereumVaultConnector.sol` | `contracts/external/euler/evc/IEthereumVaultConnector.sol` |
| `src/interfaces/IVault.sol` | `contracts/external/euler/evc/IVault.sol` |
| `src/interfaces/IERC1271.sol` | `contracts/external/euler/evc/IERC1271.sol` |
| `src/ExecutionContext.sol` | `contracts/external/euler/evc/ExecutionContext.sol` |
| `src/TransientStorage.sol` | `contracts/external/euler/evc/TransientStorage.sol` |
| `src/Events.sol` | `contracts/external/euler/evc/Events.sol` |
| `src/Errors.sol` | `contracts/external/euler/evc/Errors.sol` |
| `src/Set.sol` | `contracts/external/euler/evc/Set.sol` |

#### B. euler-price-oracle → `contracts/protocols/lending/euler/v1/oracle/`

| Source File | Destination |
|-------------|-------------|
| `src/interfaces/IPriceOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/interfaces/IPriceOracle.sol` |
| `src/EulerRouter.sol` | `contracts/protocols/lending/euler/v1/oracle/EulerRouter.sol` |
| `src/lib/ScaleUtils.sol` | `contracts/protocols/lending/euler/v1/oracle/lib/ScaleUtils.sol` |
| `src/lib/Errors.sol` | `contracts/protocols/lending/euler/v1/oracle/lib/Errors.sol` |
| `src/lib/Governable.sol` | `contracts/protocols/lending/euler/v1/oracle/lib/Governable.sol` |
| `src/adapter/BaseAdapter.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/BaseAdapter.sol` |
| `src/adapter/CrossAdapter.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/CrossAdapter.sol` |
| `src/adapter/chainlink/AggregatorV3Interface.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/chainlink/AggregatorV3Interface.sol` |
| `src/adapter/chainlink/ChainlinkOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/chainlink/ChainlinkOracle.sol` |
| `src/adapter/chainlink/ChainlinkInfrequentOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/chainlink/ChainlinkInfrequentOracle.sol` |
| `src/adapter/chainlink/ChainlinkInfrequentXStocksOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/chainlink/ChainlinkInfrequentXStocksOracle.sol` |
| `src/adapter/chronicle/IChronicle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/chronicle/IChronicle.sol` |
| `src/adapter/chronicle/ChronicleOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/chronicle/ChronicleOracle.sol` |
| `src/adapter/uniswap/UniswapV3Oracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/uniswap/UniswapV3Oracle.sol` |
| `src/adapter/pyth/PythOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/pyth/PythOracle.sol` |
| `src/adapter/pendle/PendleOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/pendle/PendleOracle.sol` |
| `src/adapter/pendle/PendleUniversalOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/pendle/PendleUniversalOracle.sol` |
| `src/adapter/redstone/RedstoneCoreOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/redstone/RedstoneCoreOracle.sol` |
| `src/adapter/lido/IStEth.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/lido/IStEth.sol` |
| `src/adapter/lido/LidoOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/lido/LidoOracle.sol` |
| `src/adapter/lido/LidoFundamentalOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/lido/LidoFundamentalOracle.sol` |
| `src/adapter/rate/IRateProvider.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/rate/IRateProvider.sol` |
| `src/adapter/rate/RateProviderOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/rate/RateProviderOracle.sol` |
| `src/adapter/fixed/FixedRateOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/fixed/FixedRateOracle.sol` |
| `src/adapter/idle/IIdleTranche.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/idle/IIdleTranche.sol` |
| `src/adapter/idle/IIdleCDO.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/idle/IIdleCDO.sol` |
| `src/adapter/idle/IdleTranchesOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/idle/IdleTranchesOracle.sol` |
| `src/adapter/ondo/OndoOracle.sol` | `contracts/protocols/lending/euler/v1/oracle/adapter/ondo/OndoOracle.sol` |

#### C. euler-vault-kit → `contracts/protocols/lending/euler/v1/vault/`

| Source File | Destination |
|-------------|-------------|
| `src/EVault/IEVault.sol` | `contracts/protocols/lending/euler/v1/vault/IEVault.sol` |
| `src/EVault/EVault.sol` | `contracts/protocols/lending/euler/v1/vault/EVault.sol` |
| `src/EVault/DToken.sol` | `contracts/protocols/lending/euler/v1/vault/DToken.sol` |
| `src/EVault/Dispatch.sol` | `contracts/protocols/lending/euler/v1/vault/Dispatch.sol` |
| `src/EVault/modules/Initialize.sol` | `contracts/protocols/lending/euler/v1/vault/modules/Initialize.sol` |
| `src/EVault/modules/Token.sol` | `contracts/protocols/lending/euler/v1/vault/modules/Token.sol` |
| `src/EVault/modules/Vault.sol` | `contracts/protocols/lending/euler/v1/vault/modules/Vault.sol` |
| `src/EVault/modules/Borrowing.sol` | `contracts/protocols/lending/euler/v1/vault/modules/Borrowing.sol` |
| `src/EVault/modules/Liquidation.sol` | `contracts/protocols/lending/euler/v1/vault/modules/Liquidation.sol` |
| `src/EVault/modules/Governance.sol` | `contracts/protocols/lending/euler/v1/vault/modules/Governance.sol` |
| `src/EVault/modules/RiskManager.sol` | `contracts/protocols/lending/euler/v1/vault/modules/RiskManager.sol` |
| `src/EVault/modules/BalanceForwarder.sol` | `contracts/protocols/lending/euler/v1/vault/modules/BalanceForwarder.sol` |
| `src/EVault/shared/Base.sol` | `contracts/protocols/lending/euler/v1/vault/shared/Base.sol` |
| `src/EVault/shared/Cache.sol` | `contracts/protocols/lending/euler/v1/vault/shared/Cache.sol` |
| `src/EVault/shared/Storage.sol` | `contracts/protocols/lending/euler/v1/vault/shared/Storage.sol` |
| `src/EVault/shared/Constants.sol` | `contracts/protocols/lending/euler/v1/vault/shared/Constants.sol` |
| `src/EVault/shared/Events.sol` | `contracts/protocols/lending/euler/v1/vault/shared/Events.sol` |
| `src/EVault/shared/Errors.sol` | `contracts/protocols/lending/euler/v1/vault/shared/Errors.sol` |
| `src/EVault/shared/EVCClient.sol` | `contracts/protocols/lending/euler/v1/vault/shared/EVCClient.sol` |
| `src/EVault/shared/BorrowUtils.sol` | `contracts/protocols/lending/euler/v1/vault/shared/BorrowUtils.sol` |
| `src/EVault/shared/LTVUtils.sol` | `contracts/protocols/lending/euler/v1/vault/shared/LTVUtils.sol` |
| `src/EVault/shared/LiquidityUtils.sol` | `contracts/protocols/lending/euler/v1/vault/shared/LiquidityUtils.sol` |
| `src/EVault/shared/BalanceUtils.sol` | `contracts/protocols/lending/euler/v1/vault/shared/BalanceUtils.sol` |
| `src/EVault/shared/AssetTransfers.sol` | `contracts/protocols/lending/euler/v1/vault/shared/AssetTransfers.sol` |
| `src/EVault/shared/types/VaultStorage.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/VaultStorage.sol` |
| `src/EVault/shared/types/Types.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/Types.sol` |
| `src/EVault/shared/types/VaultCache.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/VaultCache.sol` |
| `src/EVault/shared/types/Assets.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/Assets.sol` |
| `src/EVault/shared/types/Shares.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/Shares.sol` |
| `src/EVault/shared/types/Owed.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/Owed.sol` |
| `src/EVault/shared/types/UserStorage.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/UserStorage.sol` |
| `src/EVault/shared/types/Snapshot.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/Snapshot.sol` |
| `src/EVault/shared/types/LTVConfig.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/LTVConfig.sol` |
| `src/EVault/shared/types/ConfigAmount.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/ConfigAmount.sol` |
| `src/EVault/shared/types/AmountCap.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/AmountCap.sol` |
| `src/EVault/shared/types/Flags.sol` | `contracts/protocols/lending/euler/v1/vault/shared/types/Flags.sol` |
| `src/EVault/shared/lib/RPow.sol` | `contracts/protocols/lending/euler/v1/vault/shared/lib/RPow.sol` |
| `src/EVault/shared/lib/SafeERC20Lib.sol` | `contracts/protocols/lending/euler/v1/vault/shared/lib/SafeERC20Lib.sol` |
| `src/EVault/shared/lib/RevertBytes.sol` | `contracts/protocols/lending/euler/v1/vault/shared/lib/RevertBytes.sol` |
| `src/EVault/shared/lib/ProxyUtils.sol` | `contracts/protocols/lending/euler/v1/vault/shared/lib/ProxyUtils.sol` |
| `src/EVault/shared/lib/AddressUtils.sol` | `contracts/protocols/lending/euler/v1/vault/shared/lib/AddressUtils.sol` |
| `src/EVault/shared/lib/ConversionHelpers.sol` | `contracts/protocols/lending/euler/v1/vault/shared/lib/ConversionHelpers.sol` |
| `src/interfaces/IPriceOracle.sol` | `contracts/protocols/lending/euler/v1/vault/interfaces/IPriceOracle.sol` |
| `src/interfaces/ISequenceRegistry.sol` | `contracts/protocols/lending/euler/v1/vault/interfaces/ISequenceRegistry.sol` |
| `src/interfaces/IBalanceTracker.sol` | `contracts/protocols/lending/euler/v1/vault/interfaces/IBalanceTracker.sol` |
| `src/interfaces/IPermit2.sol` | `contracts/protocols/lending/euler/v1/vault/interfaces/IPermit2.sol` |
| `src/interfaces/IFlashLoan.sol` | `contracts/protocols/lending/euler/v1/vault/interfaces/IFlashLoan.sol` |
| `src/interfaces/IHookTarget.sol` | `contracts/protocols/lending/euler/v1/vault/interfaces/IHookTarget.sol` |
| `src/GenericFactory/GenericFactory.sol` | `contracts/protocols/lending/euler/v1/vault/GenericFactory.sol` |
| `src/GenericFactory/BeaconProxy.sol` | `contracts/protocols/lending/euler/v1/vault/BeaconProxy.sol` |
| `src/GenericFactory/MetaProxyDeployer.sol` | `contracts/protocols/lending/euler/v1/vault/MetaProxyDeployer.sol` |
| `src/SequenceRegistry/SequenceRegistry.sol` | `contracts/protocols/lending/euler/v1/vault/SequenceRegistry.sol` |
| `src/ProtocolConfig/IProtocolConfig.sol` | `contracts/protocols/lending/euler/v1/vault/interfaces/IProtocolConfig.sol` |
| `src/ProtocolConfig/ProtocolConfig.sol` | `contracts/protocols/lending/euler/v1/vault/ProtocolConfig.sol` |
| `src/Synths/ESynth.sol` | `contracts/protocols/lending/euler/v1/vault/synths/ESynth.sol` |
| `src/Synths/PegStabilityModule.sol` | `contracts/protocols/lending/euler/v1/vault/synths/PegStabilityModule.sol` |
| `src/Synths/EulerSavingsRate.sol` | `contracts/protocols/lending/euler/v1/vault/synths/EulerSavingsRate.sol` |
| `src/Synths/ERC20EVCCompatible.sol` | `contracts/protocols/lending/euler/v1/vault/synths/ERC20EVCCompatible.sol` |
| `src/Synths/HookTargetSynth.sol` | `contracts/protocols/lending/euler/v1/vault/synths/HookTargetSynth.sol` |
| `src/Synths/IRMSynth.sol` | `contracts/protocols/lending/euler/v1/vault/synths/IRMSynth.sol` |
| `src/InterestRateModels/IIRM.sol` | `contracts/protocols/lending/euler/v1/vault/interfaces/IIRM.sol` |
| `src/InterestRateModels/IRMLinearKink.sol` | `contracts/protocols/lending/euler/v1/vault/IRMLinearKink.sol` |

#### D. evk-periphery → `contracts/protocols/lending/euler/v1/periphery/`

| Source File | Destination |
|-------------|-------------|
| `src/Vault/implementation/ERC4626EVC.sol` | `contracts/protocols/lending/euler/v1/periphery/Vault/implementation/ERC4626EVC.sol` |
| `src/Vault/implementation/ERC4626EVCCollateral.sol` | `contracts/protocols/lending/euler/v1/periphery/Vault/implementation/ERC4626EVCCollateral.sol` |
| `src/Vault/implementation/ERC4626EVCCollateralCapped.sol` | `contracts/protocols/lending/euler/v1/periphery/Vault/implementation/ERC4626EVCCollateralCapped.sol` |
| `src/Vault/implementation/ERC4626EVCCollateralFreezable.sol` | `contracts/protocols/lending/euler/v1/periphery/Vault/implementation/ERC4626EVCCollateralFreezable.sol` |
| `src/Vault/deployed/ERC4626EVCCollateralSecuritize.sol` | `contracts/protocols/lending/euler/v1/periphery/Vault/deployed/ERC4626EVCCollateralSecuritize.sol` |
| `src/Swaps/Swapper.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/Swapper.sol` |
| `src/Swaps/SwapperOwnable.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/SwapperOwnable.sol` |
| `src/Swaps/ISwapper.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/ISwapper.sol` |
| `src/Swaps/SwapVerifier.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/SwapVerifier.sol` |
| `src/Swaps/TransferFromSender.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/TransferFromSender.sol` |
| `src/Swaps/handlers/BaseHandler.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/handlers/BaseHandler.sol` |
| `src/Swaps/handlers/UniswapV3Handler.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/handlers/UniswapV3Handler.sol` |
| `src/Swaps/handlers/UniswapV2Handler.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/handlers/UniswapV2Handler.sol` |
| `src/Swaps/handlers/GenericHandler.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/handlers/GenericHandler.sol` |
| `src/Swaps/tools/PendleLPWrapperTool.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/tools/PendleLPWrapperTool.sol` |
| `src/Swaps/vendor/IUniswapV3SwapCallback.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/vendor/IUniswapV3SwapCallback.sol` |
| `src/Swaps/vendor/ISwapRouterV3.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/vendor/ISwapRouterV3.sol` |
| `src/Swaps/vendor/ISwapRouterV2.sol` | `contracts/protocols/lending/euler/v1/periphery/Swaps/vendor/ISwapRouterV2.sol` |
| `src/Lens/VaultLens.sol` | `contracts/protocols/lending/euler/v1/periphery/Lens/VaultLens.sol` |
| `src/Lens/OracleLens.sol` | `contracts/protocols/lending/euler/v1/periphery/Lens/OracleLens.sol` |
| `src/Lens/AccountLens.sol` | `contracts/protocols/lending/euler/v1/periphery/Lens/AccountLens.sol` |
| `src/Lens/UtilsLens.sol` | `contracts/protocols/lending/euler/v1/periphery/Lens/UtilsLens.sol` |
| `src/Lens/Utils.sol` | `contracts/protocols/lending/euler/v1/periphery/Lens/Utils.sol` |
| `src/Lens/LensTypes.sol` | `contracts/protocols/lending/euler/v1/periphery/Lens/LensTypes.sol` |
| `src/Lens/IRMLens.sol` | `contracts/protocols/lending/euler/v1/periphery/Lens/IRMLens.sol` |
| `src/Lens/EulerEarnVaultLens.sol` | `contracts/protocols/lending/euler/v1/periphery/Lens/EulerEarnVaultLens.sol` |
| `src/IRM/IRMAdaptiveCurve.sol` | `contracts/protocols/lending/euler/v1/periphery/IRM/IRMAdaptiveCurve.sol` |
| `src/IRM/IRMLinearKinky.sol` | `contracts/protocols/lending/euler/v1/periphery/IRM/IRMLinearKinky.sol` |
| `src/IRM/IRMFixedCyclicalBinary.sol` | `contracts/protocols/lending/euler/v1/periphery/IRM/IRMFixedCyclicalBinary.sol` |
| `src/IRM/IRMBasePremium.sol` | `contracts/protocols/lending/euler/v1/periphery/IRM/IRMBasePremium.sol` |
| `src/IRM/lib/ExpLib.sol` | `contracts/protocols/lending/euler/v1/periphery/IRM/lib/ExpLib.sol` |
| `src/IRMFactory/EulerKinkyIRMFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/IRMFactory/EulerKinkyIRMFactory.sol` |
| `src/IRMFactory/EulerKinkIRMFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/IRMFactory/EulerKinkIRMFactory.sol` |
| `src/IRMFactory/EulerIRMAdaptiveCurveFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/IRMFactory/EulerIRMAdaptiveCurveFactory.sol` |
| `src/IRMFactory/EulerFixedCyclicalBinaryIRMFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/IRMFactory/EulerFixedCyclicalBinaryIRMFactory.sol` |
| `src/IRMFactory/interfaces/IEulerKinkyIRMFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/IRMFactory/interfaces/IEulerKinkyIRMFactory.sol` |
| `src/IRMFactory/interfaces/IEulerKinkIRMFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/IRMFactory/interfaces/IEulerKinkIRMFactory.sol` |
| `src/IRMFactory/interfaces/IEulerFixedCyclicalBinaryIRMFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/IRMFactory/interfaces/IEulerFixedCyclicalBinaryIRMFactory.sol` |
| `src/Governor/GovernorAccessControl.sol` | `contracts/protocols/lending/euler/v1/periphery/Governor/GovernorAccessControl.sol` |
| `src/Governor/GovernorGuardian.sol` | `contracts/protocols/lending/euler/v1/periphery/Governor/GovernorGuardian.sol` |
| `src/Governor/GovernorAccessControlEmergency.sol` | `contracts/protocols/lending/euler/v1/periphery/Governor/GovernorAccessControlEmergency.sol` |
| `src/Governor/FactoryGovernor.sol` | `contracts/protocols/lending/euler/v1/periphery/Governor/FactoryGovernor.sol` |
| `src/Governor/CapRiskSteward.sol` | `contracts/protocols/lending/euler/v1/periphery/Governor/CapRiskSteward.sol` |
| `src/Governor/ReadOnlyProxy.sol` | `contracts/protocols/lending/euler/v1/periphery/Governor/ReadOnlyProxy.sol` |
| `src/GovernorFactory/GovernorAccessControlEmergencyFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/GovernorFactory/GovernorAccessControlEmergencyFactory.sol` |
| `src/GovernorFactory/CapRiskStewardFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/GovernorFactory/CapRiskStewardFactory.sol` |
| `src/GovernorFactory/interfaces/IGovernorAccessControlEmergencyFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/GovernorFactory/interfaces/IGovernorAccessControlEmergencyFactory.sol` |
| `src/GovernorFactory/interfaces/ICapRiskStewardFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/GovernorFactory/interfaces/ICapRiskStewardFactory.sol` |
| `src/HookTarget/BaseHookTarget.sol` | `contracts/protocols/lending/euler/v1/periphery/HookTarget/BaseHookTarget.sol` |
| `src/HookTarget/HookTargetAccessControl.sol` | `contracts/protocols/lending/euler/v1/periphery/HookTarget/HookTargetAccessControl.sol` |
| `src/HookTarget/HookTargetAccessControlKeyring.sol` | `contracts/protocols/lending/euler/v1/periphery/HookTarget/HookTargetAccessControlKeyring.sol` |
| `src/HookTarget/HookTargetGuardian.sol` | `contracts/protocols/lending/euler/v1/periphery/HookTarget/HookTargetGuardian.sol` |
| `src/HookTarget/HookTargetMarketStatus.sol` | `contracts/protocols/lending/euler/v1/periphery/HookTarget/HookTargetMarketStatus.sol` |
| `src/HookTarget/HookTargetStakeDelegator.sol` | `contracts/protocols/lending/euler/v1/periphery/HookTarget/HookTargetStakeDelegator.sol` |
| `src/HookTarget/HookTargetTermsOfUse.sol` | `contracts/protocols/lending/euler/v1/periphery/HookTarget/HookTargetTermsOfUse.sol` |
| `src/Perspectives/implementation/BasePerspective.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/implementation/BasePerspective.sol` |
| `src/Perspectives/implementation/interfaces/IPerspective.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/implementation/interfaces/IPerspective.sol` |
| `src/Perspectives/implementation/PerspectiveErrors.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/implementation/PerspectiveErrors.sol` |
| `src/Perspectives/deployed/EulerUngovernedPerspective.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/deployed/EulerUngovernedPerspective.sol` |
| `src/Perspectives/deployed/GovernedPerspective.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/deployed/GovernedPerspective.sol` |
| `src/Perspectives/deployed/EulerEarnFactoryPerspective.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/deployed/EulerEarnFactoryPerspective.sol` |
| `src/Perspectives/deployed/EVKFactoryPerspective.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/deployed/EVKFactoryPerspective.sol` |
| `src/Perspectives/deployed/EdgeFactoryPerspective.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/deployed/EdgeFactoryPerspective.sol` |
| `src/Perspectives/deployed/EscrowedCollateralPerspective.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/deployed/EscrowedCollateralPerspective.sol` |
| `src/Perspectives/deployed/CustomWhitelistPerspective.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/deployed/CustomWhitelistPerspective.sol` |
| `src/Perspectives/deployed/OneOfMetaPerspective.sol` | `contracts/protocols/lending/euler/v1/periphery/Perspectives/deployed/OneOfMetaPerspective.sol` |
| `src/SnapshotRegistry/SnapshotRegistry.sol` | `contracts/protocols/lending/euler/v1/periphery/SnapshotRegistry/SnapshotRegistry.sol` |
| `src/FeeFlow/FeeFlowControllerEVK.sol` | `contracts/protocols/lending/euler/v1/periphery/FeeFlow/FeeFlowControllerEVK.sol` |
| `src/Util/FeeCollectorUtil.sol` | `contracts/protocols/lending/euler/v1/periphery/Util/FeeCollectorUtil.sol` |
| `src/Util/FeeFlowControllerUtil.sol` | `contracts/protocols/lending/euler/v1/periphery/Util/FeeFlowControllerUtil.sol` |
| `src/Liquidator/SBLiquidator.sol` | `contracts/protocols/lending/euler/v1/periphery/Liquidator/SBLiquidator.sol` |
| `src/Liquidator/CustomLiquidatorBase.sol` | `contracts/protocols/lending/euler/v1/periphery/Liquidator/CustomLiquidatorBase.sol` |
| `src/OFT/OFTFeeCollector.sol` | `contracts/protocols/lending/euler/v1/periphery/OFT/OFTFeeCollector.sol` |
| `src/OFT/OFTFeeCollectorGulper.sol` | `contracts/protocols/lending/euler/v1/periphery/OFT/OFTFeeCollectorGulper.sol` |
| `src/OFT/OFTAdapterUpgradeable.sol` | `contracts/protocols/lending/euler/v1/periphery/OFT/OFTAdapterUpgradeable.sol` |
| `src/OFT/MintBurnOFTAdapter.sol` | `contracts/protocols/lending/euler/v1/periphery/OFT/MintBurnOFTAdapter.sol` |
| `src/ERC20/implementation/ERC20WrapperLocked.sol` | `contracts/protocols/lending/euler/v1/periphery/ERC20/implementation/ERC20WrapperLocked.sol` |
| `src/ERC20/deployed/ERC20BurnableMintable.sol` | `contracts/protocols/lending/euler/v1/periphery/ERC20/deployed/ERC20BurnableMintable.sol` |
| `src/ERC20/deployed/ERC20Synth.sol` | `contracts/protocols/lending/euler/v1/periphery/ERC20/deployed/ERC20Synth.sol` |
| `src/ERC20/deployed/RewardToken.sol` | `contracts/protocols/lending/euler/v1/periphery/ERC20/deployed/RewardToken.sol` |
| `src/BaseFactory/BaseFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/BaseFactory/BaseFactory.sol` |
| `src/BaseFactory/interfaces/IFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/BaseFactory/interfaces/IFactory.sol` |
| `src/EdgeFactory/EdgeFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/EdgeFactory/EdgeFactory.sol` |
| `src/EdgeFactory/interfaces/IEdgeFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/EdgeFactory/interfaces/IEdgeFactory.sol` |
| `src/EulerRouterFactory/EulerRouterFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/EulerRouterFactory/EulerRouterFactory.sol` |
| `src/EulerRouterFactory/interfaces/IEulerRouterFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/EulerRouterFactory/interfaces/IEulerRouterFactory.sol` |
| `src/VaultFactory/ERC4626EVCCollateralSecuritizeFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/VaultFactory/ERC4626EVCCollateralSecuritizeFactory.sol` |
| `src/VaultFactory/interfaces/IERC4626EVCCollateralSecuritizeFactory.sol` | `contracts/protocols/lending/euler/v1/periphery/VaultFactory/interfaces/IERC4626EVCCollateralSecuritizeFactory.sol` |
| `src/AccessControl/SelectorAccessControl.sol` | `contracts/protocols/lending/euler/v1/periphery/AccessControl/SelectorAccessControl.sol` |
| `src/Chainlink/DataStreamsVerifier.sol` | `contracts/protocols/lending/euler/v1/periphery/Chainlink/DataStreamsVerifier.sol` |
| `src/TermsOfUseSigner/TermsOfUseSigner.sol` | `contracts/protocols/lending/euler/v1/periphery/TermsOfUseSigner/TermsOfUseSigner.sol` |
| `src/Integrations/Idle-Fasanara/SwapHandler.sol` | `contracts/protocols/lending/euler/v1/periphery/Integrations/Idle-Fasanara/SwapHandler.sol` |
| `src/Integrations/Idle-Fasanara/HookTarget.sol` | `contracts/protocols/lending/euler/v1/periphery/Integrations/Idle-Fasanara/HookTarget.sol` |

---

## Phase 4: Submodule Removal

After successful porting and testing:

1. Remove submodule entries from `.gitmodules`
2. Remove submodule directory from `.git/config`
3. Delete submodule directory from `lib/`
4. Commit changes

```bash
git submodule deinit -f lib/euler-vault-connector
git submodule deinit -f lib/euler-price-oracle
git submodule deinit -f lib/euler-vault-kit
git submodule deinit -f lib/evk-periphery
rm -rf lib/euler-vault-connector lib/euler-price-oracle lib/euler-vault-kit lib/evk-periphery
git rm .gitmodules
git rm .git/modules (if exists)
git commit -m "feat: port Euler protocol code from submodules"
```

---

## Implementation Order (Dependency Order)

Port in this order to minimize import errors:

1. **EVC** (no dependencies) → `contracts/protocols/lending/euler/v1/evc/`
2. **Price Oracle** (depends on EVC) → `contracts/protocols/lending/euler/v1/oracle/`
   - **NEW**: Vendor new deps first: `pyth/`, `pendle/`, `redstone/` before porting oracle adapters
3. **Vault Kit** (depends on EVC) → `contracts/protocols/lending/euler/v1/vault/`
   - **NEW**: Vendor `permit2/` (full lib) and ensure `solmate/` is accessible
4. **Periphery** (depends on Vault Kit, Price Oracle, EVC) → `contracts/protocols/lending/euler/v1/periphery/`
   - **NEW**: Vendor `layerzerolabs/` (lz-evm-oapp-v2, lz-evm-protocol-v2) before porting OFT code
   - **NEW**: Vendor `uniswap/v4-core/` before porting euler-swap integration
   - Port evk-periphery's nested `lib/euler-price-oracle/` and `lib/euler-vault-kit/` together as a unit
5. **Tests** (depends on all) → `test/foundry/spec/protocols/lending/euler/v1/`

---

## External Dependency Handling

### Already Available in Crane ✅
| Dependency | Crane Location | Notes |
|-----------|---------------|-------|
| OpenZeppelin | `contracts/external/openzeppelin/` | Full v4.x; use via `@crane/contracts/external/openzeppelin/` |
| Uniswap V3 Core | `contracts/external/balancer/v3/` | Check if full coverage; may need supplement |
| Uniswap V3 Periphery | `contracts/external/balancer/v3/` | Check if full coverage; may need supplement |
| Solady | `contracts/solady/` + `contracts/external/balancer/v3/solidity-utils/contracts/solmate/` | Full Solady at `contracts/solady/` |
| Chainlink | `contracts/external/chainlink/` | Already vendored |
| Permit2 | `contracts/protocols/utils/permit2/` (wrappers) | Full lib at `lib/euler-vault-kit/lib/permit2/`; port wrappers + lib |
| solmate | Multiple locations | Full at `lib/evc-playground/lib/solmate/`; subset at balancer |
| forge-std | `lib/forge-std/` | Use via `forge-std/` remapping |

### Needs Vendoring ❌
| Dependency | Vendor To | Notes |
|-----------|-----------|-------|
| `@layerzerolabs/lz-evm-oapp-v2` | `contracts/external/layerzerolabs/lz-evm-oapp-v2/` | Used by OFTFeeCollector, FeeFlowControllerEVK |
| `@layerzerolabs/lz-evm-protocol-v2` | `contracts/external/layerzerolabs/lz-evm-protocol-v2/` | LayerZero V2 protocol |
| `@pyth/` (pyth-sdk-solidity) | `contracts/external/pyth/` | Used by PythOracle adapter |
| `@pendle/core-v2/` | `contracts/external/pendle/core-v2/` | Used by PendleOracle adapter |
| `@redstone/evm-connector/` | `contracts/external/redstone/` | Used by RedstoneCoreOracle adapter |
| `@uniswap/v4-core/` | `contracts/external/uniswap/v4-core/` | Used by euler-swap (nested in evk-periphery) |
| Lido (optional) | `contracts/external/lido/` | If Lido oracle adapter is needed |

### Remapping Strategy
Add to `remappings.txt`:
```
# Euler protocol code
@euler/contracts/=contracts/protocols/lending/euler/v1/
@euler/external/=contracts/external/euler/
@euler/evc/=contracts/protocols/lending/euler/v1/evc/

# New external dependencies needed for Euler
@layerzerolabs/=contracts/external/layerzerolabs/
@pyth/=contracts/external/pyth/
@pendle/=contracts/external/pendle/
@redstone/=contracts/external/redstone/
@unisdk/=contracts/external/uniswap/v4-core/
```

### Import Rewriting Strategy

**Rule**: When porting any submodule, rewrite all OpenZeppelin imports to use Crane's existing vendored copy at `contracts/external/openzeppelin/`. Do NOT copy nested OZ libs from submodules.

**evk-periphery special handling**:
- evk-periphery's `lib/euler-price-oracle/` and `lib/euler-vault-kit/` are nested copies used by its tests — port these together as a unit
- Rewrite their OZ imports to Crane's v4.9 copy
- Port euler-swap/ (nested in evk-periphery) which uses Uniswap V4 Core

### Certora Formal Verification

Port all `certora/` directories from each submodule to `certora/` at the repo root:
- `certora/EVC/` — from ethereum-vault-connector
- `certora/specs/` — from euler-vault-kit

These contain `.cvl` formal specification files used by Certora Prover.

### Important: Nested Submodule Discovery

**evk-periphery contains its own nested copies** of `euler-price-oracle` and `euler-vault-kit` inside `lib/evk-periphery/lib/`. These nested copies bring additional dependencies not in the top-level 4 submodules:
- `lib/evk-periphery/lib/euler-swap/` — Euler swap integration (uses Uniswap V4 Core at `contracts/protocols/dexes/uniswap/v4/`)
- These nested libs must be analyzed separately if evk-periphery tests exercise these paths

When porting evk-periphery:
1. Port its nested `lib/euler-price-oracle/` and `lib/euler-vault-kit/` together as a unit
2. Rewrite all OZ imports to Crane's existing v4.9 copy
3. Also port `lib/euler-swap/` (depends on Uniswap V4 Core — already in Crane at `contracts/protocols/dexes/uniswap/v4/`)
4. Rewrite imports to use the newly-porting versions (not the nested copies)

---

## Crane Conventions to Follow

1. **Naming**: Use Crane suffixes (Repo, Target, Facet, Service, AwareRepo, TestBase_)
2. **Storage**: Use Diamond storage pattern with `_layout()` functions
3. **Interfaces**: Prefix with `I` (IEVault, IPriceOracle)
4. **Tests**: TestBase in `contracts/`, specs in `test/foundry/spec/`
5. **Imports**: Use `@crane/contracts/...` remappings
6. **viaIR**: Keep disabled (no IR compilation)

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Circular dependencies | Architecture review before porting (none found so far — EVC has no deps, others depend outward) |
| Missing transitive deps | Phase 2 analysis found 6 new external deps not in Crane: LayerZero V2, Pyth, Pendle, Redstone, Uniswap V4 Core, Lido |
| Nested submodules in evk-periphery | evk-periphery bundles its own evk-price-oracle + evk-vault-kit + euler-swap. Treat as a unit; port nested libs together; rewrite imports to use ported versions |
| Multiple OpenZeppelin versions | All OZ imports rewritten to Crane's existing v4.9. Rewrite strategy confirmed with user |
| Test failures | Incremental port + test each phase; port tests as-is (preserve original coverage) |
| Import path hell | Careful remapping management; use `@euler/` namespace for ported code |
| Large code size | Use service libraries for complex logic; Crane's Facet-Target-Repo pattern |
| Uniswap V4 dependency | Uniswap V4 Core already exists at `contracts/protocols/dexes/uniswap/v4/`; confirmed by user |
| LayerZero V2 vendor size | OFT code requires full LayerZero V2; port even though large |
| Certora specs | Port all `.cvl` files to `certora/` at repo root |
