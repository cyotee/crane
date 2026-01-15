# Task CRANE-070: Reduce Noisy Logs from Camelot Stubs

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-044
**Worktree:** `fix/camelot-stub-logs`
**Origin:** Code review suggestion from CRANE-044

---

## Description

Reduce noisy debug logs from CamelotPair stub contracts. Running the Camelot test suite prints debug logs from `CamelotPair._getAmountOut`. If these logs aren't intentionally part of the test UX, consider removing or gating them to keep CI output clean.

Note: This is pre-existing behavior, not introduced by CRANE-044.

(Created from code review of CRANE-044)

## Dependencies

- CRANE-044: Add Camelot V2 Asymmetric Fee Tests (parent task)

## User Stories

### US-CRANE-070.1: Clean up debug logs in stub contracts

As a developer, I want clean CI output without noisy debug logs so that test failures are easier to identify.

**Acceptance Criteria:**
- [ ] Remove or gate debug logs from `CamelotPair._getAmountOut`
- [ ] Consider using a DEBUG flag or environment variable for optional verbose output
- [ ] CI output is clean without spurious log lines
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-044 is complete
- [ ] CamelotPair.sol stub exists
- [ ] Debug logs are present in `_getAmountOut`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] CI output is clean
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
