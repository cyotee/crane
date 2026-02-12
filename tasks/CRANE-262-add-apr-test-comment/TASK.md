# Task CRANE-262: Add Explanatory Comment for Large APR in Fork Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-238 (Complete)
**Worktree:** `docs/CRANE-262-add-apr-test-comment`
**Origin:** Code review suggestion from CRANE-238 (Suggestion 1)

---

## Description

Add a brief comment to the `test_calculateRewardAPR_livePool()` fork test explaining why the APR result can be extremely large (~7,006,862%). The test uses `liquidityValue = 1e18` (1 AERO nominal), which is intentionally small relative to the pool's reward rate (~2.57 AERO/sec on ~8.96e18 staked liquidity). The proportionality check is the true correctness validation, not the magnitude of the APR.

(Created from code review of CRANE-238)

## Dependencies

- CRANE-238: Fix test_calculateRewardAPR_livePool Assertion (Complete)

## User Stories

### US-CRANE-262.1: Add explanatory comment for large APR value

As a developer reading the fork test, I want a comment explaining why the APR can be ~7M% so that I understand the intentionally small `liquidityValue` produces a valid but large result and the proportionality assertion is the real correctness check.

**Acceptance Criteria:**
- [ ] Add comment near line ~580 (where `liquidityValue = 1e18`) explaining that 1 AERO is intentionally small relative to pool-scale rewards
- [ ] Note that the proportionality check is the primary correctness validation, not APR magnitude
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/fork/base_main/slipstream/SlipstreamRewardUtils_Fork.t.sol (line ~580)

## Inventory Check

Before starting, verify:
- [ ] SlipstreamRewardUtils_Fork.t.sol exists
- [ ] `test_calculateRewardAPR_livePool()` function exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
