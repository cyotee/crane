# Task CRANE-072: Add TokenConfigUtils Field Alignment Fuzz Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-051
**Worktree:** `test/tokenconfig-alignment-fuzz`
**Origin:** Code review suggestion from CRANE-051

---

## Description

Add a fuzz test that assigns distinct per-token metadata (e.g., `rateProvider = address(uint160(token) ^ 0x1234)`) and asserts that after sorting, each `token` still maps to its original metadata. Current fuzz tests verify ordering/length, but not alignment under arbitrary inputs.

This would directly guard against regressions of the original "swap only token address" bug class.

(Created from code review of CRANE-051)

## Dependencies

- CRANE-051: Fix TokenConfigUtils._sort() Data Corruption Bug (parent task)

## User Stories

### US-CRANE-072.1: Add field alignment fuzz test

As a developer, I want fuzz tests that verify field alignment is preserved under arbitrary inputs so that I can catch regressions where only the token address is swapped but metadata is corrupted.

**Acceptance Criteria:**
- [ ] Add fuzz test that generates distinct per-token metadata
- [ ] Assert that after sorting, each token maps to its original `rateProvider`, `tokenType`, and `paysYieldFees`
- [ ] Use deterministic metadata derivation (e.g., `address(uint160(token) ^ 0x1234)`)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/utils/TokenConfigUtils.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-051 is complete
- [ ] TokenConfigUtils.t.sol exists
- [ ] Current fuzz tests exist for ordering/length

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Fuzz tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
