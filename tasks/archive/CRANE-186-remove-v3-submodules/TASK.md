# Task CRANE-186: Remove v3-core and v3-periphery Submodules

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-151
**Worktree:** `chore/remove-v3-submodules`
**Origin:** Code review suggestion from CRANE-151

---

## Description

Now that all Uniswap V3 contracts are ported and tested locally, remove the v3-core and v3-periphery submodules to reduce repository complexity and dependency on external repos.

(Created from code review of CRANE-151)

## Dependencies

- CRANE-151: Port and Verify Uniswap V3 Core + Periphery (parent task)

## User Stories

### US-CRANE-186.1: Remove V3 Submodules

As a developer, I want v3-core and v3-periphery submodules removed so that we rely only on our ported contracts.

**Acceptance Criteria:**
- [ ] Remove lib/v3-core submodule
- [ ] Remove lib/v3-periphery submodule
- [ ] Update .gitmodules
- [ ] Verify no imports reference submodule paths
- [ ] Build succeeds
- [ ] All tests pass

## Files to Create/Modify

**Modified Files:**
- `.gitmodules`

**Deleted Directories:**
- `lib/v3-core/`
- `lib/v3-periphery/`

## Inventory Check

Before starting, verify:
- [ ] CRANE-151 is complete
- [ ] All V3 tests passing
- [ ] No imports reference @uniswap/v3-core or @uniswap/v3-periphery

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
