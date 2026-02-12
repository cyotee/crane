# Task CRANE-247: Fix Misleading NatSpec in Burn Invariant Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** CRANE-104
**Worktree:** `fix/CRANE-247-fix-burn-invariant-natspec`
**Origin:** Code review suggestion from CRANE-104

---

## Description

Several NatSpec comments were simplified in ways that make them less accurate:

1. The contract-level doc on `CamelotV2_invariant` implies K never decreases on burns (incorrect - K decreases proportionally on burns)
2. `test_K_stable_after_burn` implies K is stable after burn (it isn't - it decreases proportionally). Should be renamed to `test_K_decreases_after_burn` or `test_reserves_positive_after_burn`
3. The handler comment on Check 3 claims "linear proportionality" but the code verifies quadratic proportionality (`K_after * r0_before^2 ~= K_before * r0_after^2`)

(Created from code review of CRANE-104)

## Dependencies

- CRANE-104: Add Burn Proportional Invariant Check (parent task - complete)

## User Stories

### US-CRANE-247.1: Accurate NatSpec for Burn Invariants

As a developer, I want NatSpec comments to accurately describe K invariant behavior per operation type so that future developers understand the correct invariants.

**Acceptance Criteria:**
- [ ] Restore detailed contract-level NatSpec documenting per-operation K behavior:
  - Swaps: K_new >= K_old (fees accumulate)
  - Mints: K_new > K_old (reserves increase)
  - Burns: K_new < K_old proportionally (expected)
- [ ] Rename `test_K_stable_after_burn` to accurately reflect what it tests
- [ ] Fix handler comment on Check 3 to say "quadratic" not "linear" proportionality
- [ ] Add correct derivation comment: if r0_after/r0_before = f, then K_after/K_before = f^2
- [ ] Tests pass (no logic changes, only comments/names)
- [ ] Build succeeds

## Technical Details

**Correct Derivation:**
```
If burns are proportional: r0_after / r0_before = r1_after / r1_before = f
Then: K_after = r0_after * r1_after = f * r0_before * f * r1_before = f^2 * K_before
So: K_after * r0_before^2 = K_before * r0_after^2 (quadratic, not linear)
```

**Test Suite:** Documentation only (comments + rename)

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_invariant.t.sol`
- `test/foundry/spec/protocols/dexes/camelot/v2/handlers/CamelotV2Handler.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-104 is complete
- [ ] CamelotV2_invariant.t.sol exists
- [ ] CamelotV2Handler.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
