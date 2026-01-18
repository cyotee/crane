# Task CRANE-126: Fix Unchecked-Call Lint Warning

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-18
**Dependencies:** CRANE-071
**Worktree:** `fix/unchecked-call-lint`
**Origin:** Code review suggestion from CRANE-071 (build warnings)

---

## Description

Address the `unchecked-call` lint warning that appears during `forge build` to achieve a cleaner build output with fewer warnings.

(Created from code review of CRANE-071)

## Dependencies

- CRANE-071: Remove Unused IERC20 Import from TokenConfigUtils (parent task - completed)

## User Stories

### US-CRANE-126.1: Clean Build Output

As a developer, I want `forge build` to have fewer lint warnings so that real issues are easier to spot and the build output is cleaner.

**Acceptance Criteria:**
- [ ] Identify the source of unchecked-call lint warning
- [ ] Fix or suppress the warning appropriately
- [ ] Document reasoning if suppression is chosen
- [ ] No new warnings introduced
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- TBD (requires investigation to identify affected files)

## Inventory Check

Before starting, verify:
- [x] CRANE-071 is complete
- [ ] Run `forge build` to identify exact warning location

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
