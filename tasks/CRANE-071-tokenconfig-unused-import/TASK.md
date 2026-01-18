# Task CRANE-071: Remove Unused IERC20 Import from TokenConfigUtils

**Repo:** Crane Framework
**Status:** Complete
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
- [x] Verify if `IERC20` import is actually needed for `TokenConfig` type resolution
- [x] If not needed: remove the import
- [ ] ~~If needed: document why and close as "Won't Fix"~~ (N/A - import was not needed)
- [x] Build succeeds without new warnings
- [x] Tests pass

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-051 is complete
- [x] TokenConfigUtils.sol exists
- [x] Verify `IERC20` import usage

## Completion Criteria

- [x] All acceptance criteria met
- [x] `forge build` succeeds
- [x] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
