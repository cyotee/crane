# Task CRANE-021: Fix ERC5267Facet Array Size Bug

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-005
**Worktree:** `fix/erc5267-array-size`
**Origin:** Code review suggestion from CRANE-005

---

## Description

`ERC5267Facet.facetInterfaces()` allocates an array of size 2 but only populates index 0, leaving index 1 as `bytes4(0)`. This could cause issues with Diamond facet introspection.

(Created from code review of CRANE-005)

## Dependencies

- CRANE-005: Token Standards Review (parent task - Complete)

## User Stories

### US-CRANE-021.1: Fix Array Allocation

As a developer using Diamond introspection, I want `facetInterfaces()` to return correctly-sized arrays so that interface enumeration works correctly.

**Acceptance Criteria:**
- [ ] Array allocation changed from size 2 to size 1
- [ ] Only IERC5267 interface ID is returned
- [ ] Tests pass

## Technical Details

**Current Code (contracts/utils/cryptography/ERC5267/ERC5267Facet.sol:40-43):**
```solidity
interfaces = new bytes4[](2);  // BUG: allocates 2 slots
interfaces[0] = type(IERC5267).interfaceId;
// interfaces[1] never assigned, remains bytes4(0)
```

**Fix:**
```solidity
interfaces = new bytes4[](1);  // FIXED: allocates 1 slot
interfaces[0] = type(IERC5267).interfaceId;
```

## Files to Create/Modify

**Modified Files:**
- `contracts/utils/cryptography/ERC5267/ERC5267Facet.sol` (line 40)

## Inventory Check

Before starting, verify:
- [x] CRANE-005 is complete
- [ ] `contracts/utils/cryptography/ERC5267/ERC5267Facet.sol` exists

## Completion Criteria

- [ ] Array size changed to 1
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
