# Task CRANE-173: Add Aerodrome Interface Comparison Report

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-148
**Worktree:** `docs/aerodrome-interface-comparison`
**Origin:** Code review suggestion from CRANE-148

---

## Description

Extract the interface comparison results from CRANE-148's PROGRESS.md into a standalone INTERFACE_COMPARISON.md file for future reference. This provides a permanent record of the verification work done during the Aerodrome port.

(Created from code review of CRANE-148)

## Dependencies

- CRANE-148: Verify Aerodrome Contract Port Completeness (parent task - Complete)

## User Stories

### US-CRANE-173.1: Create Interface Comparison Document

As a developer, I want a standalone document showing the interface comparison between original Aerodrome contracts and the Crane port so that future maintainers can reference the verification work.

**Acceptance Criteria:**
- [ ] Create `contracts/protocols/dexes/aerodrome/v1/INTERFACE_COMPARISON.md`
- [ ] Document all verified interface files with their selector counts
- [ ] Include summary of acceptable differences (pragma, imports, etc.)
- [ ] Reference original verification date and methodology
- [ ] Build succeeds (no compilation changes)

## Files to Create/Modify

**Created Files:**
- `contracts/protocols/dexes/aerodrome/v1/INTERFACE_COMPARISON.md`

**Reference Files (read-only):**
- `tasks/archive/CRANE-148-aerodrome-port-verification/PROGRESS.md` (source of comparison data)

## Inventory Check

Before starting, verify:
- [ ] CRANE-148 is complete
- [ ] PROGRESS.md contains interface comparison results
- [ ] Aerodrome v1 directory exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Document is well-formatted and readable
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
