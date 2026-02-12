# Task CRANE-246: Add Debugging Info to Violation Tracking

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** CRANE-104
**Worktree:** `fix/CRANE-246-violation-tracking-debug-info`
**Origin:** Code review suggestion from CRANE-104

---

## Description

When a violation flag is set in the CamelotV2Handler, there's no way to determine which burn operation caused it or what the actual values were (since state is overwritten on each burn). Add a violation counter or store the first-violating burn's data in separate variables to aid debugging.

(Created from code review of CRANE-104)

## Dependencies

- CRANE-104: Add Burn Proportional Invariant Check (parent task - complete)

## User Stories

### US-CRANE-246.1: Violation Debugging Info

As a developer, I want violation tracking to preserve context about the first failure so that I can debug invariant violations without re-running with `-vvv` traces.

**Acceptance Criteria:**
- [ ] Add violation counter to track how many burns violated invariants
- [ ] Store first-violating burn's data (K values, reserves, LP amounts) in separate variables
- [ ] Preserve first violation data even when subsequent burns overwrite current state
- [ ] Add accessor functions for violation debug data
- [ ] Tests pass
- [ ] Build succeeds

## Technical Details

**Current Pattern:**
```solidity
// State is overwritten on each burn
burnKBefore = kBefore;
burnReserve0Before = r0Before;
// ...

// Violation flag set but no context preserved
if (violation) burnProportionalViolation = true;
```

**Improved Pattern:**
```solidity
uint256 public burnViolationCount;
uint256 public firstViolationKBefore;
uint256 public firstViolationKAfter;
// ...

if (violation) {
    burnProportionalViolation = true;
    burnViolationCount++;
    if (burnViolationCount == 1) {
        firstViolationKBefore = kBefore;
        firstViolationKAfter = kAfter;
        // ... store all relevant state
    }
}
```

**Test Suite:** Unit

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/handlers/CamelotV2Handler.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-104 is complete
- [ ] CamelotV2Handler.sol exists with burn violation tracking

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
