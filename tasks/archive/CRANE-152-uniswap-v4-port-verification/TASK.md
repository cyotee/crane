# Task CRANE-152: Port and Verify Uniswap V4 Core + Periphery

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** None
**Worktree:** `feature/uniswap-v4-port-verification`

---

## Description

Port and verify Uniswap V4 contracts from `lib/v4-core/src/` and `lib/v4-periphery/src/` into `contracts/protocols/dexes/uniswap/v4/`. A partial port exists (18 of 109 files) covering some core libraries, types, and interfaces. The remaining core contracts (PoolManager, ERC6909, etc.) and the entire periphery (PositionManager, V4Router, hooks, lens, etc.) must be ported. All contracts must be behavior and interface equivalent as drop-in replacements, verified via adapted test suite.

## Goal

Enable removal of `lib/v4-core` and `lib/v4-periphery` submodules by completing the local port.

## Source Analysis

### v4-core (Submodule: `lib/v4-core/src/`) — 45 files

```
src/
├── PoolManager.sol            # Central pool manager (singleton)
├── ProtocolFees.sol           # Protocol fee controller
├── ERC6909.sol                # Multi-token standard
├── ERC6909Claims.sol          # Claims extension
├── Extsload.sol               # External storage reads
├── Exttload.sol               # External transient reads
├── NoDelegateCall.sol         # Delegate call guard
├── interfaces/ (10 files)
│   ├── IPoolManager.sol
│   ├── IProtocolFees.sol
│   ├── IHooks.sol
│   ├── IExtsload.sol, IExttload.sol
│   ├── callback/IUnlockCallback.sol
│   └── external/IERC20Minimal.sol, IERC6909Claims.sol
├── libraries/ (24 files)
│   ├── Pool.sol, Hooks.sol, StateLibrary.sol
│   ├── TickMath.sol, SqrtPriceMath.sol, SwapMath.sol
│   ├── FullMath.sol, BitMath.sol, SafeCast.sol
│   ├── TickBitmap.sol, Position.sol, LiquidityMath.sol
│   ├── FixedPoint96.sol, FixedPoint128.sol, UnsafeMath.sol
│   ├── CurrencyDelta.sol, CurrencyReserves.sol
│   ├── Lock.sol, NonzeroDeltaCount.sol
│   ├── LPFeeLibrary.sol, ProtocolFeeLibrary.sol
│   ├── CustomRevert.sol, ParseBytes.sol
│   └── TransientStateLibrary.sol
└── types/ (6 files)
    ├── BalanceDelta.sol, BeforeSwapDelta.sol
    ├── Currency.sol, PoolId.sol
    ├── PoolKey.sol, Slot0.sol
```

### v4-periphery (Submodule: `lib/v4-periphery/src/`) — 64 files

```
src/
├── PositionManager.sol        # NFT position manager
├── PositionDescriptor.sol     # NFT metadata
├── V4Router.sol               # Swap router
├── UniswapV4DeployerCompetition.sol
├── base/ (15 files)
│   ├── BaseActionsRouter.sol, BaseV4Quoter.sol
│   ├── DeltaResolver.sol, SafeCallback.sol
│   ├── ImmutableState.sol, NativeWrapper.sol
│   ├── Notifier.sol, Permit2Forwarder.sol
│   ├── ReentrancyLock.sol, UnorderedNonce.sol
│   ├── PoolInitializer_v4.sol
│   ├── EIP712_v4.sol, ERC721Permit_v4.sol
│   ├── Multicall_v4.sol
│   └── hooks/BaseTokenWrapperHook.sol
├── hooks/ (3 files)
│   ├── WETHHook.sol, WstETHHook.sol
│   └── WstETHRoutingHook.sol
├── interfaces/ (18 files)
│   ├── IPositionManager.sol, IPositionDescriptor.sol
│   ├── IV4Router.sol, IV4Quoter.sol
│   ├── IStateView.sol, ISubscriber.sol
│   ├── INotifier.sol, IPermit2Forwarder.sol
│   ├── IImmutableState.sol, IMsgSender.sol
│   ├── IMulticall_v4.sol, IUnorderedNonce.sol
│   ├── IEIP712_v4.sol, IERC721Permit_v4.sol
│   ├── IPoolInitializer_v4.sol
│   ├── IUniswapV4DeployerCompetition.sol
│   └── external/IWETH9.sol, IWstETH.sol
├── lens/ (2 files)
│   ├── StateView.sol, V4Quoter.sol
├── libraries/ (19 files)
│   ├── Actions.sol, ActionConstants.sol
│   ├── CalldataDecoder.sol, PathKey.sol
│   ├── LiquidityAmounts.sol, SlippageCheck.sol
│   ├── PositionConfig.sol, PositionConfigId.sol
│   ├── PositionInfoLibrary.sol
│   ├── QuoterRevert.sol, Locker.sol
│   ├── BipsLibrary.sol, ERC721PermitHash.sol
│   ├── SafeCurrencyMetadata.sol, VanityAddressLib.sol
│   ├── Descriptor.sol, SVG.sol
│   ├── HexStrings.sol, AddressStringUtil.sol
│   └── CurrencyRatioSortOrder.sol
└── utils/ (2 files)
    ├── BaseHook.sol, HookMiner.sol
```

### Local Port (Current: 18 files)

```
contracts/protocols/dexes/uniswap/v4/
├── interfaces/
│   ├── IHooks.sol
│   └── IPoolManager.sol
├── libraries/
│   ├── BitMath.sol, FixedPoint96.sol, FullMath.sol
│   ├── LiquidityMath.sol, SafeCast.sol
│   ├── SqrtPriceMath.sol, SwapMath.sol
│   ├── TickMath.sol, UnsafeMath.sol
├── types/
│   ├── Currency.sol, PoolId.sol
│   ├── PoolKey.sol, Slot0.sol
└── utils/
    ├── UniswapV4Quoter.sol
    ├── UniswapV4Utils.sol
    └── UniswapV4ZapQuoter.sol
```

### Gap Analysis

**v4-core: 27 of 45 files missing**
- PoolManager.sol, ProtocolFees.sol (main contracts)
- ERC6909.sol, ERC6909Claims.sol, Extsload.sol, Exttload.sol, NoDelegateCall.sol
- 8 interfaces (IProtocolFees, IExtsload, IExttload, IUnlockCallback, IERC20Minimal, IERC6909Claims)
- 14 libraries (Pool, Hooks, StateLibrary, CurrencyDelta, CurrencyReserves, Lock, NonzeroDeltaCount, LPFeeLibrary, ProtocolFeeLibrary, CustomRevert, ParseBytes, TransientStateLibrary, FixedPoint128, TickBitmap, Position)
- 2 types (BalanceDelta, BeforeSwapDelta)

**v4-periphery: ~61 of 64 files missing**
- 3 Crane-specific utils exist (UniswapV4Quoter, UniswapV4Utils, UniswapV4ZapQuoter) — review for equivalence
- All periphery contracts, base, hooks, interfaces, lens, and libraries need porting

## Dependencies

None — this is a verification/completion task.

**Related tasks:**
- CRANE-150 (Permit2 port) — v4-periphery uses Permit2 via Permit2Forwarder

## User Stories

### US-CRANE-152.1: Complete v4-core Contract Port

As a developer, I want all v4-core contracts available locally.

**Acceptance Criteria:**
- [ ] PoolManager.sol ported
- [ ] ProtocolFees.sol ported
- [ ] ERC6909.sol and ERC6909Claims.sol ported
- [ ] Extsload.sol and Exttload.sol ported
- [ ] NoDelegateCall.sol ported
- [ ] All function signatures match original

### US-CRANE-152.2: Complete v4-core Interfaces

As a developer, I want all v4-core interfaces available.

**Acceptance Criteria:**
- [ ] IProtocolFees.sol ported
- [ ] IExtsload.sol and IExttload.sol ported
- [ ] IUnlockCallback.sol ported
- [ ] IERC20Minimal.sol and IERC6909Claims.sol ported
- [ ] IHooks.sol and IPoolManager.sol verified (already ported)

### US-CRANE-152.3: Complete v4-core Libraries

As a developer, I want all v4-core libraries available.

**Acceptance Criteria:**
- [ ] Pool.sol, Hooks.sol, StateLibrary.sol ported
- [ ] CurrencyDelta.sol, CurrencyReserves.sol ported
- [ ] Lock.sol, NonzeroDeltaCount.sol ported
- [ ] LPFeeLibrary.sol, ProtocolFeeLibrary.sol ported
- [ ] CustomRevert.sol, ParseBytes.sol ported
- [ ] TransientStateLibrary.sol ported
- [ ] FixedPoint128.sol, TickBitmap.sol, Position.sol ported
- [ ] Already-ported libraries verified

### US-CRANE-152.4: Complete v4-core Types

As a developer, I want all v4-core type definitions available.

**Acceptance Criteria:**
- [ ] BalanceDelta.sol ported
- [ ] BeforeSwapDelta.sol ported
- [ ] Already-ported types verified (Currency, PoolId, PoolKey, Slot0)

### US-CRANE-152.5: Port v4-periphery Core Contracts

As a developer, I want periphery core contracts ported.

**Acceptance Criteria:**
- [ ] PositionManager.sol ported
- [ ] PositionDescriptor.sol ported
- [ ] V4Router.sol ported
- [ ] UniswapV4DeployerCompetition.sol ported

### US-CRANE-152.6: Port v4-periphery Base Contracts

As a developer, I want periphery base contracts ported.

**Acceptance Criteria:**
- [ ] All 15 base contracts ported
- [ ] BaseActionsRouter.sol, DeltaResolver.sol, SafeCallback.sol
- [ ] Permit2Forwarder.sol, ImmutableState.sol, NativeWrapper.sol
- [ ] EIP712_v4.sol, ERC721Permit_v4.sol, Multicall_v4.sol
- [ ] BaseTokenWrapperHook.sol

### US-CRANE-152.7: Port v4-periphery Hooks

As a developer, I want periphery hook contracts ported.

**Acceptance Criteria:**
- [ ] WETHHook.sol ported
- [ ] WstETHHook.sol ported
- [ ] WstETHRoutingHook.sol ported

### US-CRANE-152.8: Port v4-periphery Interfaces

As a developer, I want all periphery interfaces available.

**Acceptance Criteria:**
- [ ] All 18 interface files ported
- [ ] Function signatures match original

### US-CRANE-152.9: Port v4-periphery Lens + Libraries

As a developer, I want lens and library contracts ported.

**Acceptance Criteria:**
- [ ] StateView.sol and V4Quoter.sol ported
- [ ] All 19 library files ported
- [ ] BaseHook.sol and HookMiner.sol ported (utils)

### US-CRANE-152.10: Review Crane Additions

As a developer, I want Crane-specific V4 utilities reviewed.

**Acceptance Criteria:**
- [ ] UniswapV4Quoter.sol reviewed for equivalence/purpose
- [ ] UniswapV4Utils.sol reviewed
- [ ] UniswapV4ZapQuoter.sol reviewed
- [ ] Documented as Crane-specific additions

### US-CRANE-152.11: Test Suite Adaptation

As a developer, I want comprehensive tests for all ported contracts.

**Acceptance Criteria:**
- [ ] Fork/adapt Uniswap V4 core test suite
- [ ] Fork/adapt Uniswap V4 periphery test suite
- [ ] All critical path tests pass
- [ ] Integration between core and periphery verified

## Technical Details

### Key Considerations

1. **Transient Storage (EIP-1153):** V4 uses `TSTORE`/`TLOAD` extensively (Lock, CurrencyDelta, NonzeroDeltaCount, TransientStateLibrary). Target chains must be post-Cancun.
2. **Permit2 Dependency:** Periphery's Permit2Forwarder imports Permit2 — coordinate with CRANE-150.
3. **WETH9/WstETH:** Hook contracts depend on WETH9/WstETH interfaces.
4. **Solidity 0.8.x:** V4 uses 0.8.x natively — no version migration needed.
5. **Singleton Architecture:** V4 uses a single PoolManager, not individual pool contracts. The port must preserve this pattern.
6. **Flash Accounting:** V4's unlock/callback pattern with delta tracking is critical to preserve exactly.

### File Structure After Port

```
contracts/protocols/dexes/uniswap/v4/
├── # ─── v4-core ───
├── PoolManager.sol
├── ProtocolFees.sol
├── ERC6909.sol, ERC6909Claims.sol
├── Extsload.sol, Exttload.sol
├── NoDelegateCall.sol
├── interfaces/ (10 core + 18 periphery)
├── libraries/ (24 core + 19 periphery)
├── types/ (6 files)
├── # ─── v4-periphery ───
├── periphery/
│   ├── PositionManager.sol
│   ├── V4Router.sol
│   ├── PositionDescriptor.sol
│   ├── base/ (15 files)
│   ├── hooks/ (3 files)
│   └── lens/ (2 files)
├── # ─── Crane additions ───
└── utils/
    ├── UniswapV4Quoter.sol
    ├── UniswapV4Utils.sol
    ├── UniswapV4ZapQuoter.sol
    └── BaseHook.sol, HookMiner.sol
```

## Files to Create/Modify

**Verify (18 existing):**
- Existing libraries, interfaces, types, and utils

**Port (~91 new files):**
- v4-core: ~27 files (contracts, interfaces, libraries, types)
- v4-periphery: ~64 files (contracts, base, hooks, interfaces, lens, libraries, utils)

**Tests:**
- `test/foundry/protocols/uniswap/v4/*.t.sol`

## Completion Criteria

- [ ] All v4-core contracts ported and verified (45 files)
- [ ] All v4-periphery contracts ported and verified (64 files)
- [ ] Crane additions reviewed and documented
- [ ] Import paths use local contracts only
- [ ] Adapted test suite passes
- [ ] Both submodules can be safely removed

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
