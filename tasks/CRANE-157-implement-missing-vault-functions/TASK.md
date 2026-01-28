# Task CRANE-157: Implement Missing Balancer V3 Vault Interface Functions

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** CRANE-141
**Worktree:** `feature/implement-missing-vault-functions`
**Origin:** Code review suggestion from CRANE-141

---

## Description

Implement the missing interface functions required for 100% Balancer V3 interface compatibility. The CRANE-141 review identified multiple functions from `IVaultMain`, `IVaultExtension`, and `IVaultAdmin` that are not implemented or have mismatched signatures.

(Created from code review of CRANE-141 - Suggestion 3)

## Dependencies

- CRANE-141: Refactor Balancer V3 Vault as Diamond Facets (parent task)

## User Stories

### US-CRANE-157.1: Implement IVaultMain Missing Functions

As a developer, I want all IVaultMain functions implemented so that the Diamond is fully compatible.

**Acceptance Criteria:**
- [ ] `getVaultExtension()` returns `address(this)` (Diamond architecture)
- [ ] All other IVaultMain functions either implemented or stubbed with correct signatures

### US-CRANE-157.2: Implement IVaultExtension Missing Functions

As a developer, I want all IVaultExtension functions implemented so that queries and reads work correctly.

**Acceptance Criteria:**
- [ ] `getVaultAdmin()` returns `address(this)` (Diamond architecture)
- [ ] Transient accounting reads implemented:
  - `getNonzeroDeltaCount()` - read from transient storage
  - `getTokenDelta(IERC20)` - read from transient storage
  - `getAddLiquidityCalledFlag(address)` - read from transient storage
- [ ] Pool info reads implemented:
  - `getHooksConfig(address)` - match interface signature (not `getHooksContract`)
  - `getBptRate(address)` - return BPT rate for pool
  - `getPoolPausedState(address)` - expose existing internal helper
- [ ] Query entrypoints implemented:
  - `quote(bytes)` - staticcall-only semantics
  - `quoteAndRevert(bytes)` - staticcall-only semantics
- [ ] `emitAuxiliaryEvent(bytes32,bytes)` implemented
- [ ] ERC4626 buffer reads implemented:
  - `isERC4626BufferInitialized(IERC4626)`
  - `getERC4626BufferAsset(IERC4626)`
- [ ] Fee reads match interface signatures:
  - `getAggregateSwapFeeAmount(address,IERC20)` - separate function
  - `getAggregateYieldFeeAmount(address,IERC20)` - separate function

### US-CRANE-157.3: Implement IVaultAdmin Missing Functions

As a developer, I want all IVaultAdmin functions implemented so that admin operations work correctly.

**Acceptance Criteria:**
- [ ] `getPauseWindowEndTime()` - fix name to match interface (not `getVaultPauseWindowEndTime`)
- [ ] `getMinimumPoolTokens()` - return constant
- [ ] `getMaximumPoolTokens()` - return constant
- [ ] `getPoolMinimumTotalSupply()` - return constant
- [ ] `getBufferMinimumTotalSupply()` - return constant

## Technical Details

### Missing Functions by Facet

**VaultQueryFacet additions:**
- `getVaultExtension()` → `address(this)`
- `getVaultAdmin()` → `address(this)`
- `getNonzeroDeltaCount()`
- `getTokenDelta(IERC20)`
- `getAddLiquidityCalledFlag(address)`
- `getHooksConfig(address)` (rename from `getHooksContract`)
- `getBptRate(address)`
- `getPoolPausedState(address)`
- `isERC4626BufferInitialized(IERC4626)`
- `getERC4626BufferAsset(IERC4626)`
- Split `getAggregateSwapAndYieldFeeAmounts` into two functions

**New VaultQueryEntryFacet (or add to VaultQueryFacet):**
- `quote(bytes)`
- `quoteAndRevert(bytes)`

**VaultAdminFacet additions:**
- Rename `getVaultPauseWindowEndTime()` → `getPauseWindowEndTime()`
- `getMinimumPoolTokens()` → constant (e.g., 2)
- `getMaximumPoolTokens()` → constant (e.g., 8)
- `getPoolMinimumTotalSupply()` → constant (e.g., 1e6)
- `getBufferMinimumTotalSupply()` → constant (e.g., 1e4)

**VaultTransientFacet or new facet:**
- `emitAuxiliaryEvent(bytes32,bytes)`

### Transient Storage Reads

The transient accounting functions need to read from the BalancerV3VaultStorageRepo transient slots:
```solidity
function getNonzeroDeltaCount() external view returns (uint256) {
    return BalancerV3VaultStorageRepo._getNonzeroDeltaCount();
}
```

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol` - Add missing query functions
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultAdminFacet.sol` - Add missing admin functions, fix naming
- `contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultStorageRepo.sol` - Add transient read helpers if needed

**New Files (if needed):**
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultAuxiliaryFacet.sol` - For misc functions

**Tests:**
- Update `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDiamond.t.sol`

## Inventory Check

Before starting, verify:
- [ ] Current facet implementations exist
- [ ] Balancer interface files are accessible for reference
- [ ] BalancerV3VaultStorageRepo has transient storage slots

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All IVaultMain functions callable via Diamond
- [ ] All IVaultExtension functions callable via Diamond
- [ ] All IVaultAdmin functions callable via Diamond
- [ ] Function signatures match Balancer interfaces exactly
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
