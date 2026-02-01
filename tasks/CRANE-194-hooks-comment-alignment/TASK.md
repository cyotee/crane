# Task CRANE-194: Align Hook Comments With Actual Behavior

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-31
**Dependencies:** CRANE-147
**Worktree:** `fix/hooks-comment-alignment`
**Origin:** Code review suggestion from CRANE-147

---

## Description

Fix minor comment mismatches in hook implementations and tests to improve code readability and prevent confusion.

Identified issues:
1. `ExitFeeHookExample.sol`: Comment says "Router" in donation call context, but `msg.sender` is actually the Vault (due to `onlyVault` modifier)
2. `VeBALFeeDiscountHookExample.t.sol`: Comments mention "linear" discount, but the hook implements a binary 50% discount when `balanceOf(user) > 0`

(Created from code review of CRANE-147)

## Dependencies

- CRANE-147: Refactor Balancer V3 Pool Hooks Package (parent task, complete)

## User Stories

### US-CRANE-194.1: Fix ExitFeeHookExample Comment

As a developer reading the code, I want accurate comments so that I understand the actual call flow.

**Acceptance Criteria:**
- [ ] Update comment to correctly identify `msg.sender` as Vault, not Router
- [ ] Ensure any related comments are also accurate

### US-CRANE-194.2: Fix VeBAL Discount Test Comments

As a developer reading the tests, I want comments to match the actual implementation behavior.

**Acceptance Criteria:**
- [ ] Update "linear" discount comments to correctly describe binary 50% discount
- [ ] Clarify the discount condition (`balanceOf(user) > 0`)

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/hooks/ExitFeeHookExample.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/hooks/VeBALFeeDiscountHookExample.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-147 is complete
- [ ] Affected files exist

## Implementation Notes

1. This is a documentation-only change - no logic modifications
2. Read each file to understand the context before making changes
3. Keep comments concise and accurate

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (no test logic changes, just comments)
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
