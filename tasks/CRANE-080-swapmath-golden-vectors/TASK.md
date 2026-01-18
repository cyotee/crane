# Task CRANE-080: Add SwapMath Golden Vector Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-033
**Worktree:** `test/swapmath-golden-vectors`
**Origin:** Code review suggestion from CRANE-033

---

## Description

Add 3-6 deterministic "golden vector" exact-output assertions for `SwapMath.computeSwapStep()`. These should be known inputs → exact outputs vectors derived from the upstream Uniswap V4 reference implementation to catch subtle rounding/fee regressions.

(Created from code review of CRANE-033)

## Dependencies

- CRANE-033: Add Uniswap V4 Pure Math Unit Tests (Complete - parent task)

## User Stories

### US-CRANE-080.1: Add Golden Vector Tests

As a developer, I want deterministic test vectors for SwapMath so that I can catch subtle rounding and fee calculation regressions.

**Acceptance Criteria:**
- [x] 3-6 exact input/output test vectors added
- [x] Covers both swap directions (zeroForOne true/false)
- [x] Covers both modes (exactIn/exactOut)
- [x] At least one case that reaches target price
- [x] At least one case that exhausts amount before reaching target
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-033 is complete
- [x] SwapMath.t.sol exists

## Completion Criteria

- [x] All acceptance criteria met
- [x] `forge test --match-path 'test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.t.sol'` passes
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
