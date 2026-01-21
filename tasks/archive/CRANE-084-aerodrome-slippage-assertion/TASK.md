# Task CRANE-084: Strengthen Stable-vs-Volatile Slippage Assertion

**Repo:** Crane Framework
**Status:** Complete (Reviewed)
**Created:** 2026-01-15
**Dependencies:** CRANE-037
**Worktree:** `test/aerodrome-slippage-assertion`
**Origin:** Code review suggestion from CRANE-037

---

## Description

The test `test_stableVsVolatile_stableHasLowerSlippage()` currently only asserts that both swaps produce output. It does not assert that the stable pool actually has lower slippage / higher output.

Add a real assertion such as `assertGt(stableOut, volatileOut, ...)`. With current stub fees (stable 0.05%, volatile 0.3%), this should be deterministic and meaningful.

(Created from code review of CRANE-037)

## Dependencies

- CRANE-037: Add Aerodrome Stable Pool Support (Complete - parent task)

## User Stories

### US-CRANE-084.1: Add Slippage Comparison Assertion

As a developer, I want the slippage comparison test to actually assert the expected behavior so that the test is meaningful and not just smoke testing.

**Acceptance Criteria:**
- [x] `assertGt(stableOut, volatileOut, ...)` or equivalent assertion added
- [x] Test name matches what it actually checks
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-037 is complete
- [x] AerodromServiceStable.t.sol exists with `test_stableVsVolatile_stableHasLowerSlippage()`

## Completion Criteria

- [x] All acceptance criteria met
- [x] `forge test --match-path 'test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.t.sol'` passes
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
