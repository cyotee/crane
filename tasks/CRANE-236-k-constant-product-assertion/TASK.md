# Task CRANE-236: Add k() Assertion for Constant-Product Mode

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** CRANE-099
**Worktree:** `test/k-constant-product-assertion`
**Origin:** Code review suggestion from CRANE-099

---

## Description

Add a direct `assertEq` test for `k()` in constant-product mode (stableSwap=false), where `_k()` returns `balance0 * balance1`. This provides full branch coverage of `_k()`. Currently, the `test_kCalculation_stableVsConstantProduct` test compares outputs but doesn't directly assert the constant-product K value.

(Created from code review of CRANE-099)

## Dependencies

- CRANE-099: Add Direct Assertion for Cubic Invariant _k() (parent task)

## User Stories

### US-CRANE-236.1: Verify constant-product k() branch

As a developer, I want to directly assert the constant-product `_k()` formula so that any regression in the trivial `balance0 * balance1` branch is caught deterministically.

**Acceptance Criteria:**
- [ ] Test calls `k()` on a non-stable pair and asserts `k == reserve0 * reserve1`
- [ ] Assertion uses `assertEq` for exact match
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_stableSwap.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-099 is complete
- [ ] `CamelotPair.sol` has `k()` wrapper function

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
