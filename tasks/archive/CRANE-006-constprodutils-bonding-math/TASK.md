# Task CRANE-006: Review — Constant Product & Bonding Math Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-constprodutils-and-bonding-math`

---

## Description

Review Crane's constant-product and bonding math utilities (especially `contracts/utils/math/ConstProdUtils.sol`) for rounding correctness, overflow safety, invariant preservation, and adequate test coverage.

This task exists as a prerequisite for downstream protocol components (e.g., bonding/exchange flows) that rely on these math primitives.

## Dependencies

- None

## User Stories

### US-CRANE-006.1: Produce a Math Correctness Memo

As a maintainer, I want a memo describing the math invariants and edge cases so that downstream protocol logic can rely on these utilities.

**Acceptance Criteria:**
- [ ] Memo lists key invariants, rounding modes, and overflow/underflow assumptions
- [ ] Memo identifies any surprising behaviors (e.g., boundary conditions at 0/1 reserves)

### US-CRANE-006.2: Add at Least One High-Signal Test

As a maintainer, I want at least one concrete test improvement around math edge cases so that regressions are caught.

**Acceptance Criteria:**
- [ ] Add/strengthen at least one unit/spec/fuzz test that covers a boundary or adversarial case
- [ ] `forge test` passes

## Technical Details

Focus areas:

**Constant Product Math:**
- `x * y = k` invariant preservation
- Quote calculations (getAmountOut, getAmountIn)
- Fee integration (997/1000 factor)
- Rounding direction (favor protocol vs user)

**Boundary Conditions:**
- Zero reserves
- Single-wei reserves
- Maximum uint256 values
- Dust amounts

**Precision:**
- Fixed-point arithmetic if used
- Scaling factors
- Cumulative error in multi-hop scenarios

## Files to Create/Modify

**New Files:**
- `docs/review/constprodutils-and-bonding-math.md` - Review memo

**Potentially Modified Files:**
- `test/foundry/**` - Add/strengthen tests

**Tests:**
- Add at least one boundary/adversarial test case

## Inventory Check

Before starting, verify:
- [ ] Identify all public entrypoints/consumers of `ConstProdUtils`
- [ ] Identify any assumptions about fee units, precision, or scaling factors
- [ ] Review existing tests in `test/foundry/spec/utils/math/constProdUtils/`

## Completion Criteria

- [ ] Memo exists at `docs/review/constprodutils-and-bonding-math.md`
- [ ] At least one meaningful test improvement included
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
