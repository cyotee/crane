# Task CRANE-090: Add Exact-Output Edge Case Tests to Slipstream Fork Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-039
**Worktree:** `test/slipstream-fork-exactout-edge`
**Origin:** Code review suggestion from CRANE-039

---

## Description

Round out the edge-case matrix for exact-output quoting. There is a zero-amount test for exact-input, but exact-output needs coverage too.

Add:
1. `quoteExactOutputSingle(0, …) == 0` test
2. Optionally, a "dust exact-output" test with slightly relaxed tolerance

(Created from code review of CRANE-039)

## Dependencies

- CRANE-039: Add Slipstream Fork Tests (Complete - parent task)

## User Stories

### US-CRANE-090.1: Add Exact-Output Edge Case Tests

As a developer, I want edge case tests for exact-output quoting so that behavior remains stable as utils evolve.

**Acceptance Criteria:**
- [ ] Add `quoteExactOutputSingle(0, …) == 0` test
- [ ] Optionally add dust exact-output test
- [ ] Tests pass on fork
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/fork/base_main/slipstream/SlipstreamUtils_Fork.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-039 is complete
- [x] SlipstreamUtils_Fork.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` succeeds
- [ ] Fork tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
