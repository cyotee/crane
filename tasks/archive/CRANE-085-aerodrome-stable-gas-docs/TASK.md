# Task CRANE-085: Document Stable Swap-Deposit Gas/Complexity

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-037
**Worktree:** `docs/aerodrome-stable-gas`
**Origin:** Code review suggestion from CRANE-037

---

## Description

`_swapDepositStable` uses a 20-iteration binary search, each calling Newton-Raphson up to 255 iterations in the worst case. Add NatSpec documentation explaining:
- Expected convergence behavior
- Gas usage characteristics
- Early-exit heuristics if this will be used heavily on-chain

This is not a correctness blocker; tests pass and the approach matches Aerodrome's pool math.

(Created from code review of CRANE-037)

## Dependencies

- CRANE-037: Add Aerodrome Stable Pool Support (Complete - parent task)

## User Stories

### US-CRANE-085.1: Document Gas/Complexity

As a developer, I want to understand the gas and complexity characteristics of stable swap-deposit quoting so that I can make informed decisions about on-chain usage.

**Acceptance Criteria:**
- [ ] NatSpec added to `_swapDepositStable` explaining iteration limits
- [ ] NatSpec added to `_binarySearchOptimalSwapStable` explaining convergence
- [ ] Document expected gas range for typical inputs
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-037 is complete
- [x] AerodromServiceStable.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` succeeds
- [ ] Tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
