# Task CRANE-069: Tighten Camelot Bidirectional Fuzz Assertion

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-044
**Worktree:** `test/camelot-bidirectional-fuzz`
**Origin:** Code review suggestion from CRANE-044

---

## Description

Tighten the "both directions" fuzz assertion in Camelot V2 asymmetric fee tests. The current `testFuzz_asymmetricFees_bothDirections` test validates fee selection via `_sortReservesStruct()` and that both swaps succeed, but does not assert output correctness against `ConstProdUtils._saleQuote`.

Consider splitting into two phases with fresh pools (or snapshot/restore) so each direction can be validated against the expected quote under known reserves.

(Created from code review of CRANE-044)

## Dependencies

- CRANE-044: Add Camelot V2 Asymmetric Fee Tests (parent task)

## User Stories

### US-CRANE-069.1: Add quote validation to bidirectional fuzz test

As a developer, I want the bidirectional fuzz test to validate swap outputs against expected quotes so that I can catch calculation regressions.

**Acceptance Criteria:**
- [ ] Split test into two phases with fresh pools OR use snapshot/restore
- [ ] Assert output correctness against `ConstProdUtils._saleQuote` for each direction
- [ ] Each direction validated under known reserves
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_asymmetricFees.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-044 is complete
- [ ] CamelotV2_asymmetricFees.t.sol exists
- [ ] Current testFuzz_asymmetricFees_bothDirections test exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Fuzz tests pass with new assertions
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
