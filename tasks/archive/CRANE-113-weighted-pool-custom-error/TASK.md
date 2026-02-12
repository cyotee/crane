# Task CRANE-113: Replace require String with Custom Error in WeightedTokenConfigUtils

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-055
**Worktree:** `fix/weighted-pool-custom-error`
**Origin:** Code review suggestion from CRANE-055

---

## Description

Replace the `require(..., "Length mismatch")` string error in `WeightedTokenConfigUtils._sortWithWeights()` with a custom error for consistency with Crane patterns. Custom errors reduce bytecode size and provide standardized revert semantics.

(Created from code review of CRANE-055 - Suggestion 1)

## Dependencies

- CRANE-055: Implement Balancer V3 Weighted Pool Facet/Target (parent task)

## User Stories

### US-CRANE-113.1: Replace require with custom error

As a developer, I want consistent error handling so that all reverts follow Crane conventions and are gas-efficient.

**Acceptance Criteria:**
- [ ] Create `error LengthMismatch(uint256 expected, uint256 actual);` custom error
- [ ] Replace `require(tokenConfigs.length == normalizedWeights.length, "Length mismatch")` with custom error
- [ ] Update docstring comment (note that `sortedConfigs = tokenConfigs;` does not copy, it sorts in-place on memory array)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/pool-weighted/WeightedTokenConfigUtils.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-055 is complete/archived
- [ ] WeightedTokenConfigUtils.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Custom error follows Crane conventions
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
