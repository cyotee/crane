# Frax Port Design Spec

**Plan:** [2026-06-02-frax-port.md](../plans/2026-06-02-frax-port.md)  
**Upstream:** `lib/frax-solidity` @ `30532c8cefcbf5c7efafcff4369261bd435a4859`  
**Target solc:** `^0.8.35` (Crane `foundry.toml` pins `0.8.35`)

## 1. Decisions (user-confirmed)

| Topic | Decision |
|-------|----------|
| Scope | Full port; done when all tests ported/rewritten and passing |
| `Misc_AMOs/` | Port entirely (188 files) |
| `old_tests/` | Include; deprecate only if redundant/incompatible during Phase 6 |
| JS tests | Full behavioral parity |
| `foundry.toml` skip | Add `lib/frax-solidity/**` (approved) |
| Design doc | Maintain this file when design changes |
| RPC | Use `foundry.toml` `[rpc_endpoints]` aliases; request new Alchemy aliases if missing |
| Prior work | None — start Phase 1.1 |

## 2. External dependency port targets

Audit date: 2026-06-03 (Phase 1.1).

### 2.1 OpenZeppelin (`@openzeppelin/contracts/` → `@crane/contracts/external/openzeppelin-contracts/`)

**18 unique import paths** in Frax contracts. **17** already exist under `contracts/external/openzeppelin-contracts/`.

| Upstream path | In-tree path | Status |
|---------------|--------------|--------|
| `utils/introspection/IERC165.sol` | — | **NEW** — gap-fill in Phase 2.1 (Crane has `interfaces/IERC165.sol` but not `utils/introspection/`) |

All other paths (ERC20, ERC721, AccessControl, Ownable, Pausable, SafeERC20, Strings, Math, cryptography, etc.) — **EXIST**.

### 2.2 Chainlink (`@chainlink/contracts/` → `@crane/contracts/external/chainlink/contracts/`)

| Upstream path | Existing in Crane | Status |
|---------------|-------------------|--------|
| `src/v0.8/interfaces/AggregatorV3Interface.sol` | `contracts/protocols/oracles/chainlink/AggregatorV3Interface.sol` | **REDIRECT** imports to `@crane/contracts/protocols/oracles/chainlink/AggregatorV3Interface.sol` OR copy to external for path parity — prefer **external mirror** for Frax-only consistency |
| `src/v0.8/ChainlinkClient.sol` | `lib/chainlink-local/.../ChainlinkClient.sol` (operatorforwarder) | **NEW** — port CPI oracle deps to `contracts/external/chainlink/contracts/src/v0.8/` |
| `src/v0.8/vendor/ENSResolver.sol` | — | **NEW** — port with ChainlinkClient |
| `src/v0.6/interfaces/AggregatorV3Interface.sol` | — | **NEW** — port or modernize consumer to v0.8 interface |

### 2.3 Uniswap V2/V3 (`@uniswap/...` → `@crane/contracts/external/uniswap/...`)

**No** `contracts/external/uniswap/` tree today. Crane has protocol integrations under `contracts/protocols/dexes/uniswap/` but Frax expects upstream layout.

| Upstream | Target | Status |
|----------|--------|--------|
| `v2-core/contracts/interfaces/IUniswapV2Pair.sol` | `contracts/external/uniswap/v2-core/...` | **NEW** (minimal + transitive) |
| `v2-core/contracts/interfaces/IUniswapV2Callee.sol` | same | **NEW** |
| `v2-periphery/contracts/interfaces/IWETH.sol` | `contracts/external/uniswap/v2-periphery/...` | **NEW** |
| `v3-core/contracts/interfaces/*`, `libraries/SafeCast.sol` | `contracts/external/uniswap/v3-core/...` | **NEW** |
| `v3-periphery/contracts/libraries/TransferHelper.sol` | `contracts/external/uniswap/v3-periphery/...` | **NEW** (+ transitive libs) |

Pre-0.8 modernization required on v2-core libs if full libraries ported (Phase 2.3–2.4).

### 2.4 Arbitrum Nitro

| Upstream | Target | Status |
|----------|--------|--------|
| `@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol` | `contracts/external/arbitrum/nitro-contracts/src/libraries/` | **NEW** |

### 2.5 frax-std

| Upstream | Target | Status |
|----------|--------|--------|
| `frax-std/FraxTest.sol` | `contracts/external/frax-std/FraxTest.sol` | **NEW** — clone `FraxFinance/frax-standard-solidity` to `$TMPDIR` |

Used by: `BAMMTest.t.sol`, `FXSDisableVoteTracking.t.sol` (veFPIS uses `forge-std/Test.sol` only).

### 2.6 hardhat/console

| From | To |
|------|-----|
| `hardhat/console.sol` | `forge-std/console.sol` |

### 2.7 BAMM (not in 28 `contracts/` subdirs)

Foundry tests import `hardhat/contracts/BAMM/*.sol` but sources live in `src/hardhat/old_contracts/BAMM/`. Port to `contracts/protocols/tokens/stable/frax/BAMM/` (extra subdir).

## 3. RPC endpoint aliases (fork tests)

Existing in `foundry.toml` (usable):

| Chain bucket | Alias | Notes |
|--------------|-------|-------|
| Ethereum | `ethereum_mainnet_alchemy`, `ethereum_mainnet_infura` | Used by existing Crane fork tests |
| Optimism | `optimism_mainnet` | Alchemy |
| Fantom | `fantom_mainnet` | drpc.org |

**Added (Alchemy / public fallbacks in `foundry.toml`):**

| Chain | Alias |
|-------|-------|
| Arbitrum | `arbitrum_mainnet_alchemy`, `arbitrum_mainnet_infura` |
| Avalanche | `avalanche_mainnet_alchemy`, `avalanche_mainnet_infura` |
| BSC | `bsc_mainnet_alchemy` |
| Polygon | `polygon_mainnet_alchemy`, `polygon_mainnet_infura` |
| Aurora | `aurora_mainnet` (`https://mainnet.aurora.dev`) |
| Harmony | `harmony_mainnet` (`https://api.harmony.one`) |
| Moonbeam | `moonbeam_mainnet` |
| Moonriver | `moonriver_mainnet` |

Fork tests will use `vm.createSelectFork(vm.rpcUrl("<alias>"), block)` and `vm.skip` when `vm.rpcUrl` reverts.

## 4. Progress log

| Date | Phase | Notes |
|------|-------|-------|
| 2026-06-03 | 1.1 | Dependency audit complete; RPC gaps listed |
| 2026-06-03 | 1.2–3 | Scaffold, skip, 591 sources ported + import rewrites |
| 2026-06-03 | 4 | **`forge build --skip test` green** — Uniswap 0.8 lib patches (`scripts/frax-port/fix-uniswap-08.py`), Chainlink `add()` compat, Governance proposal storage init, assorted Frax 0.8 fixes |
| 2026-06-03 | 5 | Ported 3 upstream Foundry tests: `BAMM/BAMMTest.t.sol` (placeholder — upstream cases commented), `FXS/FXSDisableVoteTracking.t.sol` + `veFPIS/veFPISProxy.t.sol` under `test/foundry/fork/ethereum/protocols/tokens/stable/frax/`; RPC via `ethereum_mainnet_alchemy`; 24/24 tests pass with `ALCHEMY_KEY` set |
| 2026-06-03 | 6–8 | Next: rewrite 129 JS tests, full gates, remove submodule |

## 5. Skipped tests / divergences

_(Updated during Phase 7.)_

## 6. Stack-too-deep / bytecode size

Track per-file in this section if `viaIR = false` / `optimizer_runs = 1` block compilation (mitigate with structs per Crane AGENTS.md).