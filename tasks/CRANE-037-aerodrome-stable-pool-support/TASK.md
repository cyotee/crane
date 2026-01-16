# Task CRANE-037: Add Aerodrome Stable Pool Support

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Updated:** 2026-01-15
**Dependencies:** CRANE-010
**Worktree:** `feature/aerodrome-stable-pool`
**Origin:** Code review suggestion from CRANE-010 (Suggestion 1)

---

## Description

Split `AerodromService` into separate volatile and stable pool libraries. This gives developers the flexibility to include only the pool type they need, without conditional flow control. Developers who want both can import both libraries.

Current `AerodromService.sol` hardcodes `stable: false`. Rather than adding a `stable` parameter (which forces all consumers to handle both cases), we create:

- `AerodromServiceVolatile.sol` - Volatile pools only (`xy = k` curve)
- `AerodromServiceStable.sol` - Stable pools only (`x³y + xy³ = k` curve)

The existing `AerodromService.sol` will be deprecated with a notice pointing to the new libraries.

(Created from code review of CRANE-010, refined via /design:design on 2026-01-15)

## Dependencies

- CRANE-010: Aerodrome V1 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-037.1: Volatile Pool Library

As a developer who only needs volatile pools, I want a dedicated volatile pool library so that I don't need to include stable pool code or manage conditional flow control.

**Acceptance Criteria:**
- [ ] `AerodromServiceVolatile.sol` contains all volatile-only functions
- [ ] Functions: `_swapVolatile`, `_swapDepositVolatile`, `_withdrawSwapVolatile`, `_quoteSwapDepositSaleAmtVolatile`
- [ ] All functions explicitly pass `stable: false` to router/factory calls
- [ ] Uses `ConstProdUtils` for volatile pool math (`xy = k`)
- [ ] Existing volatile pool tests pass with the new library

### US-CRANE-037.2: Stable Pool Library

As a developer who only needs stable pools, I want a dedicated stable pool library so that I don't need to include volatile pool code.

**Acceptance Criteria:**
- [ ] `AerodromServiceStable.sol` contains all stable-only functions
- [ ] Functions: `_swapStable`, `_swapDepositStable`, `_withdrawSwapStable`, `_quoteSwapDepositSaleAmtStable`
- [ ] All functions explicitly pass `stable: true` to router/factory calls
- [ ] Implements stable pool curve math (`x³y + xy³ = k`) for quoting
- [ ] New tests for stable pool swaps

### US-CRANE-037.3: Deprecate Original Library

As a developer, I want clear guidance on migrating from the old library so that I know which new library to use.

**Acceptance Criteria:**
- [ ] `AerodromService.sol` marked as deprecated with NatSpec comment
- [ ] Deprecation notice references `AerodromServiceVolatile` and `AerodromServiceStable`
- [ ] Old tests updated to use new volatile library (since old library was volatile-only)

## Technical Details

### File Structure

```
contracts/protocols/dexes/aerodrome/v1/services/
├── AerodromService.sol           # DEPRECATED - points to new libraries
├── AerodromServiceVolatile.sol   # NEW - volatile pools only
└── AerodromServiceStable.sol     # NEW - stable pools only
```

### Stable Pool Math

Stable pools use the `x³y + xy³ = k` curve. The swap output calculation differs from volatile pools. Reference the Aerodrome Pool.sol stub for the exact formula.

Key differences from volatile:
- `getAmountOut` uses `_k()` invariant calculation
- Fee handling may differ between pool types
- Price impact characteristics are different

### Struct Design

Each library should have its own param structs. They may be identical but keeping them separate allows future divergence:

```solidity
// In AerodromServiceVolatile.sol
struct SwapVolatileParams { ... }
struct SwapDepositVolatileParams { ... }
struct WithdrawSwapVolatileParams { ... }

// In AerodromServiceStable.sol
struct SwapStableParams { ... }
struct SwapDepositStableParams { ... }
struct WithdrawSwapStableParams { ... }
```

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceVolatile.sol`
- `contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol`
- `test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.t.sol`

**Modified Files:**
- `contracts/protocols/dexes/aerodrome/v1/services/AerodromService.sol` (add deprecation notice)
- `test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromService.t.sol` (update to use volatile library)

**Reference Files:**
- `contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol` (stable pool math)
- `contracts/utils/math/ConstProdUtils.sol` (volatile pool math)

## Inventory Check

Before starting, verify:
- [x] CRANE-010 is complete
- [x] AerodromService.sol exists
- [x] Pool.sol stub exists with stable pool implementation
- [ ] Understand stable pool `_k()` formula from Pool.sol

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test --match-path test/foundry/spec/protocols/dexes/aerodrome/`)
- [ ] Build succeeds (`forge build`)
- [ ] No regressions in existing volatile pool functionality

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
