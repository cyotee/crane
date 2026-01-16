# Task CRANE-028: Add Price Impact Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-13
**Dependencies:** CRANE-007
**Worktree:** `test/price-impact-tests`
**Origin:** Code review suggestion from CRANE-007 (Suggestion 3)

---

## Description

Add explicit price impact percentage tests across various trade sizes. Currently there are no tests that verify price impact calculations behave correctly across different trade magnitudes.

(Created from code review of CRANE-007)

## Dependencies

- CRANE-007: Uniswap V2 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-028.1: Price Impact Test Coverage

As a developer, I want tests that verify price impact calculations so that I can ensure swap calculations account for slippage correctly across different trade sizes.

**Acceptance Criteria:**
- [x] Tests for small trades (< 1% of reserves) - minimal price impact
- [x] Tests for medium trades (1-10% of reserves) - moderate price impact
- [x] Tests for large trades (> 10% of reserves) - significant price impact
- [x] Tests verify price impact formula: `priceImpact = 1 - (effectivePrice / spotPrice)`
- [x] Fuzz tests across trade sizes and reserve ratios
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol`

**Reference Files:**
- `contracts/utils/math/ConstProdUtils.sol`
- `test/foundry/spec/utils/math/constProdUtils/` (existing test patterns)

## Inventory Check

Before starting, verify:
- [x] CRANE-007 is complete
- [x] ConstProdUtils.sol exists
- [x] Existing test patterns available for reference

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass (`forge test --match-path test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol`)
- [x] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
