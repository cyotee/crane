# Task CRANE-184: Add V3 Quoter Function Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-151
**Worktree:** `test/v3-quoter-tests`
**Origin:** Code review suggestion from CRANE-151

---

## Description

Add explicit tests for `quoteExactInputSingle` and `quoteExactOutputSingle` functions in the Quoter and QuoterV2 contracts.

(Created from code review of CRANE-151)

## Dependencies

- CRANE-151: Port and Verify Uniswap V3 Core + Periphery (parent task)

## User Stories

### US-CRANE-184.1: Add Quoter Function Tests

As a developer, I want explicit tests for quote functions so that quote behavior is directly verified.

**Acceptance Criteria:**
- [ ] Test for Quoter.quoteExactInputSingle
- [ ] Test for Quoter.quoteExactOutputSingle
- [ ] Test for QuoterV2.quoteExactInputSingle
- [ ] Test for QuoterV2.quoteExactOutputSingle
- [ ] Quote results match actual swap amounts
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/UniswapV3PeripheryRepo.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-151 is complete
- [ ] UniswapV3PeripheryRepo.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
