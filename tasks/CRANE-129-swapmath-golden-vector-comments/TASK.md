# Task CRANE-129: Align SwapMath Golden Vector Comments with Upstream

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-18
**Dependencies:** CRANE-080
**Worktree:** `fix/swapmath-golden-vector-comments`
**Origin:** Code review suggestion from CRANE-080

---

## Description

Update the `@dev Derived from Uniswap V4 reference:` string in `test_goldenVector_zeroForOne_lowLiquidity_reachTarget` to match the upstream test name/direction (or clarify that the upstream naming is counterintuitive). This keeps the "golden vectors are upstream-derived" breadcrumb reliable.

(Created from code review of CRANE-080)

## Dependencies

- CRANE-080: Add SwapMath Golden Vector Tests (parent task - Complete)

## User Stories

### US-CRANE-129.1: Accurate Documentation Reference

As a developer, I want the golden vector test comments to accurately reference their upstream source so that I can easily cross-check test values against the original Uniswap V4 reference tests.

**Acceptance Criteria:**
- [ ] `@dev` comment in `test_goldenVector_zeroForOne_lowLiquidity_reachTarget` accurately reflects upstream test name
- [ ] Direction in comment matches test behavior (zeroForOne vs oneForZero)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-080 is complete
- [x] SwapMath.t.sol exists with golden vector tests

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
