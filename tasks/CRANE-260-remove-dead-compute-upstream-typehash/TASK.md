# Task CRANE-260: Remove Dead _computeUpstreamRequestTypeHash Function

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-239 (Complete)
**Worktree:** `fix/CRANE-260-remove-dead-compute-upstream-typehash`
**Origin:** Code review suggestion from CRANE-239

---

## Description

Remove the unreferenced `_computeUpstreamRequestTypeHash()` function from `TestBase_OpenGSNFork.sol`. This function was bypassed during the CRANE-239 fix (which switched all call sites to use the stored `upstreamRequestTypeHash` field instead). Leaving the dead function in place creates a trap: a future developer might call it thinking it's the correct way to get the upstream type hash, re-introducing the original bug.

(Created from code review of CRANE-239)

## Dependencies

- CRANE-239: Fix OpenGSN Forwarder Fork Test Type Hash Registration (Complete)

## User Stories

### US-CRANE-260.1: Remove dead function

As a maintainer, I want the dead `_computeUpstreamRequestTypeHash()` function removed so that no future developer accidentally reintroduces the type hash mismatch bug.

**Acceptance Criteria:**
- [ ] `_computeUpstreamRequestTypeHash()` function deleted from `TestBase_OpenGSNFork.sol` (lines 148-155, including NatSpec)
- [ ] No references to the function remain in the codebase
- [ ] All 16 OpenGSN fork tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/fork/ethereum_main/gsn/TestBase_OpenGSNFork.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-239 is complete
- [ ] `TestBase_OpenGSNFork.sol` exists and contains the function

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
