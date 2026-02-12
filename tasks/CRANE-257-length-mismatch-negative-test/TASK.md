# Task CRANE-257: Add Negative Test for WeightedTokenConfigUtils LengthMismatch

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-113
**Worktree:** `test/CRANE-257-length-mismatch-negative-test`
**Origin:** Code review suggestion from CRANE-113

---

## Description

Add a test that directly calls `WeightedTokenConfigUtils._sortWithWeights()` with arrays of different lengths and asserts the `LengthMismatch(uint256 expected, uint256 actual)` custom error reverts correctly. The function is `internal` to a library, so the test needs either a wrapper contract or a call path that doesn't pre-validate lengths. Currently, all callers (e.g., `BalancerV3WeightedPoolDFPkg.calcSalt`, `CowPoolDFPkg.calcSalt`) validate lengths with `WeightsTokensMismatch` before reaching `_sortWithWeights`, so this check is defense-in-depth.

(Created from code review of CRANE-113 - Suggestion 1)

## Dependencies

- CRANE-113: Replace require String with Custom Error in WeightedTokenConfigUtils (parent task)

## User Stories

### US-CRANE-257.1: Add LengthMismatch revert test

As a developer, I want a test covering the `LengthMismatch` revert path so that the defense-in-depth validation in `_sortWithWeights` is explicitly verified and protected from regression.

**Acceptance Criteria:**
- [ ] Create a test wrapper contract that exposes `_sortWithWeights` for testing (since it's `internal`)
- [ ] Add test asserting `LengthMismatch` revert when `tokenConfigs.length != normalizedWeights.length`
- [ ] Test verifies error parameters: `expected` = tokenConfigs.length, `actual` = weights.length
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/WeightedTokenConfigUtils.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-113 is complete
- [ ] `WeightedTokenConfigUtils.LengthMismatch` error exists
- [ ] `_sortWithWeights` is an internal library function

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
