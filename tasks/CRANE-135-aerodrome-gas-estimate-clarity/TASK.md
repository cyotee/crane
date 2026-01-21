# Task CRANE-135: Tighten/Clarify Aerodrome Gas Estimate Language

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-21
**Dependencies:** CRANE-085
**Worktree:** `docs/aerodrome-gas-clarity`
**Origin:** Code review suggestion from CRANE-085

---

## Description

Update the NatSpec gas notes to avoid "~25 gwei" (cost vs gas confusion), and clearly label the gas figures as "rough order-of-magnitude" / "environment-dependent" with a pointer to a reproducible measurement method (e.g., a Foundry gas snapshot or dedicated micro-benchmark test).

The current documentation provides gas estimates and references "mainnet, ~25 gwei", but gwei does not affect gas usage (only cost), and the estimates are not clearly sourced. This could miscalibrate expectations if developers treat the numbers as authoritative.

(Created from code review of CRANE-085)

## Dependencies

- CRANE-085: Document Stable Swap-Deposit Gas/Complexity (Complete - parent task)

## User Stories

### US-CRANE-135.1: Clarify Gas Documentation

As a developer, I want clear and accurate gas documentation so that I understand the actual gas usage without confusing gas units with gas cost.

**Acceptance Criteria:**
- [ ] Remove "~25 gwei" reference (gwei is cost, not gas)
- [ ] Label gas figures as "rough order-of-magnitude" or "environment-dependent"
- [ ] Add pointer to reproducible measurement method (Foundry gas snapshot or micro-benchmark)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-085 is complete
- [ ] AerodromServiceStable.sol exists with gas documentation

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-path '**/aerodrome/**'` passes
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
