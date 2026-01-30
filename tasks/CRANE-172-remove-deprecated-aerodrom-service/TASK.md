# Task CRANE-172: Remove Deprecated AerodromService

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-148
**Worktree:** `chore/remove-deprecated-aerodrom-service`
**Origin:** Code review suggestion from CRANE-148

---

## Description

Remove the deprecated `AerodromService.sol` file to reduce maintenance burden. The file is marked as DEPRECATED in the Aerodrome v1 README and is no longer needed since `AerodromeStableService.sol` provides the necessary stable pool support.

(Created from code review of CRANE-148)

## Dependencies

- CRANE-148: Verify Aerodrome Contract Port Completeness (parent task - Complete)

## User Stories

### US-CRANE-172.1: Remove Deprecated Service

As a developer, I want to remove the deprecated AerodromService.sol file so that there is no confusion about which service to use and the codebase stays clean.

**Acceptance Criteria:**
- [ ] `contracts/protocols/dexes/aerodrome/v1/services/AerodromService.sol` is deleted
- [ ] No remaining imports or references to AerodromService
- [ ] README.md updated to remove DEPRECATED notice (if applicable)
- [ ] Tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**Deleted Files:**
- `contracts/protocols/dexes/aerodrome/v1/services/AerodromService.sol`

**Modified Files:**
- `contracts/protocols/dexes/aerodrome/v1/README.md` (remove deprecated service mention)

## Inventory Check

Before starting, verify:
- [ ] CRANE-148 is complete
- [ ] AerodromService.sol exists and is marked deprecated
- [ ] No active code depends on AerodromService

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
