# Task CRANE-177: Add NatSpec Examples to GradualValueChange Library

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-143
**Worktree:** `docs/gradualvaluechange-natspec`
**Origin:** Code review suggestion from CRANE-143

---

## Description

Add usage examples to the contract-level NatSpec documentation for the `GradualValueChange` library. The library has good function-level docs but could benefit from contract-level usage examples showing how to use the interpolation functions.

(Created from code review of CRANE-143)

## Dependencies

- CRANE-143: Refactor Balancer V3 Weighted Pool Package (parent task)

## User Stories

### US-CRANE-177.1: NatSpec Documentation

As a developer, I want GradualValueChange to have usage examples so that I can understand how to integrate it.

**Acceptance Criteria:**
- [ ] Add contract-level NatSpec with usage example
- [ ] Show typical LBP weight interpolation pattern
- [ ] Documentation is clear and accurate
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/GradualValueChange.sol`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
