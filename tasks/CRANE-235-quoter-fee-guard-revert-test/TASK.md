# Task CRANE-235: Add SlipstreamQuoter Fee Guard Revert Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** CRANE-095
**Worktree:** `test/quoter-fee-guard-revert`
**Origin:** Code review suggestion from CRANE-095

---

## Description

Add a test that verifies the `SL:INVALID_FEE` guard in `SlipstreamQuoter.sol` when `includeUnstakedFee` is true and the combined fee exceeds 1e6. The guard at line 83 of SlipstreamQuoter.sol is currently exercised through the `_quote()` function but has no dedicated revert test. This requires mocking the `ICLPool` interface to return an extreme `unstakedFee()` value.

(Created from code review of CRANE-095)

## Dependencies

- CRANE-095: Add Slipstream Combined Fee Guard (parent task - complete)

## User Stories

### US-CRANE-235.1: Verify SlipstreamQuoter fee guard revert

As a developer, I want to verify that `SlipstreamQuoter` reverts with `SL:INVALID_FEE` when the combined fee exceeds 1e6 so that the guard is proven to work in the quoter path.

**Acceptance Criteria:**
- [ ] Test mocks `ICLPool` to return a `fee()` and `unstakedFee()` that sum to >= 1e6
- [ ] Test verifies revert with `SL:INVALID_FEE` when `includeUnstakedFee` is true
- [ ] Test verifies NO revert when `includeUnstakedFee` is false (fee alone is valid)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- Test file for SlipstreamQuoter fee guard (new file or extension of existing quoter tests)

**Reference Files:**
- `contracts/utils/math/SlipstreamQuoter.sol` (line 83 - the guard under test)
- `test/foundry/spec/utils/math/slipstream/SlipstreamUtils_UnstakedFee.t.sol` (pattern reference)

## Inventory Check

Before starting, verify:
- [ ] CRANE-095 is complete
- [ ] `contracts/utils/math/SlipstreamQuoter.sol` exists and contains the guard
- [ ] Existing SlipstreamQuoter test patterns are available for reference

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
