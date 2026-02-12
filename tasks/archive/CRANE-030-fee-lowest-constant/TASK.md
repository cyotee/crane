# Task CRANE-030: Add FEE_LOWEST Constant to TestBase

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-008
**Worktree:** `fix/fee-lowest-constant`
**Origin:** Code review suggestion from CRANE-008 (Suggestion 1)

---

## Description

Add `FEE_LOWEST = 100` (0.01%, tick spacing 1) to TestBase_UniswapV3.sol for completeness. This would enable testing the lowest fee tier pools.

(Created from code review of CRANE-008)

## Dependencies

- CRANE-008: Uniswap V3 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-030.1: Add 0.01% Fee Tier Constants

As a developer, I want the TestBase to include the 0.01% fee tier constant so that I can write tests for pools with the lowest fee tier.

**Acceptance Criteria:**
- [ ] Add `FEE_LOWEST = 100` constant
- [ ] Add `TICK_SPACING_LOWEST = 1` constant
- [ ] Constants are correctly placed alongside FEE_LOW, FEE_MEDIUM, FEE_HIGH
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/uniswap/v3/test/bases/TestBase_UniswapV3.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-008 is complete
- [x] TestBase_UniswapV3.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
