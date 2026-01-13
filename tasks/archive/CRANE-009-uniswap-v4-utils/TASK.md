# Task CRANE-009: Review — Uniswap V4 Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-uniswap-v4-utils`

---

## Description

Review Crane's Uniswap V4 utility surfaces for PoolManager integration, hook handling, delta accounting, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-009.1: Produce a Uniswap V4 Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases for Uniswap V4 integrations so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [ ] PROGRESS.md lists key invariants for Uniswap V4
- [ ] PROGRESS.md documents PoolManager singleton interactions
- [ ] PROGRESS.md documents hook integration points
- [ ] PROGRESS.md documents delta/flash accounting
- [ ] PROGRESS.md lists missing tests and recommended suites (unit/spec/fuzz)

## Technical Details

**Uniswap V4 Focus Areas:**
- PoolManager singleton pattern
- Pool initialization and configuration
- Hook lifecycle (beforeSwap, afterSwap, etc.)
- Delta accounting and settlement
- Flash accounting for atomic operations
- Currency (native ETH vs ERC20) handling
- PoolKey and PoolId derivation
- Fee handling with dynamic fees
- Liquidity operations through PoolManager

## Files to Create/Modify

**Documentation:**
- Write all review findings, analysis, and recommendations directly in `PROGRESS.md`
- Do NOT create separate memo files in `docs/`

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/protocols/dexes/uniswap/v4/`
- [ ] Identify PoolManager integration points
- [ ] Identify hook implementations if any
- [ ] Identify all public entrypoints and consumers

## Completion Criteria

- [ ] Review findings documented in PROGRESS.md
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
