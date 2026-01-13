# Task CRANE-008: Review — Aerodrome/Slipstream Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-aerodrome-slipstream-utils`

---

## Description

Review Crane's Aerodrome and Slipstream utility surfaces for quote correctness, concentrated liquidity handling, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-008.1: Produce an Aerodrome/Slipstream Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases for Aerodrome/Slipstream integrations so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [ ] Memo lists key invariants for Aerodrome V1 and Slipstream
- [ ] Memo documents concentrated liquidity specifics
- [ ] Memo lists missing tests and recommended suites (unit/spec/fuzz)

## Technical Details

**Aerodrome V1:**
- Stable and volatile pool types
- Fee tier handling
- Quote accuracy vs actual swap
- veAERO gauge integration (if applicable)

**Slipstream (Concentrated Liquidity):**
- Tick-based liquidity
- Price range handling
- Position management
- Fee accrual mechanics

## Files to Create/Modify

**New Files:**
- `docs/review/aerodrome-slipstream-utils.md` - Review memo

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/protocols/dexes/aerodrome/v1/`
- [ ] Review `contracts/protocols/dexes/aerodrome/slipstream/`
- [ ] Identify all public entrypoints and consumers

## Completion Criteria

- [ ] Memo exists at `docs/review/aerodrome-slipstream-utils.md`
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
