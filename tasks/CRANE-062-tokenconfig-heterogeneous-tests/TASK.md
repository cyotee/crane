# Task CRANE-062: Add Heterogeneous TokenConfig Order-Independence Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-053
**Worktree:** `test/tokenconfig-heterogeneous`
**Origin:** Code review suggestion from CRANE-053 (Suggestion 3)

---

## Description

Add `calcSalt` and `processArgs` tests where each token has distinct config fields (rate provider, token type, fee flags) to ensure sorting preserves alignment and order-independence holds under realistic inputs.

The current tests mostly use identical/zeroed non-token fields, which could pass even if the sorting implementation was buggy. With distinct per-token fields, the tests will catch any field misalignment issues.

(Created from code review of CRANE-053)

## Dependencies

- CRANE-053: Create Comprehensive Test Suite for Balancer V3 (parent task)

## User Stories

### US-CRANE-062.1: Add heterogeneous TokenConfig test data

As a developer, I want tests with realistic heterogeneous token configs so that sorting edge cases are properly covered.

**Acceptance Criteria:**
- [ ] Test data includes tokens with different `tokenType` values
- [ ] Test data includes tokens with different `rateProvider` addresses
- [ ] Test data includes tokens with different `paysYieldFees` flags
- [ ] All permutations of token ordering produce the same `calcSalt` result

### US-CRANE-062.2: Add processArgs alignment assertions

As a developer, I want to verify that `processArgs` preserves field alignment after sorting.

**Acceptance Criteria:**
- [ ] After `processArgs`, each token's config fields are correctly paired
- [ ] Test asserts `tokenType`, `rateProvider`, `paysYieldFees` match the correct token
- [ ] Fuzz tests with random orderings verify alignment

## Files to Create/Modify

**Modified Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-053 is complete
- [ ] TokenConfigUtils._sort() fix is merged (swaps full structs)
- [ ] Existing calcSalt tests exist to extend

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
