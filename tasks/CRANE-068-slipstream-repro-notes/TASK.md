# Task CRANE-068: Add Slipstream Fuzz Test Repro Notes

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-038
**Worktree:** `docs/slipstream-repro-notes`
**Origin:** Code review suggestion from CRANE-038

---

## Description

Make build/test evidence easy to reproduce by recording the exact `forge test --match-path ...` command (and/or expected run counts) in documentation. This helps reviewers quickly reproduce the subset run locally.

(Created from code review of CRANE-038)

## Dependencies

- CRANE-038: Add Slipstream Fuzz Tests (parent task)

## User Stories

### US-CRANE-068.1: Document test reproduction commands

As a reviewer, I want clear documentation of how to reproduce the Slipstream fuzz test runs so that I can quickly verify test behavior locally.

**Acceptance Criteria:**
- [ ] Document exact `forge test --match-path` command for Slipstream fuzz tests
- [ ] Include expected test count or pattern
- [ ] Add to appropriate documentation file (PROGRESS.md or test file comment)
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_fuzz.t.sol (header comment)
- OR test/foundry/spec/utils/math/slipstreamUtils/SlipstreamZapQuoter_fuzz.t.sol (header comment)

## Inventory Check

Before starting, verify:
- [ ] CRANE-038 is complete
- [ ] Slipstream fuzz test files exist
- [ ] Determine best location for repro documentation

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Documentation is clear and actionable
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
