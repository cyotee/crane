# Task CRANE-073: Tighten Non-Revert Assertions in Overflow Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-15
**Dependencies:** CRANE-026
**Worktree:** `fix/tighten-overflow-assertions`
**Origin:** Code review suggestion from CRANE-026

---

## Description

Replace vacuous assertions (e.g., `feeA >= 0`) and tautologies in the success-path tests with meaningful bounds or expected relationships so the tests verify correctness beyond "no revert."

For example:
- Assert `feeA + feeB` is bounded by `claimableA + claimableB`
- Check specific expected outputs for known inputs
- Add relationship assertions between computed values

(Created from code review of CRANE-026)

## Dependencies

- CRANE-026: Strengthen Overflow Boundary Tests (parent task - complete)

## User Stories

### US-CRANE-073.1: Meaningful Assertions

As a developer, I want overflow boundary tests to have meaningful assertions so that passing tests provide confidence in correctness, not just absence of reverts.

**Acceptance Criteria:**
- [x] Replace `feeA >= 0` style assertions with bounded checks
- [x] Add relationship assertions (e.g., fees <= claimable amounts)
- [x] Add known-input/expected-output spot checks where applicable
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_OverflowBoundary.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-026 is complete
- [x] ConstProdUtils_OverflowBoundary.t.sol exists

## Completion Criteria

- [x] All vacuous assertions replaced with meaningful bounds
- [x] Relationship assertions added where applicable
- [x] Tests pass
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
