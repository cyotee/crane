# Task CRANE-007: Review — Uniswap V2 Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-uniswap-v2-utils`

---

## Description

Review Crane's Uniswap V2 utility surfaces for quote correctness, constant product math accuracy, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-007.1: Produce a Uniswap V2 Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases for Uniswap V2 integrations so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [ ] PROGRESS.md lists key invariants for Uniswap V2
- [ ] PROGRESS.md documents constant product formula implementation
- [ ] PROGRESS.md documents fee handling (0.3% standard)
- [ ] PROGRESS.md lists missing tests and recommended suites (unit/spec/fuzz)

## Technical Details

**Uniswap V2 Focus Areas:**
- Constant product formula: `x * y = k`
- `getAmountOut` / `getAmountIn` correctness
- Fee deduction (997/1000 multiplier)
- Reserve-based pricing accuracy
- Minimum liquidity handling
- Price impact calculations
- Multi-hop routing accuracy

## Files to Create/Modify

**Documentation:**
- Write all review findings, analysis, and recommendations directly in `PROGRESS.md`
- Do NOT create separate memo files in `docs/`

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/protocols/dexes/uniswap/v2/`
- [ ] Identify router wrappers and quote utilities
- [ ] Identify all public entrypoints and consumers

## Completion Criteria

- [ ] Review findings documented in PROGRESS.md
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
