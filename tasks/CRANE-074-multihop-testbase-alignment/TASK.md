# Task CRANE-074: Align Multihop Test with Camelot TestBase Patterns

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-027
**Worktree:** `refactor/multihop-testbase-alignment`
**Origin:** Code review suggestion from CRANE-027 (Suggestion 1)

---

## Description

Align the multihop routing test with the existing ConstProdUtils Camelot testbase patterns for consistency in naming and helper functions.

(Created from code review of CRANE-027)

## Dependencies

- CRANE-027: Add Multi-hop Routing Tests (parent task - completed)

## User Stories

### US-CRANE-074.1: Align Test Patterns

As a developer, I want the multihop test to follow the same patterns as other ConstProdUtils tests so that the test suite is consistent and maintainable.

**Acceptance Criteria:**
- [x] Test naming follows Camelot testbase conventions
- [x] Helper functions align with existing patterns in the test suite
- [x] No functional changes to test coverage
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_multihop.t.sol`

**Reference Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_purchaseQuote_Camelot.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-027 is complete
- [x] ConstProdUtils_multihop.t.sol exists
- [x] Camelot testbase pattern files exist for reference

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass (`forge test --match-path test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_multihop_Camelot.t.sol`)
- [x] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
