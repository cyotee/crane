# Task CRANE-083: Clarify Deprecated Aerodrome Library Test Intent

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-037
**Worktree:** `fix/aerodrome-deprecated-test-intent`
**Origin:** Code review suggestion from CRANE-037

---

## Description

Clarify the intent of `AerodromService.t.sol` which still tests the deprecated API. Either:
- (a) Migrate tests to use `AerodromServiceVolatile` as the new canonical API, or
- (b) Keep it but rename/add header comment making it explicitly "deprecated/back-compat coverage"

This aligns with TASK.md acceptance criteria and prevents developers from copy/pasting deprecated usage patterns.

(Created from code review of CRANE-037)

## Dependencies

- CRANE-037: Add Aerodrome Stable Pool Support (Complete - parent task)

## User Stories

### US-CRANE-083.1: Clarify Deprecated Test Intent

As a developer, I want the deprecated library test file to clearly indicate its purpose so that I don't accidentally copy deprecated usage patterns.

**Acceptance Criteria:**
- [ ] `AerodromService.t.sol` either migrated to volatile API OR clearly marked as back-compat coverage
- [ ] Header comment added explaining the test file's purpose
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromService.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-037 is complete
- [x] AerodromService.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-path 'test/foundry/spec/protocols/dexes/aerodrome/v1/services/*.t.sol'` passes
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
