# Progress Log: CRANE-163

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Code review
**Build status:** PASS (forge build succeeds, warnings are pre-existing)
**Test status:** PASS (32/32 router diamond tests pass)

---

## Session Log

### 2026-02-08 - Implementation Complete

**Change:** Modified `_takeTokenIn()` in `BalancerV3RouterModifiers.sol` (lines 215-239)

**Problem:** `_takeTokenIn()` unconditionally called `permit2.transferFrom()` for non-WETH tokens. In prepaid mode (`permit2 == address(0)`), this reverts, breaking:
- `BufferRouterFacet.initializeBufferHook`
- `BufferRouterFacet.addLiquidityToBufferHook`
- `CompositeLiquidityERC4626Facet._processTokenInExactIn`
- `CompositeLiquidityERC4626Facet._processTokenInExactOut`

**Fix:** Added `_isPrepaid()` check inside `_takeTokenIn()`:
- **Prepaid mode:** Calls `vault.settle(tokenIn, amountIn)` directly (tokens pre-transferred to vault)
- **Retail mode:** Original behavior preserved (Permit2 transfer then settle)
- WETH/ETH wrapping path unchanged (not affected by prepaid mode)

**Why this approach:**
- Single-point fix in the base utility function, rather than modifying each caller
- Follows established pattern from `RouterAddLiquidityFacet._processTokensIn` (line 321)
- All affected facets (BufferRouterFacet, CompositeLiquidityERC4626Facet) call `_takeTokenIn` and are automatically fixed

**Files modified:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterModifiers.sol`

**Verification:**
- `forge build` succeeds (only pre-existing warnings)
- 32/32 router diamond tests pass

### 2026-01-29 - Task Created

- Task created from code review finding 3
- Origin: CRANE-142 REVIEW.md Finding 3
- Ready for agent assignment via /backlog:launch
