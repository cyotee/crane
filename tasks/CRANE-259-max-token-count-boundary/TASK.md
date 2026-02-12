# Task CRANE-259: Add Maximum Token Count Boundary Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-114
**Worktree:** `test/CRANE-259-max-token-count-boundary`
**Origin:** Code review suggestion from CRANE-114

---

## Description

Balancer V3's `WeightedPool` enforces `_MAX_TOKENS = 8`, but the Crane `BalancerV3WeightedPoolRepo` has no upper bound on the number of tokens. Either add a `MaxTokensExceeded` error to enforce the 8-token limit at the Repo level, or add a test documenting that large weight arrays (e.g., 100 tokens) are intentionally accepted. The decision should align with whether Crane pools will interoperate with Balancer V3 infrastructure.

(Created from code review of CRANE-114 - Suggestion 2)

## Dependencies

- CRANE-114: Add Explicit Negative Tests for Weight Validation (parent task)

## User Stories

### US-CRANE-259.1: Establish maximum token count policy

As a developer, I want the maximum token count for weighted pools to be explicitly defined and tested so that the behavior is documented and protected from regression.

**Acceptance Criteria:**
- [ ] Determine whether to enforce Balancer V3's 8-token limit or allow unbounded tokens
- [ ] If enforcing limit: add `MaxTokensExceeded(uint256 count, uint256 max)` error and revert test
- [ ] If allowing unbounded: add test confirming large arrays (e.g., 20+ tokens) succeed
- [ ] Document the design decision in NatSpec on `_initialize()`
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.sol
- test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-114 is complete
- [ ] `BalancerV3WeightedPoolRepo._initialize()` exists
- [ ] Balancer V3 upstream `_MAX_TOKENS` value is 8

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
