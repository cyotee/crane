# Task CRANE-128: Replace Heuristic Percent Bounds with Explicit Tolerances

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-18
**Dependencies:** CRANE-073
**Worktree:** `test/explicit-tolerances`
**Origin:** Code review suggestion from CRANE-073

---

## Description

Replace heuristic percent bounds (e.g., ">= 99%" and "<= 2%") in quote tests with derived expectations using explicit tolerances via `assertApproxEqAbs` or `assertApproxEqRel`.

The current percent-based bounds are somewhat heuristic and could become flaky if minor formula changes or rounding adjustments occur. Using explicit computed expectations with justified tolerances provides more stable and mathematically grounded assertions.

(Created from code review of CRANE-073)

## Dependencies

- CRANE-073: Tighten Non-Revert Assertions in Overflow Tests (parent task - complete)

## User Stories

### US-CRANE-128.1: Derived Expectations with Tolerances

As a developer, I want quote tests to use derived expectations with explicit tolerances so that tests are more stable and mathematically justified.

**Acceptance Criteria:**
- [ ] Identify tests using heuristic percent bounds
- [ ] Derive explicit expected values for test inputs
- [ ] Replace percent bounds with `assertApproxEqAbs` or `assertApproxEqRel`
- [ ] Document tolerance justification in test comments
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_OverflowBoundary.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-073 is complete
- [ ] Test file exists with quote tests using percent bounds

## Completion Criteria

- [ ] Heuristic percent bounds replaced with explicit tolerances
- [ ] Tolerance values mathematically justified
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
