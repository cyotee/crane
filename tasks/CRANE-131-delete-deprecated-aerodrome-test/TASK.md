# Task CRANE-131: Delete Deprecated AerodromService Test File

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-21
**Dependencies:** CRANE-083
**Worktree:** `fix/delete-deprecated-aerodrome-test`
**Origin:** Code review suggestion from CRANE-083 (modified)

---

## Description

Delete the deprecated AerodromService.t.sol test file entirely. This file was marked as deprecated in CRANE-083 with banner warnings, but user prefers complete removal over keeping deprecated code that could be copy/pasted.

The canonical volatile and stable APIs (AerodromServiceVolatile, AerodromServiceStable) are fully tested elsewhere, making this deprecated test file redundant.

(Created from code review of CRANE-083)

## Dependencies

- CRANE-083: Clarify Deprecated Aerodrome Library Test Intent (Complete - parent task)

## User Stories

### US-CRANE-131.1: Remove Deprecated Test File

As a developer, I want deprecated test files removed so that new developers don't accidentally copy deprecated usage patterns.

**Acceptance Criteria:**
- [ ] AerodromService.t.sol deleted from test/foundry/spec/protocols/dexes/aerodrome/v1/services/
- [ ] No references to deleted file remain in codebase
- [ ] All other Aerodrome tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**Deleted Files:**
- test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromService.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-083 is complete
- [ ] File exists at expected path
- [ ] No other files import/depend on this test file

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-path 'test/foundry/spec/protocols/dexes/aerodrome/**/*.t.sol'` passes
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
