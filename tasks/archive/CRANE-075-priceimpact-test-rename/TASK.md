# Task CRANE-075: Rename Price Impact Fuzz Test for Clarity

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-028
**Worktree:** `fix/priceimpact-test-rename`
**Origin:** Code review suggestion from CRANE-028 (Suggestion 1)

---

## Description

Rename `testFuzz_priceImpact_increasesWithTradeSize` to reflect what it actually asserts (bounded by theoretical maximum), or modify it to compare price impact at two sizes and assert monotonicity.

The current test name suggests it checks that price impact increases with trade size, but it actually just verifies price impact is bounded by a theoretical maximum. Monotonicity is separately covered by `testFuzz_priceImpact_monotonic`.

(Created from code review of CRANE-028)

## Dependencies

- CRANE-028: Add Price Impact Tests (parent task - completed)

## User Stories

### US-CRANE-075.1: Align Test Name with Behavior

As a developer, I want test names to accurately describe what they assert so that the test suite is self-documenting and maintainable.

**Acceptance Criteria:**
- [ ] Test name reflects actual assertion behavior
- [ ] Options: rename to `testFuzz_priceImpact_boundedByTheoretical` or modify to actually compare two trade sizes
- [ ] No functional regression
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-028 is complete
- [x] ConstProdUtils_priceImpact.t.sol exists
- [x] `testFuzz_priceImpact_monotonic` provides separate monotonicity coverage

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test --match-path test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
