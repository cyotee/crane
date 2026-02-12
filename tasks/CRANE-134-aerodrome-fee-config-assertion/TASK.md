# Task CRANE-134: Assert Aerodrome Fee Config in Stub

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-21
**Dependencies:** CRANE-084
**Worktree:** `test/aerodrome-fee-assertion`
**Origin:** Code review suggestion from CRANE-084

---

## Description

Add an assertion that the factory fees match expectations (stable 5 bps, volatile 30 bps) so the test fails loudly if stub defaults change.

This is a quick precondition check near the stable-vs-volatile comparison test that ensures the test's assumptions about fee differences are explicit and validated.

(Created from code review of CRANE-084)

## Dependencies

- CRANE-084: Strengthen Stable-vs-Volatile Slippage Assertion (Complete - parent task)

## User Stories

### US-CRANE-134.1: Assert Expected Fee Configuration

As a developer, I want the slippage comparison test to explicitly assert expected fee values so that the test fails loudly if stub defaults change unexpectedly.

**Acceptance Criteria:**
- [ ] Assertion added verifying stable pool fee is 5 bps (0.05%)
- [ ] Assertion added verifying volatile pool fee is 30 bps (0.3%)
- [ ] Assertions placed near the slippage comparison test as precondition checks
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-084 is complete
- [ ] AerodromServiceStable.t.sol exists with slippage comparison test
- [ ] Stub factory exposes fee configuration

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-path 'test/foundry/spec/protocols/dexes/aerodrome/**/*.t.sol'` passes
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
