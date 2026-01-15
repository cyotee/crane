# Task CRANE-051: Fix TokenConfigUtils._sort() Data Corruption Bug

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-14
**Dependencies:** CRANE-013
**Worktree:** `fix/tokenconfig-sort-bug`
**Origin:** Code review suggestion from CRANE-013

---

## Description

Fix the TokenConfigUtils._sort() function which only swaps the `token` field, not the entire TokenConfig struct. This corrupts `rateProvider`, `tokenType`, and `paysYieldFees` when sorting is needed.

(Created from code review of CRANE-013)

## Dependencies

- CRANE-013: Balancer V3 Utilities Review (parent task)

## User Stories

### US-CRANE-051.1: Fix struct swap in sort function

As a developer, I want the _sort() function to swap the entire TokenConfig struct so that all fields remain correctly aligned after sorting.

**Acceptance Criteria:**
- [x] `_sort()` swaps entire TokenConfig struct, not just the token address
- [x] After sorting, `rateProvider`, `tokenType`, and `paysYieldFees` are correctly paired with their tokens
- [x] Unit tests verify correct sorting behavior
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol (lines 22-26)

**New/Modified Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/utils/TokenConfigUtils.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-013 is complete
- [x] contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol exists
- [x] Current _sort() implementation only swaps .token field (was true, now fixed)

## Completion Criteria

- [x] All acceptance criteria met
- [x] Unit tests added
- [x] `forge test` passes
- [x] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
