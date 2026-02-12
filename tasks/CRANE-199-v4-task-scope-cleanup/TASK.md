# Task CRANE-199: Resolve CRANE-152 TASK.md Scope Mismatch

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-01
**Dependencies:** CRANE-152
**Worktree:** `fix/v4-task-scope-cleanup`
**Origin:** Code review suggestion from CRANE-152

---

## Description

Decide whether `PositionDescriptor.sol`, WETH/WstETH hooks, and DeployerCompetition are required for CRANE-152. If optional, update `tasks/CRANE-152-uniswap-v4-port-verification/TASK.md` acceptance criteria to reflect that.

Note: The review found these were resolved during implementation, but the TASK.md was not updated to reflect the final scope. This task formalizes the cleanup.

(Created from code review of CRANE-152)

## Dependencies

- CRANE-152: Port and Verify Uniswap V4 Core + Periphery (parent task)

## User Stories

### US-CRANE-199.1: Update Task Documentation

As a developer, I want TASK.md acceptance criteria to match what was actually implemented so that the task history is accurate.

**Acceptance Criteria:**
- [ ] CRANE-152 TASK.md updated to reflect final scope
- [ ] Acceptance criteria match implemented files
- [ ] Optional items clearly marked as optional
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `tasks/archive/CRANE-152-uniswap-v4-port-verification/TASK.md`

## Inventory Check

Before starting, verify:
- [ ] CRANE-152 is complete
- [ ] TASK.md exists in archive

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Documentation accurate

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
