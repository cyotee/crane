# Task CRANE-232: Add Slipstream Near-Depletion Exact-Output Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-06
**Dependencies:** CRANE-090
**Worktree:** `test/slipstream-near-depletion`
**Origin:** Code review suggestion from CRANE-090

---

## Description

Add a test that explicitly validates near-depletion boundary behavior for `quoteExactOutput` - requesting output that consumes most (but not all) available liquidity within a tick without crossing to the next tick. While existing large-amount tests (1e18 to 1e27 range) partially cover this, no test explicitly targets the boundary where output approaches but doesn't exceed single-tick liquidity.

(Created from code review of CRANE-090)

## Dependencies

- CRANE-090: Add Exact-Output Edge Case Tests to Slipstream Fork Tests (parent task)

## User Stories

### US-CRANE-232.1: Near-depletion boundary validation

As a developer, I want to verify that `quoteExactOutput` correctly handles requests that consume nearly all liquidity in a single tick so that edge cases near tick boundaries are explicitly tested.

**Acceptance Criteria:**
- [ ] Add test requesting output that consumes ~95-99% of available liquidity in a single tick
- [ ] Verify the quote returns without reverting
- [ ] Verify the quoted input amount is reasonable (non-zero, proportional to output)
- [ ] Verify the quote doesn't cross a tick boundary when liquidity is sufficient
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_quoteExactOutput.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-090 is complete
- [ ] SlipstreamUtils_quoteExactOutput.t.sol exists with existing near-boundary tests

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
