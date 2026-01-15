# Task CRANE-071: Remove Unused IERC20 Import from TokenConfigUtils

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-051
**Worktree:** `fix/tokenconfig-unused-import`
**Origin:** Code review suggestion from CRANE-051

---

## Description

Remove the unused `IERC20` import in `TokenConfigUtils.sol` to reduce compiler warnings and keep the file minimal. If the import is actually necessary due to how the compiler resolves transitive types for `TokenConfig`, keep it and close this task as "Won't Fix".

(Created from code review of CRANE-051)

## Dependencies

- CRANE-051: Fix TokenConfigUtils._sort() Data Corruption Bug (parent task)

## User Stories

### US-CRANE-071.1: Remove unused import

As a developer, I want clean imports without unused dependencies so that compiler warnings are minimized and code intent is clear.

**Acceptance Criteria:**
- [ ] Verify if `IERC20` import is actually needed for `TokenConfig` type resolution
- [ ] If not needed: remove the import
- [ ] If needed: document why and close as "Won't Fix"
- [ ] Build succeeds without new warnings
- [ ] Tests pass

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-051 is complete
- [ ] TokenConfigUtils.sol exists
- [ ] Verify `IERC20` import usage

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` succeeds
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
