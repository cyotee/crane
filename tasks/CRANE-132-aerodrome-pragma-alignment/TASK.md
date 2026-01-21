# Task CRANE-132: Align Aerodrome Test Pragma with Repo Version

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-21
**Dependencies:** CRANE-083
**Worktree:** `fix/aerodrome-pragma-alignment`
**Origin:** Code review suggestion from CRANE-083

---

## Description

Update `pragma solidity ^0.8.0;` in Aerodrome test files to match the repo's pinned compiler version for consistency with the prevailing convention elsewhere in `test/`.

(Created from code review of CRANE-083)

## Dependencies

- CRANE-083: Clarify Deprecated Aerodrome Library Test Intent (Complete - parent task)

## User Stories

### US-CRANE-132.1: Align Pragma Version

As a developer, I want consistent pragma versions across test files so that compiler behavior is predictable and matches the repo standard.

**Acceptance Criteria:**
- [ ] All Aerodrome test files use the repo's standard pragma version
- [ ] Pragma is consistent with other test files in the repo
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/aerodrome/v1/services/*.t.sol (update pragma)

## Inventory Check

Before starting, verify:
- [x] CRANE-083 is complete
- [ ] Determine repo's standard pragma version from other test files
- [ ] Identify all Aerodrome test files with non-standard pragma

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-path 'test/foundry/spec/protocols/dexes/aerodrome/**/*.t.sol'` passes
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
