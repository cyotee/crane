# Task CRANE-230: Document SafeCast Wrapper Delegation Pattern

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-06
**Dependencies:** CRANE-223
**Worktree:** `docs/safecast-delegation-pattern`
**Origin:** Code review suggestion from CRANE-223

---

## Description

The `SafeCast.sol` wrapper declares `SafeCastOverflowedUintDowncast` but delegates to `SafeCastLib` which throws `Overflow()` at runtime. This subtlety could trip up future developers writing tests or debugging reverts. Add NatSpec comments to `SafeCast.sol` noting that runtime reverts use `SafeCastLib.Overflow` (not the declared error).

(Created from code review of CRANE-223)

## Dependencies

- CRANE-223: Fix Error Selector Mismatches After OZ Removal (parent task)

## User Stories

### US-CRANE-230.1: Add NatSpec to SafeCast Wrapper

As a developer, I want SafeCast.sol to document which error is actually thrown at runtime so that I correctly use `SafeCastLib.Overflow.selector` in `vm.expectRevert()` calls.

**Acceptance Criteria:**
- [ ] SafeCast.sol has NatSpec comment explaining the delegation pattern
- [ ] Comment clarifies that `SafeCastLib.Overflow()` is the runtime error, not `SafeCastOverflowedUintDowncast`
- [ ] Build succeeds
- [ ] No test regressions

## Files to Create/Modify

**Modified Files:**
- `contracts/utils/SafeCast.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-223 is complete
- [ ] `contracts/utils/SafeCast.sol` exists and delegates to `SafeCastLib`

## Completion Criteria

- [ ] NatSpec added to SafeCast.sol
- [ ] Build succeeds
- [ ] No test regressions

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
