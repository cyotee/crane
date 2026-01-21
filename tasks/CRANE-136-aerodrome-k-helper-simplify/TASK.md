# Task CRANE-136: Simplify _k_from_f Helper in Aerodrome Stable

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-21
**Dependencies:** CRANE-085
**Worktree:** `fix/aerodrome-k-helper-simplify`
**Origin:** Code review suggestion from CRANE-085

---

## Description

Replace `_k_from_f(x0, y + 1)` with `_f(x0, y + 1)` (or rename the helper to something more explicit). Keeps the Newton-Raphson section easier to audit.

`_k_from_f()` is a thin wrapper around `_f()`. The name implies a different calculation than `_f`, but it is identical. This is harmless, but slightly confusing in the Newton-Raphson early-exit comment that references it.

(Created from code review of CRANE-085)

## Dependencies

- CRANE-085: Document Stable Swap-Deposit Gas/Complexity (Complete - parent task)

## User Stories

### US-CRANE-136.1: Simplify Helper Function

As a developer auditing the Newton-Raphson implementation, I want clear and non-redundant helper names so that the code is easier to understand.

**Acceptance Criteria:**
- [ ] Either inline `_f` directly where `_k_from_f` is called, OR rename the helper to be more explicit about its purpose
- [ ] Newton-Raphson section comments updated if needed
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-085 is complete
- [ ] AerodromServiceStable.sol exists with `_k_from_f` helper

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-path '**/aerodrome/**'` passes
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
