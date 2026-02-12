# Task CRANE-110: Add Non-Zero Selector Guard to DFPkg Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-054
**Worktree:** `test/selector-nonzero-guard`
**Origin:** Code review suggestion from CRANE-054

---

## Description

In addition to checking for duplicate selectors, add a guard that no selector equals `bytes4(0)`. This catches "partially initialized array" issues even if they don't produce duplicates.

The current duplicate check would not fail if there is exactly one `0x00000000` selector.

(Created from code review of CRANE-054)

## Dependencies

- CRANE-054: Add DFPkg Deployment Test for Selector Collision (parent task)

## User Stories

### US-CRANE-110.1: Detect zero selectors in facet cuts

As a developer, I want tests to catch zero-value selectors so that partially initialized arrays fail fast.

**Acceptance Criteria:**
- [ ] Add assertion that no selector equals `bytes4(0)` in selector collision tests
- [ ] Test fails if any facet returns a zero selector
- [ ] Existing tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-054 is complete
- [ ] Real facets test file exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
