# Task CRANE-107: Reduce Stub Log Noise in Verbose Test Runs

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-050
**Worktree:** `fix/stub-log-noise`
**Origin:** Code review suggestion from CRANE-050

---

## Description

Verbose test runs (`forge test -vvv`) emit excessive `CamelotPair._getAmountOut` logs from stubs, making review runs noisy. Gate these logs behind a debug flag or remove them.

(Created from code review of CRANE-050)

## Dependencies

- CRANE-050: Add Multi-Hop Swap with Directional Fees Tests (parent task - complete)

## Related Tasks

- CRANE-070: Reduce Noisy Logs from Camelot Stubs (from CRANE-044)
- CRANE-101: Remove/Gate console.log in Camelot Stubs (from CRANE-045)

**Note:** This task may overlap with CRANE-070 and CRANE-101. Consider consolidating if those address the same issue.

## User Stories

### US-CRANE-107.1: Quieter Verbose Test Output

As a developer, I want verbose test runs to show relevant logs only so that debugging is easier.

**Acceptance Criteria:**
- [ ] Review `console.log` statements in CamelotPair stub
- [ ] Remove or gate behind `DEBUG` flag
- [ ] Verbose test runs (`-vvv`) produce cleaner output
- [ ] Tests pass
- [ ] Build succeeds

## Technical Details

**Current Issue:**
```
CamelotPair._getAmountOut(1000000, 1000000000, 1000000000, 300, 500)
CamelotPair._getAmountOut(997000, 1000000000, 1000000000, 300, 500)
... (repeated many times)
```

**Options:**
1. Remove `console.log` calls entirely
2. Gate behind `vm.envBool("DEBUG")` or similar
3. Use `console2.log` which can be stripped in production

**Test Suite:** N/A (code cleanup)

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol`

## Inventory Check

Before starting, verify:
- [ ] CamelotPair.sol exists
- [ ] Check if CRANE-070 or CRANE-101 already addresses this

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
