# Task CRANE-010: Review — Aerodrome V1 Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-aerodrome-v1-utils`

---

## Description

Review Crane's Aerodrome V1 utility surfaces for stable/volatile pool handling, quote accuracy, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-010.1: Produce an Aerodrome V1 Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases for Aerodrome V1 integrations so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [x] PROGRESS.md lists key invariants for Aerodrome V1
- [x] PROGRESS.md documents stable vs volatile pool differences
- [x] PROGRESS.md documents fee handling
- [x] PROGRESS.md lists missing tests and recommended suites (unit/spec/fuzz)

## Technical Details

**Aerodrome V1 Focus Areas:**
- Stable pool curve: `x³y + xy³ = k`
- Volatile pool curve: `x * y = k` (like Uniswap V2)
- Pool type detection and routing
- Fee structure and fee recipient
- veAERO gauge integration (if applicable)
- Router wrapper correctness
- Quote accuracy vs actual swap execution
- Pair factory interactions

## Files to Create/Modify

**Documentation:**
- Write all review findings, analysis, and recommendations directly in `PROGRESS.md`
- Do NOT create separate memo files in `docs/`

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [x] Review `contracts/protocols/dexes/aerodrome/v1/`
- [x] Identify stable vs volatile pool handling
- [x] Identify router and factory integrations
- [x] Identify all public entrypoints and consumers

## Completion Criteria

- [x] Review findings documented in PROGRESS.md
- [x] `forge build` passes
- [x] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
