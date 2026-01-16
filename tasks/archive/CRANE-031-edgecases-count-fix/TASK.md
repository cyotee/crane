# Task CRANE-031: Fix EdgeCases Test Count Documentation

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-008
**Worktree:** `fix/edgecases-count-doc`
**Origin:** Code review suggestion from CRANE-008 (Suggestion 2)

---

## Description

Update PROGRESS.md table to show 14 tests for EdgeCases instead of 19. This is a documentation accuracy fix only.

(Created from code review of CRANE-008)

## Dependencies

- CRANE-008: Uniswap V3 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-031.1: Correct Test Count Documentation

As a developer, I want accurate test counts in documentation so that I can trust the documentation.

**Acceptance Criteria:**
- [x] Update EdgeCases test count from 19 to 14 in PROGRESS.md
- [x] Verify actual test count matches documentation
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `tasks/archive/CRANE-008-uniswap-v3-utils/PROGRESS.md`

## Inventory Check

Before starting, verify:
- [x] CRANE-008 is complete
- [x] PROGRESS.md exists in archive

## Completion Criteria

- [x] Test count corrected
- [x] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
