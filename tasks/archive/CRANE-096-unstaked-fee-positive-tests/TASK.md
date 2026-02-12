# Task CRANE-096: Add Unstaked Fee Positive-Path Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-042
**Worktree:** `test/unstaked-fee-positive`
**Origin:** Code review suggestion from CRANE-042

---

## Description

Add positive-path tests that set `includeUnstakedFee=true` and verify that quotes change in the expected direction. Current tests primarily ensure backwards compatibility with `includeUnstakedFee=false`.

(Created from code review of CRANE-042)

## Dependencies

- CRANE-042: Add Unstaked Fee Handling (parent task - complete)

## User Stories

### US-CRANE-096.1: Add Positive-Path Tests for Unstaked Fee

As a developer, I want tests that verify the `includeUnstakedFee=true` code path so that the feature is properly validated.

**Acceptance Criteria:**
- [ ] Add test with `includeUnstakedFee=true` for SlipstreamQuoter
- [ ] Add test with `includeUnstakedFee=true` for SlipstreamZapQuoter (ZapIn)
- [ ] Add test with `includeUnstakedFee=true` for SlipstreamZapQuoter (ZapOut)
- [ ] Tests assert quotes change in expected direction (exact-in output decreases, exact-out input increases)
- [ ] MockCLPool exposes configurable `unstakedFee()` if needed
- [ ] `forge build` passes
- [ ] `forge test` passes

## Technical Details

The tests should:
1. Configure MockCLPool with a non-zero `unstakedFee()`
2. Call quote functions with `includeUnstakedFee=true`
3. Compare against `includeUnstakedFee=false` baseline
4. Assert the expected directional change

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamQuoter_tickCrossing.t.sol`
- `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamZapQuoter_ZapIn.t.sol`
- `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamZapQuoter_ZapOut.t.sol`

**Possibly Modified:**
- Mock contracts (if MockCLPool needs `unstakedFee()` support)

## Inventory Check

Before starting, verify:
- [ ] CRANE-042 is complete
- [ ] Affected test files exist
- [ ] MockCLPool interface available

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
