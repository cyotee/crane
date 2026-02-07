# Task CRANE-094: Align Slipstream Test Pragma with Repo Conventions

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-040
**Worktree:** `fix/slipstream-pragma-style`
**Origin:** Code review suggestion from CRANE-040 (Suggestion 3)

---

## Description

Pin `pragma solidity 0.8.30;` (or the repo's chosen exact pragma) for consistency in the Slipstream edge case test file. Currently uses `^0.8.0` which compiles but differs from repo convention.

(Created from code review of CRANE-040)

## Dependencies

- CRANE-040: Add Slipstream Edge Case Tests (parent task - completed)

## User Stories

### US-CRANE-094.1: Consistent Pragma Style

As a developer, I want consistent pragma versions across test files so that the codebase follows uniform conventions.

**Acceptance Criteria:**
- [ ] Update pragma to match repo conventions (likely `0.8.30`)
- [ ] Verify file still compiles
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_edgeCases.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-040 is complete
- [x] SlipstreamUtils_edgeCases.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
