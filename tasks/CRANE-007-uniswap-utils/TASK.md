# Task CRANE-007: Review — Uniswap Utilities (V2/V3/V4)

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-uniswap-utils`

---

## Description

Review Crane's Uniswap utility surfaces (V2, V3, V4) for quote correctness, rounding, revert expectations, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-007.1: Produce a Uniswap Utilities Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases for Uniswap integrations so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [ ] Memo lists key invariants per Uniswap version (V2, V3, V4)
- [ ] Memo documents rounding behavior and slippage assumptions
- [ ] Memo lists missing tests and recommended suites (unit/spec/fuzz)

## Technical Details

**Uniswap V2:**
- Quote calculations using constant product formula
- Fee handling (0.3% standard)
- Reserve-based pricing accuracy
- `getAmountOut` / `getAmountIn` correctness

**Uniswap V3:**
- Concentrated liquidity quote accuracy
- Tick math and price impact
- sqrtPriceX96 handling
- Multi-hop routing

**Uniswap V4:**
- Hook integration points
- Pool manager interactions
- Delta accounting
- Flash accounting

## Files to Create/Modify

**New Files:**
- `docs/review/uniswap-utils.md` - Review memo

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/protocols/dexes/uniswap/v2/`
- [ ] Review `contracts/protocols/dexes/uniswap/v3/`
- [ ] Review `contracts/protocols/dexes/uniswap/v4/`
- [ ] Identify all public entrypoints and consumers

## Completion Criteria

- [ ] Memo exists at `docs/review/uniswap-utils.md`
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
