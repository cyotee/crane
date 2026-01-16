# Task CRANE-029: ConstProdUtils Code Cleanup and NatSpec

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-007
**Worktree:** `fix/constprodutils-cleanup`
**Origin:** Code review suggestions from CRANE-007 (Suggestions 5 + 6)

---

## Description

Clean up ConstProdUtils.sol by removing dead code and adding proper NatSpec documentation tags per Crane coding standards.

This combines two related suggestions:
- Remove commented-out code (lines 848-1312) and debug console imports
- Add `@custom:signature` and `@custom:selector` tags per Crane NatSpec standards

(Created from code review of CRANE-007)

## Dependencies

- CRANE-007: Uniswap V2 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-029.1: Remove Dead Code

As a developer, I want the codebase free of commented-out code so that it's easier to read and maintain.

**Acceptance Criteria:**
- [ ] Remove commented-out code block (lines 848-1312 or equivalent)
- [ ] Remove debug console imports if present
- [ ] No functional changes to the contract
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-029.2: Add NatSpec Documentation Tags

As a developer, I want proper NatSpec tags on public functions so that documentation can be auto-generated.

**Acceptance Criteria:**
- [ ] All public/external functions have `@custom:signature` tag
- [ ] All public/external functions have `@custom:selector` tag
- [ ] Tags follow Crane NatSpec standard (see CLAUDE.md)
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/utils/math/ConstProdUtils.sol`

**Reference Files:**
- `CLAUDE.md` (NatSpec documentation standard)

## Inventory Check

Before starting, verify:
- [x] CRANE-007 is complete
- [x] ConstProdUtils.sol exists
- [x] CLAUDE.md documents NatSpec standards

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test`)
- [ ] Build succeeds (`forge build`)
- [ ] No commented-out code blocks remain
- [ ] All public functions have required NatSpec tags

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
