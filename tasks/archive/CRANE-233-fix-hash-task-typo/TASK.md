# Task CRANE-233: Fix TASK.md encodePacked Typo

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-06
**Dependencies:** CRANE-091
**Worktree:** `fix/hash-task-typo`
**Origin:** Code review suggestion from CRANE-091 (Suggestion 1)

---

## Description

Fix the description typo in CRANE-091's archived TASK.md that says `keccak256(abi.encodePacked(...))` when it should say `keccak256(abi.encode(...))`. The library uses 32-byte word-aligned `mstore` which matches `abi.encode` semantics, not `abi.encodePacked`.

(Created from code review of CRANE-091)

## Dependencies

- CRANE-091: Add BetterEfficientHashLib Hash Equivalence Test (parent task - completed)

## User Stories

### US-CRANE-233.1: Correct Documentation

As a developer, I want the archived task description to accurately reflect the library semantics so that future readers are not misled.

**Acceptance Criteria:**
- [ ] Change `abi.encodePacked` to `abi.encode` in archived TASK.md description
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `tasks/archive/CRANE-091-hash-equivalence-test/TASK.md`

## Inventory Check

Before starting, verify:
- [x] CRANE-091 is complete
- [x] Archived TASK.md exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
