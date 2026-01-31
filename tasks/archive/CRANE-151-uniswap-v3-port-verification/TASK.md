# Task CRANE-151: Port and Verify Uniswap V3 Core + Periphery

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** None
**Worktree:** `feature/uniswap-v3-port-verification`

---

## Description

Verify the Uniswap V3 core contracts (`lib/v3-core`) are completely ported to `contracts/protocols/dexes/uniswap/v3/` and port the V3 periphery contracts (`lib/v3-periphery`) into the same location. The ported contracts must be behavior and interface equivalent to serve as drop-in replacements, enabling eventual removal of both submodules.

## Goal

Enable removal of `lib/v3-core` and `lib/v3-periphery` submodules by having complete local ports with functional test suites.

## Source Analysis

### v3-core (Submodule: `lib/v3-core/contracts/`)

**Status: Appears fully ported (33 → 34 files)**

```
contracts/
├── UniswapV3Pool.sol          # Core pool
├── UniswapV3Factory.sol       # Pool factory
├── UniswapV3PoolDeployer.sol  # Deployer
├── NoDelegateCall.sol         # Delegate call guard
├── interfaces/
│   ├── IUniswapV3Pool.sol
│   ├── IUniswapV3Factory.sol
│   ├── IUniswapV3PoolDeployer.sol
│   ├── IERC20Minimal.sol
│   ├── callback/ (3 files)
│   └── pool/ (6 files)
└── libraries/ (16 files)
    ├── TickMath.sol, SqrtPriceMath.sol, SwapMath.sol
    ├── FullMath.sol, BitMath.sol, Oracle.sol
    ├── Tick.sol, TickBitmap.sol, Position.sol
    ├── LiquidityMath.sol, SafeCast.sol
    ├── FixedPoint96.sol, FixedPoint128.sol
    ├── LowGasSafeMath.sol, UnsafeMath.sol
    └── TransferHelper.sol
```

### v3-periphery (Submodule: `lib/v3-periphery/contracts/`)

**Status: NOT PORTED YET (52 files)**

```
contracts/
├── SwapRouter.sol
├── NonfungiblePositionManager.sol
├── NonfungibleTokenPositionDescriptor.sol
├── V3Migrator.sol
├── base/ (9 files)
│   ├── SelfPermit.sol, LiquidityManagement.sol
│   ├── PoolInitializer.sol, PeripheryImmutableState.sol
│   ├── PeripheryPayments.sol, PeripheryPaymentsWithFee.sol
│   ├── ERC721Permit.sol, Multicall.sol
│   ├── BlockTimestamp.sol, PeripheryValidation.sol
├── examples/
│   └── PairFlash.sol
├── interfaces/ (18 files)
│   ├── ISwapRouter.sol, INonfungiblePositionManager.sol
│   ├── IQuoter.sol, IQuoterV2.sol, ITickLens.sol
│   ├── ISelfPermit.sol, IV3Migrator.sol
│   └── external/ (IWETH9, IERC1271, IERC20PermitAllowed)
├── lens/ (4 files)
│   ├── Quoter.sol, QuoterV2.sol
│   ├── TickLens.sol, UniswapInterfaceMulticall.sol
└── libraries/ (12 files)
    ├── LiquidityAmounts.sol, PoolAddress.sol
    ├── Path.sol, CallbackValidation.sol
    ├── PositionKey.sol, PositionValue.sol
    ├── OracleLibrary.sol, TransferHelper.sol
    ├── NFTDescriptor.sol, NFTSVG.sol
    ├── HexStrings.sol, BytesLib.sol
    └── ChainId.sol, TokenRatioSortOrder.sol
```

### Local Port Location

**Target:** `contracts/protocols/dexes/uniswap/v3/`

Currently contains:
- All v3-core contracts (33 files, appears complete)
- `test/bases/TestBase_UniswapV3.sol` (Crane test base)
- No v3-periphery contracts

## Dependencies

None - this is a verification/completion task.

## User Stories

### US-CRANE-151.1: Verify v3-core Port

As a developer, I want to verify the v3-core port is complete and correct.

**Acceptance Criteria:**
- [ ] All 33 v3-core contracts present in local port
- [ ] All function signatures match original
- [ ] All events and errors match original
- [ ] Core pool contract behavior matches

### US-CRANE-151.2: Port v3-periphery Base Contracts

As a developer, I want periphery base contracts ported.

**Acceptance Criteria:**
- [ ] SelfPermit.sol ported
- [ ] LiquidityManagement.sol ported
- [ ] PoolInitializer.sol ported
- [ ] PeripheryImmutableState.sol ported
- [ ] PeripheryPayments.sol ported
- [ ] PeripheryPaymentsWithFee.sol ported
- [ ] ERC721Permit.sol ported
- [ ] Multicall.sol ported
- [ ] BlockTimestamp.sol ported
- [ ] PeripheryValidation.sol ported

### US-CRANE-151.3: Port SwapRouter

As a developer, I want SwapRouter ported for local swap testing.

**Acceptance Criteria:**
- [ ] SwapRouter.sol ported
- [ ] ISwapRouter.sol interface ported
- [ ] All swap functions work identically to original

### US-CRANE-151.4: Port NonfungiblePositionManager

As a developer, I want NFT position manager ported.

**Acceptance Criteria:**
- [ ] NonfungiblePositionManager.sol ported
- [ ] INonfungiblePositionManager.sol ported
- [ ] Position minting/burning works

### US-CRANE-151.5: Port Lens Contracts

As a developer, I want Quoter and TickLens ported for price queries.

**Acceptance Criteria:**
- [ ] Quoter.sol ported
- [ ] QuoterV2.sol ported
- [ ] TickLens.sol ported
- [ ] UniswapInterfaceMulticall.sol ported

### US-CRANE-151.6: Port Periphery Libraries

As a developer, I want all periphery libraries available locally.

**Acceptance Criteria:**
- [ ] LiquidityAmounts.sol ported
- [ ] PoolAddress.sol ported
- [ ] Path.sol ported
- [ ] CallbackValidation.sol ported
- [ ] OracleLibrary.sol ported
- [ ] PositionKey.sol ported
- [ ] PositionValue.sol ported
- [ ] TransferHelper.sol ported
- [ ] NFT rendering libraries ported (NFTDescriptor, NFTSVG, HexStrings)
- [ ] BytesLib.sol ported

### US-CRANE-151.7: Port Periphery Interfaces

As a developer, I want all periphery interfaces available.

**Acceptance Criteria:**
- [ ] All 18 interface files ported
- [ ] Function signatures match original
- [ ] Events match original

### US-CRANE-151.8: Test Suite Adaptation

As a developer, I want comprehensive tests for the ported contracts.

**Acceptance Criteria:**
- [ ] Fork/adapt Uniswap V3 core test suite
- [ ] Fork/adapt Uniswap V3 periphery test suite
- [ ] All critical path tests pass
- [ ] Integration between core and periphery verified

## Technical Details

### File Structure After Port

```
contracts/protocols/dexes/uniswap/v3/
├── # ─── v3-core (already ported) ───
├── UniswapV3Pool.sol
├── UniswapV3Factory.sol
├── UniswapV3PoolDeployer.sol
├── NoDelegateCall.sol
├── interfaces/
│   ├── IUniswapV3Pool.sol
│   ├── IUniswapV3Factory.sol
│   ├── IUniswapV3PoolDeployer.sol
│   ├── IERC20Minimal.sol
│   ├── callback/
│   └── pool/
├── libraries/
│   ├── (16 core libraries)
│   └── (12 periphery libraries)
├── # ─── v3-periphery (to port) ───
├── periphery/
│   ├── SwapRouter.sol
│   ├── NonfungiblePositionManager.sol
│   ├── NonfungibleTokenPositionDescriptor.sol
│   ├── V3Migrator.sol
│   ├── base/
│   ├── lens/
│   └── examples/
├── periphery-interfaces/
│   ├── ISwapRouter.sol
│   ├── INonfungiblePositionManager.sol
│   └── ... (18 files)
└── test/
    └── bases/TestBase_UniswapV3.sol
```

**Note:** The periphery directory structure may be flattened or reorganized to match Crane conventions as long as imports resolve correctly.

### Import Remapping

Periphery contracts import from core using `@uniswap/v3-core/contracts/...`. These must be remapped to the local core port path.

### Key Considerations

1. **Solidity Version:** v3-core and v3-periphery use Solidity 0.7.x. Verify Crane's compiler settings support this or port to 0.8.x with appropriate unchecked blocks.
2. **WETH9 dependency:** Periphery depends on IWETH9 - ensure this interface is available.
3. **Permit2 dependency:** SelfPermit may reference Permit2 - coordinate with CRANE-150 port.

## Files to Create/Modify

**Verify/Existing:**
- `contracts/protocols/dexes/uniswap/v3/*.sol` - 33 core files

**New Files:**
- `contracts/protocols/dexes/uniswap/v3/periphery/*.sol` - ~35 periphery files
- `contracts/protocols/dexes/uniswap/v3/periphery/interfaces/*.sol` - 18 interfaces
- `test/foundry/protocols/uniswap/v3/*.t.sol` - Adapted test suite

## Completion Criteria

- [ ] All v3-core contracts verified as behavior equivalent
- [ ] All v3-periphery contracts ported
- [ ] All interfaces available (core + periphery)
- [ ] Import paths remapped to local contracts
- [ ] Adapted test suite passes
- [ ] Both submodules can be safely removed

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
