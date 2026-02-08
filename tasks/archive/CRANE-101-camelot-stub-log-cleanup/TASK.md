# Task CRANE-101: Remove/Gate console.log in Camelot Stubs

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-045
**Worktree:** `fix/camelot-stub-logs`
**Origin:** Code review suggestion from CRANE-045

---

## Description

Remove or gate `console.log` calls in Camelot stubs. The `CamelotPair._getAmountOut()` and `_mintFee()` functions emit multiple console.log lines that create noisy test output, especially under fuzzing. This makes `forge test` output harder to interpret and can add significant noise as the test suite grows.

(Created from code review of CRANE-045)

## Dependencies

- CRANE-045: Add Camelot V2 Stable Swap Pool Tests (parent task - complete)

## User Stories

### US-CRANE-101.1: Remove Console Log Spam

As a developer, I want Camelot stubs to not spam console output so that test results are easier to read and failures are easier to identify.

**Acceptance Criteria:**
- [ ] Identify all `console.log` calls in CamelotPair.sol stub
- [ ] Either remove the logs entirely, OR
- [ ] Gate them behind a constant flag (e.g., `bool constant DEBUG_LOGS = false`)
- [ ] Verify fuzz tests don't produce excessive output
- [ ] Tests pass
- [ ] Build succeeds

## Technical Details

**Files with console.log:**
- `contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol`
  - `_getAmountOut()` - multiple logs in stable and non-stable paths
  - `_mintFee()` - additional logs

**Options:**
1. Remove logs entirely (simplest)
2. Gate behind constant: `if (DEBUG_LOGS) console.log(...)`
3. Use a debug modifier pattern

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol

## Inventory Check

Before starting, verify:
- [ ] CamelotPair.sol stub exists
- [ ] Contains console.log statements

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
