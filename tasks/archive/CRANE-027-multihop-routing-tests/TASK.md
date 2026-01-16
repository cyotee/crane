# Task CRANE-027: Add Multi-hop Routing Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-007
**Worktree:** `test/multihop-routing-tests`
**Origin:** Code review suggestion from CRANE-007 (Suggestion 2)

---

## Description

Add test coverage for multi-hop routing scenarios in ConstProdUtils. Currently there are no tests for chained `getAmountsOut`/`getAmountsIn` calculations across multiple pools.

(Created from code review of CRANE-007)

## Dependencies

- CRANE-007: Uniswap V2 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-027.1: Multi-hop Route Calculation Tests

As a developer, I want comprehensive tests for multi-hop routing calculations so that I can be confident the chained swap logic is correct.

**Acceptance Criteria:**
- [ ] Tests for 2-hop routes (A -> B -> C)
- [ ] Tests for 3-hop routes (A -> B -> C -> D)
- [ ] Tests verify intermediate amounts match expected values
- [ ] Fuzz tests for varying pool reserves and amounts
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_multihop.t.sol`

**Reference Files:**
- `contracts/utils/math/ConstProdUtils.sol`
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_purchaseQuote_Camelot.t.sol` (example pattern)

## Inventory Check

Before starting, verify:
- [x] CRANE-007 is complete
- [x] ConstProdUtils.sol exists
- [x] Existing test patterns available for reference

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test --match-path test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_multihop.t.sol`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
